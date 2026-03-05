with base as (
  select 
    parse_date('%Y%m%d', event_date) as event_dt,
    user_pseudo_id,

    (select value.int_value
    from unnest(event_params)
    where key = 'ga_session_id') as session_id,

    event_name,
    device.category as device_category,
    ecommerce.purchase_revenue
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

session_funnel as (
  select
    event_dt,
    device_category,
    concat (user_pseudo_id, cast(session_id as string)) as session_key,

    max(if(event_name = 'view_item',1,0)) as view_item,
    max(if(event_name = 'add_to_cart',1,0)) as add_to_cart,
    max(if(event_name = 'begin_checkout',1,0)) as begin_checkout,
    max(if(event_name = 'purchase',1,0)) as purchase,

    sum(if(event_name = 'purchase', purchase_revenue,0)) as revenue
  from base
  where session_id is not NULL
  group by event_dt, device_category, session_key
)

select 
  device_category,
  count (*) as sessions,
  sum (view_item) as view_item_sessions,
  sum (add_to_cart) as add_to_cart_sessions,
  sum (begin_checkout) as checkout_sessions,
  sum (purchase) as purchase_sessions,
  sum (revenue) as total_revenue,

  safe_divide(sum(add_to_cart), sum(view_item)) as view_to_cart_rate,
  safe_divide(sum(begin_checkout), sum(add_to_cart)) as cart_to_checkout_rate,
  safe_divide(sum(purchase), sum(begin_checkout)) as checkout_to_purchase_rate

from session_funnel
group by device_category
order by total_revenue DESC