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
    from {{ source('raw_cdc', 'CUSTOMERS_CDC') }}
),

cleaned_events as (
    select
        nullif(trim(coalesce(
            record_content:"after":"customer_id"::string,
            record_metadata:"Key":"customer_id"::string
        )), '') as customer_id,
        nullif(trim(record_content:"after":"customer_unique_id"::string), '') as customer_unique_id,
        case
            when record_content:"after":"customer_zip_code_prefix" is null then null
            else lpad(trim(record_content:"after":"customer_zip_code_prefix"::string), 5, '0')
        end as customer_zip_code_prefix,
        nullif(lower(trim(record_content:"after":"customer_city"::string)), '') as customer_city,
        nullif(upper(trim(record_content:"after":"customer_state"::string)), '') as customer_state,
        cdc_event_timestamp,
        to_date(cdc_event_timestamp) as cdc_event_date,
        to_time(cdc_event_timestamp) as cdc_event_time,
        cdc_operation,
        sha2(
            concat_ws(
                '|',
                coalesce(nullif(trim(record_content:"after":"customer_unique_id"::string), ''), ''),
                coalesce(
                    case
                        when record_content:"after":"customer_zip_code_prefix" is null then null
                        else lpad(trim(record_content:"after":"customer_zip_code_prefix"::string), 5, '0')
                    end,
                    ''
                ),
                coalesce(nullif(lower(trim(record_content:"after":"customer_city"::string)), ''), ''),
                coalesce(nullif(upper(trim(record_content:"after":"customer_state"::string)), ''), '')
            ),
            256
        ) as change_hash
    from raw_events
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by customer_id, cdc_event_timestamp, change_hash
            order by cdc_event_timestamp desc
        ) as rn
    from cleaned_events
    where customer_id is not null
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    cdc_event_timestamp,
    cdc_event_date,
    cdc_event_time,
    cdc_operation,
    change_hash
from deduplicated
where rn = 1
