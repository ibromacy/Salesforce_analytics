{% snapshot accounts_snapshot %}

{{
    config(
        target_schema='snapshots_salesforce',
        unique_key='account_id',
        strategy='timestamp',
        updated_at='last_modified_at'
    )
}}

select * from {{ ref('stg_accounts') }}

{% endsnapshot %}