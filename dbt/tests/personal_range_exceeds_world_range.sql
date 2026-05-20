-- The structural sanity check for the case. The thesis depends on the personal
-- daily-burn range being WIDER than the world's national kcal supply range.
--
-- Returns failing rows if the personal range does not exceed the world range,
-- which would mean the case's argument is empirically wrong for this data and
-- the deck needs to be reworked. Empty result = test passes.

with personal as (
    select
        max(calories_burned_kcal) - min(calories_burned_kcal) as personal_range_kcal
    from {{ ref('fct_personal_vs_world') }}
    where calories_burned_kcal > 0
),

world as (
    select
        max(kcal_per_capita_per_day) - min(kcal_per_capita_per_day) as world_range_kcal
    from {{ ref('fct_world_kcal_supply') }}
    where kcal_per_capita_per_day is not null
)

select p.personal_range_kcal, w.world_range_kcal
from personal p, world w
where p.personal_range_kcal <= w.world_range_kcal
