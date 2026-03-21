/*
    dim_date — Standard date dimension

    Generates a date spine covering the range of activity
    in the Salesforce data. Used for trending, period 
    comparisons, and fiscal quarter analysis.
*/

with date_spine as (
    select
        date
    from
        unnest(
            generate_date_array(
                '2020-01-01',
                current_date()
            )
        ) as date
),

enriched as (
    select
        -- key
        date as date_day,
        
        -- date parts
        extract(year from date) as year,
        extract(quarter from date) as quarter,
        extract(month from date) as month,
        extract(week from date) as week_of_year,
        extract(day from date) as day_of_month,
        extract(dayofweek from date) as day_of_week,

        -- formatted
        format_date('%B', date) as month_name,
        format_date('%b', date) as month_short,
        format_date('%A', date) as day_name,
        format_date('%Y-%m', date) as year_month,
        format_date('%Y-Q%Q', date) as year_quarter,

        -- fiscal (assuming fiscal year = calendar year)
        extract(year from date) as fiscal_year,
        extract(quarter from date) as fiscal_quarter,

        -- flags
        case when extract(dayofweek from date) in (1, 7) then true else false end as is_weekend,
        case when extract(day from date) = 1 then true else false end as is_month_start,
        date = last_day(date) as is_month_end
    from date_spine
)

select * from enriched