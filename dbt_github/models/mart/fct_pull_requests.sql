with pulls as(
    select
        *
    from {{ref('stg_pull_requests')}}
),
users as(
    select
        *
    from {{ref('dim_users')}}
),
links as(
    select
        *
    from {{ref('int_pr_issue_link')}}
),

final as(
    select
        p.pr_id,
        p.pr_number,
        p.author_id,
        l.linked_issue_number,

        p.state,
        p.title,
        u.user_type,
        u.author_association,

        p.created_at,
        p.merged_at,
        p.closed_at,

        timestamp_diff(p.merged_at, p.created_at, hour) as hours_to_merge,
        timestamp_diff(p.closed_at, p.created_at, hour) as hours_to_close,

        case when p.merged_at is not null then true else false end as is_merged,
        case when u.user_type = 'bot' then true else false end as is_bot_action,
        case 
            when u.author_association in ('OWNER', 'MEMBER', 'COLLABORATOR') then false
            else true
        end as is_community_contribution
    from pulls p
    left join users u on p.author_id = u.author_id
    left join links l on p.pr_id = l.pr_id
)

select
*
from final