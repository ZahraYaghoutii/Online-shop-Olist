# check delivery date completeness
select
	count(*) as delivered_orders,
    count(*) - count(order_delivered_customer_date) as missing_actual_delivery_dates,
    count(*) - count(order_estimated_delivery_date) as missing_estimated_delivery_dates
from olist_analysis.orders
where order_status = 'delivered';


# calculate delivery diffrence in days
select
	order_id,
    date(order_delivered_customer_date) as actual_delivery_date,
    date(order_estimated_delivery_date) as estimated_delivery_date,
    datediff(order_delivered_customer_date, order_estimated_delivery_date) as delivery_difference_days
from olist_analysis.orders
where order_status = 'delivered'
and
order_delivered_customer_date is not null
and
order_estimated_delivery_date is not null
order by delivery_difference_days desc
limit 20;


# count orders by delivery timing
with delivery_check as (
select
    datediff(order_delivered_customer_date, order_estimated_delivery_date) as delivery_difference_days
from olist_analysis.orders
where order_status = 'delivered'
and
order_delivered_customer_date is not null
and
order_estimated_delivery_date is not null
)
select
	count(*) as evaluated_orders,
    sum(delivery_difference_days < 0) as early_orders,
    sum(delivery_difference_days = 0) as on_time_orders,
    sum(delivery_difference_days > 0) as late_orders
from delivery_check;

# calculate the late delivery rate
with delivery_check as (
select
	datediff(order_delivered_customer_date, order_estimated_delivery_date) as delivery_difference_days
from olist_analysis.orders
where order_status = 'delivered'
and
order_delivered_customer_date is not null
and
order_estimated_delivery_date is not null
)
select
	count(*) as evaluated_orders,
    sum(delivery_difference_days > 0) as late_orders,
    round(sum(delivery_difference_days > 0) / nullif(count(*), 0) * 100, 2) as late_delivery_percent
from delivery_check;


# calculate the late delivery rate by customer state
with delivery_by_state as (
select
	c.customer_state,
    datediff(order_delivered_customer_date, order_estimated_delivery_date) as diffrence_days
from olist_analysis.customers as c
join olist_analysis.orders as o
on o.customer_id = c.customer_id
where o.order_status = 'delivered'
and
order_delivered_customer_date is not null
and 
order_estimated_delivery_date is not null
)
select
	customer_state,
    count(*) evaluated_orders,
    sum(diffrence_days > 0) as late_delivery,
    round(sum(diffrence_days > 0) / nullif(count(*), 0) * 100, 2) as late_delivery_percent
from delivery_by_state
group by customer_state
order by late_delivery_percent desc;


# compare imported review counts by score
select
	review_score,
    count(*) as review_count
from olist_analysis.reviews
group by review_score
order by review_score;


# check wether the first source review was imported
select 
	review_id,
    order_id,
    review_score,
    review_creation_date
from olist_analysis.reviews
where review_id = '7bc2406110b926393aa56f80a40eba40';


# Restore the missing source review


INSERT INTO olist_analysis.reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    '7bc2406110b926393aa56f80a40eba40',
    '73fc7af87114b39712e6da79b0a377eb',
    4,
    NULL,
    NULL,
    '2018-01-18 00:00:00',
    '2018-01-18 21:46:59'
WHERE NOT EXISTS (
    SELECT 1
    FROM olist_analysis.reviews
    WHERE review_id = '7bc2406110b926393aa56f80a40eba40'
);

select 
	count(*) as review_rows,
    sum(review_score = 4) as score_4
from olist_analysis.reviews;

# compare review score by delivery timing
with delivery_groups as (
select order_id,
case
	when order_status <> 'delivered' or order_delivered_customer_date is null or order_estimated_delivery_date is null then 'Not Evaluated'
    when datediff(order_delivered_customer_date, order_estimated_delivery_date) < 0 then 'Early'
    when datediff(order_delivered_customer_date, order_estimated_delivery_date) = 0 then 'On Time'
    else 'Late'
    end as delivery_timing
from olist_analysis.orders
)
select
	d.delivery_timing,
	count(r.review_score) as review_score_count,
	round(avg(r.review_score), 2) as averege_review_score
from delivery_groups as d
join olist_analysis.reviews as r
on r.order_id = d.order_id
group by d.delivery_timing
order by averege_review_score desc;