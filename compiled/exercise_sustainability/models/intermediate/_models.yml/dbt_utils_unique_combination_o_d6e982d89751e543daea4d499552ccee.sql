





with validation_errors as (

    select
        area_code, year
    from ANALYTICS_PROD.intermediate.int_country_year_kcal_supply
    group by area_code, year
    having count(*) > 1

)

select *
from validation_errors


