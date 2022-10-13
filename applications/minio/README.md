# Installing Minio S3 object storage
https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
```
minikube ssh
sudo mkdir -p /media/working/minio-volume/0
sudo mkdir -p /media/working/minio-volume/1
sudo mkdir -p /media/working/minio-volume/2
sudo mkdir -p /media/working/minio-volume/3

kubectl apply -f pv.yaml -n  local-minio

helm install \
  --namespace local-minio \
  --create-namespace \
  minio-operator minio/operator

helm install --namespace local-minio \
   --create-namespace local-minio \
   minio/tenant --values values.yaml


kubectl get pvc -n local-minio
kubectl -n local-minio get all
kubectl get pods --namespace local-minio

kubectl port-forward service/console 9090:9090 9443:9443 --namespace local-minio
```