# Installing Minio S3 object storage
See this guide on understanding PersistentVolumes and how Pods use PersistentVolumeClaims to automatically bound to a suitable PersistentVolume (of the same storage class that the claim is requesting)

https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
```
minikube ssh
sudo mkdir -p /export/data
sudo chown 1000 -R /export/data
kubectl create namespace local-minio
kubectl apply -f pv.yaml -n  local-minio

helm install \
  --namespace local-minio \
  --create-namespace \
  minio-operator minio/operator

helm upgrade --namespace local-minio \
   --create-namespace local-minio \
   minio/tenant --values values.yaml


kubectl get pv -n local-minio
kubectl get pvc -n local-minio
kubectl -n local-minio get all
kubectl get pods --namespace local-minio

kubectl port-forward service/console 9090:9090 --namespace local-minio
kubectl port-forward service/minio-s3-console 9443:9443 --namespace local-minio

kubectl -n local-minio  get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode
```




kubectl create secret generic minio-creds \
  --from-file=./password.txt

