# Makefile for building Litmus and its tools
# Reference Guide - https://www.gnu.org/software/make/manual/make.html

#
# Internal variables or constants.
# NOTE - These will be executed when any make target is invoked.
#
IS_DOCKER_INSTALLED = $(shell which docker >> /dev/null 2>&1; echo $$?)

# Docker info
DOCKER_REPO ?= litmuschaos
DOCKER_IMAGE ?= go-runner
DOCKER_TAG ?= ci

.PHONY: help
help:
	@echo ""
	@echo "Usage:-"
	@echo "\tmake deps          -- sets up dependencies for image build"
	@echo "\tmake build         -- builds the litmus-go binary & docker multi-arch image"
	@echo "\tmake push          -- pushes the litmus-go multi-arch image"
	@echo "\tmake build-amd64   -- builds the litmus-go binary & docker amd64 image"
	@echo "\tmake push-amd64    -- pushes the litmus-go amd64 image"
	@echo ""

.PHONY: all
all: deps gotasks build push trivy-check

.PHONY: deps
deps: _build_check_docker

_build_check_docker:
	@echo "------------------"
	@echo "--> Check the Docker deps" 
	@echo "------------------"
	@if [ $(IS_DOCKER_INSTALLED) -eq 1 ]; \
		then echo "" \
		&& echo "ERROR:\tdocker is not installed. Please install it before build." \
		&& echo "" \
		&& exit 1; \
		fi;

.PHONY: gotasks
gotasks: unused-package-check

.PHONY: unused-package-check
unused-package-check:
	@echo "------------------"
	@echo "--> Check unused packages for the litmus-go"
	@echo "------------------"
	@tidy=$$(go mod tidy); \
	if [ -n "$${tidy}" ]; then \
		echo "go mod tidy checking failed!"; echo "$${tidy}"; echo; \
	fi

.PHONY: build
build: experiment-build docker.buildx image-build

.PHONY: experiment-build
experiment-build:
	@echo "------------------------------"
	@echo "--> Build experiment go binary" 
	@echo "------------------------------"
	@./build/go-multiarch-build.sh build/generate_go_binary

.PHONY: docker.buildx
docker.buildx:
	@echo "------------------------------"
	@echo "--> Setting up Builder        " 
	@echo "------------------------------"
	@if ! docker buildx ls | grep -q multibuilder; then\
		docker buildx create --name multibuilder;\
		docker buildx inspect multibuilder --bootstrap;\
		docker buildx use multibuilder;\
	fi

.PHONY: image-build
image-build:	
	@echo "-------------------------"
	@echo "--> Build go-runner image" 
	@echo "-------------------------"
	@docker buildx build --file build/Dockerfile --progress plane --platform linux/arm64,linux/amd64 --no-cache --tag $(DOCKER_REPO)/$(DOCKER_IMAGE):$(DOCKER_TAG) .

.PHONY: build-amd64
build-amd64:

	@echo "------------------------------"
	@echo "--> Build experiment go binary" 
	@echo "------------------------------"
	@env GOOS=linux GOARCH=amd64 sh build/generate_go_binary
	@echo "-------------------------"
	@echo "--> Build go-runner image" 
	@echo "-------------------------"
	@sudo docker build --file build/Dockerfile --tag $(DOCKER_REPO)/$(DOCKER_IMAGE):$(DOCKER_TAG) . --build-arg TARGETARCH=amd64

.PHONY: push-amd64
push-amd64:

	@echo "------------------------------"
	@echo "--> Pushing image" 
	@echo "------------------------------"
	@sudo docker push $(DOCKER_REPO)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	
.PHONY: push
push: docker.buildx litmus-go-push

litmus-go-push:
	@echo "-------------------"
	@echo "--> go-runner image" 
	@echo "-------------------"
	REPONAME="$(DOCKER_REPO)" IMGNAME="$(DOCKER_IMAGE)" IMGTAG="$(DOCKER_TAG)" ./build/push
	
.PHONY: trivy-check
trivy-check:

	@echo "------------------------"
	@echo "---> Running Trivy Check"
	@echo "------------------------"
	@./trivy --exit-code 0 --severity HIGH --no-progress $(DOCKER_REPO)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	@./trivy --exit-code 0 --severity CRITICAL --no-progress $(DOCKER_REPO)/$(DOCKER_IMAGE):$(DOCKER_TAG)
