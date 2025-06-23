#!/usr/bin/env bash
# shellcheck disable=SC2154
#  PURPOSE: Creates an AWS S3 Bucket for remote terraform state storage.
#           Intended for use with DynamoDB to support state locking and
#           consistency checking.
#
#           Managing the S3 and Backend config in the same file ensures
#           consistent bucket naming. S3 bucket = backend bucket. To guard
#           against errors, these should not be separated.
# -----------------------------------------------------------------------------
#  PREREQS: a) The bucket must exist before initializing the backend.
#           b)
#           c)
# -----------------------------------------------------------------------------
#  EXECUTE:
# -----------------------------------------------------------------------------
#     TODO: 1)
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2018/12/09
# -----------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# ENV Stuff
: "${state_bucket? Theres no bucket name; please source-in the variables.}"


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### Setup Terraform state locking with a DynamoDB Table
###---
printf '\n\n%s\n' "Provisioning Terraform state Storage and Locking..."
aws configure set default.region "$TF_VAR_region"


###---
### Setup Terraform state storage in an S3 Bucket
###---
printf '\n\n%s\n' "Creating a bucket for remote terraform state..."
# Bucket name must be unique to all bucket names
if ! aws s3 mb "s3://${state_bucket}"; then
    pMsg """

    There was an issue creating the bucket: $state_bucket, or
    The bucket already exists.

    """
    exit
else
    pMsg "  The bucket has been created: $state_bucket"
fi

### Enable versioning
pMsg "  Enabling versioning..."
aws s3api put-bucket-versioning --bucket "$state_bucket" \
    --versioning-configuration Status=Enabled

### Enable encryption
pMsg "  Enabling encryption..."
aws s3api put-bucket-encryption --bucket "$state_bucket" \
    --server-side-encryption-configuration \
    '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

### Enable encryption
pMsg "  Blocking public access..."
aws s3api put-public-access-block --bucket "$state_bucket" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"


###---
### Create the Terraform backend definition for this bucket
###---
scripts/setup/create-tf-provider.sh


###---
### Make the announcement
###---
printf '\n\n%s\n\n' "We're ready to start Terraforming!"


###---
### fin~
###---
exit 0
