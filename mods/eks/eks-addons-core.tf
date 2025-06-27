#######################################################################################################################
# These add-ons are included in the EKS Auto Mode by default
# VPC CNI plugin
# CoreDNS
# kube-proxy
# EBS storage capability (not the full EBS CSI driver addon)
# AWS Load Balancer Controller
# Karpenter for node management

# Not Included & Managed:
# Preconfigured (but disabled) storage add-ons:
#   * AWS EFS CSI driver
#   * FSx CSI driver
#   * Mountpoint for S3 CSI driver
#   * Snapshot Controller (Builds in 15m20s)
#----------------------------------------------------------------------------------------------------------------------
# For now, we're favoring SigNoz; we won't be using these:
#   * Observability Stack Components
#     - AWS Distro for OpenTelemetry (ADOT)
#     - AWS X-Ray
#     - AWS CloudWatch Container Insights
#     - AWS CloudWatch Logs
#     - AWS CloudWatch Metrics
#     - AWS CloudWatch Events
#     - AWS CloudWatch Alarms

########################################################################################################################
# IRSAs to Support EKS Addons
# VER: https://github.com/terraform-aws-modules/terraform-aws-iam/releases
# TFR: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/examples/iam-role-for-service-accounts-eks
# SPT: https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/examples/iam-role-for-service-accounts-eks
# DOC: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/
# EXs: https://github.com/terraform-aws-modules/terraform-aws-iam/blob/7825816ce6cb6a2838c0978b629868d24358f5aa/README.md
# ######################################################################################################################
