/*
One row: the world population-weighted average kcal/capita/day for the latest year
(should be 2023) with usable coverage. 

Reads from int_country_year_kcal_supply only.

"Latest with usable coverage" means: the max year for which at least 100 have kcal supply and population.

Population weighting is to ensure that countries like Bhutan don't count the same globally as China or Indonesia,
that would be big big skew on our data.
*/

with country_year as (
    select *
    from {{ ref('int_country_year_kcal_supply') }}
    where kcal_per_capita_per_day is not null
      and population               is not null
),

coverage_per_year as (
    select year, count(*) as country_count
    from country_year
    group by year
),

latest_year as (
    select max(year) as baseline_year
    from coverage_per_year
    where country_count >= 100
),

weighted as (
    select
        ly.baseline_year                                                       as baseline_year,
        sum(cy.kcal_per_capita_per_day * cy.population) / sum(cy.population)   as world_avg_kcal_per_capita_per_day
    from country_year cy
    cross join latest_year ly
    where cy.year = ly.baseline_year
    group by ly.baseline_year
)

select * from weighted
