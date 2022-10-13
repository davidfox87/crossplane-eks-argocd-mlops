# Installing Minio S3 object storage
```
helm install \
  --namespace local-minio \
  --create-namespace \
  minio-operator minio/operator

helm install --namespace local-minio \
   --create-namespace local-minio \
   minio/tenant --values values.yaml

<!-- 
kubectl apply -f pv.yaml -n  local-minio
kubectl get pvc -n local-minio
kubectl get po -n local-minio -->

kubectl get pods --namespace minio-tenant-1

kubectl port-forward service/console 9090:9090 --namespace minio-operator
```