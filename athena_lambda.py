def lambda_handler(event, context):
    import boto3, os
    athena = boto3.client('athena')
    queries = [
        ("TopStatusCodes", "SELECT status_code, COUNT(*) AS occurrences FROM logs_table GROUP BY status_code ORDER BY occurrences DESC LIMIT 5"),
        ("TopUnauthorizedIPs", "SELECT ip_address, COUNT(*) AS attempts FROM logs_table WHERE status_code IN (401, 403) GROUP BY ip_address ORDER BY attempts DESC LIMIT 5"),
        ("Top404IPs", "SELECT ip_address, COUNT(*) AS not_found_count FROM logs_table WHERE status_code = 404 GROUP BY ip_address ORDER BY not_found_count DESC LIMIT 5"),
        ("Top5xxIPs", "SELECT ip_address, COUNT(*) AS server_error_count FROM logs_table WHERE status_code BETWEEN 500 AND 599 GROUP BY ip_address ORDER BY server_error_count DESC LIMIT 5"),
        ("TopUserAgents", "SELECT user_agent, COUNT(*) AS frequency FROM logs_table GROUP BY user_agent ORDER BY frequency DESC LIMIT 5"),
        ("UnauthorizedSpikesHourly", "SELECT date_trunc('hour', request_time) AS hour, COUNT(*) AS request_count FROM logs_table WHERE status_code = 403 GROUP BY hour ORDER BY hour DESC LIMIT 24")
    ]
    for name, query in queries:
        athena.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": os.environ['DATABASE']},
            ResultConfiguration={"OutputLocation": f"{os.environ['OUTPUT']}{name}/"},
            WorkGroup=os.environ['WORKGROUP']
        )