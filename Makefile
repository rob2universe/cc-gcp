namespace ?= robscc
# https://helm.camunda.io/
# ~/git/camunda-cloud-helm/charts/zeebe-full-helm
chart ?= zeebe/zeebe-full-helm
region ?= asia-southeast1
zone ?= asia-southeast1-a
project ?= camunda-researchanddevelopment

.PHONY: info zeebe
info: 
	@echo namespace
	@echo chart

.PHONY: zeebe
zeebe:
	-helm install --namespace $(namespace) $(namespace) zeebe/zeebe-cluster-helm
#	-helm install --namespace $(namespace) $(namespace) $(chart) -f zeebe-values.yaml --skip-crds
#	-kubectl apply -n $(namespace) -f curator-cronjob.yaml
#	-kubectl apply -n $(namespace) -f curator-configmap.yaml

# Generates templates from the zeebe helm charts, useful to make some more specific changes which are not doable by the values file.
# To apply the templates use k apply -f zeebe-cluster/templates/
.PHONY: zeebe-template
zeebe-template:
	-helm template $(namespace) $(chart) -f zeebe-values.yaml --skip-crds --output-dir .

.PHONY: clean
clean: clean-zeebe

.PHONY: clean-zeebe
clean-zeebe:
	-helm --namespace $(namespace) uninstall $(namespace)

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


.PHONY: create-cluster
create-cluster:
	-gcloud container clusters create $(namespace)-cluster --num-nodes=2

.PHONY: login
login:
	-gcloud container clusters get-credentials $(namespace)-cluster

# .PHONY: create-ns
# create-ns:
# 	-kubectl create namespace ${namespace}
# 	-kubectl config set-context --current --namespace=${namespace}

.PHONY: port-forward
port-forward:
	-kubectl port-forward svc/$(namespace)-zeebe-gateway 26500:26500 -n robscc