/*
    dim_opportunity_stage — Pipeline stage reference dimension

    Source: stg_opportunity_stages

    Small reference table defining pipeline stages,
    their sort order, win/close flags, and default
    probability. Used to enrich opportunity analysis
    with stage metadata.
*/

with stages as (
    select * from {{ ref('stg_opportunity_stages') }}
),

final as (
    select
        stage_id,
        stage_api_name,
        stage_label,
        description,
        sort_order,
        default_probability,
        is_closed,
        is_won,
        forecast_category,
        forecast_category_name
    from stages
)

select * from final