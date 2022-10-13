# Set up Ingress on Minikube with the NGINX Ingress controller
https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

```
minikube addons enable ingress
```

```
helm install \
  --namespace minio-operator \
  --create-namespace \
  minio-operator minio/operator

helm install --namespace minio-operator \
   tenant minio/tenant --values values.yaml

kubectl get pvc -n tenant-ns
kubectl apply -f pv.yaml -n tenant-ns
kubectl get po -n tenant-ns

kubectl get pods --namespace minio-local

kubectl port-forward service/minio-s3-console 9090:9090 9443:9443 --namespace minio-local
```