# Installing an AWS EKS cluster and an autoscaling Node group


- EKS Cluster: AWS managed Kubernetes cluster of master servers
- EKS Node Group and optionally update an Auto Scaling Group of Kubernetes worker nodes compatible with EKS.
- Associated VPC, Internet Gateway, Security Groups, and Subnets: Operator managed networking resources for the EKS Cluster and worker node instances
- Associated IAM Roles and Policies: Operator managed access resources for EKS and worker node instances


```
terraform init
terraform get
terraform apply
```


Run the following command to retrieve the access credentials for your cluster and configure kubectl.

``` 
aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)
```

Create an OIDC provider and associate it with for your EKS cluster with the following command:
```
eksctl utils associate-iam-oidc-provider --cluster $(terraform output -raw cluster_name) \
--region $(terraform output -raw region) --approve
```

First, get information about the cluster.
```
kubectl cluster-info
```

Now verify that all three worker nodes are part of the cluster.
```
kubectl get nodes
```

# IAM role for service account with OIDC
IAM roles for service accounts provide the ability to manage credentials for your applications, similar to the way that Amazon EC2 instance profiles provide credentials to Amazon EC2 instances. Instead of creating and distributing your AWS credentials to the containers or using the Amazon EC2 instance’s role, you associate an IAM role with a Kubernetes service account and configure your pods to use the service account.

With IAM roles for service accounts on Amazon EKS clusters, you can associate an IAM role with a Kubernetes service account. This module creates a single IAM role which can be assumed by trusted resources using OpenID Connect federated users. 

Ensure the iam-test is created and eks-iam-test pod is running:
```
kubectl apply -f service-account.yaml
```

Successfully created service account, you can deploy test application. This will run a pod to try to describe s3 buckets on your AWS account using aws-cli.

```
kubectl apply -f list-s3.yaml
```

Looking at the logs for the pod:
```
kubectl logs aws-cli-mp5kx
2022-08-28 00:16:21 churn-dataset
2022-08-24 16:11:05 elasticbeanstalk-eu-west-2-880572800141
2022-08-24 16:12:15 elasticbeanstalk-us-east-2-880572800141
2022-08-26 01:01:03 mlflow-artifacts-30cccc8
2022-09-17 22:46:49 my-test-k8s-bucket
```

Success! 

View the ARN of the IAM role that the pod is using
```
kubectl describe pod aws-cli-mp5kx | grep AWS_ROLE_ARN:
```
# Associating the service-account with the depolyment
```
cat >my-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      serviceAccountName: my-service-account
      containers:
      - name: my-app
        image: public.ecr.aws/nginx/nginx:1.21
EOF
```

Deploy the manifest to the cluster
```
kubectl apply -f my-deployment.yaml
```

Check the pods were deployed 
```
kubectl get pods | grep my-app
```

View the ARN of the IAM role that the pod is using
```
kubectl describe pod my-app-6f4dfff6cb-76cv9 | grep AWS_ROLE_ARN:
```

Confirm the deployment is using the service-account
```
kubectl describe deployment my-app | grep "Service Account"
```

# Install Airflow chart using Helm
First test using minikube local k8s cluster


# Clean up your workspace

You have now provisioned an EKS cluster, configured kubectl, and verified that your cluster is ready to use.

```
terraform destroy
```



https://learn.hashicorp.com/tutorials/terraform/eks


kubectl apply -f pods/commands.yaml
kubectl get pods
kubectl logs command-demo
