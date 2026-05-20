-- Country-year world-side fact. Thin wrapper over the intermediate, exposed as
-- a mart so the a tested and clean source can be queried.
select
    country_name,
    year,
    kcal_per_capita_per_day,
    population
from {{ ref('int_country_year_kcal_supply') }}
where kcal_per_capita_per_day is not null
