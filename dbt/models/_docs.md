{#
Reusable documentation blocks. Referenced from column descriptions via {{ doc('block_name') }}. 
Defined once here so the business meaning of the key terms stays consistent everywhere.
#}

{% docs closest_country_match %}
For each personal activity day, the (country, year) whose FAOSTAT
`kcal_per_capita_per_day` is closest in absolute value to that day's
`calories_burned_kcal`. Computed via `ROW_NUMBER` over a cross join in
`int_personal_day_matched_country`. Reads as "today you would have eaten like a
person in [country] in [year]." Ties broken by Snowflake's row order; matches
are stable across runs given stable data.
{% enddocs %}

{% docs sustainability_class %}
Personal-day classification against the world's population-weighted kcal/cap/day
baseline. Three buckets:

- `within_world_avg` — burn at or below the world average
- `above_world_avg` — burn above the world average but at or below 1.25x
- `globally_unsustainable` — burn above 1.25x the world average

`unknown` when `calories_burned_kcal` is missing. The 1.25x cutoff is a design
choice (see [`docs/01-thesis.md`](../../docs/01-thesis.md)); different threshold,
different headline percentage, same structural shape.
{% enddocs %}
