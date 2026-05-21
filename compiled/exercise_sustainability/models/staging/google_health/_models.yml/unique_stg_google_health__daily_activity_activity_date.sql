
    
    

select
    activity_date as unique_field,
    count(*) as n_records

from ANALYTICS_PROD.staging.stg_google_health__daily_activity
where activity_date is not null
group by activity_date
having count(*) > 1


