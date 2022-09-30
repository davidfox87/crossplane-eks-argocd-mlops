Cool Kustomize trick 
```kustomize edit set image foxy7887/task-tracker-app=foxy7887/task-tracker-app:v2```

then a new entry will get added to kustomization.yaml
```
images:
- name: foxy7887/task-tracker-app
  newName: foxy7887/task-tracker-app
  newTag: v2
```