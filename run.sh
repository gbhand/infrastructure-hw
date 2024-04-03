#!/bin/bash
#
# A simple wrapper managing the infrastructure-hw project.
#

set -e

### Global read-only constants
readonly TIME_FORMAT='+%Y-%m-%dT%H:%M:%SZ'
date -u "${TIME_FORMAT}" > /dev/null

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly SCRIPT_DIR

usage() {
    # Print usage information about this script to STDOUT.
    echo
    echo "Usage: ${BASH_SOURCE[0]} [ACTION]"
    echo 
    echo "  When run without [ACTION] this script will automatically create all resources needed."
    echo
    echo "  [ACTION]     Action to perform"
    echo "    Allowed options:"
    echo "       - start:  Start k8s cluster"
    echo "       - build:  Build Docker images"
    echo "       - deploy: Deploy Helm charts to running cluster"
    echo "       - delete: Stop cluster and remove any created resources"
    echo "       - k9s:    Start k9s terminal for running cluster"
    echo
    echo "  -q | --quiet         Print less messages from this script"
    echo "  -h | --help          Display this help message"
    echo
}

info() {
    # Print formatted log message to STDOUT unless `QUIET` is true.
    if [[ "${QUIET}" != "true" ]]; then
        echo "[$(date -u ${TIME_FORMAT}) INFO  ${BASH_SOURCE[0]}]: $*"
    fi
}

error() {
    # Print formatted error message to STDERR.
    echo "[$(date -u ${TIME_FORMAT}) ERROR  ${BASH_SOURCE[0]}]: $*" >&2
}

configure() {
    # Set k8s environment variables, reading from local .env if exists.
    if [[ -f ".env" ]]; then
        # shellcheck source=/dev/null
        source ".env"
    fi

    export KUBECONFIG="${KUBECONFIG:-${SCRIPT_DIR}/.kube/config-hello}"
}

verify_minikube() {
    if ! command -v minikube > /dev/null; then
        error "minicube not found on path! See https://minikube.sigs.k8s.io/docs/start/ for installation steps."
        exit 1
    fi
}

verify_k9s() {
    if ! command -v k9s > /dev/null; then
        error "k9s not found on path! See https://k9scli.io/topics/install/ for installation steps."
        exit 1
    fi
}

verify_docker() {
    if ! command -v docker > /dev/null; then
        error "docker not found on path! See https://docs.docker.com/engine/install/ for installation steps."
        exit 1
    fi
}

verify_helm() {
    if ! command -v helm > /dev/null; then
        error "helm not found on path! See https://helm.sh/docs/intro/install/ for installation steps."
        exit 1
    fi
}

start_minikube() {
    verify_minikube
    minikube start
}

delete_minikube() {
    verify_minikube
    minikube delete
}

start_k9s() {
    verify_k9s
    k9s
}

build_images() {
    # Builds each directory in ./docker with the minikube docker environment.
    verify_docker

    info "Attempting to fetch minikube docker-env"
    # Hacky way to print error message if failed since minikube doesn't use STDERR
    if ! minikube docker-env; then
        exit 1
    fi
    DOCKER_CONFIG="$(minikube docker-env)"
    eval "${DOCKER_CONFIG}"

    find "${SCRIPT_DIR}/docker" -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' subdir; do 
        image="$(basename "${subdir}")"
        info "Building ${image}"
        docker build -t "${image}" "${subdir}" 
    done
}

deploy_helm() {
    # Installs/upgrades each chart in ./helm then prints host-accessible app URL.
    verify_helm

    find "${SCRIPT_DIR}/helm" -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' subdir; do 
        release="$(basename "${subdir}")"
        info "Deploying chart ${release} from ${subdir}"
        helm upgrade --install "${release}" "${subdir}"
    done

    info "Helm charts successfully deployed! The deployed webapp can be viewed from the following URL (CTRL-C to quit)"
    minikube service hello-receive --url

}

### Entrypoint ###
main() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -q|--quiet)
                QUIET=true
                readonly QUIET
                shift
                ;;
            start|build|deploy|delete|k9s)
                ACTION="$1"
                readonly ACTION
                shift
                ;;
            *)
                error "Unexpected parameter ${1}"
                usage
                exit 1
                ;;
        esac
    done

    configure

    if [ -z "${ACTION}" ]; then
        info "No action provided, creating new stack from scratch."
        if minikube status > /dev/null; then
            info "minikube already running, terminating existing cluster"
            delete_minikube
        fi

        start_minikube
        build_images
        deploy_helm
        delete_minikube
    else

        case "${ACTION}" in
            start)
                info "Starting minikube with config ${KUBECONFIG}"
                start_minikube
                ;;
            build)
                info "Building all images in ${SCRIPT_DIR}/docker within minikube VM"
                build_images
                ;;
            deploy)
                info "Deploying helm charts from ${SCRIPT_DIR}/helm with config ${KUBECONFIG}"
                deploy_helm
                ;;
            delete)
                info "Deleting minikube cluster with config ${KUBECONFIG}"
                delete_minikube
                ;;
            k9s)
                info "Entering k9s terminal with config ${KUBECONFIG}"
                start_k9s
                ;;
            *)
                error "Action ${ACTION} not implemented"
                exit 1
                ;;
        esac
    fi
}

main "$@"