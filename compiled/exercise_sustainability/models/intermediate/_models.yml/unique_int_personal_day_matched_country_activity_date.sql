
    
    

select
    activity_date as unique_field,
    count(*) as n_records

from ANALYTICS_PROD.intermediate.int_personal_day_matched_country
where activity_date is not null
group by activity_date
having count(*) > 1


