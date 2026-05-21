{#
    Custom schema naming so dev and prod look different.
    In prod (target.name == 'prod'), schemas are exactly the +schema config:
    'staging', 'intermediate', 'marts', 'seeds'. Pre-created by
    snowflake/infrastructure/02_create_databases_and_schemas.sql.
    In dev (any other target), default dbt behaviour: target.schema is
    prepended, so +schema: marts becomes dbt_yourname_marts.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if target.name == 'prod' and custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    {%- elif custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}