{{
    config(
        materialized='view'
    )
}}

select
    date_day as ds
from {{ ref('dim_date') }}