/*
    fct_campaign_performance — Campaign effectiveness fact table

    Grain: One row per campaign

    Measures campaign reach, engagement, conversion,
    and revenue attribution. Answers: which campaigns
    generate the most pipeline, best conversion rate,
    and highest ROI.
*/

with campaigns as (
    select * from {{ ref('stg_campaigns') }}
),

member_metrics as (
    select
        campaign_id,

        -- reach
        count(*) as total_members,
        countif(member_type = 'Lead') as lead_members,
        countif(member_type = 'Contact') as contact_members,

        -- engagement
        countif(has_responded) as total_responded,
        safe_divide(countif(has_responded), count(*)) as response_rate,

        -- opt-out
        countif(has_opted_out_of_email) as opted_out_of_email,
        countif(do_not_call) as do_not_call_count

    from {{ ref('stg_campaign_members') }}
    group by campaign_id
),

final as (
    select
        -- keys
        c.campaign_id,
        c.owner_id,

        -- campaign details
        c.campaign_name,
        c.campaign_type,
        c.status,
        c.start_date,
        c.end_date,

        -- budget
        c.budgeted_cost,
        c.actual_cost,
        c.expected_revenue,

        -- member metrics (from campaign members)
        coalesce(m.total_members, 0) as total_members,
        coalesce(m.lead_members, 0) as lead_members,
        coalesce(m.contact_members, 0) as contact_members,
        coalesce(m.total_responded, 0) as total_responded,
        m.response_rate,

        -- salesforce rollup metrics (from campaign object)
        c.number_of_leads,
        c.number_of_contacts,
        c.number_of_converted_leads,
        c.number_of_opportunities,
        c.number_of_won_opportunities,
        c.amount_all_opportunities,
        c.amount_won_opportunities,

        -- derived conversion metrics
        safe_divide(c.number_of_converted_leads, nullif(c.number_of_leads, 0)) as lead_conversion_rate,
        safe_divide(c.number_of_won_opportunities, nullif(c.number_of_opportunities, 0)) as opportunity_win_rate,

        -- ROI
        safe_divide(c.amount_won_opportunities - c.actual_cost, nullif(c.actual_cost, 0)) as campaign_roi,
        safe_divide(c.actual_cost, nullif(c.number_of_won_opportunities, 0)) as cost_per_won_deal,
        safe_divide(c.actual_cost, nullif(coalesce(m.total_members, 0), 0)) as cost_per_member,

        -- metadata
        c.last_modified_at,
        c.airbyte_extracted_at

    from campaigns c
    left join member_metrics m
        on c.campaign_id = m.campaign_id
)

select * from final