from __future__ import annotations

import os
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

PROJECT_ROOT = os.environ.get(
    "ECOMMERCE_PROJECT_DIR",
    "/opt/airflow/ecommerce-data-platform",
)
DBT_PROJECT_DIR = f"{PROJECT_ROOT}/dbt/ecommerce_analytics"


def dbt_task(task_id: str, command: str) -> BashOperator:
    return BashOperator(
        task_id=task_id,
        bash_command=command,
        cwd=DBT_PROJECT_DIR,
        append_env=True,
    )


with DAG(
    dag_id="ecommerce_snowflake_dbt_pipeline",
    description="Run the e-commerce Snowflake dbt pipeline.",
    start_date=datetime(2026, 5, 28),
    schedule=None,
    catchup=False,
    tags=["ecommerce", "snowflake", "dbt"],
) as dag:
    start = EmptyOperator(task_id="start")
    dbt_debug = dbt_task("dbt_debug", "dbt debug")
    run_silver = dbt_task("run_silver_models", "dbt run --select path:models/silver")
    run_intermediate = dbt_task("run_intermediate_models", "dbt run --select path:models/intermediate")
    run_gold = dbt_task("run_gold_models", "dbt run --select path:models/gold")
    run_validations = dbt_task(
        "run_validation_models",
        "dbt run --select silver_validation_summary stream_silver_validation_summary cdc_silver_validation_summary intermediate_unified_validation_summary gold_validation_summary"
    )
    end = EmptyOperator(task_id="end")

    start >> dbt_debug >> run_silver >> run_intermediate >> run_gold >> run_validations >> end