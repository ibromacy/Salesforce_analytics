with source as (
    select * from {{ source('raw_salesforce', 'Campaign') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as campaign_id,
        OwnerId as owner_id,
        ParentId as parent_campaign_id,

        -- campaign info
        Name as campaign_name,
        Type as campaign_type,
        Status as status,
        Description as description,
        IsActive as is_active,

        -- dates
        StartDate as start_date,
        EndDate as end_date,

        -- financials
        BudgetedCost as budgeted_cost,
        ActualCost as actual_cost,
        ExpectedRevenue as expected_revenue,
        ExpectedResponse as expected_response_pct,

        -- salesforce rollup metrics
        NumberSent as number_sent,
        NumberOfLeads as number_of_leads,
        NumberOfContacts as number_of_contacts,
        NumberOfResponses as number_of_responses,
        NumberOfOpportunities as number_of_opportunities,
        NumberOfWonOpportunities as number_of_won_opportunities,
        NumberOfConvertedLeads as number_of_converted_leads,
        AmountAllOpportunities as amount_all_opportunities,
        AmountWonOpportunities as amount_won_opportunities,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        LastActivityDate as last_activity_date,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed