# Local deployment of Jenkins and ArgoCD on minikube K8s cluster

This is a demonstration of a GitOps CI/CD pipeline using Jenkins and ArgoCD deployed in a Kubernetes cluster
```
minikube
```

Create the Jenkins namespace
```
kubectl create namespace jenkins
kubectl get namespaces
```

# Configure Helm

Once Helm is installed and set up properly, add the Jenkins repo as follows:
```
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
helm search repo jenkinsci
```

# Create a volume called jenkins-pv
It’s worth noting that, in the above spec, hostPath uses the /data/jenkins-volume/ of your node to emulate network-attached storage. This approach is only suited for development and testing purposes. For production, you should provide a network resource like a Google Compute Engine persistent disk, or an Amazon Elastic Block Store volume. 
```
kubectl apply -f jenkins-volume.yaml
```

Apply service-account manifest
```
kubectl apply -f jenkins-sa.yaml
```

## install 
 helm show values jenkinsci/jenkins > helm-values/values.yaml

modify the values for ServiceType, serviceaccoutn and storageClass
```
chart=jenkinsci/jenkins
helm install jenkins -n jenkins -f helm-values/values.yaml $chart
```

kubectl get node -o wide -n jenkins

Notice that the persistent volume host path folder is created with root ownership and the pod will not be able to start.
You will see this message by looking at the logs of the pod
```
kubectl logs jenkins-0 -p -n jenkins -c init
```


Change the permissions in the /data/jenkins-volume entering into the node with 
```
minikube ssh
docker@minikube:~$ sudo chown -R 1000:1000 /data/jenkins-volume
```


Now if you check the pods, everything will be running fine:
```
kubectl get pods --namespace jenkins -o wide
```


chart=jenkinsci/jenkins
helm upgrade jenkins -n jenkins -f helm-values/values.yaml $chart


NOTES:
1. Get your 'admin' user password by running:
  kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  export NODE_PORT=$(kubectl get --namespace jenkins -o jsonpath="{.spec.ports[0].nodePort}" services jenkins)
  export NODE_IP=$(kubectl get nodes --namespace jenkins -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT/login

# port forward to get access to the nodeport service in the cluster
kubectl port-forward svc/jenkins 30359:8080 -n jenkins





# installing argocd in the same cluster
reference
https://argo-cd.readthedocs.io/en/stable/getting_started/

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl port-forward svc/argocd-server -n argocd 31719:443

The API server can then be accessed using https://localhost:31719


kubectl get secret argocd-initial-admin-secret -n argocd
echo aGdhbGU0ZGhQVVIzMjN1WQ== | base64 --decode