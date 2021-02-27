#!/usr/bin/env groovy

node("arm64") {
    stage('Setup node') {
        git url: 'https://github.com/mclueppers/alpine.git'

        env.ALPINE_VERSION=params.ALPINE_VERSION
        env.BUILDDIR='/home/ubuntu/alpine'
        env.PACKAGE_NAME=params.PACKAGE_NAME
        env.PLATFORM='linux/arm64'
        sh """
            mkdir -p .cache public
            sudo chown ubuntu. .cache public -R
        """
    }

    stage("Build") {
        sh 'make package p=$PACKAGE_NAME'
    }
}