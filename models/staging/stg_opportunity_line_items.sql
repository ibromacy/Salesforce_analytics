with source as (
    select * from {{ source('raw_salesforce', 'OpportunityLineItem') }}
    where not IsDeleted
),

renamed as (
    select
        -- keys
        Id as line_item_id,
        OpportunityId as opportunity_id,
        Product2Id as product_id,
        PricebookEntryId as pricebook_entry_id,

        -- product info
        Name as product_name,
        ProductCode as product_code,
        Description as description,

        -- financials
        Quantity as quantity,
        UnitPrice as unit_price,
        ListPrice as list_price,
        TotalPrice as total_price,
        case
            when ListPrice > 0 and UnitPrice < ListPrice
            then round((1 - UnitPrice / ListPrice) * 100, 2)
            else 0
        end as discount_pct,

        -- dates
        ServiceDate as service_date,

        -- display
        SortOrder as sort_order,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed