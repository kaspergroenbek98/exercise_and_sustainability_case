-- Internal stage for the FAOSTAT bulk CSV. Run as the DBT role or whichever role owns RAW.
use role pc_dbt_role;
use database raw;
use warehouse loading_wh;

create schema if not exists faostat
    comment = 'Raw FAOSTAT food balance sheets loaded once from the bulk CSV (2010-2023.';

use schema faostat;

create or replace stage faostat_stage
    file_format = faostat_csv_format
    comment     = 'Internal stage for the FAOSTAT bulk CSV.';
