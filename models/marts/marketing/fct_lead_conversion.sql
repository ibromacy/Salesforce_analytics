/*
    fct_lead_conversion — Lead conversion funnel fact table

    Grain: One row per lead

    Tracks the full lifecycle of a lead from creation
    to conversion (or death). Answers: conversion rate
    by source, time to convert, which channels produce
    the highest quality leads.
*/

with leads as (
    select * from {{ ref('stg_leads') }}
),

opportunities as (
    select 
        opportunity_id,
        amount,
        is_won,
        is_closed,
        stage_name,
        close_date
    from {{ ref('stg_opportunities') }}
),

final as (
    select
        -- keys
        l.lead_id,
        l.owner_id,
        l.converted_account_id,
        l.converted_contact_id,
        l.converted_opportunity_id,

        -- lead attributes
        l.full_name as lead_name,
        l.company,
        l.title,
        l.lead_source,
        l.industry,
        l.rating,
        l.status,

        -- location
        l.city,
        l.state,
        l.country,

        -- conversion metrics
        l.is_converted,
        l.converted_date,
        l.created_at as lead_created_at,
        case 
            when l.is_converted then date_diff(l.converted_date, cast(l.created_at as date), day)
            else null 
        end as days_to_convert,

        -- converted opportunity details
        o.amount as converted_opportunity_amount,
        o.is_won as converted_opportunity_won,
        o.is_closed as converted_opportunity_closed,
        o.stage_name as converted_opportunity_stage,

        -- custom fields
        l.product_interest,
        l.number_of_locations,
        l.annual_revenue as lead_annual_revenue,
        l.number_of_employees as lead_number_of_employees,

        -- metadata
        l.last_modified_at,
        l.last_activity_date,
        l.airbyte_extracted_at

    from leads l
    left join opportunities o
        on l.converted_opportunity_id = o.opportunity_id
)

select * from final