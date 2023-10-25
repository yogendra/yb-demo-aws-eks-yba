# YugabyteDB Anywhere on EKS

This is a demo project to get YBA running on an eks cluster.

## Pre-requisite

1. AWS Route53 Hosted Zone
2. Existing VPC with 3 AZ and  private subnets
3. Private subnets are tagged for ELB ([read here](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html))
4. Internet access

### Tools
1. bash
2. direnv
3. k9s
4. kubectl
5. jq
6. envsubst
7. helm
8. aws cli

## Quick start

1. Git clone this project

    ```bash
    git clone <repo> yb-eks-demo
    cd yb-eks-demo
    direnv allow
    ```
2. Create `config/demo.env` file from `config/demo.template.env` file

    ```bash
    cp config/demo.template.env config/demo.env
    ```

3. Edit file and set the `PROJECT_DOMAIN` and `AWS_HOSTEDZONE_ID`

    ```bash
    export AWS_HOSTEDZONE_ID=Z04311021JK3VSZKS3Q9R
    export PROJECT_NAME=shr-eks-sg
    ```

4. Put YugabyteDB Anywhere license file (Image Pull Secret) in the `config/` directory. Name is like `yugabyte-pull-secret.yaml`

5. Update `config/eks.yaml`. Change
   1. `metadata.tags`: put correct tags for you environment
   2. `metadata.region`: AWS Region to deploy the cluster in
   3. `vpc.id`: VPC id to deploy the cluster to
   4. `vpc.subnets.private.*`: AZ names to deploy cluster on
   5. `vpc.subnets.private.*.id`: Subnets on which nodes will be placed
   6. `managedNodeGroups[0].securityGroups.attachIDs[*]`: Put correct security group id (as array)
   7. `managedNodeGroups[0].availabilityZones[*]`: Put correct AZ (a)
   8. `managedNodeGroups[0].tags`: Put correct tags
   9. `managedNodeGroups[1].securityGroups.attachIDs[*]`: Put correct security group id (as array)
   10. `managedNodeGroups[1].availabilityZones[*]`: Put correct AZ (b)
   11. `managedNodeGroups[1].tags`: Put correct tags
   12. `managedNodeGroups[2].securityGroups.attachIDs[*]`: Put correct security group id (as array)
   13. `managedNodeGroups[2].availabilityZones[*]`: Put correct AZ (c)
   14. `managedNodeGroups[2].tags`: Put correct tags

6. Start cluster

    ```bash
    bin/demo start
    ```

    This command will:

    1. Create IAM Policy
    2. Creates IAM User
    3. Attach IAM Policy to User
    4. Create Access Key
    5. Creates an eks cluster with VPC CNI, CoreDNS, Kube Proxy , AWS ELB Controller, and EBS CSI.
    6. Create three (3) EKS Node Group with 16 vCPU spot instances
    7. Configures Cert Manager
    8. Configures Root CA
    9. Configures Ingress Controller
    10. Configures Route53 to point to the Ingress Controller LB
    11. Install YBA
    12. Configures YBA Cloud Provider
    13. Configures YBA Backup to S3
    14. Configures YBA KMS to AWS KMS
    15. Create xsmall universe (db1) and deploy workload simulator app.

7. Destroy / Cleanup

    ```bash
    bin/demo stop
    ```
8. Pause environment (downsize eks cluster)

    ```bash
    bin/demo pause
    ```

9. Resume environment (upsize eks cluster)

    ```bash
    bin/demo pause
    ```

## Configuration Parameters
Following configuration parameters can be put in the `config/demo.env` file, next to this `README.md`. Refer to [config/demo.template.env](config/demo.template.env) file

* PROJECT_DIR: Directory containing this file
* PROJECT_CONFIG_DIR: `$PROJECT_DIR/config/`

| Variable          | Description                    |
| ----------------- | ------------------------------ |
| PROJECT_NAME      | **(Required)** Project Name    |
| AWS_HOSTEDZONE_ID | **(Required)** Hosted AWS Zone |

Optional Config variables

| Variable                   | Description                                     | Default                                       |
| -------------------------- | ----------------------------------------------- | --------------------------------------------- |
| AWS_HOSTEDZONE_ROOT_DOMAIN | Root domain under which sub-domain is created   | *Automatically found from the hosted zone*    |
| AWS_REGION                 | AWS Region to deploy cluster                    | Based on profile                              |
| AWS_VPC_ID                 | VPC ID                                          | Default VPC in Region                         |
| AWS_AZ1                    | AWS Availability Zone 1                         | First AZ in the given VPC                     |
| AWS_AZ1_SUBNET             | AWS Availability Zone 1 Subnet                  | First Private in First AZ in the given VPC    |
| AWS_AZ2                    | AWS Availability Zone 2                         | Second AZ in the given VPC                    |
| AWS_AZ2_SUBNET             | AWS Availability Zone 2 Subnet                  | First Private in Second AZ in the given VPC   |
| AWS_AZ3                    | AWS Availability Zone 3                         | Third AZ in the given VPC                     |
| AWS_AZ3_SUBNET             | AWS Availability Zone 3 Subnet                  | First Private in Third AZ in the given VPC    |
| AWS_SECURITY_GROUP         | AWS Security Group                              | Default Security Group in the VPC             |
| AWS_WORKER_TYPE            | Worker Type                                     | m6a.4xlarge                                   |
| AWS_KEYPAIR_NAME           |
| INGRESS_NGINX_HELM_VALUES  | NGINX Ingress Helm Values file                  | $PROJECT_CONFIG_DIR/ingress-nginx-values.yaml |
| CERT_MANAGER_CONFIG        | Config file for cert-manager based certificates | $PROJECT_CONFIG_DIR/certs.yaml                |
| K8S_CLUSTER_CONFIG         | EKS Cluster config                              | $PROJECT_CONFIG_DIR/shr-eks-sg.yaml           |
| PROJECT_USER               | User / Owner of this environment                | $USER                                         |
| PROJECT_ENV_FILE           | Project environment file                        | $PROJECT_DIR/demo.env                         |
| PROJECT_DOMAIN             | Project domain                                  | $PROJECT_NAME.$AWS_HOSTEDZONE_ROOT_DOMAIN     |
| PROJECT_DIR                | Project Directory                               | *Directory containing this file*              |
| PROJECT_CONFIG_DIR         | Project Config Directory                        | $PROJECT_DIR/config                           |
| YBA_BACKUP_BUCKET          | YugabyteDB Anywhere S3 Backup Bucket Name       | yugabyte-apj-demo-backup                      |
| YBA_HELM_RELEASE           | YugabyteDB Anywhere Helm Release Name           | yba                                           |
| YBA_HELM_VALUES            | YugabyteDB Anywhere  Helm values                | $PROJECT_CONFIG_DIR/yugaware-values.yaml      |
| YBA_HELM_VERSION           | YugabyteDB Anywhere Helm Version                | 2.18.2+1                                      |
| YBA_HOSTNAME               | YugabyteDB Anywhere DNS Name                    | yba.$PROJECT_DOMAIN                           |
| YBA_PROM_HOSTNAME          | YugabyteDB Anywhere Prometheus DNS Name         | yba-prom.$PROJECT_DOMAIN                      |
| YBA_K8S_PROVIDER_NAME      | YugabyteDB Anywhere K8s Cloud Provider Name     | $PROJECT_NAME                                 |
| YBA_K8S_STORAGECLASS       | YugabyteDB Anywhere K8s Cloud Provider Storage  | gp3                                           |
| YBA_LICENSE                | YugabyteDB Anywhere License file.               | $PROJECT_CONFIG_DIR/yugabyte-*-secret.yml     |
| YBA_NS                     | YugabyteDB Anywhere Namespace                   | yb-platform                                   |
| YBA_PASSWORD               | YugabyteDB Anywhere Admin User Password         | Password#123                                  |
| YBA_USERNAME               | YugabyteDB Anywhere Admin Username              | superadmin@yugabyte.com                       |
| YBA_VERSION                | YugabyteDB Anywhere Version to install          | 2.18.2.1-b1                                   |
