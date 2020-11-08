VER := $(or ${ALPINE_VERSION},${ALPINE_VERSION},3.12)
PLATFORM := $(or ${PLATFORM},${PLATFORM},linux/arm64)
PLATFORM_SLUG := $(shell echo $(PLATFORM) | sed -e 's/\//-/g')
BUILDDIR := $(or ${BUILDDIR},${BUILDDIR},`pwd`)
.RECIPEPREFIX +=
.DEFAULT_GOAL := help
STEPS := build run package clean sh upload public-key private-key generate-index
ALPINE_VERSIONS := 3.7 3.8 3.9 3.10 3.11 3.12

targets = $(foreach ver,$(ALPINE_VERSIONS),.build.$(ver)-$(PLATFORM_SLUG))

$(ALPINE_VERSIONS): %: .build.%-$(PLATFORM_SLUG):

.PHONY: $(STEPS) $(ALPINE_VERSIONS)

help:
  @echo "\033[33mUsage:\033[0m\n  make [target] [arg=\"val\"...]\n\n\033[33mTargets:\033[0m"
  @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'

build: $(targets) ## Build necessary Docker image for building packages

.build.%-$(PLATFORM_SLUG): TARGET=$(shell echo $* | sed -e 's/\://g')
.build.%-$(PLATFORM_SLUG):
  @echo '> Creating Alpine $(TARGET) abuild container for ${PLATFORM}'
  @docker pull --platform $(PLATFORM) alpine:$(VER)
  @docker image build --platform ${PLATFORM} --no-cache --build-arg IMAGE_TAG=$(TARGET) -t dobrevit-abuild:v$(TARGET)-${PLATFORM_SLUG}  -f .docker/abuild/Dockerfile .docker/abuild
  @touch .build.$(TARGET)-${PLATFORM_SLUG}

run: build ## Run a command in a new Docker container; make run a=[...]
  @docker run --platform ${PLATFORM} --rm -it -v $(BUILDDIR)/build:/build -v $(BUILDDIR)/public:/public dobrevit-abuild:v$(VER)-${PLATFORM_SLUG} $(a)

package: ## Usage: make package [p="5.6|7.0|7.1|7.2|all|<package-name1> <package-name2> ..."]
  @test $(p)
  make run a="package $(VER) $(p)"

generate-index: ## Generate index file APKINDEX.tar.gz usage: make generate-index
  make run a="generate-index v$(VER)"

private-key: ## Generate new private key
  make run a="openssl genrsa -out dobrevit.rsa.priv 4096"

public-key: ## Generate new public key
  make run a="openssl rsa -in dobrevit.rsa.priv -pubout -out /public/dobrevit.rsa.pub"

clean: ## Remove pkg, src, tmp and log folders when building packages for Alpine
  rm -rf build/$(VER)/*/pkg build/$(VER)/*/src build/$(VER)/*/tmp log/* .build.*

sh: ## Run shell
  make run a=/bin/sh

upload: ARCH=$(shell docker run --platform ${PLATFORM} --rm dobrevit-abuild:v$(VER)-$(PLATFORM_SLUG) apk --print-arch)
upload: ## Upload build packages to Linux repos server
  @rsync -avz --del public/v$(VER)/$(ARCH) root@repos.dobrev.it:/var/www/html/alpine/v$(VER)/
