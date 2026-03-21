/*
    fct_sales_activities — Sales activity tracking fact table

    Grain: One row per task/activity

    Tracks all sales activities (calls, emails, meetings)
    linked to accounts and opportunities. Answers: rep
    activity levels, activities per deal, correlation
    between activity volume and deal outcomes.
*/

with tasks as (
    select * from {{ ref('stg_tasks') }}
),

final as (
    select
        -- keys
        task_id,
        owner_id,
        account_id,
        who_id,
        what_id,

        -- activity details
        subject,
        status,
        priority,
        task_subtype,
        description,

        -- dates
        activity_date,
        completed_at,
        created_at,
        case 
            when completed_at is not null 
            then date_diff(cast(completed_at as date), cast(created_at as date), day)
            else null 
        end as days_to_complete,

        -- call details
        call_type,
        call_disposition,
        call_duration_seconds,
        case 
            when call_duration_seconds is not null 
            then round(call_duration_seconds / 60.0, 1)
            else null 
        end as call_duration_minutes,

        -- status flags
        is_closed,
        is_high_priority,
        is_archived,

        -- metadata
        last_modified_at,
        airbyte_extracted_at

    from tasks
)

select * from final