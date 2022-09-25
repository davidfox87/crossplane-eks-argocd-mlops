# Local deployment of ArgoCD and Argo workflows on a local minikube K8s cluster

This is a demonstration of a GitOps CI/CD pipeline using Argo workflows (clone, build and push docker image, and update helm chart repo)
and ArgoCD to update cluster configuration from the helm chart repository. Both Argo workflows and ArgoCD are deployed in the same Kubernetes cluster.


# installing argocd 
reference
https://argo-cd.readthedocs.io/en/stable/getting_started/

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl port-forward svc/argocd-server -n argocd 31719:443

The API server can then be accessed using https://localhost:31719


kubectl get secret argocd-initial-admin-secret -n argocd
echo aGdhbGU0ZGhQVVIzMjN1WQ== | base64 --decode

To get the node port
```kubectl get svc -o wide -n myapp```
```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE   SELECTOR
myapp-service   NodePort   10.103.252.29   <none>        8080:31888/TCP   39m   app=myapp
```

Set up the port forward to the service
```kubectl port-forward svc/myapp-service -n myapp 31888:80```



# Installing Argo workflows
As of today, v3.4.9 is the latest release tag in github
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.0/install.yaml


kubectl patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "server",
  "--auth-mode=server"
]}]'

kubectl patch svc argo-server -n argo -p '{"spec": {"type": "NodePort"}}'

Set up the port forward to the service
```kubectl -n argo port-forward deployment/argo-server 2746:2746```
https://localhost:2746

## create a workflow template 
argo template create -n argo local/argo-workflows/workflow1-template.yaml 

## trigger a workflow using that template
argo submit -n argo local/argo-workflows/workflow1.yaml 

## multistep workflow that passes outputs into inputs
To run Argo workflows that use artifacts, you must configure and use an artifact repository. Argo supports any S3 compatible artifact repository such as AWS, GCS and MinIO. 
```
helm repo add minio https://helm.min.io/ # official minio Helm charts
helm repo update
helm install argo-artifacts minio/minio --set service.type=NodePort --set fullnameOverride=argo-artifacts

```
To access Minio from localhost, run the below commands:

  1. ```export POD_NAME=$(kubectl get pods --namespace default -l "release=argo-artifacts" -o jsonpath="{.items[0].metadata.name}")```
  2. ```kubectl port-forward svc/argo-artifacts 9001:9000``` or ```kubectl port-forward po/$POD_NAME 9001:9000```

http://localhost:9001 in the terminal!!!!

ACCESS_KEY=$(kubectl get secret argo-artifacts -o jsonpath="{.data.accesskey}" | base64 --decode)
SECRET_KEY=$(kubectl get secret argo-artifacts -o jsonpath="{.data.secretkey}" | base64 --decode)

Log in to minio and create the "my-bucket" bucket

modify the configmap in the argo namespace, which will reference the artifact repository in the default namespace

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: workflow-controller-configmap
data:
    artifactRepository: |    # However, all nested maps must be strings
      archiveLogs: true
      s3:
        endpoint: argo-artifacts.default:9000
        bucket: my-bucket
        insecure: false
        accessKeySecret:
          name: argo-artfacts
          key: accesskey
        secretKeySecret:
          name: argo-artfacts
          key: secretkey

```

## submit argo artifact-passing workflow to argo namespace
Go over to http://localhost:9001 and check the bucket for the new file
``` argo submit -n argo local/argo-workflows/artifact-passing.yaml --watch```


### Configure the Default Artifact Repository¶

In order for Argo to use your artifact repository, you can configure it as the default repository. Edit the workflow-controller config map with the correct endpoint and access/secret keys for your repository. 

get a shell to running container
```kubectl exec --stdin --tty argo-artifacts-7785b88865-llzh7 -- /bin/bash```

kubectl apply -f local/argo-workflows/default-artifact-repository.yaml -n argo

## how to do git clone of a repo within workflow
in the inputs section do...
```
artifacts:
  - name: git-clone
    path: "/workspace/project"
    git:
      revision: "{{inputs.parameters.BRANCH}}"
      repo: "{{inputs.parameters.git_ssh_url}}"
      singleBranch: false
      sshPrivateKeySecret:
        name: gitlab
        key: id_rsa
      insecureIgnoreHostKey: true
```


## create a secret for docker hub credentials
https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret

To configure that, you:

1. Create a secret or use an existing one. Multiple Pods can reference the same secret.
2. Modify your Pod definition to add a volume under .spec.volumes[]. Name the volume anything, and have a .spec.volumes[].secret.secretName field equal to the name of the Secret object.
3. Add a .spec.containers[].volumeMounts[] to each container that needs the secret. Specify .spec.containers[].volumeMounts[].readOnly = true and .spec.containers[].volumeMounts[].mountPath to an unused directory name where you would like the secrets to appear.
4. Modify your image or command line so that the program looks for files in that directory. Each key in the secret data map becomes the filename under mountPath.

```
kubectl create secret docker-registry dockercred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=foxy7887 \
    --docker-password=xxxxx \
    --docker-email=davidmfox87@gmail.com
```

## argo-events
now have github to send a webhook to our k8s cluster
tell processes in the cluster to trigger some pipelines (argo workflows)


install argo events
https://argoproj.github.io/argo-events/installation/


K8s ingress
https://kubernetes.io/docs/concepts/services-networking/ingress/
An API object that manages external access to the services in a cluster, typically HTTP.

In order for the Ingress resource to work, the cluster must have an ingress controller running.
https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/


```
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install my-release nginx-stable/nginx-ingress
```
or add ingress add-on to minikube
minikube addons enable ingress


kubectl apply -f local/argo-events/event-sources.yaml 







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


First, get information about the cluster.
```
kubectl cluster-info
```

Now verify that all three worker nodes are part of the cluster.
```
kubectl get nodes
```

Verify the aws-load-balancer-controller is installed
```
kubectl get deployment -n kube-system aws-load-balancer-controller
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


## try installing aws-load-balancer-controller manually

kubectl apply -f modules/eks-cluster/load-balancer-controller-service-account.yaml 
kubectl get serviceaccounts -n kube-system

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=load-balancer-controller \
  --set vpcId=vpc-02692294b4491d4f8 \
  --set region=us-west-1 \
  --set image.repository=602401143452.dkr.ecr.us-west-1.amazonaws.com/amazon/aws-load-balancer-controller


kubectl get deployment -n kube-system aws-load-balancer-controller
```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           81s
```

## Exposing the service
```
kubectl -n task-tracker-app patch svc service-task-tracker-app -p '{"spec": {"type": "LoadBalancer"}}'

export loadbalancer=$(kubectl -n task-tracker-app get svc service-task-tracker-app -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')

kubectl -n task-tracker-app describe service service-task-tracker-app | grep Ingress
```

Hypothetically, we should be able to type that address in the browser to view our app

http://a2a82cd1cb3b941d8b0b8aa2210cd4ef-39901005.us-west-1.elb.amazonaws.com/

Please read up on ingress and load-balancer-controller
```https://www.eksworkshop.com/beginner/130_exposing-service/exposing/```
```https://www.eksworkshop.com/beginner/130_exposing-service/ingress/```



## installing argocd, argo workflow, argo events

## create service accounts and assocate them with load-balancer-controller and argo worfklows (for s3 access)







# Clean up your workspace

You have now provisioned an EKS cluster, configured kubectl, and verified that your cluster is ready to use.

```
terraform destroy
```



https://learn.hashicorp.com/tutorials/terraform/eks


kubectl apply -f pods/commands.yaml
kubectl get pods
kubectl logs command-demo
