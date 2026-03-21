/*
    fct_marketing_performance — Aggregated marketing metrics

    Grain: One row per lead source

    Parent models: fct_lead_conversion, fct_campaign_performance

    Combines lead conversion and campaign data to give
    marketing a complete view of channel effectiveness.
    Answers: which channels produce the most leads,
    best conversion rates, and highest revenue.
*/

with lead_metrics as (
    select
        lead_source,

        -- volume
        count(*) as total_leads,
        countif(is_converted) as converted_leads,
        countif(not is_converted) as unconverted_leads,

        -- conversion
        safe_divide(countif(is_converted), count(*)) as conversion_rate,
        avg(days_to_convert) as avg_days_to_convert,

        -- revenue from converted leads
        sum(converted_opportunity_amount) as total_converted_revenue,
        avg(converted_opportunity_amount) as avg_converted_deal_size,
        countif(converted_opportunity_won) as converted_deals_won,

        -- quality score: conversion rate * avg deal size
        safe_divide(
            countif(is_converted) * avg(converted_opportunity_amount),
            count(*)
        ) as lead_quality_score

    from {{ ref('fct_lead_conversion') }}
    where lead_source is not null
    group by lead_source
),

campaign_metrics as (
    select
        campaign_type,

        count(*) as total_campaigns,
        sum(total_members) as total_campaign_reach,
        sum(actual_cost) as total_campaign_spend,
        sum(amount_won_opportunities) as total_campaign_revenue,
        safe_divide(
            sum(amount_won_opportunities) - sum(actual_cost),
            nullif(sum(actual_cost), 0)
        ) as overall_campaign_roi

    from {{ ref('fct_campaign_performance') }}
    where campaign_type is not null
    group by campaign_type
),

final as (
    select
        -- lead source metrics
        l.lead_source,
        l.total_leads,
        l.converted_leads,
        l.unconverted_leads,
        l.conversion_rate,
        l.avg_days_to_convert,
        l.total_converted_revenue,
        l.avg_converted_deal_size,
        l.converted_deals_won,
        l.lead_quality_score

    from lead_metrics l
)

select * from final