# Adjust as desired
namespace ?= robscc
region ?= asia-southeast1
zone ?= asia-southeast1-a
project ?= camunda-researchanddevelopment
release ?= robscc-r1
# zeebe-full-helm-values.yaml
valuesFile ?= https://raw.githubusercontent.com/camunda-community-hub/zeebe-helm-profiles/master/zeebe-dev-profile.yaml
# https://cloud.google.com/compute/docs/general-purpose-machines
machineType ?= n2-standard-4
numNodes ?= 1

# https://helm.camunda.io/
# https://github.com/camunda-community-hub/camunda-cloud-helm/tree/main/charts/zeebe-full-helm
# ~/git/camunda-cloud-helm/charts/zeebe-full-helm
chart ?= zeebe/zeebe-full-helm

.PHONY: info
info: 
	@echo Project: $(project)
	@echo Region: $(region)
	@echo Zone: $(zone)
	@echo Namespace: $(namespace)
	@echo Release: $(release)
	@echo Chart: $(chart)
	@echo Values: $(valuesFile)
	@echo machine-type: $(machineType)
	@echo num nodes: $(numNodes)

.PHONY: zeebe
zeebe:
	-helm install $(release) $(chart) -f $(valuesFile) --namespace $(namespace) --skip-crds
	-kubectl get pods
# -helm install --namespace $(namespace) $(namespace) $(chart) -f zeebe-values.yaml --skip-crds
#	-kubectl apply -n $(namespace) -f curator-cronjob.yaml
#	-kubectl apply -n $(namespace) -f curator-configmap.yaml

.PHONY: simpleStarter
simpleStarter:
	kubectl apply -n $(namespace) -f simpleStarter.yaml
	
.PHONY: clean-zeebe
clean-zeebe:
	-helm uninstall $(release) --namespace $(namespace)
	-kubectl delete -n $(namespace) pvc -l app.kubernetes.io/instance=$(namespace)
	-kubectl delete -n $(namespace) pvc -l app=elasticsearch-master

.PHONY: delete-ns
delete-ns: 
	-kubectl delete namespaces $(namespace)
	-kubectl get namespaces

.PHONY: init-repos
init-repos: 
#	-helm repo add camundacloud https://helm.camunda.io
	-helm repo add zeebe https://helm.camunda.io
	-helm repo update

# https://cloud.google.com/about/locations/
.PHONY: init-gcloud
init-gcloud: 
	-gcloud config set compute/zone $(zone)
	-gcloud config set compute/region $(region)
	-gcloud config set project $(project)

.PHONY: create-cluster list-cluster
create-cluster:
# Insufficent resources for zeebe-full-helm chart with default values
#	-gcloud container clusters create $(namespace)-cluster --region $(region) --node-locations $(zone) --num-nodes=3
# Autopilot cluster does not work with zeebe-full-helm chart 
#	-gcloud container clusters create-auto $(namespace)-cluster --region $(region) --project=$(project)
#
#  n2-standard-4 machines are adequate
	-gcloud container clusters create $(namespace)-cluster --region $(region) --node-locations $(zone) \
--num-nodes=$(numNodes) --cluster-version latest --machine-type $(machineType) 
# --enable-autoscaling --min-nodes 1 --max-nodes 5

.PHONY: delete-cluster 
delete-cluster:
	-gcloud container clusters delete $(namespace)-cluster --project=$(project) --region $(region)

.PHONY: list-cluster
list-cluster:
	-gcloud container clusters list

.PHONY: login
login:
	-gcloud container clusters get-credentials $(namespace)-cluster --region $(region)

.PHONY: pv
pv:
	-kubectl get pvc -n $(namespace)
	-kubectl get pv -n $(namespace)
#	kubectl get pvc -o jsonpath='{.items[*].metadata.name}'

.PHONY: create-ns
create-ns:
	-kubectl create namespace ${namespace}
	-kubectl config set-context --current --namespace=${namespace}

# Generates templates from the zeebe helm charts, useful to make some more specific changes which are not doable by the values file.
# To apply the templates use k apply -f zeebe-cluster/templates/
.PHONY: zeebe-template
zeebe-template:
	-helm template $(namespace) $(chart) -f zeebe-values.yaml --skip-crds --output-dir .

.PHONY: ports
ports:
	-kubectl port-forward svc/$(release)-zeebe-gateway 26500:26500 &
	-kubectl port-forward svc/$(release)-zeebe-tasklist-helm 8080:80 &
	-kubectl port-forward svc/$(release)-zeebe-operate-helm 8081:80 &
	-ps -f | grep 'kubectl' | grep 'port-forward' | awk '{print $$10 " " $$11}'
	
.PHONY: forward
forward:
	-kubectl port-forward svc/$(release)-zeebe-gateway 26500:26500 &
	-kubectl port-forward svc/$(release)-zeebe-tasklist-helm 8080:80 &
	-kubectl port-forward svc/$(release)-zeebe-operate-helm 8081:80 &
	-ps -f | grep 'kubectl' | grep 'port-forward' | awk '{print $$10 " " $$11}'

# pkill kubectl
# for pid in $(ps -f | grep 'kubectl' | grep 'port-forward' | awk '{print $2}');do kill -9 $pid; done
.PHONY: noforward
noforward:
	-kill $$(ps -o pid -o cmd | awk '$$3 == "port-forward" {print $$1}')

#get external ip under which Operate should be reachable
.PHONY: ip
ip:
	-kubectl get svc | grep LoadBalancer | awk '{print $$7}'

.PHONY: list
list:
	-kubectl get pod
	-kubectl get svc


