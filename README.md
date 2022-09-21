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

## Configure Helm

add the Jenkins repo to Helm :
```
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
helm search repo jenkinsci
```

## Create a volume called jenkins-pv
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


kubectl port-forward svc/myapp-service 


# installing argocd 
reference
https://argo-cd.readthedocs.io/en/stable/getting_started/

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl port-forward svc/argocd-server -n argocd 31719:443

The API server can then be accessed using https://localhost:31719


kubectl get secret argocd-initial-admin-secret -n argocd
echo aGdhbGU0ZGhQVVIzMjN1WQ== | base64 --decode

To get the node port
```kubectl get svc -o wide -n myapp```
```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE   SELECTOR
myapp-service   NodePort   10.103.252.29   <none>        8080:31888/TCP   39m   app=myapp
```

Set up the port forward to the service
```kubectl port-forward svc/myapp-service -n myapp 31888:80```





# Argo workflows
As of today, v3.4.9 is the latest release tag in github
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.0/install.yaml


kubectl patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "server",
  "--auth-mode=server"
]}]'

kubectl patch svc argo-server -n argo -p '{"spec": {"type": "NodePort"}}'
kubectl port-forward svc/argo-server 2747:2747 -n argo

Set up the port forward to the service
```kubectl -n argo port-forward deployment/argo-server 2746:2746```
https://localhost:2746

## create a workflow template 
argo template create -n argo local/argo-workflows/workflow1-template.yaml 

## trigger a workflow using that template
argo submit -n argo local/argo-workflows/workflow1.yaml 

## multistep workflow that passes outputs into inputs
To run Argo workflows that use artifacts, you must configure and use an artifact repository. Argo supports any S3 compatible artifact repository such as AWS, GCS and MinIO. 
```
helm repo add minio https://helm.min.io/ # official minio Helm charts
helm repo update
helm install argo-artifacts minio/minio --set service.type=NodePort --set fullnameOverride=argo-artifacts

```
To access Minio from localhost, run the below commands:

  1. ```export POD_NAME=$(kubectl get pods --namespace default -l "release=argo-artifacts" -o jsonpath="{.items[0].metadata.name}")```
  2. ```kubectl port-forward svc/argo-artifacts 9001:9000``` or ```kubectl port-forward po/$POD_NAME 9001:9000```

http://localhost:9001 in the terminal!!!!

ACCESS_KEY=$(kubectl get secret argo-artifacts -o jsonpath="{.data.accesskey}" | base64 --decode)
SECRET_KEY=$(kubectl get secret argo-artifacts -o jsonpath="{.data.secretkey}" | base64 --decode)

### Configure the Default Artifact Repository¶

In order for Argo to use your artifact repository, you can configure it as the default repository. Edit the workflow-controller config map with the correct endpoint and access/secret keys for your repository. 

get a shell to running container
```kubectl exec --stdin --tty argo-artifacts-7785b88865-llzh7 -- /bin/bash```

kubectl apply -f local/argo-workflows/default-artifact-repository.yaml -n argo

## how to do git clone of a repo within workflow
in the inputs section do...

artifacts:
  - name: git-clone
    path: "/workspace/project"
    git:
      revision: "{{inputs.parameters.BRANCH}}"
      repo: "{{inputs.parameters.git_ssh_url}}"
      singleBranch: false
      sshPrivateKeySecret:
        name: gitlab
        key: id_rsa
      insecureIgnoreHostKey: true