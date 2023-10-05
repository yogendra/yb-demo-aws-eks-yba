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
2. Create `demo.env` file from `demo.template.env` file

    ```bash
    cp demo.template.env demo.env
    ```
3. Update `config/shr-eks-sg.yaml`. Change
   1. `metadata.tags`: put correct tags for you environment
   2. `metadata.region`: AWS Region to deploy the cluster in
   3. `vpc.id`: VPC id to deploy the cluster to
   4. `vpc.subnets.private.*`: AZ names to deploy cluster on
   5. `vpc.subnets.private.*.id`: Subnets on which nodes will be placed
   6. `managedNodeGroups[0].securityGroups.attachIDs[*]`: Put correct security group id (as array)
   7. `managedNodeGroups[0].tags`: Put correct tags

4. Put YugabyteDB Anywhere license file (Image Pull Secret) in the `config/` directory. Name is like `yugabyte-pull-secret.yaml`

5. Edit file and set the `PROJECT_DOMAIN` and `AWS_HOSTEDZONE_ID`

    ```bash
    export AWS_HOSTEDZONE_ID=Z04311021JK3VSZKS3Q9R
    export PROJECT_DOMAIN=shr-eks-sg.apj.yugabyte.com
    export YBA_AWS_ACCESS_KEY_ID=A******************6
    export YBA_AWS_SECRET_ACCESS_KEY="4**************************************t"
    ```

6. Start cluster

    ```bash
    bin/demo start
    ```

    This command will:

    1. Creates an eks cluster with VPC CNI, CoreDNS, Kube Proxy , AWS ELB Controller, and EBS CSI.
    2. Create a EKS Node Group with 16 vCPU spot instances
    3. Configures Cert Manager
    4. Configures Root CA
    5. Configures Ingress Controller
    6. Configures Route53 to point to the Ingress Controller LB
    7. Install YBA
    8. Configures YBA Cloud Provider
    9. Configures YBA Backup to S3
    10. Configures YBA KMS to AWS KMS
    11. Create 3 xsmall DBs (db1, db2 and db3)

7. Destroy / Cleanup

    ```bash
    bin/demo stop
    ```


## Configuration Parameters
Following configuration parameters can be put in the `demo.env` file, next to this `README.md`. Refer to [demo.template.env](demo.template.env) file

* PROJECT_DIR: Directory containing this file
* PROJECT_CONFIG_DIR: `$PROJECT_DIR/config/`

| Variable                  | Description                                     | Default                                       |
| ------------------------- | ----------------------------------------------- | --------------------------------------------- |
| PROJECT_DOMAIN            | **(Required)** Domain for the project.          |                                               |
| AWS_HOSTEDZONE_ID         | **(Required)** Hosted AWS Zone                  |                                               |
| YBA_AWS_ACCESS_KEY_ID     | **(Required)** YBA AWS Access Key ID            |                                               |
| YBA_AWS_SECRET_ACCESS_KEY | **(Required)** YBA AWS Secret Access Key        |                                               |
| CERT_MANAGER_CONFIG       | Config file for cert-manager based certificates | $PROJECT_CONFIG_DIR/certs.yaml                |
| INGRESS_NGINX_HELM_VALUES | NGINX Ingress Helm Values file                  | $PROJECT_CONFIG_DIR/ingress-nginx-values.yaml |
| K8S_CLUSTER_CONFIG        | EKS Cluster config                              | $PROJECT_CONFIG_DIR/shr-eks-sg.yaml           |
| YBA_BACKUP_BUCKET         | YugabyteDB Anywhere S3 Backup Bucket Name       | yugabyte-apj-demo-backup                      |
| YBA_HELM_RELEASE          | YugabyteDB Anywhere Helm Release Name           | yba                                           |
| YBA_HELM_VALUES           | YugabyteDB Anywhere  Helm values                | $PROJECT_CONFIG_DIR/yugaware-values.yaml      |
| YBA_HELM_VERSION          | YugabyteDB Anywhere Helm Version                | 2.18.2+1                                      |
| YBA_HOSTNAME              | YugabyteDB Anywhere DNS Name                    | yba.$PROJECT_DOMAIN                           |
| YBA_PROM_HOSTNAME         | YugabyteDB Anywhere Prometheus DNS Name         | yba-prom.$PROJECT_DOMAIN                      |
| YBA_K8S_PROVIDER_NAME     | YugabyteDB Anywhere K8s Cloud Provider Name     | shr-eks-sg                                    |
| YBA_K8S_STORAGECLASS      | YugabyteDB Anywhere K8s Cloud Provider Storage  | gp3                                           |
| YBA_LICENSE               | YugabyteDB Anywhere License file.               | $PROJECT_CONFIG_DIR/yugabyte-*-secret.yml     |
| YBA_NS                    | YugabyteDB Anywhere Namespace                   | yb-platform                                   |
| YBA_PASSWORD              | YugabyteDB Anywhere Admin User Password         | Password#123                                  |
| YBA_USERNAME              | YugabyteDB Anywhere Admin Username              | superadmin@yugabyte.com                       |
| YBA_VERSION               | YugabyteDB Anywhere Version to install          | 2.18.2.1-b1                                   |
