# Your one-stop shop platform for GitOps CI/CD, Machine learning workflows, service mesh and observability

| application   | View  |
| -----------   | ---   |
| Deploy an EKS cluster using Terraform | [README](terraform/infra/README.md) |
| Istio ingress gateway and secure service mesh |  [README](applications/istio-1-15/README.md) |
| Argo CD | [README](applications/argo-cd/README.md) |
| Argo events | [README](applications/argo-events/README.md) |
| Argo workflows | [README](applications/argo-workflows/README.md) |
| Prometheus and Grafana | Coming soon |
| MLflow | [README](applications/mlflow/README.md) |
| minio artifact storage | [README](applications/minio/README.md) |
| ngrok | [README](applications/ngrok_/README.md) |
| task-tracker app (MERN stack demo) | [README](applications/task-tracker-app/README.md) |
| sealed-secrets | |
| Seldon-core | Coming soon |
## Use argocd to deploy applications to our Kubernetes cluster 
In a different project folder, clone the repo which has our ArgoCD project and application manifests 
```
git clone git@github.com:davidfox87/argocd-production.git
```
Install projects and apps
```
kubectl apply -f projects.yaml
kubectl apply -f apps.yaml
```

## wait for everything to sync and be healthy in the argo-cd UI
The following screenshot shows the applications that argocd has deployed into our EKS cluster either from our own kustomize application manifests or third-party helm charts.
![argocd](argocd.png)


## apply ingress object
The ingress object has a backend that points to istio-ingressgateway. Apply the object to the istio-system namespace:

```
kubectl apply -f istio-1-15/istio-resources/ingress.yaml -n istio-system
```

The AWS ALB Ingress Controller will create a TargetGroup to be used with the ALB
The Gateway and VirtualService that will configure Envoy of the Istio Ingress Gateway to route traffic to the service of the application.

## Map the domain name that is associated with ACM certificate to the ALB just spawned
![route53](route53.png)

## Our true GitOps CI/CD platform
![GitOps ArgoCD](https://www.eksworkshop.com/images/argocd/argocd_architecture.png)







