with issues as(
    select
        *
    from {{ref('stg_issues')}}
),
users as(
    select
        *
    from {{ref('dim_users')}}
),

issue_labels as (
    select 
        item_id,
        countif(lower(label_name) like '%bug%') > 0 as is_bug
    from {{ ref('int_github_labels') }}
    where item_type = 'issue'
    group by 1
),

final as(
    select
        i.issue_id,
        i.issue_number,
        i.author_id,

        i.state,
        i.title,
        u.user_type,
        u.author_association,
        
        i.created_at,
        i.closed_at,
        coalesce(il.is_bug, false) as is_bug,

        timestamp_diff(i.closed_at, i.created_at, hour) as hours_to_close,

        case when i.closed_at is not null then true else false end as is_closed,
        case 
            when u.author_association in ('OWNER', 'MEMBER', 'COLLABORATOR') then false
            else true
        end as is_community_contribution
    from issues i
    left join users u on i.author_id = u.author_id
    left join issue_labels il on i.issue_id = il.item_id
)

select
*
from final