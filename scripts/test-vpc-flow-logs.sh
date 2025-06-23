#!/bin/bash
# Universal Observability Infrastructure Test Plan
# Environment: stage, Project: gitops-demo-stage
# Duration: ~30 minutes

echo "🧪 UNIVERSAL OBSERVABILITY TESTING - gitops-demo-stage"
echo "======================================================"

# ============================================================================
# STEP 1: VERIFY TERRAFORM OUTPUTS (2 minutes)
# ============================================================================
echo "📋 Step 1: Verify Terraform Outputs"
echo "------------------------------------"

echo "1.1 VPC Flow Logs CloudWatch Log Group:"
terraform output vpc_flow_logs_log_group_name
terraform output vpc_flow_logs_log_group_arn

echo -e "\n1.2 S3 Archive Bucket:"
terraform output observability_archive_bucket_name
terraform output observability_archive_bucket_arn

# ============================================================================
# STEP 2: VERIFY AWS RESOURCES EXIST (3 minutes)
# ============================================================================
echo -e "\n📦 Step 2: Verify AWS Resources"
echo "-------------------------------"

echo "2.1 CloudWatch Log Group exists:"
aws logs describe-log-groups \
    --log-group-name-prefix "/aws/vpc/flowlogs/gitops-demo-stage" \
    --query 'logGroups[0].[logGroupName,retentionInDays,storedBytes]' \
    --output table

echo -e "\n2.2 S3 Bucket exists:"
BUCKET_NAME=$(terraform output -raw observability_archive_bucket_name)
aws s3 ls s3://$BUCKET_NAME
echo "Bucket: $BUCKET_NAME"

echo -e "\n2.3 S3 Bucket Lifecycle Configuration:"
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET_NAME

echo -e "\n2.4 VPC Flow Logs Configuration:"
aws ec2 describe-flow-logs \
    --filter "Name=resource-type,Values=VPC" \
    --query 'FlowLogs[?contains(LogDestination, `gitops-demo-stage`)].[FlowLogId,FlowLogStatus,LogDestination,TrafficType]' \
    --output table

echo -e "\n2.5 IAM Role for VPC Flow Logs:"
aws iam list-roles \
    --query 'Roles[?contains(RoleName, `gitops-demo-stage-vpc-flow-logs`)].RoleName' \
    --output table

# ============================================================================
# STEP 3: VERIFY VPC FLOW LOGS DATA (10 minutes)
# ============================================================================
echo -e "\n📊 Step 3: Verify VPC Flow Logs Data Flow"
echo "-----------------------------------------"

LOG_GROUP="/aws/vpc/flowlogs/gitops-demo-stage"

echo "3.1 Check if log streams exist:"
aws logs describe-log-streams \
    --log-group-name $LOG_GROUP \
    --order-by LastEventTime \
    --descending \
    --max-items 5 \
    --query 'logStreams[].[logStreamName,lastEventTime,storedBytes]' \
    --output table

echo -e "\n3.2 Get recent VPC Flow Logs (last 15 minutes):"
START_TIME=$(date -d '15 minutes ago' +%s)000
END_TIME=$(date +%s)000

aws logs filter-log-events \
    --log-group-name $LOG_GROUP \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --limit 10 \
    --query 'events[].message' \
    --output table

echo -e "\n3.3 Count of log events in last hour:"
START_TIME_HOUR=$(date -d '1 hour ago' +%s)000
EVENT_COUNT=$(aws logs filter-log-events \
    --log-group-name $LOG_GROUP \
    --start-time $START_TIME_HOUR \
    --end-time $END_TIME \
    --query 'length(events)' \
    --output text)
echo "Events in last hour: $EVENT_COUNT"

# ============================================================================
# STEP 4: TEST CLOUDWATCH INSIGHTS QUERIES (8 minutes)
# ============================================================================
echo -e "\n🔍 Step 4: Test CloudWatch Insights Queries"
echo "--------------------------------------------"

echo "4.1 List our pre-built queries:"
aws logs describe-query-definitions \
    --query 'queryDefinitions[?contains(name, `gitops-demo-stage`)].[name,queryDefinitionId]' \
    --output table

echo -e "\n4.2 Test Top Talkers Query:"
QUERY_ID=$(aws logs start-query \
    --log-group-name $LOG_GROUP \
    --start-time $START_TIME_HOUR \
    --end-time $END_TIME \
    --query-string 'fields @timestamp, srcaddr, dstaddr, bytes | filter bytes > 0 | stats sum(bytes) as total_bytes by srcaddr, dstaddr | sort total_bytes desc | limit 10' \
    --query 'queryId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting 10 seconds for query to complete..."
sleep 10

aws logs get-query-results --query-id $QUERY_ID \
    --query 'results[]' \
    --output table

echo -e "\n4.3 Test Rejected Traffic Query:"
QUERY_ID2=$(aws logs start-query \
    --log-group-name $LOG_GROUP \
    --start-time $START_TIME_HOUR \
    --end-time $END_TIME \
    --query-string 'fields @timestamp, srcaddr, dstaddr, action | filter action = "REJECT" | stats count(*) as reject_count by srcaddr, dstaddr | sort reject_count desc | limit 10' \
    --query 'queryId' \
    --output text)

echo "Query ID: $QUERY_ID2"
echo "Waiting 10 seconds for query to complete..."
sleep 10

aws logs get-query-results --query-id $QUERY_ID2 \
    --query 'results[]' \
    --output table

# ============================================================================
# STEP 5: VERIFY S3 LIFECYCLE AND PERMISSIONS (5 minutes)
# ============================================================================
echo -e "\n🗄️ Step 5: Verify S3 Configuration"
echo "----------------------------------"

echo "5.1 S3 Bucket Versioning:"
aws s3api get-bucket-versioning --bucket $BUCKET_NAME

echo -e "\n5.2 S3 Bucket Encryption:"
aws s3api get-bucket-encryption --bucket $BUCKET_NAME

echo -e "\n5.3 S3 Public Access Block:"
aws s3api get-public-access-block --bucket $BUCKET_NAME

echo -e "\n5.4 Test S3 Write Access (create a test file):"
echo "Test observability data - $(date)" | aws s3 cp - s3://$BUCKET_NAME/test-observability-$(date +%s).txt
echo "Test file uploaded successfully"

echo -e "\n5.5 List objects in bucket:"
aws s3 ls s3://$BUCKET_NAME/ --human-readable

# ============================================================================
# STEP 6: GENERATE NETWORK ACTIVITY FOR TESTING (2 minutes)
# ============================================================================
echo -e "\n🌐 Step 6: Generate Test Network Activity"
echo "----------------------------------------"

echo "6.1 Generate some network traffic for VPC Flow Logs:"
echo "Pinging external hosts to generate ACCEPT traffic..."
ping -c 3 8.8.8.8 > /dev/null 2>&1 &
ping -c 3 1.1.1.1 > /dev/null 2>&1 &

echo "Testing connection to non-existent internal IP to generate REJECT traffic..."
timeout 2 telnet 10.101.255.254 80 2>/dev/null &

echo "Waiting for traffic generation..."
sleep 5

echo "Traffic generation complete. New VPC Flow Logs should appear in 5-10 minutes."

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo -e "\n✅ TESTING SUMMARY"
echo "=================="
echo "Environment: stage"
echo "Project: gitops-demo-stage"
echo "Log Group: $LOG_GROUP"
echo "S3 Bucket: $BUCKET_NAME"
echo ""
echo "🔍 What to look for:"
echo "- VPC Flow Logs should show network traffic"
echo "- CloudWatch Insights queries should return data"
echo "- S3 bucket should be properly configured with lifecycle rules"
echo "- New log events should appear in the next 5-10 minutes"
echo ""
echo "🚀 Ready for tool-specific overlays (Grafana, Datadog, etc.)"
