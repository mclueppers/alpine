VER := $(or ${ALPINE_VERSION},${ALPINE_VERSION},3.10)
.RECIPEPREFIX +=
.DEFAULT_GOAL := help
STEPS := build run package clean sh upload public-key private-key generate-index
ALPINE_VERSIONS := 3.7 3.8 3.9 3.10

targets = $(foreach ver,$(ALPINE_VERSIONS),.build.$(ver))

$(ALPINE_VERSIONS): %: .build.%:

.PHONY: $(STEPS) $(ALPINE_VERSIONS)

help:
  @echo "\033[33mUsage:\033[0m\n  make [target] [arg=\"val\"...]\n\n\033[33mTargets:\033[0m"
  @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'

build: $(targets) ## Build necessary Docker image for building packages

.build.%: TARGET=$(shell echo $* | sed -e 's/\://g')
.build.%:
  @echo '> Creating Alpine $(TARGET) abuild container'
  @docker image build -t dobrevit-abuild:v$(TARGET)  -f .docker/abuild/Dockerfile-$(TARGET) .docker/abuild
  @touch .build.$(TARGET)

run: build ## Run a command in a new Docker container; make run a=[...]
  @docker run -it --rm -v `pwd`/build:/build -v `pwd`/public:/public dobrevit-abuild:v$(VER) $(a)

package: ## Usage: make package [p="5.6|7.0|7.1|7.2|all|<package-name1> <package-name2> ..."]
  @test $(p)
  make run a="package $(VER) $(p)"

generate-index: ## Generate index file APKINDEX.tar.gz usage: make generate-index
  make run a="generate-index $(VER)"

private-key: ## Generate new private key
  make run a="openssl genrsa -out dobrevit.rsa.priv 4096"

public-key: ## Generate new public key
  make run a="openssl rsa -in dobrevit.rsa.priv -pubout -out /public/dobrevit.rsa.pub"

clean: ## Remove pkg, src, tmp and log folders when building packages for Alpine
  @rm -rf build/$(VER)/*/pkg build/$(VER)/*/src build/$(VER)/*/tmp log/* .build.*

sh: ## Run shell
  make run a=sh

upload: ## Upload build packages to Linux repos server
  @rsync -avz --del public/ root@repos.dobrev.it:/var/www/html/alpine/
