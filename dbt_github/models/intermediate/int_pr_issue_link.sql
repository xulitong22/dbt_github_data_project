with pulls as(
    select 
    pr_id,
    pr_number,
    body
    from {{ref('stg_pull_requests')}}
),

extracted as(
    select
    pr_id,
    pr_number,
    regexp_extract_all(
            body, 
            r'(?i)(?:fixes|closes|resolves|fixed|closed|resolved)\s*#([0-9]+)'
        ) as linked_issue_array
    from pulls
)

select
pr_id,
pr_number,
cast(issue_number as int64) as linked_issue_number
from extracted
cross join unnest(linked_issue_array) as issue_number