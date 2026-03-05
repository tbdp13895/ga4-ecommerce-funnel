with base as (
  select 
    parse_date('%Y%m%d', event_date) as event_dt,
    user_pseudo_id,

    (select value.int_value
    from unnest(event_params)
    where key = 'ga_session_id') as session_id,

    event_name,
    device.category as device_category,
    traffic_source.source as traffic_source,
    geo.country as country,
    ecommerce.purchase_revenue
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

session_funnel as (
  select 
    event_dt,
    device_category,
    traffic_source,
    country,
    concat(user_pseudo_id, cast(session_id as string)) as session_key,

    max(if(event_name = 'view_item',1,0)) as view_item,
    max(if(event_name = 'add_to_cart',1,0)) as add_to_cart,
    max(if(event_name = 'begin_checkout',1,0)) as begin_checkout,
    max(if(event_name = 'purchase',1,0)) as purchase,

    sum(if(event_name = 'purchase', purchase_revenue, 0)) as revenue
  from base
  where session_id is not null
  group by event_dt, device_category, traffic_source, country, session_key)

select *
from session_funnel



