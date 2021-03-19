NAME=http-echo
VERSION=1.0.1
AUTHOR=vgryzunov
REGISTRY=docker.io
OS=linux
ARCH=amd64

DOCKER_BUILD := docker build --build-arg VERSION=${VERSION}
CONTAINER_TOOL=$(shell command -v podman 2>/dev/null || command -v docker)
LFLAGS ?= -X main.gitsha=${GIT_SHA} -X main.compiled=${BUILD_TIME}

# source files in package
GOFILES=\
	http-echo.go

default: build

.PHONY: golang
golang:
	@echo "--> Go Version"
	@go version

.PHONY: build
build: golang
	@echo "--> Compiling the project"
	@mkdir -p bin
	go build -o bin/$(NAME) $(GOFILES)

.PHONY: static
static: golang
	@echo "--> Compiling the project statically"
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags "-s -w $(LDFLAGS)" -o bin/$(NAME)

.PHONY: docker-build
container-build: docker-build
docker-build:
	@echo "--> Compiling the project, inside a temporary container"
	@mkdir -p bin
	$(eval IMAGE=$(shell uuidgen | tr "[:upper:]" "[:lower:]"))
	$(CONTAINER_TOOL) build --target build-env -t $(IMAGE) .
	$(CONTAINER_TOOL) run --rm $(IMAGE) /bin/cat /opt/$(NAME)/$(NAME) > bin/$(NAME)
	$(CONTAINER_TOOL) rmi $(IMAGE)
	chmod +x bin/$(NAME)

.PHONY: docker
docker: build
	@echo "--> Creating docker image"
	$(CONTAINER_TOOL) build -t $(REGISTRY)/$(AUTHOR)/$(NAME):$(VERSION) .

.PHONY: docker-push
docker-push: docker
	$(CONTAINER_TOOL) push $(REGISTRY)/$(AUTHOR)/$(NAME):$(VERSION)
	$(CONTAINER_TOOL) tag $(REGISTRY)/$(AUTHOR)/$(NAME):$(VERSION) $(REGISTRY)/$(AUTHOR)/$(NAME):latest
	$(CONTAINER_TOOL) push $(REGISTRY)/$(AUTHOR)/$(NAME):latest

clean:
	rm -f bin/*
