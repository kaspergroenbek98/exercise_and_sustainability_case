/*
For each personal activity day, find the (country, year) whose
kcal_per_capita_per_day is closest to my calories_burned_kcal on that day.

ROW_NUMBER over a cross join keeps one match per day.

Cross-join size at current scale is quite small: ~600-700 days × ~2,800 country-years
is ~2M ish intermediate rows.

XS warehouses should be more than enough for that.
If the personal data grew to multi-year multi-user this cross-join would be
one of the first things to visit and consider table materialization and binnign for.
*/
with personal as (
    select * from {{ ref('stg_google_health__daily_activity') }}
    where calories_burned_kcal is not null
),

country_year as (
    select
        country_name,
        year,
        kcal_per_capita_per_day
    from {{ ref('int_country_year_kcal_supply') }}
    where kcal_per_capita_per_day is not null
),

matched as (
    select
        p.activity_date,
        p.calories_burned_kcal,
        cy.country_name              as closest_country_name,
        cy.year                      as closest_year,
        cy.kcal_per_capita_per_day   as closest_kcal_per_capita_per_day,
        abs(p.calories_burned_kcal - cy.kcal_per_capita_per_day) as kcal_diff,
        row_number() over (
            partition by p.activity_date
            order by abs(p.calories_burned_kcal - cy.kcal_per_capita_per_day)
        ) as rn
    from personal p
    cross join country_year cy
)

select
    activity_date,
    closest_country_name,
    closest_year,
    closest_kcal_per_capita_per_day,
    kcal_diff
from matched
where rn = 1
