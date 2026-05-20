use role accountadmin;

-- create databases, raw for loading, analytics dev for per-developer transformations, and analytics prod is for production.
create database if not exists raw
    comment = 'Source-of-truth raw data. FAOSTAT + Google Health.';

create database if not exists analytics_dev
    comment = 'dbt outputs goes here. Schemas are created per-developer through dbt (dbt_<user>_*)';

create database if not exists analytics_prod
    comment = 'dbt scheduled runs are intended to be output here. This is a potential "if I had the time"';
    
use database analytics_prod;
create schema if not exists staging        comment = 'dbt staging views.';
create schema if not exists intermediate   comment = 'dbt intermediate tables.';
create schema if not exists marts          comment = 'dbt marts tables / end-users consumes here';
create schema if not exists seeds          comment = 'dbt seeds.';
