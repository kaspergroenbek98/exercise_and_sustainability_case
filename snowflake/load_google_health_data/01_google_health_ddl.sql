use role pc_dbt_role;
use database raw;
use warehouse loading_wh;

create schema if not exists google_health
    comment = 'Personal daily activity from Google Health API, loaded from outside scripts.';

use schema google_health;

create table if not exists daily_activity (
    activity_date          date     not null,
    source_family          varchar  not null,
    calories_burned_kcal   float,
    steps                  integer,
    distance_meters        float,
    active_zone_minutes    integer,
    ingested_at            timestamp_ntz default current_timestamp(),
    primary key (activity_date, source_family)
);
