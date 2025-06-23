# New Defaults for EKS Auto Mode

This page holds a list of surprising changes (not good/bad) to just keep in mind while experimenting.

## IRSA and the Metadata Service

[Identities and Credentials for EKS pods]

I filed an issue regarding an [IMDS Configuration Issue] (metadata) being unavailable; apparently, this is [the intended behavior]; things change.

<!-- docs/refs -->

[Identities and Credentials for EKS pods]:https://docs.aws.amazon.com/eks/latest/best-practices/identity-and-access-management.html#_identities_and_credentials_for_eks_pods_recommendations
[IMDS Configuration Issue]:https://github.com/aws/containers-roadmap/issues/2633
[the intended behavior]:https://github.com/aws/containers-roadmap/issues/2633#issuecomment-2994313292
