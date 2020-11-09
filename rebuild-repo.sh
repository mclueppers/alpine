#!/usr/bin/env bash
ALPINE_VERSIONS="3.11 3.12"
PLATFORMS="amd64 arm64 armhf"

for VERSION in $ALPINE_VERSIONS; do
	for CPU_ARCH in $PLATFORMS; do
		echo "Building packages for Alpine ${VERSION}, platform: linux/$CPU_ARCH"
		export ALPINE_VERSION=$VERSION
		export PLATFORM="linux/$CPU_ARCH"

		docker pull --platform $PLATFORM alpine:$VERSION
		make build
		make package p=opentracing-cpp
		make package p=dd-opentracing-cpp
		make package p=other
		make package p=php7.2
		make package p=php7.3
		make package p=php7.4
		make package p=7.2
		make package p=7.3
		make package p=7.4
	done
done

unset ALPINE_VERSION ALPINE_VERSIONS VERSION PLATFORMS PLATFORM CPU_ARCH
