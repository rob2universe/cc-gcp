# cc-gcp

The projects helps to setup CAMUNDA Cloud Self-Managed on Google Cloud Platform.


## Environment Setup

Kubectl: https://kubernetes.io/docs/tasks/tools/

Helm: https://helm.sh/docs/intro/install/

Google Cloud SDK: https://cloud.google.com/sdk/docs/install


### GCloud Project
Create a project in Gcloud or make one accessible to your account (project admin needs to add you).

### Parameters

Edit the [Makefile](/Makefile) and set the desired values for 

- namespace ?= your_pref_name   
- region ?= your_region   
- zone ?= your_zone   
- project ?= your_project_id   
- release ?= your_release_name  
- valuesFile ?= Your_values_file (e.g. https://raw.githubusercontent.com/camunda-community-hub/zeebe-helm-profiles/master/zeebe-dev-profile.yaml)  
- machineType ?= desired_machine_type (e.g. n2-standard-4)  
- numNodes ?= desired_number_of_nodes

To get a list of available regions and zones you can use:  
```bash gcloud compute regions list```   
```bash gcloud compute zones list```

## One-time Initalization
```bash make create-ns```  
```bash make login```  
```bash make init-gcloud```    


## Start, use and delete cluster

### Create Cluster
```make create-cluster```

### Create namepsace
```make create-nc```

### Check startup
```make list```  
or  
```kubectl get pods```

### Forward local ports to cluster
```make forward```

### Stop forwarding local ports to cluster
```make noforward```

### Delete cluster
```make delete-cluster```

### Check external ip of cluster
```make ip```