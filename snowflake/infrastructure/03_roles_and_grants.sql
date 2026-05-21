use role accountadmin;
-- we use the dbt partner connect role pc_dbt_role as both LOADER and TRANSFORMER
-- with more time, I would create both a LOADER, TRANSFORMER, and ANALYST/BI role, just like the warehouses.
grant role pc_dbt_role to role sysadmin;

-- Grant that would be designated for a LOADER and TRANSFORMER to the pc_dbt_role
grant usage on warehouse LOADING_WH to role pc_dbt_role;
grant usage on warehouse TRANSFORM_WH to role pc_dbt_role;
grant usage on warehouse ANALYTICS_WH to role pc_dbt_role;

-- Loader grants (+ some Transformer, like reading raw)
grant usage   on database raw to role pc_dbt_role;

grant create schema  on database raw to role pc_dbt_role;
grant usage   on all schemas    in database raw to role pc_dbt_role;
grant usage   on future schemas in database raw to role pc_dbt_role;

grant select  on all tables     in database raw to role pc_dbt_role;
grant select  on future tables  in database raw to role pc_dbt_role;

-- Transformer grants
grant ownership on database analytics_dev                   to role pc_dbt_role copy current grants;
grant ownership on all schemas    in database analytics_dev to role pc_dbt_role copy current grants;
grant create schema  on database analytics_dev              to role pc_dbt_role;

grant ownership on database analytics_prod                          to role pc_dbt_role copy current grants;
grant ownership on all schemas    in database analytics_prod        to role pc_dbt_role copy current grants;
grant create schema  on database analytics_prod                     to role pc_dbt_role;

revoke ownership on future schemas in database analytics_dev  from role pc_dbt_role copy current grants;
revoke ownership on future schemas in database analytics_prod from role pc_dbt_role copy current grants;

grant ownership on future schemas in database analytics_dev to role pc_dbt_role copy current grants;
grant ownership on future schemas in database analytics_prod        to role pc_dbt_role copy current grants;

-- BI/Analyst grants
grant usage on warehouse analytics_wh to role pc_dbt_role;

grant usage on database analytics_prod to role pc_dbt_role;
grant usage on schema analytics_prod.prod_marts to role pc_dbt_role;

grant select on all tables    in schema analytics_prod.prod_marts to role pc_dbt_role;
grant select on future tables in schema analytics_prod.prod_marts to role pc_dbt_role;
grant select on all views     in schema analytics_prod.prod_marts to role pc_dbt_role;
grant select on future views  in schema analytics_prod.prod_marts to role pc_dbt_role;
