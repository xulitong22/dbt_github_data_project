with item_with_labels as(
    select
    issue_id as item_id,
    'issue' as item_type,
    labels
    from {{ref('stg_issues')}}

    union all

    select
    pr_id as item_id,
    'pull request' as item_type,
    labels
    from {{ref('stg_pull_requests')}}
)

select
item_id,
item_type,
label.id as label_id,
label.name as label_name,
label.color as label_color,
label.description as label_description
from item_with_labels
cross join unnest(labels) as label