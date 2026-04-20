with union_users as (
    select
        author_id,
        author_username,
        author_association,
        updated_at
    from {{ref('stg_pull_requests')}}
    union distinct
    select
        author_id,
        author_username,
        author_association,
        updated_at
    from {{ref('stg_issues')}}
),

ranked_user as(
    select
    *,
    row_number()over(partition by author_id order by updated_at) as rn
    from union_users
)

select
author_id,
author_username,
author_association,
case 
    when lower(author_username) like '%bot%'
      or lower(author_username) like '%actions%' 
    then 'bot'
    else 'human'
end as user_type
from ranked_user
where rn = 1