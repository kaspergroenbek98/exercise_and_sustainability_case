
    
    

with all_values as (

    select
        world_sustainability_class as value_field,
        count(*) as n_records

    from ANALYTICS_PROD.marts.fct_personal_vs_world
    group by world_sustainability_class

)

select *
from all_values
where value_field not in (
    'within_world_avg','above_world_avg','globally_unsustainable','unknown'
)


