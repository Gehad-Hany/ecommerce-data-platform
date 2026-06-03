from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import pyodbc
import snowflake.connector
from dotenv import load_dotenv
from snowflake.connector.pandas_tools import write_pandas


PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")


@dataclass(frozen=True)
class TableMapping:
    source_table: str
    target_table: str
    key_columns: tuple[str, ...]


TABLE_MAPPINGS = [
    TableMapping("sales.customers", "CUSTOMERS", ("CUSTOMER_ID",)),
    TableMapping("sales.orders", "ORDERS", ("ORDER_ID",)),
    TableMapping("sales.order_items", "ORDER_ITEMS", ("ORDER_ID", "ORDER_ITEM_ID")),
    TableMapping("sales.order_payments", "ORDER_PAYMENTS", ("ORDER_ID", "PAYMENT_SEQUENTIAL")),
    TableMapping("sales.order_reviews", "ORDER_REVIEWS", ("REVIEW_ID", "ORDER_ID")),
    TableMapping("sales.products", "PRODUCTS", ("PRODUCT_ID",)),
    TableMapping("sales.sellers", "SELLERS", ("SELLER_ID",)),
    TableMapping("sales.product_category_translation", "PRODUCT_CATEGORY_TRANSLATION", ("PRODUCT_CATEGORY_NAME",)),
    TableMapping(
        "geolocation.geolocation",
        "GEOLOCATION",
        (
            "GEOLOCATION_ZIP_CODE_PREFIX",
            "GEOLOCATION_LAT",
            "GEOLOCATION_LNG",
            "GEOLOCATION_CITY",
            "GEOLOCATION_STATE",
        ),
    ),
    TableMapping("calendar.brazil_holidays", "BRAZIL_HOLIDAYS", ("CALENDAR_DATE", "EVENT_NAME")),
]


TIMESTAMP_COLUMNS = {
    "ORDER_PURCHASE_TIMESTAMP",
    "ORDER_APPROVED_AT",
    "ORDER_DELIVERED_CARRIER_DATE",
    "ORDER_DELIVERED_CUSTOMER_DATE",
    "ORDER_ESTIMATED_DELIVERY_DATE",
    "SHIPPING_LIMIT_DATE",
    "REVIEW_CREATION_DATE",
    "REVIEW_ANSWER_TIMESTAMP",
}

DATE_COLUMNS = {
    "CALENDAR_DATE",
}


def get_env(name: str, default: str | None = None, required: bool = False) -> str:
    value = os.getenv(name, default)
    if required and not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value or ""


def build_sqlserver_connection_string() -> str:
    driver = get_env("SQLSERVER_DRIVER", "ODBC Driver 17 for SQL Server")
    server = get_env("SQLSERVER_SERVER", required=True)
    database = get_env("SQLSERVER_DATABASE", "Ecommerce_Source_DB")
    trusted = get_env("SQLSERVER_TRUSTED_CONNECTION", "yes").lower()

    if trusted in {"yes", "true", "1"}:
        return (
            f"DRIVER={{{driver}}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            "Trusted_Connection=yes;"
            "TrustServerCertificate=yes;"
        )

    username = get_env("SQLSERVER_USERNAME", required=True)
    password = get_env("SQLSERVER_PASSWORD", required=True)

    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "TrustServerCertificate=yes;"
    )


def connect_sqlserver():
    return pyodbc.connect(build_sqlserver_connection_string())


def connect_snowflake():
    return snowflake.connector.connect(
        account=get_env("SNOWFLAKE_ACCOUNT", required=True),
        user=get_env("SNOWFLAKE_USER", required=True),
        password=get_env("SNOWFLAKE_PASSWORD", required=True),
        role=get_env("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
        warehouse=get_env("SNOWFLAKE_WAREHOUSE", "ECOMMERCE_INGEST_WH"),
        database=get_env("SNOWFLAKE_DATABASE", "ECOMMERCE_ANALYTICS_DB"),
        schema=get_env("SNOWFLAKE_SCHEMA", "RAW_BATCH"),
    )


def normalize_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [column.upper() for column in df.columns]

    for column in df.select_dtypes(include=["object"]).columns:
        df[column] = df[column].where(df[column].isna(), df[column].astype(str).str.strip())

    for column in TIMESTAMP_COLUMNS:
        if column in df.columns:
            parsed_dates = pd.to_datetime(df[column], errors="coerce")
            df[column] = parsed_dates.dt.strftime("%Y-%m-%d %H:%M:%S")
            df[column] = df[column].where(parsed_dates.notna(), None)

    for column in DATE_COLUMNS:
        if column in df.columns:
            parsed_dates = pd.to_datetime(df[column], errors="coerce")
            df[column] = parsed_dates.dt.strftime("%Y-%m-%d")
            df[column] = df[column].where(parsed_dates.notna(), None)

    return df


def create_temp_table(sf_conn, target_table: str, temp_table: str) -> None:
    with sf_conn.cursor() as cursor:
        cursor.execute(f"CREATE OR REPLACE TEMP TABLE {temp_table} LIKE {target_table}")


def get_target_row_count(sf_conn, target_table: str) -> int:
    with sf_conn.cursor() as cursor:
        cursor.execute(f"SELECT COUNT(*) FROM {target_table}")
        return int(cursor.fetchone()[0])


def build_null_safe_match(columns: list[str], left_alias: str = "tgt", right_alias: str = "src") -> str:
    return " AND ".join(
        f"{left_alias}.{column} IS NOT DISTINCT FROM {right_alias}.{column}"
        for column in columns
    )


def merge_temp_table(sf_conn, target_table: str, temp_table: str, columns: list[str], key_columns: tuple[str, ...]) -> None:
    key_columns = tuple(column.upper() for column in key_columns)
    non_key_columns = [column for column in columns if column not in key_columns]
    match_condition = build_null_safe_match(list(key_columns))
    insert_columns = ", ".join(columns)
    insert_values = ", ".join(f"src.{column}" for column in columns)

    if non_key_columns:
        update_assignments = ", ".join(
            f"{column} = src.{column}"
            for column in non_key_columns
        )
        change_condition = " OR ".join(
            f"tgt.{column} IS DISTINCT FROM src.{column}"
            for column in non_key_columns
        )
        matched_clause = f"""
        WHEN MATCHED AND ({change_condition}) THEN
            UPDATE SET {update_assignments}
        """
    else:
        matched_clause = ""

    merge_sql = f"""
        MERGE INTO {target_table} AS tgt
        USING {temp_table} AS src
            ON {match_condition}
        {matched_clause}
        WHEN NOT MATCHED THEN
            INSERT ({insert_columns})
            VALUES ({insert_values})
    """

    with sf_conn.cursor() as cursor:
        cursor.execute(merge_sql)


def load_table(sql_conn, sf_conn, mapping: TableMapping, chunk_size: int) -> None:
    print(f"Loading {mapping.source_table} -> RAW_BATCH.{mapping.target_table}")

    query = f"SELECT * FROM {mapping.source_table}"
    total_rows = 0
    chunk_number = 0

    for chunk in pd.read_sql_query(query, sql_conn, chunksize=chunk_size):
        chunk_number += 1
        chunk = normalize_dataframe(chunk)
        temp_table = f"{mapping.target_table}__LOAD_TMP_{chunk_number}"
        columns = list(chunk.columns)

        create_temp_table(sf_conn, mapping.target_table, temp_table)

        success, _, inserted_rows, _ = write_pandas(
            conn=sf_conn,
            df=chunk,
            table_name=temp_table,
            database=get_env("SNOWFLAKE_DATABASE", "ECOMMERCE_ANALYTICS_DB"),
            schema=get_env("SNOWFLAKE_SCHEMA", "RAW_BATCH"),
            quote_identifiers=False,
            auto_create_table=False,
            overwrite=False,
        )

        if not success:
            raise RuntimeError(f"Failed to load table: {mapping.target_table}")

        merge_temp_table(sf_conn, mapping.target_table, temp_table, columns, mapping.key_columns)

        total_rows += inserted_rows
        print(f"  chunk {chunk_number}: staged={inserted_rows} rows, merged into target")

    target_count = get_target_row_count(sf_conn, mapping.target_table)
    print(f"Finished {mapping.target_table}: staged={total_rows}, target_count={target_count}")


def main() -> int:
    chunk_size = int(get_env("LOAD_CHUNK_SIZE", "50000"))

    print("Starting SQL Server to Snowflake RAW_BATCH load")
    print(f"Chunk size: {chunk_size}")

    sql_conn = connect_sqlserver()
    sf_conn = connect_snowflake()

    try:
        for mapping in TABLE_MAPPINGS:
            load_table(sql_conn, sf_conn, mapping, chunk_size)
    finally:
        sql_conn.close()
        sf_conn.close()

    print("All RAW_BATCH tables loaded successfully")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
