with base as (
  select 
    parse_date('%Y%m%d', event_date) as event_dt,
    user_pseudo_id,

    (select value.int_value
    from unnest(event_params)
    where key = 'ga_session_id') as session_id,

    event_name,
   traffic_source.source as traffic_source,
   ecommerce.purchase_revenue
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

session_funnel as (
  select 
    traffic_source,
    concat(user_pseudo_id, cast(session_id as string)) as session_key,

    max(if(event_name = 'view_item',1,0)) as view_item,
    max(if(event_name = 'add_to_cart',1,0)) as add_to_cart,
    max(if(event_name = 'begin_checkout',1,0)) as begin_checkout,
    max(if(event_name = 'purchase',1,0)) as purchase,

    sum(if(event_name = 'purchase', purchase_revenue, 0)) as revenue
  from base
  where session_id is not null
  group by traffic_source, session_key
)

select 
  traffic_source,
  count (*) as sessions,
  sum(purchase) as purchase,
  sum(revenue) as revenue,
  
  safe_divide(sum(purchase), count(*)) as conversion_rate

from session_funnel 
group by traffic_source 
order by revenue DESC