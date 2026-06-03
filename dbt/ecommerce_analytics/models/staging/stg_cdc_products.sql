with raw_events as (
    select
        record_metadata,
        record_content,
        to_timestamp_ntz(record_metadata:"CreateTime"::number / 1000) as cdc_event_timestamp,
        case coalesce(
            nullif(lower(trim(record_content:"op"::string)), ''),
            nullif(lower(trim(record_metadata:"Operation"::string)), ''),
            'u'
        )
            when 'c' then 'insert'
            when 'u' then 'update'
            when 'd' then 'delete'
            when 'r' then 'snapshot'
            else 'unknown'
        end as cdc_operation
    from {{ source('raw_cdc', 'PRODUCTS_CDC') }}
),

cleaned_events as (
    select
        nullif(trim(coalesce(
            record_content:"after":"product_id"::string,
            record_metadata:"Key":"product_id"::string
        )), '') as product_id,
        nullif(lower(trim(record_content:"after":"product_category_name"::string)), '') as product_category_name,
        cast(record_content:"after":"product_name_lenght" as number(38, 0)) as product_name_lenght,
        cast(record_content:"after":"product_description_lenght" as number(38, 0)) as product_description_lenght,
        cast(record_content:"after":"product_photos_qty" as number(38, 0)) as product_photos_qty,
        cast(record_content:"after":"product_weight_g" as number(38, 0)) as product_weight_g,
        cast(record_content:"after":"product_length_cm" as number(38, 0)) as product_length_cm,
        cast(record_content:"after":"product_height_cm" as number(38, 0)) as product_height_cm,
        cast(record_content:"after":"product_width_cm" as number(38, 0)) as product_width_cm,
        cdc_event_timestamp,
        to_date(cdc_event_timestamp) as cdc_event_date,
        to_time(cdc_event_timestamp) as cdc_event_time,
        cdc_operation,
        sha2(
            concat_ws(
                '|',
                coalesce(nullif(lower(trim(record_content:"after":"product_category_name"::string)), ''), ''),
                coalesce(record_content:"after":"product_name_lenght"::string, ''),
                coalesce(record_content:"after":"product_description_lenght"::string, ''),
                coalesce(record_content:"after":"product_photos_qty"::string, ''),
                coalesce(record_content:"after":"product_weight_g"::string, ''),
                coalesce(record_content:"after":"product_length_cm"::string, ''),
                coalesce(record_content:"after":"product_height_cm"::string, ''),
                coalesce(record_content:"after":"product_width_cm"::string, '')
            ),
            256
        ) as change_hash
    from raw_events
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by product_id, cdc_event_timestamp, change_hash
            order by cdc_event_timestamp desc
        ) as rn
    from cleaned_events
    where product_id is not null
)

select
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    cdc_event_timestamp,
    cdc_event_date,
    cdc_event_time,
    cdc_operation,
    change_hash
from deduplicated
where rn = 1
