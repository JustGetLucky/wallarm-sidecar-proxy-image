UPSTREAM_TAG=4.0.2-1
BUILD_IMAGE=quay.io/dmitriev/sidecar-proxy:$(UPSTREAM_TAG)

BUILDARGS :=
BUILDARGS += --build-arg UPSTREAM_TAG=$(UPSTREAM_TAG)

MINIKUBE_IP := $(shell minikube ip)
LOCAL_IMAGE = $(MINIKUBE_IP):5000/sidecar-proxy:$(UPSTREAM_TAG)

all_local: build push_local
.PHONY: all_local

all: build push rmi
.PHONY: all

.PHONY: build
build: ## Build docker image.
	@docker build $(BUILDARGS) -t $(BUILD_IMAGE) . --pull --progress=plain #--no-cache

.PHONY: push
push: ## Push docker image to remote registry
	@docker push $(BUILD_IMAGE)

.PHONY: push_local
push_local: ## Push docker image to local registry
	@docker rmi $(LOCAL_IMAGE) || true
	@docker tag $(BUILD_IMAGE) $(LOCAL_IMAGE)
	@docker push $(LOCAL_IMAGE)

.PHONY: rmi
rmi: ## Remove local docker image
	@docker rmi $(BUILD_IMAGE) || true
	@docker rmi $(LOCAL_IMAGE) || true