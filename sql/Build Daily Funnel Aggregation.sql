--this whole script is a 3-layer pipeline:
--base = raw GA4 events, cleaned + session id extracted
--session_funnel = one row per session, with funnel step flags + revenue

--Final SELECT = daily aggregation of sessions → counts, conversion rates, AOV

--Daily Funnel Aggregation
with base as (
  select 
    parse_date('%Y%m%d', event_date) as event_dt,
    user_pseudo_id,
    -- Extract GA session id from nested event_params
      (select value.int_value
      from unnest (event_params)
      where key = 'ga_session_id') as session_id,

    event_name,
    ecommerce.purchase_revenue
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

session_funnel as (
select 
  event_dt, 
  concat (user_pseudo_id, cast(session_id as string)) as session_key,

  Max (if(event_name = 'view_item',1,0)) as view_item,
  max (if(event_name = 'add_to_cart',1,0)) as add_to_cart,
  max (if(event_name = 'begin_checkout',1,0)) as begin_checkout,
  max (if(event_name = 'purchase',1,0)) as purchase,

  sum(if(event_name = 'purchase',purchase_revenue,0)) as revenue

from base
where session_id is not NULL
group by event_dt, session_key
)

select
  event_dt,

  count(*) as total_sessions,
  sum(view_item) as view_item_sessions,
  sum(add_to_cart) as add_to_cart_sessions,
  sum(begin_checkout) as checkout_sessions,
  sum(purchase) as purchase_sessions,

  sum(revenue) as total_revenue,

  --Conversion Rates
  safe_divide(sum(add_to_cart), sum(view_item)) as view_to_cart_rate,
  safe_divide(sum(begin_checkout), sum(add_to_cart)) as cart_to_checkout_rate,
  safe_divide(sum(purchase), sum(begin_checkout)) as checkout_to_purchase_rate,
  safe_divide(sum(purchase), count(*)) as overall_conversion_rate,

  --AOV
  safe_divide(sum(revenue), sum(purchase)) as avg_order_value

from session_funnel
group by event_dt
order by event_dt