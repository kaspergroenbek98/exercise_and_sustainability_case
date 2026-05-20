/*
One row per (area_code, country_name, year) with both kcal/cap/day and
population on the same row. The staging layer carries both metrics in long
form; the intermediate pivots them to wide and applies the aggregate filter.
*/
with staged as (
    select * from {{ ref('stg_faostat__food_balance_sheets') }}
),

exclusions as (
    select faostat_area_code from {{ ref('faostat_area_exclusions') }}
),

-- Pivot the two elements to wide. MAX over a partition where each value appears.
pivoted as (
    select
        area_code,
        area_name as country_name,
        year,
        max(case when element_code = '664' then value end) as kcal_per_capita_per_day,
        max(case when element_code = '511' then value end) as population
    from staged
    group by area_code, area_name, year
),

filtered as (
    select pivoted.*
    from pivoted
    left join exclusions on pivoted.area_code = exclusions.faostat_area_code
    where exclusions.faostat_area_code is null
)

select * from filtered
