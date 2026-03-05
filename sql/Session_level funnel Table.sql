--Build session-level funnel base
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
)
select 
  event_dt, 
  user_pseudo_id,
  session_id,

  --Funnel flags
  Max (if(event_name = 'view_item',1,0)) as view_item,
  max (if(event_name = 'add_to_cart',1,0)) as add_to_cart,
  max (if(event_name = 'begin_checkout',1,0)) as begin_checkout,
  max (if(event_name = 'purchase',1,0)) as purchase,

  --Revenue per session
  sum(if(event_name = 'purchase',purchase_revenue,0)) as revenue

from base
where session_id is not NULL
group by event_dt, user_pseudo_id, session_id
order by base.event_dt
limit 100