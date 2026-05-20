# Is excessive exercise sustainable?

**Scaled to humanity, is the calorie demand of my (semi, who am I kidding...) active lifestyle compatible with the world's actual food
supply?**

> **My motivation:** If my daily calorie burn often exceeds 1.25x the world’s
> population-weighted food supply per person, that points to a problem.
> On those days, the model classifies the developer as `globally_unsustainable`
> under its own criteria.
> Across the roughly 600 to 700 days I have worn a FitBit Charge 6, X% of days
> fall into that class.
> If that pattern were scaled to eight billion people, the global food supply
> may not be sufficient.

The 1.25x threshold is a design choice rather than an established rule.

The point isn't a public-health pronouncement; it's that an estimate of whether, by the looks of it,
there would be enough food supply to support my lifestyle (and I wanted to do something with the data :p )

## Stack

- **Snowflake** trial account, single dev role, two databases (RAW, ANALYTICS), one warehouse.
- **dbt Cloud** with project structured in the dbt classic staging/intermediate/marts layers.
- **A bit of Claude-assisted Python scripts** for Google Health API → Snowflake. (Not in Snowflake, that is reserved for if I had more time...)

## Data sources

Two sources only. Both load into RAW.

| Source | Role | Notes |
|---|---|---|
| FAOSTAT Food Balance Sheets | Country food supply baseline | Filtered to element 664 (kcal/capita/day) and element 511 (population) at item 2901 (Grand Total). ~5,600 rows, 2010-2023, ~200 countries. |
| Google Health API | Personal daily activity | My Fitbit Charge 6 data, from when I bought it in 2024-09-20 and onward |

World Bank development indicators were considered and dropped. The thesis is about
kcal range, not income brackets, but it could be an interesting extenstion!

## Model design

### Three layers (+ raw)

```
RAW
  ├── faostat.food_balance_sheets             | CSV → internal stage → COPY INTO
  └── google_health.daily_activity            | Python loader, MERGE on (activity_date, source_family)

STAGING (views)
  ├── stg_faostat__food_balance_sheets        | filter to element 664 (kcal) + 511 (population), item 2901, type-cast, strip M49 apostrophe
  └── stg_google_health__daily_activity       | passthrough + type casts

INTERMEDIATE (tables)
  ├── int_country_year_kcal_supply            | one row per (iso/area, year) with kcal_per_capita_per_day + population
  ├── int_world_kcal_baseline                 | one-row table: world population-weighted avg kcal/cap/day for the latest available year
  └── int_personal_day_matched_country        | cross-join match: closest country-year per personal day by kcal

MARTS (tables)
  ├── fct_world_kcal_supply                   | country-year, the world-supply curve
  └── fct_personal_vs_world                   | Google Health date + match + baseline + sustainability class
```

### Layering rationale

**Staging is views.** Renames, casts, light filters. The FAOSTAT staging carries
both kcal and population because both come from the same source table; splitting
them into two staging views just to be one-element-per-model would add files
without separating real concerns.

**Intermediate is views.** Nothing is too expensive in this setup, I wouild consider
materializing the int_personal_day_matched_country model as table at scale, e.g.,
more subjects than just me, because it grows exponentially. Otherwise, both
XS warehouses and views are fine for this setup, but performance drops downstream
would a pointer to consider optimizations and table materialization if run at bulk.
Otherwise, incrementally/CDC would work beautifully for this type of data.

**Marts are tables.** They're the BI/analytics end-user facing surface. Two marts because the
grain differs (country-year vs personal-day); forcing them onto one mart would
either explode the country-year fact to personal-day grain or hide one inside a
JSON column. These are tables for performance, incremental is a candidate too in a mature
prod setup.

### The closest-match join, by design

`int_personal_day_matched_country` is a cross join between personal days and
country-years, keyed by absolute kcal difference, with `ROW_NUMBER` keeping the
single closest match per day.

- **Why cross-join not temporal join:** FAOSTAT publishes through 2023. Personal
  data starts in 2024. A temporal join would orphan every personal row. The
  cross-join asks a different question: "which country-year had a supply closest
  to today's burn?", which maps directly to the slide.
- **Size at current scale:** ~870 personal days × ~2,800 country-years = ~2.4M
  intermediate rows. Snowflake handles it on XS without complaint. If the
  personal data grew to multi-user, replace the cross join with a binned lookup.

### World average, population-weighted

`int_world_kcal_baseline` is a single-row table. Two design choices:

1. **Population-weighted, not unweighted.** Country averages without population
   weights treat tiny countries (Bhutan, Iceland) the same as China and India.
   That's the wrong shape for a "world average". The weight comes from FAOSTAT's
   own population element (511) — consistent with the kcal data being weighted.
2. **Latest available year, not the personal day's year.** The personal data is
   2024+, FAOSTAT stops at 2023. There's no aligned year. Pinning the baseline
   to the latest available FAOSTAT year is the honest move; the slide narrates it.
