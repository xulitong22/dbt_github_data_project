with labels as (
    select
    *
    from {{ref('int_github_labels')}}
)

select
item_id,
item_type,
{{ dbt_utils.generate_surrogate_key(['label_name']) }} as label_key,
label_name
from labels
