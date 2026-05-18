# Agent Instructions

## Project Name

E-Commerce Data Platform for Batch Sales Analytics and CDC-Based Change Tracking

## General Rules

- Use English names for files, folders, tables, schemas, variables, and comments.
- Do not build the whole project at once.
- Focus only on the task requested by the user.
- Keep the folder structure professional and clean.
- Explain the plan before writing code.
- Prefer beginner-friendly data engineering patterns.
- Do not add unnecessary complexity.
- Do not rename existing folders or files unless requested.
- Do not delete existing files unless requested.

## Current Project Scope

For now, the project focuses only on:

- Batch pipeline preparation
- SQL Server source database setup
- Raw data organization
- CDC preparation
- Python ingestion preparation
- Documentation

## Important Restrictions

Do not add or implement the following unless explicitly requested:

- Snowflake
- dbt
- Kafka
- Debezium
- Databricks
- Power BI
- Real-time orders API
- Full Docker environment
- Full Airflow DAGs

These tools will be added later.

## Coding Style

- Write clean and simple code.
- Add comments when needed.
- Use clear function names.
- Use clear file names.
- Avoid hardcoded credentials.
- Use `.env` files for sensitive configuration.
- Keep scripts modular and easy to understand.

## SQL Rules

- Use clear SQL formatting.
- Use schema names clearly.
- Keep SQL scripts separated by purpose.
- Do not mix database creation, table creation, data loading, and CDC setup in one file.
- Use SQL Server syntax.
- Do not create warehouse or dbt models yet.

## Python Rules

- Use Python only when needed for ingestion or automation.
- Keep scripts simple.
- Use environment variables for database connections.
- Do not write large complex pipelines unless requested.
- Do not add Spark code yet unless requested.

## Documentation Rules

- Keep documentation clear and short.
- Use markdown files for project explanation.
- Explain what each folder or script is used for.
- Do not add long theoretical explanations unless requested.

## Current Expected Work

The current work should focus on:

1. Creating the project structure
2. Preparing documentation files
3. Preparing SQL Server scripts
4. Preparing raw data folders
5. Preparing the project for batch ingestion and CDC setup

## Final Note

Always follow the user step by step.

Do not jump to future tools or future phases unless the user asks for them.