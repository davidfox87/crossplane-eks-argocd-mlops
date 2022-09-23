# Local deployment of ArgoCD and Argo workflows on a local minikube K8s cluster

This is a demonstration of a GitOps CI/CD pipeline using Argo workflows (clone, build and push docker image, and update helm chart repo)
and ArgoCD to update cluster configuration from the helm chart repository. Both Argo workflows and ArgoCD are deployed in the same Kubernetes cluster.


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



# Installing Argo workflows
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

Log in to minio and create the "my-bucket" bucket

modify the configmap in the argo namespace, which will reference the artifact repository in the default namespace

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: workflow-controller-configmap
data:
    artifactRepository: |    # However, all nested maps must be strings
      archiveLogs: true
      s3:
        endpoint: argo-artifacts.default:9000
        bucket: my-bucket
        insecure: false
        accessKeySecret:
          name: argo-artfacts
          key: accesskey
        secretKeySecret:
          name: argo-artfacts
          key: secretkey

```

## submit argo artifact-passing workflow to argo namespace
Go over to http://localhost:9001 and check the bucket for the new file
``` argo submit -n argo local/argo-workflows/artifact-passing.yaml --watch```


### Configure the Default Artifact Repository¶

In order for Argo to use your artifact repository, you can configure it as the default repository. Edit the workflow-controller config map with the correct endpoint and access/secret keys for your repository. 

get a shell to running container
```kubectl exec --stdin --tty argo-artifacts-7785b88865-llzh7 -- /bin/bash```

kubectl apply -f local/argo-workflows/default-artifact-repository.yaml -n argo

## how to do git clone of a repo within workflow
in the inputs section do...
```
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
```


## create a secret for docker hub credentials
https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret

To configure that, you:

1. Create a secret or use an existing one. Multiple Pods can reference the same secret.
2. Modify your Pod definition to add a volume under .spec.volumes[]. Name the volume anything, and have a .spec.volumes[].secret.secretName field equal to the name of the Secret object.
3. Add a .spec.containers[].volumeMounts[] to each container that needs the secret. Specify .spec.containers[].volumeMounts[].readOnly = true and .spec.containers[].volumeMounts[].mountPath to an unused directory name where you would like the secrets to appear.
4. Modify your image or command line so that the program looks for files in that directory. Each key in the secret data map becomes the filename under mountPath.

```
kubectl create secret docker-registry dockercred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=foxy7887 \
    --docker-password=xxxxx \
    --docker-email=davidmfox87@gmail.com
```

## argo-events
now have github to send a webhook to our k8s cluster
tell processes in the cluster to trigger some pipelines (argo workflows)


install argo events
https://argoproj.github.io/argo-events/installation/


K8s ingress
https://kubernetes.io/docs/concepts/services-networking/ingress/
An API object that manages external access to the services in a cluster, typically HTTP.

In order for the Ingress resource to work, the cluster must have an ingress controller running.
https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/


```
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install my-release nginx-stable/nginx-ingress
```
or add ingress add-on to minikube
minikube addons enable ingress


kubectl apply -f local/argo-events/event-sources.yaml 