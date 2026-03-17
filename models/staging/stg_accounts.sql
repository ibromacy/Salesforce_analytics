with source as (
    select * from {{ source('raw_salesforce', 'Account') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as account_id,
        OwnerId as owner_id,
        ParentId as parent_account_id,

        -- account info
        Name as account_name,
        Type as account_type,
        Industry as industry,
        Rating as rating,
        Ownership as ownership,
        Website as website,
        Phone as phone,
        Fax as fax,
        Description as description,
        AccountNumber as account_number,
        AccountSource as account_source,
        AnnualRevenue as annual_revenue,
        NumberOfEmployees as number_of_employees,

        -- address
        BillingStreet as billing_street,
        BillingCity as billing_city,
        BillingState as billing_state,
        BillingPostalCode as billing_postal_code,
        BillingCountry as billing_country,
        ShippingStreet as shipping_street,
        ShippingCity as shipping_city,
        ShippingState as shipping_state,
        ShippingPostalCode as shipping_postal_code,
        ShippingCountry as shipping_country,

        -- custom fields
        SLA__c as sla,
        Active__c as is_active,
        CustomerPriority__c as customer_priority,
        UpsellOpportunity__c as upsell_opportunity,
        NumberofLocations__c as number_of_locations,
        SLAExpirationDate__c as sla_expiration_date,
        SLASerialNumber__c as sla_serial_number,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed