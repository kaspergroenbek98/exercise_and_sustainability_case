-- we use the dbt partner connect role pc_dbt_role as both LOADER and TRANSFORMER
-- with more time, I would create both a LOADER, TRANSFORMER, and ANALYST/BI role, just like the warehouses.
grant role pc_dbt_role to role sysadmin;

-- Grant for both LOADER and TRANSFORMER to the pc_dbt_
grant usage on warehouse LOADING_WH to role pc_dbt_role;
grant usage on warehouse TRANSFORM_WH to role pc_dbt_role;
grant usage on warehouse ANALYTICS_WH to role pc_dbt_role;

grant usage   on database raw to role pc_dbt_role;

grant create schema  on database raw to role pc_dbt_role;
grant usage   on all schemas    in database raw to role pc_dbt_role;
grant usage   on future schemas in database raw to role pc_dbt_role;

grant select  on all tables     in database raw to role pc_dbt_role;
grant select  on future tables  in database raw to role pc_dbt_role;

grant ownership on database analytics_dev to role pc_dbt_role copy current grants;

grant ownership on all schemas    in database analytics_dev to role pc_dbt_role copy current grants;
grant ownership on future schemas in database analytics_dev to role pc_dbt_role copy current grants;