-- Pass-through with type casts. The loader writes typed columns but the staging
-- layer is the contract surface. The casts then enforce that.

with source as (
    select * from RAW.GOOGLE_HEALTH.DAILY_ACTIVITY
)

select
    cast(activity_date         as date)    as activity_date,
    cast(source_family         as varchar) as source_family,
    cast(calories_burned_kcal  as float)   as calories_burned_kcal,
    cast(steps                 as integer) as steps,
    cast(distance_meters       as float)   as distance_meters,
    cast(active_zone_minutes   as integer) as active_zone_minutes,
    cast(ingested_at           as timestamp_ntz) as ingested_at
from source