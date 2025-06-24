#!/usr/bin/env bash


# VARS
#badFile='/tmp/region.tf'
badFile='.terraform/modules/eks.ebs_csi_driver_irsa/modules/iam-role-for-service-accounts-eks/main.tf'


# Use printer
source scripts/lib/printer.func


print_req """

            FIXING: region attribute \"name\" is deprecated

           """

### FIX File

set -x
grep 'data.aws_region.current' "$badFile"
sed -i 's/data\.aws_region\.current\.name/data\.aws_region\.current\.region/g' "$badFile"
grep 'data.aws_region.current' "$badFile"

#diff /tmp/region.tf /tmp/region.orig

