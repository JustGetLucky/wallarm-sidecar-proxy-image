UPSTREAM_TAG=4.0.3-1
BUILD_IMAGE=quay.io/dmitriev/sidecar-proxy:$(UPSTREAM_TAG)

BUILDARGS := --build-arg UPSTREAM_TAG=$(UPSTREAM_TAG)

all_local: build push_local rmi
.PHONY: all_local

build_minikube:
	@eval $$(minikube docker-env) ;\
	docker build $(BUILDARGS) -t $(BUILD_IMAGE) -f Dockerfile . --force-rm --pull --no-cache --progress=plain ;\
	docker rmi $$(docker images -f dangling=true -q) || true
.PHONY: build_minikube

all: build push rmi
.PHONY: all

.PHONY: build
build: ## Build docker image.
	@docker build $(BUILDARGS) -t $(BUILD_IMAGE) . --pull --progress=plain --no-cache

.PHONY: push
push: ## Push docker image to remote registry
	@docker push $(BUILD_IMAGE)

.PHONY: rmi
rmi: ## Remove local docker image
	@docker rmi $(BUILD_IMAGE) || true
	docker rmi $$(docker images -f dangling=true -q) || true