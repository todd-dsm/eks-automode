# Istio Gateway Testing and Troubleshooting Guide

This document provides comprehensive testing procedures and troubleshooting steps for the modern Istio Gateway implementation on EKS Auto Mode.

## Testing Order and Validation Procedures

### Phase 1: Infrastructure Validation

#### 1.1 Verify EKS Cluster Health

```bash
# Check cluster status
% kubectl cluster-info

# Verify nodes are ready
% kubectl get nodes -o wide

# Check EKS Auto Mode configuration
% aws eks describe-cluster --name gitops-demo-stage \
  --query 'cluster.computeConfig' --output table

# Expected: computeConfig.enabled = true
```

**Expected Output:**

```shell
Kubernetes control plane is running at https://...
CoreDNS is running at https://...

NAME                          STATUS   ROLES    AGE
ip-10-1-xx-xx.ec2.internal    Ready    <none>   Xm
```

#### 1.2 Verify Istio Control Plane

```bash
# Check istiod deployment
% kubectl -n istio-system get deployment istiod
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
istiod   1/1     1            1           9h

# Verify istiod pods are running
% kubectl -n istio-system get pods -l app=istiod
NAME                      READY   STATUS    RESTARTS   AGE
istiod-7d56d75f5b-6vfvv   1/1     Running   0          9h

# Check istiod logs for errors
% kubectl -n istio-system logs deployment/istiod --tail=50

# Verify OIDC endpoint configuration
% kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep caBundle
```

#### 1.3 Verify Gateway API CRDs

```bash
# Check Gateway API CRDs are installed
% kubectl get crd | grep gateway
gatewayclasses.gateway.networking.k8s.io    2025-06-28T00:17:00Z
gateways.gateway.networking.k8s.io          2025-06-28T00:17:00Z
httproutes.gateway.networking.k8s.io        2025-06-28T00:17:00Z

# Verify GatewayClass exists and is accepted
% kubectl get gatewayclass
NAME                  CONTROLLER                    ACCEPTED   AGE
istio                 istio.io/gateway-controller   True       12h
istio-gateway-class   istio.io/gateway-controller   True       3h52m
istio-remote          istio.io/unmanaged-gateway    True       12h
istio-waypoint        istio.io/mesh-controller      True       12h


# Check Gateway API version
% kubectl api-resources | grep gateway
gatewayclasses                      gc           gateway.networking.k8s.io/v1        false        GatewayClass
gateways                            gtw          gateway.networking.k8s.io/v1        true         Gateway
grpcroutes                                       gateway.networking.k8s.io/v1        true         GRPCRoute
httproutes                                       gateway.networking.k8s.io/v1        true         HTTPRoute
referencegrants                     refgrant     gateway.networking.k8s.io/v1beta1   true         ReferenceGrant
gateways                            gw           networking.istio.io/v1              true         Gateway
```

**Expected Output:**

### Phase 2: Gateway Resource Validation

#### 2.1 Verify Gateway Configuration

```bash
# Check Gateway resources
% kubectl -n istio-system get gateway
NAME                        CLASS                 ADDRESS                                                                         PROGRAMMED   AGE
gitops-demo-stage-gateway   istio-gateway-class   k8s-istiosys-gitopsde-959a5c9a6f-263f69aaf3630f18.elb.us-east-1.amazonaws.com   True         4h7m

# Detailed Gateway status
% kubectl -n istio-system describe gateway
Name:         gitops-demo-stage-gateway
Namespace:    istio-system
Labels:       app=istio-gateway
              environment=stage
...

# Check Gateway conditions (with example output)
% kubectl -n istio-system  get gateway -o yaml | grep -A 10 conditions 
...
      conditions:
      - lastTransitionTime: "2025-06-28T00:35:00Z"
        message: No errors found
        observedGeneration: 2
        reason: Accepted
        status: "True"
        type: Accepted
      - lastTransitionTime: "2025-06-28T00:35:00Z"
        message: No errors found
        observedGeneration: 2
        reason: NoConflicts
...
```

#### 2.2 Verify HTTPRoute Configuration

```bash
# Check HTTPRoute resources
% kubectl -n istio-system get httproute
NAME                               HOSTNAMES   AGE
gitops-demo-stage-default-routes               4h22m
gitops-demo-stage-https-redirect               4h22m


# Verify route attachment
% kubectl -n istio-system describe httproute

# Check route status
% kubectl -n istio-system get httproute -o yaml | grep -A 5 parentRefs
```

### Phase 3: Auto-Created Infrastructure Validation

#### 3.1 Verify Gateway Deployment

```bash
# Check auto-created deployment
% kubectl -n istio-system get deployment -l app=istio-gateway
NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
gitops-demo-stage-gateway-istio-gateway-class   1/1     1            1           3h59m

# Verify deployment status
% kubectl -n istio-system describe deployment -l app=istio-gateway

# Check pod status and labels
% kubectl -n istio-system get pods -l app=istio-gateway --show-labels

# Verify resource requests/limits
% kubectl -n istio-system get deployment -l app=istio-gateway -o yaml | grep -A 10 resources
```

#### 3.2 Verify Gateway Service and Load Balancer

```bash
# Check auto-created service
% kubectl -n istio-system get svc -l app=istio-gateway
NAME                                            TYPE           CLUSTER-IP      EXTERNAL-IP                                                                     PORT(S)
gitops-demo-stage-gateway-istio-gateway-class   LoadBalancer   aaa.bbb.ccc.ddd   k8s-istiosys-.elb.us-east-1.amazonaws.com   15021:30888/TCP,80:32210/TCP,443:30734/TCP

# Verify load balancer annotations
% kubectl -n istio-system get svc -l app=istio-gateway -o yaml | grep -A 10 annotations
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-east-1:405322537961:certificate/4eb89bca-503a-4160-80e6-f93fe4c438b2
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
    creationTimestamp: "2025-06-28T00:47:49Z"
    finalizers:
    - service.eks.amazonaws.com/resources
    labels:

# Check load balancer status
% kubectl -n istio-system describe svc -l app=istio-gateway

# Get load balancer hostname
GATEWAY_LB=$(kubectl -n istio-system get svc -l app=istio-gateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'); echo $GATEWAY_LB"
k8s-istiosys-gitopsde-959a5c9a6f-263f69aaf3630f18.elb.us-east-1.amazonaws.com
```

### Phase 4: Certificate and DNS Validation

#### 4.1 Verify ACM Certificate

```bash
# Check ACM certificate status FIXME
% aws acm describe-certificate \
  --certificate-arn $(terraform output -raw acm_certificate_arn) \
  --query 'Certificate.[Status,DomainName,SubjectAlternativeNames]' \
  --output table

Status: ISSUED
DomainName: my.domain.tld

# Verify certificate is issued
aws acm list-certificates \
  --query 'CertificateSummaryList[?DomainName==`stage.ptest.us`]' \
  --output table
```

#### 4.2 Verify DNS Configuration

```bash
# Check Route53 record exists FIXME
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terraform output -raw route53_zone_id) \
  --query 'ResourceRecordSets[?Name==`stage.ptest.us.`]' \
  --output table

# Test DNS resolution
% dig stage.ptest.us CNAME +short
k8s-istiosys-gitopsde-959a5c9a6f-263f69aaf3630f18.elb.us-east-1.amazonaws.com.
% nslookup stage.ptest.us
Server:		209.18.47.62
Address:	209.18.47.62#53

Non-authoritative answer:
stage.ptest.us	canonical name = k8s-istiosys-gitopsde-xxx.elb.us-east-1.amazonaws.com.
Name:	k8s-istiosys-gitopsde-xxx.elb.us-east-1.amazonaws.com
Address: 52.54.121.46


# Verify DNS propagation
% nslookup stage.ptest.us
Server:		209.18.47.62
Address:	209.18.47.62#53

Non-authoritative answer:
stage.ptest.us	canonical name = k8s-istiosys-gitopsde-959a5c9a6f-263f69aaf3630f18.elb.us-east-1.amazonaws.com.
Name:	k8s-istiosys-gitopsde-959a5c9a6f-263f69aaf3630f18.elb.us-east-1.amazonaws.com
Address: 52.54.121.46
```

### Phase 5: End-to-End Traffic Validation

#### 5.1 Test Load Balancer Connectivity

```bash
# Test HTTP connectivity (should redirect to HTTPS)
% curl -v -H "Host: stage.ptest.us" http://$GATEWAY_LB/
* Host k8s-istiosys-gitopsde-xxx.elb.us-east-1.amazonaws.com:80 was resolved.
...
* Request completely sent off
< HTTP/1.1 301 Moved Permanently <- the redirect
< location: https://stage.ptest.us/


# Test HTTPS connectivity
% curl -v -H "Host: stage.ptest.us" https://$GATEWAY_LB/
# HTTPS should work
< HTTP/1.1 404 Not Found  (expected - no backend configured)
< server: istio-envoy

# Test health endpoint
% curl -v -H "Host: stage.ptest.us" https://$GATEWAY_LB/healthz
# Health check should work
< HTTP/1.1 200 OK
```

**Expected Output:**

#### 5.2 Test DNS-Based Access

```shell
# Test HTTPS redirect
% curl -I http://stage.ptest.us/
HTTP/1.1 301 Moved Permanently (for HTTP redirect)

# Test with domain name
% curl -I https://stage.ptest.us/
HTTP/1.1 404 Not Found
server: istio-envoy
date: Sat, 28 Jun 2025 01:48:53 GMT

# Test health endpoint via DNS
% curl -I https://stage.ptest.us/healthz
HTTP/1.1 200 OK (for /healthz)
```

## Common Issues and Solutions

### Issue 1: Gateway Not Programmed

**Symptoms:**

```shell
% kubectl -n istio-system get gateway
NAME                        CLASS                 ADDRESS                                                 PROGRAMMED   AGE
gitops-demo-stage-gateway   istio-gateway-class   k8s-istiosys-gitopsde-xxx.elb.us-east-1.amazonaws.com   True         4h31m
```

**Diagnosis:**

```shell
# Check Gateway status
% kubectl -n istio-system describe gateway my-gateway

# Look for error messages
% kubectl -n istio-system  get gateway my-gateway -o yaml | grep -A 10 conditions
```

**Common Causes & Solutions:**

1. **Resource name too long (>63 characters)**

   ```bash
   # Check for name length errors in istiod logs
   % kubectl -n istio-system logs deployment/istiod | grep "must be no more than 63 characters"
   
   # Solution: Shorten GatewayClass name
   metadata:
     name: "istio"  # Instead of long names
   ```

2. **Missing GatewayClass**

This already terraformed; provided as reference:

   ```bash
   # Verify GatewayClass exists
   % kubectl get gatewayclass
   
   # Solution: Create GatewayClass
   kubectl apply -f - <<EOF
   apiVersion: gateway.networking.k8s.io/v1
   kind: GatewayClass
   metadata:
     name: istio
   spec:
     controllerName: istio.io/gateway-controller
   EOF
   ```

1. **Istio controller not ready**

   ```bash
   # Check istiod status
   % kubectl -n istio-system get pods -l app=istiod
   
   # Solution: Wait for istiod or restart
   % kubectl rollout restart deployment/istiod -n istio-system
   ```

### Issue 2: Load Balancer Not Created

**Symptoms:**

```bash
% kubectl -n istio-system get svc -l app=istio-gateway
# No services found
```

**Diagnosis:**

```bash
# Check if Gateway is programmed
% kubectl describe gateway -n istio-system

# Check istiod logs for service creation
% kubectl -n istio-system logs deployment/istiod | grep -i service
```

**Solutions:**

1. **Wait for eventual consistency**

   ```bash
   # Gateway API is eventually consistent
   # Wait 2-5 minutes then check again
   % kubectl -n istio-system get svc -l app=istio-gateway
   ```

2. **Check Gateway annotations**

   ```bash
   # Verify load balancer annotations are correct
   % kubectl -n istio-system get gateway -o yaml | grep -A 10 annotations
   ```

### Issue 3: Certificate/TLS Issues

**Symptoms:**

```bash
% curl: (60) SSL certificate problem: certificate verify failed
```

**Diagnosis:**

```bash
# Check certificate in ACM
% aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`stage.ptest.us`]'

# Verify certificate is attached to load balancer
% aws elbv2 describe-listeners --load-balancer-arn $(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(DNSName, `k8s-istiosys`)].LoadBalancerArn' --output text)
```

**Solutions:**

1. **Certificate not issued**

   ```bash
   # Check validation records in Route53
   % aws route53 list-resource-record-sets --hosted-zone-id ZXXXXX | grep -A 5 "_acme-challenge"
   
   # Wait for validation or recreate validation records
   ```

2. **Certificate not attached to load balancer**

   ```bash
   # Verify Gateway annotations
   % kubectl -n istio-system get gateway -o yaml | grep ssl-cert
   
   # Should show: service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:...
   ```

### Issue 4: DNS Resolution Problems

**Symptoms:**

```bash
% curl: (6) Could not resolve host: stage.ptest.us
```

**Diagnosis:**

```bash
# Check if CNAME record exists
% dig stage.ptest.us CNAME

# Verify Route53 hosted zone
% aws route53 list-hosted-zones --query 'HostedZones[?Name==`ptest.us.`]'
```

**Solutions:**

1. **Missing CNAME record**

   ```bash
   # Create CNAME record pointing to load balancer
   GATEWAY_LB=$(kubectl -n istio-system get svc -l app=istio-gateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
   
   # Add to Route53 via Terraform or aws CLI
   % aws route53 change-resource-record-sets --hosted-zone-id ZXXXXX --change-batch '{
     "Changes": [{
       "Action": "CREATE",
       "ResourceRecordSet": {
         "Name": "stage.ptest.us",
         "Type": "CNAME",
         "TTL": 300,
         "ResourceRecords": [{"Value": "'$GATEWAY_LB'"}]
       }
     }]
   }'
   ```

2. **DNS propagation delay**

   ```bash
   # Use direct DNS query to test
   dig @8.8.8.8 stage.ptest.us CNAME
   
   # Test with host header while DNS propagates
   curl -H "Host: stage.ptest.us" https://$GATEWAY_LB/
   ```

### Issue 5: Application Traffic Not Routing

**Symptoms:**

```bash
curl https://stage.ptest.us/api
HTTP/1.1 404 Not Found
```

**Diagnosis:**

```bash
# Check HTTPRoute configuration
% kubectl get httproute -A

# Verify route attachment
% kubectl describe httproute my-app-route

# Check backend service exists
% kubectl get svc my-backend-service
```

**Solutions:**

1. **Missing HTTPRoute**

This already terraformed; provided as reference:

   ```bash
   # Create HTTPRoute for your application
   % kubectl apply -f - <<EOF
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: my-app-route
   spec:
     parentRefs:
     - name: gitops-demo-stage-gateway
       namespace: istio-system
     hostnames:
     - stage.ptest.us
     rules:
     - matches:
       - path:
           type: PathPrefix
           value: /api
       backendRefs:
       - name: api-service
         port: 80
   EOF
   ```

2. **Backend service not ready**

   ```bash
   # Check backend service and endpoints
   % kubectl get svc api-service
   % kubectl get endpoints api-service
   
   # Verify pods are running
   % kubectl get pods -l app=api
   ```

## Complete End-to-End Testing Workflow

### Initial Gateway Validation (Steps 1-4)

This is the complete validation workflow we used to verify the Gateway setup:

```bash
#!/bin/bash
# Complete Gateway Validation Script

echo "=== Phase 1: Infrastructure Validation ==="

# 1.1 Check EKS cluster
% kubectl cluster-info
% kubectl get nodes

# 1.2 Check Istio control plane
% kubectl -n istio-system get pods -l app=istiod
% kubectl -n istio-system logs deployment/istiod --tail=10

# 1.3 Check Gateway API resources
% kubectl get gatewayclass
% kubectl get crd | grep gateway

echo "=== Phase 2: Gateway Resource Validation ==="

# 2.1 Check Gateway configuration
% kubectl -n istio-system get gateway
% kubectl -n istio-system describe gateway

# 2.2 Check HTTPRoute configuration
% kubectl -n istio-system get httproute
% kubectl -n istio-system describe httproute

echo "=== Phase 3: Auto-Created Infrastructure ==="

# 3.1 Check Gateway deployment
% kubectl -n istio-system get deployment -l app=istio-gateway
% kubectl -n istio-system get pods -l app=istio-gateway

# 3.2 Check Gateway service and load balancer
% kubectl -n istio-system get svc -l app=istio-gateway
GATEWAY_LB=$(kubectl -n istio-system get svc -l app=istio-gateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
echo "Gateway Load Balancer: $GATEWAY_LB"

echo "=== Phase 4: Certificate and DNS Validation ==="

# 4.1 Check ACM certificate
% aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`stage.ptest.us`]'

# 4.2 Check DNS configuration
dig stage.ptest.us CNAME +short
nslookup stage.ptest.us

echo "=== Phase 5: End-to-End Traffic Testing ==="

# 5.1 Test load balancer connectivity
echo "Testing HTTPS:"
curl -I -H "Host: stage.ptest.us" https://$GATEWAY_LB/

echo "Testing health endpoint:"
curl -I -H "Host: stage.ptest.us" https://$GATEWAY_LB/healthz

# 5.2 Test DNS-based access
echo "Testing with actual domain:"
curl -I https://stage.ptest.us/
curl -I https://stage.ptest.us/healthz

echo "Testing HTTP redirect:"
curl -I http://stage.ptest.us/

echo "=== Validation Complete ==="
echo "✅ Gateway is working if you see:"
echo "  - HTTP 301 redirects for HTTP requests"
echo "  - HTTP 404 for HTTPS / requests (expected - no backend)"
echo "  - HTTP 200 for /healthz requests"
echo "  - server: istio-envoy in response headers"
```

### Advanced Debugging Commands

#### Gateway Status Deep Dive

```bash
# Get comprehensive Gateway status
% kubectl -n istio-system get gateway -o yaml

# Check Gateway controller logs
% kubectl -n istio-system logs deployment/istiod | grep gateway

# Verify Gateway controller is watching
% kubectl -n istio-system get lease | grep gateway

# Check Gateway mutating webhook
% kubectl get mutatingwebhookconfiguration | grep istio
```

#### Service Mesh Status

```bash
# Check Istio proxy configuration
% kubectl -n istio-system exec deployment/gitops-demo-stage-gateway-istio -c istio-proxy -- pilot-agent request GET config_dump

# Verify proxy status
% istioctl proxy-status

# Check proxy configuration
% istioctl proxy-config cluster gateway-pod-name.istio-system
% istioctl proxy-config listener gateway-pod-name.istio-system
% istioctl proxy-config route gateway-pod-name.istio-system
```

#### Traffic Analysis

```bash
# Monitor access logs
% kubectl -n istio-system logs -l app=istio-gateway -c istio-proxy -f

# Check Envoy admin interface
% kubectl -n istio-system port-forward deployment/gitops-demo-stage-gateway-istio 15000:15000
# Then visit: http://localhost:15000

# Monitor metrics
% kubectl -n istio-system port-forward deployment/gitops-demo-stage-gateway-istio 15020:15020
curl http://localhost:15020/stats/prometheus | grep istio
```

## Performance and Load Testing

### Basic Load Testing

```bash
# Install hey (HTTP load testing tool)
go install github.com/rakyll/hey@latest

# Test basic load
% hey -n 1000 -c 10 https://stage.ptest.us/healthz

# Test with custom headers
% hey -n 500 -c 5 -H "User-Agent: LoadTest" https://stage.ptest.us/

# Monitor during load test
% kubectl -n istio-system top pods -l app=istio-gateway
% kubectl -n istio-system get hpa
```

### Stress Testing

```bash
# High concurrency test
hey -n 10000 -c 100 -t 30 https://stage.ptest.us/healthz

# Long duration test
hey -z 5m -c 20 https://stage.ptest.us/healthz

# Monitor cluster auto-scaling
% kubectl get nodes -w
% kubectl -n istio-system get pods -l app=istio-gateway -w
```

## Monitoring and Alerting Setup

### Prometheus Metrics

```yaml
# ServiceMonitor for Gateway metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-gateway
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-gateway
  endpoints:
  - port: http-monitoring
    path: /stats/prometheus
    interval: 30s
```

### Key Metrics to Monitor

```bash
# Gateway availability
istio_request_total{source_app="istio-gateway"}

# Response time percentiles
histogram_quantile(0.95, istio_request_duration_milliseconds_bucket{source_app="istio-gateway"})

# Error rate
rate(istio_request_total{source_app="istio-gateway",response_code!~"2.."}[5m])

# Certificate expiry
ssl_certificate_expiry_seconds
```

### Health Check Endpoints

```bash
# Istio Gateway health
curl https://stage.ptest.us/healthz/ready

# Detailed proxy health
% kubectl -n istio-system exec deployment/gitops-demo-stage-gateway-istio -c istio-proxy -- curl localhost:15021/healthz/ready

# Control plane health
% kubectl -n istio-system exec deployment/istiod -- curl localhost:15014/ready
```

## Emergency Procedures

### Rollback Gateway Changes

```bash
# Rollback Gateway configuration
% kubectl -n istio-system rollout undo deployment/gitops-demo-stage-gateway-istio

# Restore previous HTTPRoute
% kubectl apply -f previous-httproute-backup.yaml

# Emergency: Direct traffic bypass
% kubectl -n istio-system patch svc gitops-demo-stage-gateway-istio -p '{"spec":{"selector":{"app":"emergency-backend"}}}'
```

### Certificate Issues

```bash
# Emergency: Disable HTTPS temporarily
% kubectl -n istio-system patch gateway gitops-demo-stage-gateway --type='json' -p='[{"op": "remove", "path": "/spec/listeners/1"}]'

# Force certificate renewal
% aws acm resend-validation-email --certificate-arn arn:aws:acm:...

# Update certificate ARN
% kubectl -n istio-system annotate svc gitops-demo-stage-gateway-istio service.beta.kubernetes.io/aws-load-balancer-ssl-cert=arn:% aws:acm:NEW_CERT_ARN
```

### Traffic Debugging

```bash
# Enable debug logging
% kubectl -n istio-system patch deployment gitops-demo-stage-gateway-istio -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/logLevel":"debug"}}}}}'

# Capture traffic with tcpdump
% kubectl -n istio-system exec deployment/gitops-demo-stage-gateway-istio -c istio-proxy -- tcpdump -i eth0 -w /tmp/traffic.pcap

# Analyze with istioctl
% istioctl analyze --all-namespaces
```

## Best Practices Summary

### Deployment Best Practices

1. **Always validate certificates before deployment**
2. **Test in staging environment first**
3. **Use Infrastructure as Code (Terraform)**
4. **Monitor gateway metrics continuously**
5. **Implement proper backup procedures**
6. **Document all configuration changes**

### Security Best Practices

1. **Use ACM for certificate management**
2. **Enable HTTPS redirect**
3. **Implement proper RBAC**
4. **Monitor for certificate expiry**
5. **Use Network Load Balancers for performance**
6. **Implement proper logging and monitoring**

### Operational Best Practices

1. **Automate health checks**
2. **Set up proper alerting**
3. **Document troubleshooting procedures**
4. **Regularly test disaster recovery**
5. **Keep Istio updated**
6. **Monitor resource usage**

This comprehensive testing and troubleshooting guide provides the complete workflow for validating and maintaining your modern Istio Gateway implementation on EKS Auto Mode, ensuring reliable and secure traffic ingress for your applications. HTTP (should redirect):"
curl -I -H "Host: stage.ptest.us" http://$GATEWAY_LB/

echo "Testing