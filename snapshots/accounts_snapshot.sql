{% snapshot accounts_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='account_id',
        strategy='timestamp',
        updated_at='last_modified_at'
    )
}}

select * from {{ ref('stg_accounts') }}

{% endsnapshot %}