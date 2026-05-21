





with validation_errors as (

    select
        country_name, year
    from ANALYTICS_PROD.marts.fct_world_kcal_supply
    group by country_name, year
    having count(*) > 1

)

select *
from validation_errors


