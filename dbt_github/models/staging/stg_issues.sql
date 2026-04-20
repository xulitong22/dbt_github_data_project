with source as (
    select * from {{source('github_raw', 'issues')}}
),

renamed as (
    select
        id as issue_id,
        number as issue_number,
        state,
        title,
        user.login as author_username,
        user.id as author_id,
        author_association,
        labels, 
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(closed_at as timestamp) as closed_at,
        body
    from source
    where pull_request is null
)

select
*
from renamed
