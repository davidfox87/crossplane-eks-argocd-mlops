# Local deployment of ArgoCD and Argo workflows on a local minikube K8s cluster

# Deploy to the AWS EKS using Terraform! 


- EKS Cluster: AWS managed Kubernetes cluster of master servers
- EKS Node Group
- Associated VPC, Internet Gateway, Security Groups, and Subnets: Operator managed networking resources for the EKS Cluster and worker node instances
- Associated IAM Roles and Policies: Operator managed access resources for EKS and worker node instances


```
terraform init
terraform get
terraform apply
```


Verify the aws-load-balancer-controller is installed
```
kubectl get deployment -n kube-system aws-load-balancer-controller
```
Our infrastructure in aws will look like this:
![AWS infra](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/images/pattern-img/abf727c1-ff8b-43a7-923f-bce825d1b459/images/281936fa-bc43-4b4e-a343-ba1eab97df38.png)



# Installing Argo-cd 

[Getting started with ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.12/manifests/install.yaml

kubectl patch svc argo-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl port-forward svc/argocd-server -n argocd 31719:443
```

The API server can then be accessed using https://localhost:31719

```
kubectl get secret argocd-initial-admin-secret -n argocd
echo UjlTQlRJbHZvbDFBdzRueg== | base64 --decode
```
Take the decoded password and login to the ui

# Install the Argo CD CLI
sudo curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64

sudo chmod +x /usr/local/bin/argocd

# Our true GitOps CI/CD platform


Try this markdown:

![GitOps ArgoCD](https://www.eksworkshop.com/images/argocd/argocd_architecture.png)

## installing argocd, argo workflow, argo events

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


kubectl get secret argocd-initial-admin-secret -n argocd
echo anFJcTNnY3pmeVZPTWN5LQ== | base64 --decode

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo



# Clean up your workspace

Delete the application in argo-cd

Then destroy all infrastructure in AWS using
```
terraform destroy
```

