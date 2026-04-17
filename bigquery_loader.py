import pandas as pd
import pandas_gbq
import requests
import os

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "github-analytics-493513-fbbfd0791f68.json"
project_id = "github-analytics-493513"

def sync_github_endpoint(endpoint_name):
    """
    endpoint_name can be 'pulls' or 'issues'
    """
    url = f"https://api.github.com/repos/dbt-labs/dbt-core/{endpoint_name}"
    # Let's grab 200 of each to increase the chance of a match
    all_data = []
    for page in [1, 2]:
        params = {"state": "all", "per_page": 100, "page": page}
        response = requests.get(url, params=params)
        all_data.extend(response.json())
    
    df = pd.DataFrame(all_data)
    
    # We'll save them to separate tables: pull_requests and issues
    table_name = "pull_requests" if endpoint_name == "pulls" else "issues"
    table_id = f"raw_github_data.{table_name}"
    
    print(f"Loading {len(df)} records into {table_id}...")
    pandas_gbq.to_gbq(df, table_id, project_id=project_id, if_exists='replace')

# Run for both!
sync_github_endpoint("pulls")
sync_github_endpoint("issues")