--copy com
COPY olist_customers_dataset FROM 'C:\Users\pc\Downloads\archive\olist_customers_dataset.csv' DELIMITER ',' CSV HEADER;

--0COPY olist_geolocation_dataset FROM 'C:\Users\pc\Downloads\archive\olist_geolocation_dataset.csv' DELIMITER ',' CSV HEADER;

COPY olist_products_dataset FROM "C:\Users\pc\Downloads\archive\olist_products_dataset.csv' DELIMITER ',' CSV HEADER;

COPY olist_sellers_dataset FROM "C:\Users\pc\Downloads\archive\olist_sellers_dataset.csv' DELIMITER ',' CSV HEADER;

COPY olist_orders_dataset FROM "C:\Users\pc\Downloads\archive\olist_orders_dataset.csv' DELIMITER ',' CSV HEADER;

COPY olist_order_items_dataset FROM C:\Users\pc\Downloads\archive\olist_order_items_dataset.csv' DELIMITER ',' CSV HEADER;

COPY olist_order_payments_dataset FROM 'C:\Users\pc\Downloads\archive\olist_order_payments_dataset.csv' DELIMITER ',' CSV HEADER;

COPY olist_order_reviews_dataset FROM 'C:\Users\pc\Downloads\archive\olist_order_reviews_dataset.csv' DELIMITER ',' CSV HEADER;

COPY product_category_name_translation FROM 'C:\Users\pc\Downloads\archive\product_category_name_translation.csv' DELIMITER ',' CSV HEADER;



