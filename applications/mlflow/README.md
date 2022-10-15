# Installing Minio S3 object storage
See this guide on understanding PersistentVolumes and how Pods use PersistentVolumeClaims to automatically bound to a suitable PersistentVolume (of the same storage class that the claim is requesting)

https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/
```
In the overlays/standard directory, run:
```
kustomize build | kubectl apply -f -
```

Set up port forward to minio-console:
```
kubectl port-forward service/minio-svc 9001:9001 -n minio-local
```



Port forward to mlflow tracking server
```
kubectl port-forward service/mlflow-tracking-server 5555:5000 -n local-mlflow
```


