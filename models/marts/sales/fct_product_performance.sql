/*
    fct_product_performance — Product-level sales analysis

    Grain: One row per opportunity line item

    Source: stg_opportunity_line_items joined with opportunity data

    Answers: which products sell the most, average discount,
    revenue by product, and product mix per deal.

    Note: This reads from staging directly (not fct_opportunities)
    because fct_opportunities aggregates to order level —
    product_id and per-product quantity are lost at that grain.
    Same design principle as product_sales_fact in the Auto_project.
*/

with line_items as (
    select * from {{ ref('stg_opportunity_line_items') }}
),

opportunities as (
    select
        opportunity_id,
        account_id,
        owner_id,
        stage_name,
        close_date,
        is_closed,
        is_won,
        fiscal_year,
        fiscal_quarter
    from {{ ref('stg_opportunities') }}
),

final as (
    select
        -- keys
        li.line_item_id,
        li.opportunity_id,
        li.product_id,
        o.account_id,
        o.owner_id,

        -- product details
        li.product_name,
        li.product_code,

        -- financials
        li.quantity,
        li.unit_price,
        li.list_price,
        li.total_price,
        li.discount_pct,

        -- opportunity context
        o.stage_name,
        o.close_date,
        o.is_closed,
        o.is_won,
        o.fiscal_year,
        o.fiscal_quarter,

        -- revenue by status
        case when o.is_won then li.total_price else 0 end as won_product_revenue,
        case when o.is_closed and not o.is_won then li.total_price else 0 end as lost_product_revenue,
        case when not o.is_closed then li.total_price else 0 end as open_product_value,

        -- dates
        li.service_date,
        li.created_at,

        -- metadata
        li.last_modified_at,
        li.airbyte_extracted_at

    from line_items li
    inner join opportunities o
        on li.opportunity_id = o.opportunity_id
)

select * from final