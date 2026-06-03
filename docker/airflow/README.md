# Airflow orchestration

This Docker setup runs Apache Airflow with one DAG for the Snowflake/dbt part of the project.

The DAG runs:

1. `dbt debug`
2. silver models
3. intermediate models
4. gold models
5. validation models

## Run

From this folder:

```powershell
cd D:\ITI_tasks\ecommerce-data-platform\docker\airflow
docker compose up --build
```

Open Airflow:

```text
http://localhost:8080
```

Login:

```text
username: admin
password: admin
```

Trigger DAG:

```text
ecommerce_snowflake_dbt_pipeline
```
