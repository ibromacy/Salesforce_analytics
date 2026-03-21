/*
    dim_user — Sales rep / user dimension with SCD Type 2 history

    Source: users_snapshot

    Tracks changes to user attributes over time including
    title, department, division, and manager. When a rep
    changes team or gets promoted, a new row is opened.

    This ensures sales performance is attributed to the
    team the rep belonged to at the time of the deal.
*/

with snapshot_data as (
    select * from {{ ref('users_snapshot') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['user_id', 'dbt_valid_from']) }} as user_key,

        -- natural key
        user_id,
        manager_id,

        -- user attributes
        first_name,
        last_name,
        full_name,
        title,
        email,
        department,
        division,
        company_name,
        employee_number,
        user_type,

        -- contact
        phone,
        mobile_phone,

        -- location
        city,
        state,
        country,

        -- status
        is_active,
        last_login_at,

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