with source as (
    select * from {{ source('raw_salesforce', 'OpportunityStage') }}
    where IsActive
),

renamed as (
    select
        -- keys
        Id as stage_id,

        -- stage info
        ApiName as stage_api_name,
        MasterLabel as stage_label,
        Description as description,
        SortOrder as sort_order,
        DefaultProbability as default_probability,

        -- classification
        IsClosed as is_closed,
        IsWon as is_won,
        ForecastCategory as forecast_category,
        ForecastCategoryName as forecast_category_name,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed