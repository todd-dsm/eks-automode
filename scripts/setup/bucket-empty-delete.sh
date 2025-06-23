#!/usr/bin/env bash
# scripts/cleanup-state-bucket.sh

# Get bucket name from argument or environment
: "${1:-${state_bucket}}"

if [ -z "$state_bucket" ]; then
    echo "Usage: $0 <bucket-name>"
    echo "Or set state_bucket environment variable"
    exit 1
fi

echo "=== Cleaning up S3 bucket: $state_bucket ==="

# Check if bucket exists
if ! aws s3api head-bucket --bucket "$state_bucket" 2>/dev/null; then
    echo "Bucket $state_bucket does not exist"
    exit 0
fi

# Empty the bucket (including all versions if versioning is enabled)
echo "Removing all objects..."
aws s3 rm "s3://$state_bucket" --recursive

# Remove all object versions (if versioning was enabled)
echo "Removing versioned objects..."
aws s3api list-object-versions --bucket "$state_bucket" --output json | \
jq -r '.Versions[]? | "--key \"\(.Key)\" --version-id \(.VersionId)"' | \
while read -r line; do
    eval "aws s3api delete-object --bucket $state_bucket $line"
done

# Remove all delete markers
echo "Removing delete markers..."
aws s3api list-object-versions --bucket "$state_bucket" --output json | \
jq -r '.DeleteMarkers[]? | "--key \"\(.Key)\" --version-id \(.VersionId)"' | \
while read -r line; do
    eval "aws s3api delete-object --bucket $state_bucket $line"
done

# Delete the bucket
echo "Deleting bucket..."
aws s3 rb "s3://$state_bucket"

echo "✓ Bucket $state_bucket deleted successfully"
