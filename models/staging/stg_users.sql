with source as (
    select * from {{ source('raw_salesforce', 'User') }}
    where IsActive
),

renamed as (
    select
        -- keys
        Id as user_id,
        ManagerId as manager_id,
        ProfileId as profile_id,
        UserRoleId as user_role_id,

        -- user info
        FirstName as first_name,
        LastName as last_name,
        Name as full_name,
        Title as title,
        Email as email,
        Username as username,
        Alias as alias,
        Department as department,
        Division as division,
        CompanyName as company_name,
        EmployeeNumber as employee_number,
        UserType as user_type,

        -- contact
        Phone as phone,
        MobilePhone as mobile_phone,

        -- location
        City as city,
        State as state,
        PostalCode as postal_code,
        Country as country,

        -- status
        IsActive as is_active,
        LastLoginDate as last_login_at,

        -- metadata
        CreatedDate as created_at,
        LastModifiedDate as last_modified_at,
        SystemModstamp as system_modstamp,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
)

select * from renamed