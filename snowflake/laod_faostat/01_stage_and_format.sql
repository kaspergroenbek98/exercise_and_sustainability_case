-- Internal stage for the FAOSTAT bulk CSV. Run as the DBT role or whichever role owns RAW.
use role pc_dbt_role;
use database raw;
use warehouse loading_wh;

create schema if not exists faostat
    comment = 'Raw FAOSTAT food balance sheets loaded once from the bulk CSV (2010-2023.';

use schema faostat;

-- File format for the FAOSTAT bulk download. UTF-8, double-quoted, escaped quotes, header on row 1.
create or replace file format faostat_csv_format
    type             = 'csv'
    field_delimiter  = ','
    skip_header      = 1
    field_optionally_enclosed_by = '"'
    null_if          = ('', 'NA')
    empty_field_as_null = true
    encoding         = 'UTF-8'
    comment          = 'FAOSTAT Food Balance Sheets bulk download CSV format.';

create or replace stage faostat_stage
    file_format = faostat_csv_format
    comment     = 'Internal stage for the FAOSTAT bulk CSV.';
