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
    select * from RAW.FAOSTAT.FOOD_BALANCE_SHEETS
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
    where
        -- kcal supply at the Grand Total (item 2901)
        (element_code = '664' and item_code = '2901')
        -- population (item 2501 in FAOSTAT FBS)
     or (element_code = '511' and item_code = '2501')
)
select * from filtered