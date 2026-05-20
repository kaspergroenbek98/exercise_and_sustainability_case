/*
Fact on activity date, one row per date with:
    - Raw Google Health metrics (calories, steps, distance, active zone minutes)
    - The closest matching (country, year)  by calorie supply average
    - The world population-weighted baseline + sustainability classification
*/
with personal as (
    select * from {{ ref('stg_google_health__daily_activity') }}
),

matched as (
    select * from {{ ref('int_personal_day_matched_country') }}
),

baseline as (
    select * from {{ ref('int_world_kcal_baseline') }}
)

select
    -- Personal day grain
    p.activity_date,
    dayname(p.activity_date)                                            as day_of_week,
    p.calories_burned_kcal,
    p.steps,
    p.distance_meters,
    p.active_zone_minutes,

    -- Closest matching country-year ("where would I live to meet today's demand?")
    m.closest_country_name,
    m.closest_year,
    m.closest_kcal_per_capita_per_day,
    m.kcal_diff                                                         as kcal_diff_vs_closest_country,

    -- World baseline (single-row cross join)
    b.baseline_year,
    b.world_avg_kcal_per_capita_per_day,
    p.calories_burned_kcal - b.world_avg_kcal_per_capita_per_day        as kcal_excess_vs_world,
    p.calories_burned_kcal / nullif(b.world_avg_kcal_per_capita_per_day, 0)
        as world_equivalent_persons,

    -- Sustainability classification
    case
        when p.calories_burned_kcal is null
            then 'unknown'
        when p.calories_burned_kcal > 1.25 * b.world_avg_kcal_per_capita_per_day
            then 'globally_unsustainable'
        when p.calories_burned_kcal > b.world_avg_kcal_per_capita_per_day
            then 'above_world_avg'
        else 'within_world_avg'
    end as world_sustainability_class

from personal p
left join matched m on p.activity_date = m.activity_date
cross join baseline b
