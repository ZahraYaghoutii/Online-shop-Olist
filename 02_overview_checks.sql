# check total ordrs and order ID uniqueness
select count(*) as total_rows, count(distinct order_id) as unique_orders from olist_analysis.orders;

# check delivered goods value excluding freight
select 
	round(sum(i.price), 2) as deliverd_goods_value
from olist_analysis.order_items as i
inner join olist_analysis.orders as o
on o.order_id = i.order_id
where order_status = 'delivered';

# check monthly order count
select
	date_format(order_purchase_timestamp, '%Y-%m') as purchase_month,
    count(*) as total_rows
from olist_analysis.orders
group by date_format(order_purchase_timestamp, '%Y-%m')
order by purchase_month;

# check imported customer rows and unique customer IDs
select
	count(*) as imported_rows,
    count(distinct customer_id) as unique_customer_ids,
    count(distinct customer_unique_id) as unique_customers
from olist_analysis.customers;


# check order count by customer state
select
	c.customer_state,
    count(*) as total_orders
from olist_analysis.orders as o
join olist_analysis.customers as c
on o.customer_id = c.customer_id
group by c.customer_state
order by total_orders desc;

# check order counts after joining customers 
select
    count(*) as joined_rows,
    count(distinct o.order_id) as unique_orders
from olist_analysis.orders as o
join olist_analysis.customers as c
on o.customer_id = c.customer_id;


show tables from olist_analysis;

# check product row counts and unique IDs
select
	count(*) as product_rows,
    count(distinct product_id) as unique_products,
    count(*) - count(product_category_name) as missing_categories
from olist_analysis.products;

# check category translation quality
select
	count(*) as translation_rows,
    count(distinct product_category_name) as unique_categories,
    count(*) - count(product_category_name_english) as missing_names
from olist_analysis.category_translation;

# check top 5 category by delivered goods value
select
	t.product_category_name_english as category,
    sum(i.price) as delivered_goods_value
from olist_analysis.order_items as i
join olist_analysis.orders as o
on i.order_id = o.order_id
join olist_analysis.products as p
on p.product_id = i.product_id
join olist_analysis.category_translation as t
on t.product_category_name = p.product_category_name
where o.order_status = 'delivered'
group by t.product_category_name_english
order by delivered_goods_value desc
limit 5;



select 1 as connection_test;
show full processlist;
kill query 20;
show index from olist_analysis.products;
show index from olist_analysis.order_items;
show index from olist_analysis.orders;
show index from olist_analysis.category_translation;

# Add index for the category sales report
create index idx_items_order on olist_analysis.order_items(order_id);
create index idx_orders_id on olist_analysis.orders(order_id);
create index idx_items_product on olist_analysis.order_items(product_id);
create index idx_product_id on olist_analysis.products(product_id);
create index idx_product_category on olist_analysis.products(product_category_name);
create index idx_translation_category on olist_analysis.category_translation(product_category_name);

# check delivery goods without category_translation
select
	p.product_category_name as original_category,
    count(*) as item_count,
    sum(i.price) as delivered_goods_value
from olist_analysis.order_items as i
join olist_analysis.orders as o
on o.order_id = i.order_id
left join olist_analysis.products as p
on p.product_id = i.product_id
left join olist_analysis.category_translation as t
on t.product_category_name = p.product_category_name
where order_status = 'delivered' and t.product_category_name_english is null
group by p.product_category_name
order by delivered_goods_value desc;

# calculate total delivered goods value
select
	sum(i.price) as total_delivered_goods_value
from olist_analysis.order_items as i
join olist_analysis.orders as o
on o.order_id = i.order_id
where o.order_status = 'delivered';


# calculate the share of goods without category
select round(175967.21/13221498.11 *100, 2) as missing_translation_percent;