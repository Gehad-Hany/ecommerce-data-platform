# ============================================================
#  Custom Kafka Connect image
#  Base  : Confluent cp-kafka-connect 7.6.1
#  Adds  : Debezium SQL Server 2.5.4
#           Snowflake Kafka Connector 2.1.2
#
#  Build : docker compose build connect
#          (or)  docker build -t ecommerce-kafka-connect ./connect
# ============================================================
FROM confluentinc/cp-kafka-connect:7.6.1

USER root

# Install Debezium SQL Server connector
RUN confluent-hub install --no-prompt \
        debezium/debezium-connector-sqlserver:2.5.4

# Install Snowflake Kafka Connector
RUN confluent-hub install --no-prompt \
        snowflakeinc/snowflake-kafka-connector:2.1.2

USER appuser
