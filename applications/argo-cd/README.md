# Installing Argo-cd 
[Getting started with ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
From the applications/argocd folder:
```
kustomize build | kubectl apply -f -

kubectl port-forward svc/argocd-server -n argocd 9443:443

xdg-open https://localhost:9443
```

The API server can then be accessed using https://localhost:9443

```
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
echo NEVQeTE0aVZJS1g5RjI3Rg== | base64 --decode
```
Take the decoded password and login to the ui
