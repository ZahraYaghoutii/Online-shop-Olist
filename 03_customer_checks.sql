#  find customers repeat delivered orders
select
	c.customer_unique_id,
    count(*) as delivered_orders,
    max(o.order_purchase_timestamp) as last_purchase_date
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
having count(*) >= 2
order by delivered_orders desc
limit 10;


# find the reference date for customer reactivation
select
	date(max(order_purchase_timestamp)) as analysis_date
from olist_analysis.orders
where order_status = 'delivered';

# find repeat customers inactive for more than 90 days
with analysis_reference as (
select
	date(max(order_purchase_timestamp)) as analysis_date
from olist_analysis.orders
where order_status = 'delivered'
),
repeat_customers as (
select
	c.customer_unique_id,
    count(*) as delivered_orders,
    date(max(o.order_purchase_timestamp)) as last_purchase_date
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
having count(*) >= 2
)
select
	r.customer_unique_id,
    r.delivered_orders,
    r.last_purchase_date,
    a.analysis_date,
    datediff(analysis_date, last_purchase_date) as day_since_purchase
from repeat_customers as r
cross join analysis_reference as a
where datediff(analysis_date, last_purchase_date) > 90
order by day_since_purchase desc;

# count customer reactivation candidates
with analysis_reference as (
select
	date(max(order_purchase_timestamp)) as analysis_date
from olist_analysis.orders
where order_status = 'delivered'
),
repeat_customers as (
select
	c.customer_unique_id,
    count(*) as delivered_orders,
    date(max(o.order_purchase_timestamp)) as last_purchase_date
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
having count(*) >= 2
)
select
	count(*) as reactivation_candidate
from repeat_customers as r
cross join analysis_reference as a
where datediff(a.analysis_date, r.last_purchase_date) > 90;

# calculate delivered goods value per customer
select
	c.customer_unique_id,
    sum(i.price) as delivered_goods_value
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
join olist_analysis.order_items as i
on o.order_id = i.order_id
where order_status = 'delivered'
group by c.customer_unique_id
order by delivered_goods_value desc
limit 10;

# Add goods value to customer reactivation candidates
with analysis_reference as (
select
	date(max(order_purchase_timestamp)) as analysis_date
from olist_analysis.orders
where order_status = 'delivered'
),
repeat_customers as (
select
	c.customer_unique_id,
    count(*) as delivered_orders,
    date(max(o.order_purchase_timestamp)) as last_purchase_date
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
having count(*) >= 2
),
customer_goods as (
select
	c.customer_unique_id,
    sum(i.price) as delivered_goods_value
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
join olist_analysis.order_items as i
on o.order_id = i.order_id
where order_status = 'delivered'
group by c.customer_unique_id
)
select
	r.customer_unique_id,
    r.delivered_orders,
    r.last_purchase_date,
    g.delivered_goods_value,
    datediff(analysis_date, last_purchase_date) as days_since_purchase
from repeat_customers as r
left join customer_goods as g
on g.customer_unique_id = r.customer_unique_id
cross join analysis_reference as a
where datediff(analysis_date, last_purchase_date) > 90
order by delivered_goods_value desc;

