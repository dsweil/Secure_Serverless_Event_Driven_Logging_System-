# 🛡️ Secure Log Ingestion & Event Routing Pipeline (AWS Serverless)

This project implements a secure, event-driven serverless architecture for log ingestion, threat detection, and security escalation using AWS-native services. It emphasizes **fine-grained IAM controls**, **log enrichment**, and **automated alerting**.

---

## 📌 Overview

The flow captures log data from trusted sources, processes and stores it securely, then routes events based on risk level. Unauthorized injection is blocked through IAM policies, while actionable security findings are escalated via SNS.

---

## 🔁 Main Event Flow

### 1️⃣ Log Submission
A user, system, or application submits logs via **API Gateway**.

### 2️⃣ Request Forwarding
**API Gateway** forwards the request to an AWS **Lambda** function.

### 3️⃣ Log Processing
The **Lambda** function:
- Validates input format
- Optionally enriches the data
- Prepares the log for storage

### 4️⃣ Secure Storage in S3
Logs are stored in an **S3 bucket**:
- Encrypted with **KMS**
- Access restricted via IAM policies

### 5️⃣ S3 → EventBridge Trigger
When a new object is added to the S3 bucket:
- An event is emitted to **Amazon EventBridge**

### 6️⃣ IAM Validation (Security Control Point)
IAM ensures:
- Only this S3 bucket can invoke EventBridge
- EventBridge has permission to forward only trusted events

> 🛑 If IAM denies the request, the event is blocked — preventing unauthorized log injection.

### 7️⃣ Event Filtering & Routing
**EventBridge** filters incoming log events and:
- Routes high-priority logs to **SNS**
- Drops low-risk or irrelevant data

### 8️⃣ Alert Dispatch
**SNS** delivers alerts to:
- Email
- Slack
- PagerDuty or other notification tools

---

## ✅ Security Services

| 🔐 Service       | Purpose |
|------------------|---------|
| **CloudWatch**   | Logs API Gateway and Lambda activity |
| **GuardDuty**    | Monitors API calls, IAM activity, and network traffic |
| **Security Hub** | Aggregates findings from GuardDuty, IAM, CloudTrail |
| **IAM**          | Enforces role-based access and prevents abuse of EventBridge |

---

## 🔮 Planned Enhancements

| Feature | Description |
|--------|-------------|
| **Athena Integration** | Query and analyze log data stored in S3 |
| **DLQ for Lambda** | Capture failed log-processing events in a dedicated SQS Dead Letter Queue |
| **DLQ for Security Hub** | Isolate unprocessed high-risk findings for later review and auditing |

---

## 🧩 AWS Services Used

- API Gateway
- Lambda
- Amazon S3 (with KMS encryption)
- Amazon EventBridge
- Amazon SNS
- AWS IAM
- Amazon CloudWatch
- AWS GuardDuty
- AWS Security Hub
- (Planned: Athena, DLQ Queues)

---

## 🔐 IAM Policy Principles

- **Least Privilege**: Only explicitly trusted services and roles are allowed to trigger downstream components.
- **Separation of Duties**: Lambda can write to S3, but cannot trigger EventBridge directly.
- **Tamper Prevention**: IAM denies any unauthorized EventBridge trigger attempts.

---

## 📁 Directory Structure

```text
.
|-- api.tf
|-- backend
|-- cloudwatch.tf
|-- event_bridge.tf
|-- guide.txt
|-- lambda.tf
|-- lambda_function.py
|-- output.tf
|-- policy.tf
|-- process_logs_lambda.zip
|-- provider.tf
|-- s3.tf
|-- sec_hub.tf
|-- sns.tf
```

---

## 🧪 Testing

To simulate end-to-end flow:
1. Send test data to API Gateway using `curl` or Postman
2. Confirm logs appear in S3
3. Validate CloudWatch logs for Lambda
4. Check for SNS alerts based on EventBridge filtering

---

## 📃 License

MIT – feel free to use or extend this for your organization or personal projects.

---

## 🙌 Acknowledgments

Created with a focus on **secure event-driven architecture**, and designed to integrate into modern cloud-native security pipelines.
