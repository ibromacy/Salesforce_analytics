/*
    fct_account_health — Customer health and retention signals

    Grain: One row per account

    Parent models: fct_opportunities, fct_sales_activities, stg_contacts

    Aggregates signals per account to identify at-risk
    customers and upsell opportunities. Answers: which
    accounts are healthy, which are at risk of churn,
    and where are the upsell opportunities.
*/

with opportunity_metrics as (
    select
        account_id,

        -- deal history
        count(*) as total_opportunities,
        countif(is_won) as won_opportunities,
        countif(is_closed and not is_won) as lost_opportunities,
        countif(not is_closed) as open_opportunities,

        -- revenue
        sum(won_revenue) as lifetime_revenue,
        sum(open_pipeline_value) as open_pipeline_value,
        avg(case when is_won then amount end) as avg_deal_size,

        -- timing
        min(case when is_won then close_date end) as first_won_date,
        max(case when is_won then close_date end) as last_won_date,
        date_diff(
            current_date(),
            max(case when is_won then close_date end),
            day
        ) as days_since_last_won_deal,

        -- win rate for this account
        safe_divide(countif(is_won), countif(is_closed)) as account_win_rate

    from {{ ref('fct_opportunities') }}
    group by account_id
),

activity_metrics as (
    select
        account_id,

        -- engagement
        count(*) as total_activities,
        countif(is_closed) as completed_activities,
        max(activity_date) as last_activity_date,
        date_diff(current_date(), max(activity_date), day) as days_since_last_activity,

        -- call engagement
        countif(call_type is not null) as total_calls,
        avg(call_duration_minutes) as avg_call_duration_minutes

    from {{ ref('fct_sales_activities') }}
    where account_id is not null
    group by account_id
),

contact_metrics as (
    select
        account_id,
        count(*) as total_contacts,
        countif(is_email_bounced) as bounced_email_contacts

    from {{ ref('stg_contacts') }}
    group by account_id
),

accounts as (
    select
        account_id,
        account_name,
        account_type,
        industry,
        customer_priority,
        sla,
        is_active,
        upsell_opportunity
    from {{ ref('stg_accounts') }}
),

final as (
    select
        -- account details
        a.account_id,
        a.account_name,
        a.account_type,
        a.industry,
        a.customer_priority,
        a.sla,
        a.is_active,
        a.upsell_opportunity,

        -- revenue metrics
        coalesce(o.lifetime_revenue, 0) as lifetime_revenue,
        coalesce(o.open_pipeline_value, 0) as open_pipeline_value,
        o.avg_deal_size,
        coalesce(o.total_opportunities, 0) as total_opportunities,
        coalesce(o.won_opportunities, 0) as won_opportunities,
        coalesce(o.lost_opportunities, 0) as lost_opportunities,
        coalesce(o.open_opportunities, 0) as open_opportunities,
        o.account_win_rate,

        -- timing
        o.first_won_date,
        o.last_won_date,
        o.days_since_last_won_deal,

        -- engagement
        coalesce(act.total_activities, 0) as total_activities,
        act.last_activity_date,
        act.days_since_last_activity,
        coalesce(act.total_calls, 0) as total_calls,

        -- contacts
        coalesce(c.total_contacts, 0) as total_contacts,
        coalesce(c.bounced_email_contacts, 0) as bounced_email_contacts,

        -- health score (simple weighted formula)
        case
            when o.days_since_last_won_deal is null then 'No Revenue'
            when o.days_since_last_won_deal <= 90 and act.days_since_last_activity <= 30 then 'Healthy'
            when o.days_since_last_won_deal <= 180 and act.days_since_last_activity <= 60 then 'At Risk'
            when o.days_since_last_won_deal > 180 or act.days_since_last_activity > 90 then 'Churning'
            else 'Unknown'
        end as health_status,

        -- upsell signal
        case
            when a.upsell_opportunity = 'Yes' and o.open_opportunities > 0 then 'Active Upsell'
            when a.upsell_opportunity = 'Yes' and o.open_opportunities = 0 then 'Upsell Potential'
            when a.upsell_opportunity = 'Maybe' then 'Explore Upsell'
            else 'No Upsell Signal'
        end as upsell_status

    from accounts a
    left join opportunity_metrics o on a.account_id = o.account_id
    left join activity_metrics act on a.account_id = act.account_id
    left join contact_metrics c on a.account_id = c.account_id
)

select * from final