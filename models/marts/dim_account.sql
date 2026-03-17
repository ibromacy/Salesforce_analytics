/*
    dim_account — Account dimension with SCD Type 2 history

    Source: accounts_snapshot

    Tracks changes to account attributes over time including
    industry, type, ownership, customer priority, and SLA.

    When an account changes industry or priority tier,
    a new historical row is opened. This ensures revenue
    analysis reflects the account profile at the time of
    each deal, not today's values.

    JOIN pattern for point-in-time accuracy:
        JOIN dim_account da
          ON fact.account_id = da.account_id
          AND fact.close_date BETWEEN da.valid_from
          AND COALESCE(da.valid_to, CURRENT_DATE())
*/

with snapshot_data as (
    select * from {{ ref('accounts_snapshot') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['account_id', 'dbt_valid_from']) }} as account_key,

        -- natural key
        account_id,
        parent_account_id,
        owner_id,

        -- account attributes
        account_name,
        account_type,
        industry,
        rating,
        ownership,
        website,
        phone,
        account_number,
        account_source,
        annual_revenue,
        number_of_employees,

        -- address
        billing_city,
        billing_state,
        billing_postal_code,
        billing_country,
        shipping_city,
        shipping_state,
        shipping_country,

        -- custom fields
        sla,
        is_active,
        customer_priority,
        upsell_opportunity,
        number_of_locations,
        sla_expiration_date,

        -- SCD Type 2 fields
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        case 
            when dbt_valid_to is null then true 
            else false 
        end as is_current

    from snapshot_data
)

select * from final