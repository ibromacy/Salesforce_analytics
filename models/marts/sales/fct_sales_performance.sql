/*
    fct_sales_performance — Aggregated sales metrics per rep

    Grain: One row per sales rep (owner_id)

    Parent models: fct_opportunities, fct_sales_activities

    Combines pipeline performance with activity metrics
    to give a complete view of each rep's effectiveness.
    Answers: which reps close the most, who has the best
    win rate, and is activity correlated with outcomes.
*/

with opportunity_metrics as (
    select
        owner_id,

        -- deal counts
        count(*) as total_deals,
        countif(is_won) as won_deals,
        countif(is_closed and not is_won) as lost_deals,
        countif(not is_closed) as open_deals,

        -- revenue
        sum(amount) as total_pipeline_value,
        sum(won_revenue) as total_won_revenue,
        sum(lost_revenue) as total_lost_revenue,
        sum(open_pipeline_value) as total_open_pipeline,

        -- averages
        avg(case when is_won then amount end) as avg_won_deal_size,
        avg(case when is_won then days_to_close end) as avg_days_to_close,

        -- win rate
        safe_divide(countif(is_won), countif(is_closed)) as win_rate

    from {{ ref('fct_opportunities') }}
    group by owner_id
),

activity_metrics as (
    select
        owner_id,

        -- activity counts
        count(*) as total_activities,
        countif(is_closed) as completed_activities,
        countif(call_type is not null) as total_calls,
        avg(call_duration_minutes) as avg_call_duration_minutes,

        -- activity rate
        safe_divide(countif(is_closed), count(*)) as activity_completion_rate

    from {{ ref('fct_sales_activities') }}
    group by owner_id
),

final as (
    select
        o.owner_id,

        -- deal metrics
        o.total_deals,
        o.won_deals,
        o.lost_deals,
        o.open_deals,
        o.total_pipeline_value,
        o.total_won_revenue,
        o.total_lost_revenue,
        o.total_open_pipeline,
        o.avg_won_deal_size,
        o.avg_days_to_close,
        o.win_rate,

        -- activity metrics
        coalesce(a.total_activities, 0) as total_activities,
        coalesce(a.completed_activities, 0) as completed_activities,
        coalesce(a.total_calls, 0) as total_calls,
        a.avg_call_duration_minutes,
        a.activity_completion_rate,

        -- derived: activities per deal
        safe_divide(coalesce(a.total_activities, 0), o.total_deals) as activities_per_deal

    from opportunity_metrics o
    left join activity_metrics a
        on o.owner_id = a.owner_id
)

select * from final