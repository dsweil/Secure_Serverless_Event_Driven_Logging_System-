import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Received Security Hub finding event")
    logger.info(json.dumps(event))

    try:
        # Extract findings
        findings = event['detail']['findings']
        for finding in findings:
            title = finding.get('Title', 'No Title')
            severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
            resource = finding.get('Resources', [{}])[0].get('Id', 'No Resource')
            region = finding.get('Region', 'unknown')

            logger.info(f"🔐 Finding: {title}")
            logger.info(f"Severity: {severity}")
            logger.info(f"Resource: {resource}")
            logger.info(f"Region: {region}")

            # 🚧 Place for future integrations (e.g., alerting, ticketing)
            # send_to_slack(title, severity, resource)

        return {
            'statusCode': 200,
            'body': json.dumps('Security Hub event processed successfully')
        }

    except Exception as e:
        logger.error(f"Error processing Security Hub event: {e}")
        raise e
