
    
    

with all_values as (

    select
        item_code as value_field,
        count(*) as n_records

    from ANALYTICS_PROD.staging.stg_faostat__food_balance_sheets
    group by item_code

)

select *
from all_values
where value_field not in (
    '2901','2501'
)


