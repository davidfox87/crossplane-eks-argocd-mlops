# Using ArgoCD to deploy Secure end-to-end traffic on Amazon EKS using TLS certificate in ACM, ALB, and Istio gateway and service mesh.

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
Our infrastructure in aws will look like this (substitute gRPC traffic with HTTPS traffic):
![AWS infra](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/images/pattern-img/abf727c1-ff8b-43a7-923f-bce825d1b459/images/281936fa-bc43-4b4e-a343-ba1eab97df38.png)



# Installing Argo-cd 
[Getting started with ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.12/manifests/install.yaml

kubectl port-forward svc/argocd-server -n argocd 31719:443

xdg-open https://localhost:31719
```

The API server can then be accessed using https://localhost:31719

```
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
echo akRjVGZmNjhxbTdJWHB3OA== | base64 --decode
```
Take the decoded password and login to the ui

# clone the repo which has our ArgoCD manifests for the project and app
```
git clone git@github.com:davidfox87/argocd-production.git
```
Install projects and apps
```
kubectl apply -f projects.yaml
kubectl apply -f apps.yaml

```

## generate tls-secret using sealed secrets
NOTE TLS-SECRET NEEDS TO GO IN ISTIO-SYSTEM NAMESPACE
JUST PUT THE GATEWAY, VIRTUAL-SERVICE AND TLS-SECRET ALL IN THE ISTIO-SYSTEM NAMESPACE AND THEN REFERENCE THE SERVICES USING task-tracker-app-ui.staging.svc.cluster.local
```
kubectl create secret generic tls-secret -n staging \
--from-file=key=certs/key.pem \
--from-file=cert=certs/cert.pem

kubectl get secret tls-secret -n staging -o yaml | kubeseal --controller-namespace kube-system \
                                                 --controller-name sealed-secrets \
                                                 --format yaml tls-secret.yaml \ 
                                                  > base/tls-secret.yaml
kubectl delete secret tls-secret -n staging


kubectl create secret generic tls-secret -n istio-system \
--from-file=key=certs/key.pem \
--from-file=cert=certs/cert.pem
```

## wait for everything to sync and be healthy in the argo-cd UI
woop

## configure healthcheck path for alb
To configure the alb.ingress.kubernetes.io/alb.ingress.kubernetes.io/healthcheck-path get a readinessProbe from the  Deployment, which creates pods with the istio-ingressgateway:
```
kubectl -n istio-system get deploy istio-ingressgateway -o yaml
...
readinessProbe:
failureThreshold: 30
httpGet:
path: /healthz/ready
...
```
kubectl -n istio-system get svc istio-ingressgateway -o yaml

Set annotations for the istio-ingressgateway Service: 
- in the healthchek-port set the nodePort from the status-port 
- in the healthcheck-path – a path from the readinessProbe:

Note that the nodeport for the status-port will change so you will have to edit it after the service has come up

It should look like this 
```
    alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
    alb.ingress.kubernetes.io/healthcheck-port: "30829"
```

## apply ingress object
Ingress object will spawn aws-load-balancer-controler, which has a backend that points to istio-ingressgateway
Important!!! The ingress object has to go into the istio-system namespace.

```
kubectl apply -f istio-gw-ingress/ingress.yaml -n istio-system
```

AWS ALB Ingress Controller will create a TargetGroup to be used with the ALB
The Gateway and VirtualService that will configure Envoy of the Istio Ingress Gateway to route traffic to the Service of the application

# map the domain name that is associated with ACM certificate to the ALB just spawned
![route53](route53.png)

# Our true GitOps CI/CD platform
![GitOps ArgoCD](https://www.eksworkshop.com/images/argocd/argocd_architecture.png)



# Clean up your workspace

Delete the application in argo-cd

Then destroy all infrastructure in AWS using
```
terraform destroy
```






