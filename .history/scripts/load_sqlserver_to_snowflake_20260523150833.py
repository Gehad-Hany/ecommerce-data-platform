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


TABLE_MAPPINGS = [
    TableMapping("sales.customers", "CUSTOMERS"),
    TableMapping("sales.orders", "ORDERS"),
    TableMapping("sales.order_items", "ORDER_ITEMS"),
    TableMapping("sales.order_payments", "ORDER_PAYMENTS"),
    TableMapping("sales.order_reviews", "ORDER_REVIEWS"),
    TableMapping("sales.products", "PRODUCTS"),
    TableMapping("sales.sellers", "SELLERS"),
    TableMapping("sales.product_category_translation", "PRODUCT_CATEGORY_TRANSLATION"),
    TableMapping("geolocation.geolocation", "GEOLOCATION"),
    TableMapping("calendar.brazil_holidays", "BRAZIL_HOLIDAYS"),
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


def truncate_target_table(sf_conn, target_table: str) -> None:
    with sf_conn.cursor() as cursor:
        cursor.execute(f"TRUNCATE TABLE {target_table}")


def get_target_row_count(sf_conn, target_table: str) -> int:
    with sf_conn.cursor() as cursor:
        cursor.execute(f"SELECT COUNT(*) FROM {target_table}")
        return int(cursor.fetchone()[0])


def load_table(sql_conn, sf_conn, mapping: TableMapping, chunk_size: int) -> None:
    print(f"Loading {mapping.source_table} -> RAW_BATCH.{mapping.target_table}")

    truncate_target_table(sf_conn, mapping.target_table)

    query = f"SELECT * FROM {mapping.source_table}"
    total_rows = 0
    chunk_number = 0

    for chunk in pd.read_sql_query(query, sql_conn, chunksize=chunk_size):
        chunk_number += 1
        chunk = normalize_dataframe(chunk)

        success, _, inserted_rows, _ = write_pandas(
            conn=sf_conn,
            df=chunk,
            table_name=mapping.target_table,
            database=get_env("SNOWFLAKE_DATABASE", "ECOMMERCE_ANALYTICS_DB"),
            schema=get_env("SNOWFLAKE_SCHEMA", "RAW_BATCH"),
            quote_identifiers=False,
            auto_create_table=False,
            overwrite=False,
        )

        if not success:
            raise RuntimeError(f"Failed to load table: {mapping.target_table}")

        total_rows += inserted_rows
        print(f"  chunk {chunk_number}: {inserted_rows} rows")

    target_count = get_target_row_count(sf_conn, mapping.target_table)
    print(f"Finished {mapping.target_table}: loaded={total_rows}, target_count={target_count}")

    if target_count != total_rows:
        raise RuntimeError(
            f"Row count mismatch for {mapping.target_table}: "
            f"loaded={total_rows}, target_count={target_count}"
        )


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