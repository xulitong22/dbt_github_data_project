with source as (
    select * from {{source('github_raw', 'pull_requests')}}
),

renamed as (
    select
        id as pr_id,
        number as pr_number,
        state,
        title,
        user.login as author_username,
        user.id as author_id,
        author_association,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(closed_at as timestamp) as closed_at,
        cast(merged_at as timestamp) as merged_at,
        labels,
        body
    from source
)

select * from renamed