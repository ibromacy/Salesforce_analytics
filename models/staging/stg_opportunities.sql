with source as (
    select * from {{ source('raw_salesforce', 'Opportunity') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as opportunity_id,
        AccountId as account_id,
        OwnerId as owner_id,
        ContactId as contact_id,
        CampaignId as campaign_id,
        Pricebook2Id as pricebook_id,

        -- opportunity info
        Name as opportunity_name,
        Type as opportunity_type,
        StageName as stage_name,
        Description as description,
        NextStep as next_step,
        LeadSource as lead_source,

        -- financials
        Amount as amount,
        ExpectedRevenue as expected_revenue,
        Probability as probability,
        TotalOpportunityQuantity as total_quantity,

        -- dates
        CloseDate as close_date,
        LastStageChangeDate as last_stage_change_date,

        -- status flags
        IsClosed as is_closed,
        IsWon as is_won,
        HasOverdueTask as has_overdue_task,
        HasOpenActivity as has_open_activity,

        -- forecast
        ForecastCategory as forecast_category,
        ForecastCategoryName as forecast_category_name,
        FiscalYear as fiscal_year,
        FiscalQuarter as fiscal_quarter,

        -- custom fields
        OrderNumber__c as order_number,
        TrackingNumber__c as tracking_number,
        MainCompetitors__c as main_competitors,
        CurrentGenerators__c as current_generators,
        DeliveryInstallationStatus__c as delivery_installation_status,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        LastActivityDate as last_activity_date,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed