with source as (
    select * from {{ source('raw_salesforce', 'Task') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as task_id,
        WhoId as who_id,
        WhatId as what_id,
        OwnerId as owner_id,
        AccountId as account_id,

        -- task info
        Subject as subject,
        Status as status,
        Priority as priority,
        Description as description,
        TaskSubtype as task_subtype,

        -- dates
        ActivityDate as activity_date,
        CompletedDateTime as completed_at,

        -- call details
        CallType as call_type,
        CallDisposition as call_disposition,
        CallDurationInSeconds as call_duration_seconds,

        -- status flags
        IsClosed as is_closed,
        IsHighPriority as is_high_priority,
        IsArchived as is_archived,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed