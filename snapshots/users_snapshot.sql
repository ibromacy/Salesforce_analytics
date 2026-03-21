{% snapshot users_snapshot %}

{{
    config(
        target_schema='snapshots_salesforce',
        unique_key='user_id',
        strategy='timestamp',
        updated_at='last_modified_at'
    )
}}

select * from {{ ref('stg_users') }}

{% endsnapshot %}