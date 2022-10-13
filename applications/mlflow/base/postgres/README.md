kubectl create secret generic db-secret --from-literal=password=mlflow

https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/


In one terminal:
```
kubectl get pods -w -l app=postgres
```

In another terminal:
```
kubectl apply -f config-map.yaml 
kubectl apply -f db-creds.yaml
kubectl apply -f service.yaml
kubectl apply -f stateful-set.yaml 
```

The commands above creates 1 Pod, each running a postgres db. Get the postgres Service...

```
kubectl get service postgres
```

...then get the postgres StatefulSet, to verify that both were created successfully:

```
kubectl get statefulset mlflow-postgres
```

# Using Stable Network Identities
Each Pod has a stable hostname based on its ordinal index. Use kubectl exec to execute the hostname command in each Pod:
```
kubectl exec "mlflow-postgres-0" -- sh -c 'hostname'
kubectl exec -it mlflow-postgres-0 bash
psql -h localhost -U mlflow -d mlflow-db
```

or 

we can execute commands directly using kubectl exec
```
kubectl exec "mlflow-postgres-0" -- sh -c 'psql -h localhost -U mlflow -p 5432 -d mlflow-db'
```