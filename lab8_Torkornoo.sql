-- Task 1: single CTE
-- Who spent more than the average customer?
-- The CTE works out the spend first, so there is one row per customer.
-- The average in the where clause is then the average of 599 customer totals, which is what the task asks for. Averaging the payment table directly would give the average size of one payment instead.

with spend_per_customer as (
  select
    customer_id,
    round(sum(amount), 2) as total_spent
  from `sakila-aly6600.sakila.payment`
  group by customer_id
)
select
  s.customer_id,
  concat(c.first_name, ' ', c.last_name) as customer_name,
  s.total_spent
from spend_per_customer as s
join `sakila-aly6600.sakila.customer` as c using (customer_id)
where s.total_spent > (select avg(total_spent) from spend_per_customer)
order by s.total_spent desc;


-- Task 2: chained CTEs 
-- Top 5 cities by how many above-average spenders live there, plus the money those customers brought in.
-- Each CTE does one job and feeds the next one: spend_per_customer -> above_avg_spenders -> spenders_with_city

with spend_per_customer as (
  -- 1. total per customer
  select
    customer_id,
    round(sum(amount), 2) as total_spent
  from `sakila-aly6600.sakila.payment`
  group by customer_id
),
above_avg_spenders as (
  -- 2. only the ones over the average total
  select
    customer_id,
    total_spent
  from spend_per_customer
  where total_spent > (select avg(total_spent) from spend_per_customer)
),
spenders_with_city as (
  -- 3. customer -> address -> city
  select
    s.customer_id,
    s.total_spent,
    ci.city_id,
    ci.city
  from above_avg_spenders as s
  join `sakila-aly6600.sakila.customer` as c using (customer_id)
  join `sakila-aly6600.sakila.address` as a using (address_id)
  join `sakila-aly6600.sakila.city` as ci using (city_id)
)
-- 4. count and revenue per city, then rank.
-- I group on city_id too, since there are two different Londons in the city table. When I ran it, every city had exactly one above-average spender, so the count can't separate them. Revenue is the second sort key and city name the third, which gives a clear 1 to 5.

select
  row_number() over (
    order by count(*) desc, round(sum(total_spent), 2) desc, city
  ) as city_rank,
  city,
  count(*) as above_avg_customers,
  round(sum(total_spent), 2) as revenue
from spenders_with_city
group by city_id, city
order by city_rank
limit 5;
