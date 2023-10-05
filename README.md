# YugabyteDB Anywhere on EKS

This is a demo project to get YBA running on an eks cluster.

## Pre-requisite

1. AWS Route53 Hosted Zone
2. Existing VPC with 3 AZ (with private subnet)
3. Private subnets are tagged for ELB
4. Internet access
5. kubectl
6. jq
7. envsubst
8. helm
9. aws cli


## Quick start


```bash
bin/demo start
```

This command will:

1. Creates an eks cluster with VPC CNI, CoreDNS, Kube Proxy and EBS CSI.
2. Create a EKS Node Group with 16 vCPU spot instances
3. Configures Cert Manager
4. Configures Root CA
5. Configures Ingress Controller
6. Install YBA
7. Configures YBA Cloud Provider
8. Configures YBA Backup to S3
9. Configures YBA KMS to AWS KMS
10. Create 3 xsmall DBs (db1, db2 and db3)

Cleanup

```bash
bin/demo stop
```


