import pandas as pd
import json
import time
from datetime import datetime
from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient, NewTopic

KAFKA_BOOTSTRAP = 'localhost:9092'
COMPRESSION_FACTOR = 3600  # 1 real hour → 1 second

TOPICS = {
    'orders':  'olist.orders',
    'reviews': 'olist.reviews',
}

# CREATE TOPICS FIRST
print("Checking&creating Kafka topics...")

admin = AdminClient({
    'bootstrap.servers': KAFKA_BOOTSTRAP
})

existing_topics = admin.list_topics(timeout=10).topics

topics_to_create = []

for topic_name in TOPICS.values():
    if topic_name not in existing_topics:
        topics_to_create.append(
            NewTopic(
                topic_name,
                num_partitions=1,
                replication_factor=1
            )
        )

if topics_to_create:
    futures = admin.create_topics(topics_to_create)

    for topic, future in futures.items():
        try:
            future.result()
            print(f"Created topic: {topic}")
        except Exception as e:
            print(f"Failed to create topic {topic}: {e}")
else:
    print("All topics already exist.")

# small wait to ensure broker propagates metadata
time.sleep(2)

# LOAD DATA
print("\nLoading data...")

orders = pd.read_csv(
    'stream_orders.csv',
    parse_dates=[
        'order_purchase_timestamp',
        'order_approved_at',
        'order_delivered_carrier_date',
        'order_delivered_customer_date',
        'order_estimated_delivery_date',
    ]
)

items = pd.read_csv('stream_items.csv')

payments = pd.read_csv('stream_payments.csv')

customers = pd.read_csv('stream_customers.csv')

reviews = pd.read_csv(
    'stream_reviews.csv',
    parse_dates=[
        'review_creation_date',
        'review_answer_timestamp',
    ]
)

# BUILD LOOKUP DICTS
print("Building lookup dictionaries...")

items_lookup = (
    items.groupby('order_id')
         .apply(
             lambda x: x.to_dict('records'),
             include_groups=False
         )
         .to_dict()
)

payments_lookup = (
    payments.groupby('order_id')
            .apply(
                lambda x: x.to_dict('records'),
                include_groups=False
            )
            .to_dict()
)

customers_lookup = (
    customers.set_index('customer_id')
             .to_dict('index')
)


# ORDER STATUS TIMELINE
STATUS_TIMELINE = [
    ('order_purchase_timestamp', 'created'),
    ('order_approved_at', 'approved'),
    ('order_delivered_carrier_date', 'shipped'),
    ('order_delivered_customer_date', 'delivered'),
]

def ts(value):
    """Convert timestamp to string, return None if NaT."""
    return str(value) if pd.notna(value) else None

# BUILD ORDER EVENTS
print("Building order events...")

order_events = []

for _, row in orders.iterrows():

    order_id = row['order_id']
    customer_id = row['customer_id']

    for ts_col, status in STATUS_TIMELINE:

        event_time = row[ts_col]

        # stop if timestamp doesn't exist
        if pd.isna(event_time):
            break

        event = {
            'event_type': 'order_status',
            'order_id': order_id,
            'customer_id': customer_id,
            'order_status': status,
            'event_timestamp': str(event_time),
            'order_estimated_delivery_date':
                ts(row['order_estimated_delivery_date']),
        }

        # enrich only created event
        if status == 'created':
            event['customer'] = customers_lookup.get(customer_id, {})
            event['items'] = items_lookup.get(order_id, [])
            event['payments'] = payments_lookup.get(order_id, [])

        order_events.append(
            (event_time, TOPICS['orders'], event)
        )

# BUILD REVIEW EVENTS
print("Building review events...")

review_events = []

for _, row in reviews.iterrows():

    event_time = row['review_answer_timestamp']

    if pd.isna(event_time):
        continue

    event = {
        'event_type': 'review_submitted',
        'review_id': row['review_id'],
        'order_id': row['order_id'],
        'review_score': int(row['review_score']),
        'review_comment_title':
            row['review_comment_title']
            if pd.notna(row['review_comment_title'])
            else None,

        'review_comment_message':
            row['review_comment_message']
            if pd.notna(row['review_comment_message'])
            else None,

        'review_creation_date':
            ts(row['review_creation_date']),

        'review_answer_timestamp':
            str(event_time),
    }

    review_events.append(
        (event_time, TOPICS['reviews'], event)
    )

# MERGE + SORT EVENTS
all_events = order_events + review_events

all_events.sort(key=lambda x: x[0])

print(f"\nTotal events to stream: {len(all_events):,}")
print(f"  Order events:  {len(order_events):,}")
print(f"  Review events: {len(review_events):,}")

# KAFKA PRODUCER
producer = Producer({
    'bootstrap.servers': KAFKA_BOOTSTRAP,
})

def delivery_report(err, msg):
    if err:
        print(f"Delivery failed: {err}")

print(f"\nStarting stream with compression factor {COMPRESSION_FACTOR}x...")
print(f"(1 real hour = {3600 / COMPRESSION_FACTOR:.1f} second(s))\n")

prev_event_time = None

# STREAM EVENTS
for i, (event_time, topic, event) in enumerate(all_events):

    if prev_event_time is not None:

        real_gap_seconds = (
            event_time - prev_event_time
        ).total_seconds()

        sleep_seconds = (
            real_gap_seconds / COMPRESSION_FACTOR
        )

        if sleep_seconds > 0:
            time.sleep(sleep_seconds)

    producer.produce(
        topic,
        value=json.dumps(
            event,
            default=str
        ).encode('utf-8'),
        callback=delivery_report,
    )

    producer.poll(0)

    label = event.get('order_status', 'review')

    oid = event.get(
        'order_id',
        event.get('review_id', '')
    )

    print(
        f"[{i + 1:>6}] "
        f"{topic:<20} | "
        f"{label:<12} | "
        f"{oid} | "
        f"{event_time}"
    )

    prev_event_time = event_time

# FLUSH
producer.flush()

print("\nStream complete.")