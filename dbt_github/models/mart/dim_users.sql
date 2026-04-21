select
author_id,
author_username,
author_association,
user_type
from {{ref('int_github_users')}}