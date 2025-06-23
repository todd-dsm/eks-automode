# Networking

VPC Network Infrastructure Module is just a sketch to support EKS Auto Mode.

```text
                THIS IS ALL UNTESTED / FEEL FREE TO FIX
```

## VPC Config

The module deploys a production-ready VPC using the official AWS VPC module.

It creates a multi-AZ network foundation optimized for EKS workloads with Karpenter auto-scaling.
Network Architecture. Implementing:

* A dual-tier subnet architecture using dynamic CIDR allocation with `/19` subnets (`8,192` IPs each).
* Private subnets use the lower CIDR range (`k+0`), while
* Public subnets use the upper range (`k+3`), providing clear network segregation.
* Uses a single NAT Gateway for cost optimization in non-production environments.
* All private subnets route outbound traffic through this shared NAT instance.

**IPv6 Readiness**

IPv6 configuration is present but commented out. Allowing for future dual-stack enablement without architectural changes. Includes prefix allocation for both public and private subnets when activated.

## DNS Configuration

Enables both DNS hostnames and DNS support for seamless service discovery and internal name resolution within the VPC.

## EKS Features

**Load Balancer Support:**

* Public subnets are tagged with `kubernetes.io/role/elb` for AWS Load Balancer Controller integration. 
* Private subnets use `kubernetes.io/role/internal-elb` for internal load balancers.

**Karpenter Discovery**

* Both VPC and private subnets include `karpenter.sh/discovery` tags matching the project name, enabling 
* Karpenter's automatic subnet and security group discovery for node provisioning.

**Logging**

VPC Flow Logs are configured to capture network traffic metadata with `60-second` aggregation intervals. The module creates dedicated IAM role and CloudWatch Log Group for flow log delivery.

**VPC Endpoints**

There's a config in the networking directory but it's all commented. I'm not quite there yet but feel free to experiment with it.

## KNOWN ISSUES

`The attribute "name" is deprecated`

* [This one] is just annoying but it doesn't seem to hurt anything.

AI Documentation is pretty okay.

<!-- docs/refs -->
[This one]:(https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/1199)
