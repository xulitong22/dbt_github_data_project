with unique_labels as (
    select
        label_name,
        label_color,
        label_description
        from {{ref('int_github_labels')}}
    group by 1,2,3
)

select
    {{dbt_utils.generate_surrogate_key(['label_name'])}} as label_key,
    label_name,
    label_color,
    label_description
from unique_labels