use role accountadmin;

-- warehouse creation - isolated in groups, so say, a batch job does not affect the performance of BI-users.
create warehouse if not exists LOADING_WH
    warehouse_size = 'xsmall'
    auto_suspend   = 60
    auto_resume    = true
    initially_suspended = true
    comment = 'Seperated resources for isolated scaling of loading tasks';

create warehouse if not exists TRANSFORM_WH
    warehouse_size = 'xsmall'
    auto_suspend   = 60
    auto_resume    = true
    initially_suspended = true
    comment = 'Seperated resources for isolated scaling of transformation/dbt tasks';

create warehouse if not exists ANALYTICS_WH
    warehouse_size = 'xsmall'
    auto_suspend   = 60
    auto_resume    = true
    initially_suspended = true
    comment = 'Seperated resources for isolated scaling of transformation/dbt tasks';