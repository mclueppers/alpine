VER := $(or ${ALPINE_VERSION},${ALPINE_VERSION},"v3.8")
.RECIPEPREFIX +=
.DEFAULT_GOAL := help
.PHONY: *

help:
  @echo "\033[33mUsage:\033[0m\n  make [target] [arg=\"val\"...]\n\n\033[33mTargets:\033[0m"
  @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'

build-v37: ## Build Alpine v3.7 container
  @docker image build -t dobrevit-abuild:v3.7 -f .docker/abuild/Dockerfile-3.7 .docker/abuild

build-v38: ## Build Alpine v3.8 container
  @docker image build -t dobrevit-abuild:v3.8 -f .docker/abuild/Dockerfile-3.8 .docker/abuild

build: ## Build necessary Docker image for building packages
  @make build-v37
  @make build-v38

run: ## Run a command in a new Docker container; make run a=[...]
  make build
  @docker run -it --rm -v `pwd`/build:/build -v `pwd`/public:/public dobrevit-abuild:$(VER) $(a)

package: ## Usage: make package [p="5.6|7.0|7.1|7.2|all|<package-name1> <package-name2> ..."]
  @test $(p)
  make run a="package $(VER) $(p)"

generate-index: ## Generate index file APKINDEX.tar.gz usage: make generate-index
  make run a="generate-index $(VER)"

private-key: ## Generate new private key
  make run a="openssl genrsa -out dobrevit.rsa.priv 4096 --build --force-recreate"

public-key: ## Generate new public key
  make run a="openssl rsa -in dobrevit.rsa.priv -pubout -out /public/dobrevit.rsa.pub"

clean: ## Remove pkg, src, tmp and log folders when building packages for Alpine
  @rm -rf build/$(VER)/*/pkg build/$(VER)/*/src build/$(VER)/*/tmp log/*

sh: ## Run shell
  make run a=sh

upload: ## Upload build packages to Linux repos server
  @rsync -avz --del public/ root@repos.dobrev.it:/var/www/html/alpine/
