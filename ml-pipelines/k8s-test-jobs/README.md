```
kubectl describe job predictions

pods=$(kubectl get pods --selector=job-name=predictions --output=jsonpath='{.items[*].metadata.name}')
echo $pods

kubectl get po -o wide

kubectl logs predictions-vzns4-wws6p
```