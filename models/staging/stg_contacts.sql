with source as (
    select * from {{ source('raw_salesforce', 'Contact') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as contact_id,
        AccountId as account_id,
        OwnerId as owner_id,
        ReportsToId as reports_to_id,

        -- contact info
        FirstName as first_name,
        LastName as last_name,
        Name as full_name,
        Title as title,
        Department as department,
        Email as email,
        Phone as phone,
        MobilePhone as mobile_phone,
        HomePhone as home_phone,
        Salutation as salutation,
        Birthdate as birthdate,
        LeadSource as lead_source,
        Level__c as level,

        -- mailing address
        MailingStreet as mailing_street,
        MailingCity as mailing_city,
        MailingState as mailing_state,
        MailingPostalCode as mailing_postal_code,
        MailingCountry as mailing_country,

        -- other address
        OtherStreet as other_street,
        OtherCity as other_city,
        OtherState as other_state,
        OtherPostalCode as other_postal_code,
        OtherCountry as other_country,

        -- status
        IsEmailBounced as is_email_bounced,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        LastActivityDate as last_activity_date,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed