import json
import boto3
import os
import datetime
import logging

s3_client = boto3.client("s3")
sns_client = boto3.client("sns")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


S3_BUCKET = os.getenv("LOGS_BUCKET", "resumerx-logs-5y3lp26l")  
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN", "arn:aws:sns:us-east-1:123456789012:security-alerts")

def lambda_handler(event, context):
    """
    Lambda function to process logs from API Gateway.
    - Stores logs in S3.
    - Sends high-risk logs to SNS for alerts.
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")  

  
        body = json.loads(event.get("body", "{}"))

   
        if "log_type" not in body or "message" not in body:
            logger.warning("Missing required log fields.")  
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing required log fields."})
            }

        log_type = body["log_type"]
        message = body["message"]
        timestamp = datetime.datetime.utcnow().isoformat()

        # Create log object
        log_entry = {
            "timestamp": timestamp,
            "log_type": log_type,
            "message": message
        }

        # Convert log entry to JSON
        log_json = json.dumps(log_entry)

        # Define the S3 object key (file path)
        file_name = f"logs/{log_type}/{timestamp}.json"

        logger.info(f"Writing log to S3: {S3_BUCKET}/{file_name}")  

        # Store log in S3
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=file_name,
            Body=log_json,
            ContentType="application/json"
        )

        logger.info("Successfully wrote log to S3.")  

        # Check if log is critical and send SNS alert
        if log_type.lower() in ["security", "error", "critical"]:
            logger.info(f"Sending SNS alert for {log_type}") 
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=f"Security Alert: {message}",
                Subject=f"Security Alert - {log_type}"
            )
            logger.info("SNS alert sent successfully.") 

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Log processed successfully"})
        }

    except Exception as e:
        logger.error(f"Error processing log: {str(e)}") 
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
