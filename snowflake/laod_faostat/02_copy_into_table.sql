-- NOTE before this, a chunked version of the FAOSTAT data is uploaded to the stage

-- Land the FAOSTAT CSV into a typed table
use role pc_dbt_role;
use database raw;
use schema faostat;
use warehouse analytics_wh;

create or replace table food_balance_sheets (
    area_code          number,
    area_code_m49      varchar,
    area               varchar,
    item_code          number,
    item               varchar,
    element_code       number,
    element            varchar,
    year_code          number,
    year               number,
    unit               varchar,
    value              float,
    flag               varchar,
    note               varchar
)
    comment = 'FAOSTAT Food Balance Sheets, long format. Loaded once from bulk CSV. Staging filters to elements 664 (kcal supply) and 511 (population) at item 2901 (Grand Total).';

copy into food_balance_sheets (area_code, area_code_m49, area, item_code, item, element_code, element, year_code, year, unit, value, flag, note)
from @faostat_stage
file_format = (format_name = faostat_csv_format)
on_error    = 'continue';

-- Sanity checks
select count(*)                              as total_rows                            from food_balance_sheets;
select count(distinct area)                  as area_count                            from food_balance_sheets;
select min(year)                             as min_year, max(year) as max_year       from food_balance_sheets;
select element_code, element, count(*)       as row_count                             from food_balance_sheets where element_code in (664, 511) group by element_code, element;
