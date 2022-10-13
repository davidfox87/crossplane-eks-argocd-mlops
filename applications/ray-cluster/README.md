# configMaps
Now that the ConfigMap exists in your cluster as a static chunk of data, it’s not doing anything because no pods reference the object.

There are two ways to link a ConfigMap into a pod’s manifest. Your approach should depend on whether you want to use the ConfigMap’s data as environment variables, command line arguments, or mounted files. This decision should be based on how your application expects to read its config values.

From a Kubernetes perspective, environment variables can be simple to set up, inspect, and reason about. Mounted files are more sustainable for larger amounts of data. They also support automatic updates after you modify the ConfigMap’s data field. ConfigMaps injected as environment variables require a pod restart to apply new changes.

Now, look at how you can use both kinds of ConfigMap references with your pods.

# Environment Variables

Set the spec.containers.envFrom.configMapRef field to pull a ConfigMap’s data into a pod’s containers as environment variables:

```
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
 - name: app-container
 command:  ["/bin/sh", "-c", "echo $db_host"]
 image: busybox:latest
   envFrom:
     - configMapRef:
         name: app-config
```

# Mounted Volume Files

ConfigMaps can be mounted into your containers as files in a volume. When this mechanism is used, your pod references a volume that uses the configMap field to source its initial config from a named ConfigMap. That volume is then mounted into the container via the volumeMounts field:

```
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
 - name: app-container
   image: busybox:latest
   volumeMounts:
     - name: config
       mountPath: "/etc/demo-app"
       readOnly: true
   volumes:
     - name: config
       configMap:
         name: app-config

```
The previous example defines a named volume called config that references the app-config ConfigMap created earlier. The volume is mounted to the /etc/demo-app directory within the container. It’s advisable to mark the mount as readOnly, as you shouldn’t change ConfigMap values from within a container. Kubernetes automatically updates the files in the volume as you make changes to the ConfigMap’s data field, potentially overwriting any alterations you make.

ConfigMaps mounted as volumes expose each data key-pair value as a separate file inside the mount point. The key is used as the file name; the file’s content will be the corresponding value in the ConfigMap. The container created earlier can get the value of its database host setting by reading the /etc/demo-app/db_host file.