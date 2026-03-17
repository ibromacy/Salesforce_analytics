with source as (
    select * from {{ source('raw_salesforce', 'Lead') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as lead_id,
        OwnerId as owner_id,
        ConvertedAccountId as converted_account_id,
        ConvertedContactId as converted_contact_id,
        ConvertedOpportunityId as converted_opportunity_id,

        -- lead info
        FirstName as first_name,
        LastName as last_name,
        Name as full_name,
        Title as title,
        Company as company,
        Email as email,
        Phone as phone,
        MobilePhone as mobile_phone,
        Website as website,
        Salutation as salutation,

        -- classification
        Status as status,
        Rating as rating,
        LeadSource as lead_source,
        Industry as industry,
        AnnualRevenue as annual_revenue,
        NumberOfEmployees as number_of_employees,

        -- address
        Street as street,
        City as city,
        State as state,
        PostalCode as postal_code,
        Country as country,

        -- conversion
        IsConverted as is_converted,
        ConvertedDate as converted_date,

        -- custom fields
        ProductInterest__c as product_interest,
        Primary__c as is_primary,
        CurrentGenerators__c as current_generators,
        NumberofLocations__c as number_of_locations,
        SICCode__c as sic_code,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        LastActivityDate as last_activity_date,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed