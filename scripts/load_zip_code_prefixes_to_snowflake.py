from __future__ import annotations

import sys

from load_sqlserver_to_snowflake import (
    TableMapping,
    connect_snowflake,
    connect_sqlserver,
    get_env,
    load_table,
)


ZIP_CODE_PREFIXES_MAPPING = TableMapping(
    source_table="geolocation.zip_code_prefixes",
    target_table="ZIP_CODE_PREFIXES",
    key_columns=("ZIP_CODE_PREFIX",),
)


def main() -> int:
    chunk_size = int(get_env("LOAD_CHUNK_SIZE", "50000"))

    print("Starting SQL Server to Snowflake RAW_BATCH zip code prefixes load")
    print(f"Chunk size: {chunk_size}")

    sql_conn = connect_sqlserver()
    sf_conn = connect_snowflake()

    try:
        load_table(sql_conn, sf_conn, ZIP_CODE_PREFIXES_MAPPING, chunk_size)
    finally:
        sql_conn.close()
        sf_conn.close()

    print("ZIP_CODE_PREFIXES loaded successfully")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
