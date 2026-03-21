with source as (
    select * from {{ source('raw_salesforce', 'CampaignMember') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as campaign_member_id,
        CampaignId as campaign_id,
        LeadId as lead_id,
        ContactId as contact_id,
        LeadOrContactId as lead_or_contact_id,
        LeadOrContactOwnerId as lead_or_contact_owner_id,

        -- member info
        FirstName as first_name,
        LastName as last_name,
        Name as full_name,
        Title as title,
        Email as email,
        Phone as phone,
        MobilePhone as mobile_phone,
        CompanyOrAccount as company_or_account,

        -- status
        Status as status,
        HasResponded as has_responded,
        FirstRespondedDate as first_responded_date,
        LeadSource as lead_source,

        -- member type (derived)
        case
            when LeadId is not null then 'Lead'
            when ContactId is not null then 'Contact'
            else 'Unknown'
        end as member_type,

        -- contact preferences
        DoNotCall as do_not_call,
        HasOptedOutOfEmail as has_opted_out_of_email,
        HasOptedOutOfFax as has_opted_out_of_fax,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed