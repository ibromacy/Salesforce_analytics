/*
    dim_lead — Lead dimension

    Source: stg_leads

    No SCD Type 2 — leads have a short lifecycle 
    and either convert or go cold. Historical tracking
    is handled by the conversion date and status fields.
*/

with leads as (
    select * from {{ ref('stg_leads') }}
),

final as (
    select
        -- key
        lead_id,
        owner_id,

        -- lead attributes
        first_name,
        last_name,
        full_name,
        title,
        company,
        email,
        phone,

        -- classification
        status,
        rating,
        lead_source,
        industry,
        annual_revenue,
        number_of_employees,

        -- address
        city,
        state,
        postal_code,
        country,

        -- custom fields
        product_interest,
        is_primary,
        current_generators,
        number_of_locations,
        sic_code,

        -- conversion
        is_converted,
        converted_date,
        converted_account_id,
        converted_contact_id,
        converted_opportunity_id,

        -- metadata
        created_at,
        last_modified_at

    from leads
)

select * from final