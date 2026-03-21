/*
    fct_opportunities — Core sales pipeline fact table

    Grain: One row per opportunity

    This is the central fact table for sales analytics.
    It answers: pipeline value, win rate, average deal size,
    revenue by rep/account/source, and deal velocity.

    Cancelled/lost revenue is tracked separately from won
    revenue to prevent metric inflation — same principle
    as the Auto_project orders_fact design.
*/

with opportunities as (
    select * from {{ ref('stg_opportunities') }}
),

stages as (
    select * from {{ ref('stg_opportunity_stages') }}
),

final as (
    select
        -- keys
        o.opportunity_id,
        o.account_id,
        o.owner_id,
        o.contact_id,

        -- opportunity details
        o.opportunity_name,
        o.opportunity_type,
        o.stage_name,
        o.lead_source,
        o.forecast_category_name,
        o.next_step,
        o.description,

        -- financials
        o.amount,
        o.expected_revenue,
        o.probability,
        o.total_quantity,

        -- won/lost revenue isolation
        case when o.is_won then o.amount else 0 end as won_revenue,
        case when o.is_closed and not o.is_won then o.amount else 0 end as lost_revenue,
        case when not o.is_closed then o.amount else 0 end as open_pipeline_value,

        -- dates
        o.close_date,
        o.created_at,
        o.last_stage_change_date,
        date_diff(o.close_date, cast(o.created_at as date), day) as days_to_close,
        date_diff(current_date(), cast(o.created_at as date), day) as days_open,

        -- status flags
        o.is_closed,
        o.is_won,
        case 
            when o.is_won then 'Won'
            when o.is_closed and not o.is_won then 'Lost'
            else 'Open'
        end as deal_status,
        o.has_overdue_task,
        o.has_open_activity,

        -- fiscal
        o.fiscal_year,
        o.fiscal_quarter,

        -- stage metadata
        s.sort_order as stage_sort_order,
        s.default_probability as stage_default_probability,
        s.forecast_category as stage_forecast_category,

        -- custom fields
        o.order_number,
        o.tracking_number,
        o.main_competitors,
        o.delivery_installation_status,

        -- metadata
        o.last_modified_at,
        o.last_activity_date,
        o.airbyte_extracted_at

    from opportunities o
    left join stages s
        on o.stage_name = s.stage_api_name
)

select * from final