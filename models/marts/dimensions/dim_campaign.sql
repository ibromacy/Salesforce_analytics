/*
    dim_campaign — Marketing campaign dimension

    Source: stg_campaigns

    No SCD Type 2 — campaigns are typically short-lived
    with a defined start and end date. Historical tracking
    is handled by the date fields and status.
*/

with campaigns as (
    select * from {{ ref('stg_campaigns') }}
),

final as (
    select
        -- key
        campaign_id,
        owner_id,
        parent_campaign_id,

        -- campaign attributes
        campaign_name,
        campaign_type,
        status,
        description,
        is_active,

        -- dates
        start_date,
        end_date,
        date_diff(end_date, start_date, day) as campaign_duration_days,

        -- budget
        budgeted_cost,
        actual_cost,
        expected_revenue,
        expected_response_pct,

        -- metadata
        created_at,
        last_modified_at

    from campaigns
)

select * from final