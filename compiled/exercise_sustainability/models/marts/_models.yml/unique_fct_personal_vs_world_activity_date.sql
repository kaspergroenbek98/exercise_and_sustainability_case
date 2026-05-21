
    
    

select
    activity_date as unique_field,
    count(*) as n_records

from ANALYTICS_PROD.marts.fct_personal_vs_world
where activity_date is not null
group by activity_date
having count(*) > 1


