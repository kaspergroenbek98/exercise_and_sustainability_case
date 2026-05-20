/*
Passthrough with light type coercion and a case scoping filter applied 
early so downstream models read only the rows that matter.

Two element filters carry forward: 664 (Food supply, kcal/capita/day) for the
world supply baseline, and 511 (Population, 1000 persons) for population
weighting in the world average. Item 2901 is FAOSTAT's "Grand Total". I would expect
summing leaf items would drift a couple percent, so we trust the published total.

M49 codes ship with a leading apostrophe, we fix those.
*/
with source as (
    select * from {{ source('faostat', 'food_balance_sheets') }}
),

renamed as (
    select
        cast(area_code     as varchar)                       as area_code,
        cast(area          as varchar)                       as area_name,
        ltrim(cast(area_code_m49 as varchar), '''')          as m49_code,
        cast(item_code     as varchar)                       as item_code,
        cast(item          as varchar)                       as item_name,
        cast(element_code  as varchar)                       as element_code,
        cast(element       as varchar)                       as element_name,
        cast(year          as integer)                       as year,
        cast(unit          as varchar)                       as unit,
        cast(value         as float)                         as value,
        cast(flag          as varchar)                       as flag
    from source
),

filtered as (
    select *
    from renamed
    where item_code    = '2901'                              -- Grand Total
      and element_code in ('664', '511')                     -- kcal supply, population
)

select * from filtered
