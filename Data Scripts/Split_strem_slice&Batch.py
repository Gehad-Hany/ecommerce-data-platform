#Impoert pandas library
import pandas as pd 

#Read tables fro csv
orders=pd.read_csv("olist_orders_dataset.csv",parse_dates=["order_purchase_timestamp"] )
customers=pd.read_csv("olist_customers_dataset.csv")
items=pd.read_csv("olist_order_items_dataset.csv")
reviews=pd.read_csv("olist_order_reviews_dataset.csv")
payments=pd.read_csv("olist_order_payments_dataset.csv")

slice=orders["order_purchase_timestamp"] >= "2018-07-01" 

#Take the slice of the orders table
stream_orders=orders[slice]
Batch_orders=orders[~slice] # all before 2018-07-01

#order_ids of stream orders
stream_order_ids=stream_orders["order_id"]
batch_order_ids=Batch_orders["order_id"]

#Take the slice of the items table
stream_items=items[items["order_id"].isin(stream_order_ids)] 
Batch_items=items[items["order_id"].isin(batch_order_ids)]

#Take the slice of the reviews table
stream_reviews=reviews[reviews["order_id"].isin(stream_order_ids)] 
Batch_reviews=reviews[reviews["order_id"].isin(batch_order_ids)]

#Take the slice of the payments table
stream_payments=payments[payments["order_id"].isin(stream_order_ids)]   
Batch_payments=payments[payments["order_id"].isin(batch_order_ids)]

#To get strem slice from customers table we need to get the customer_ids of stream orders and then take the slice of customers table based on those customer_ids
#customer_ids of stream orders
stream_customer_ids=stream_orders["customer_id"]

#Take the slice of the customers table
stream_customers=customers[customers["customer_id"].isin(stream_customer_ids)] 
Batch_customers=customers[~customers["customer_id"].isin(stream_customer_ids)]

#save the stream and batch slices to csv files
stream_orders.to_csv("Stream/stream_orders.csv", index=False) 
Batch_orders.to_csv("Batch/Batch_orders.csv", index=False)
stream_items.to_csv("Stream/stream_items.csv", index=False)
Batch_items.to_csv("Batch/Batch_items.csv", index=False)
stream_reviews.to_csv("Stream/stream_reviews.csv", index=False)
Batch_reviews.to_csv("Batch/Batch_reviews.csv", index=False)
stream_payments.to_csv("Stream/stream_payments.csv", index=False)
Batch_payments.to_csv("Batch/Batch_payments.csv", index=False)
stream_customers.to_csv("Stream/stream_customers.csv", index=False)
Batch_customers.to_csv("Batch/Batch_customers.csv", index=False)
