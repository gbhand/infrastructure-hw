#!/bin/bash
#
# TODO
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
    echo "  [ACTION]     Action to perform"
    echo "    Allowed options:"
    echo "       - start:  Start k8s cluster"
    echo "       - build:  Build Docker images"
    echo "       - deploy: Deploy Helm charts to running cluster"
    echo "       - delete: Stop cluster and remove any created resources"
    echo "       - test:   TODO"
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
    # TODO
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
    # TODO
    verify_minikube
    minikube start
}

delete_minikube() {
    # TODO
    verify_minikube
    minikube delete
}

start_k9s() {
    # TODO
    verify_k9s
    k9s
}

build_images() {
    # TODO
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
    # TODO
    verify_helm

    find "${SCRIPT_DIR}/helm" -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' subdir; do 
        release="$(basename "${subdir}")"
        info "Deploying chart ${release} from ${subdir}"
        if helm status "${release}" &> /dev/null; then
            info "${release} already installed, upgrading instead."
            helm upgrade "${release}" "${subdir}"
        else
            helm install "${release}" "${subdir}"
        fi
    done

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
            start|build|deploy|delete|test|k9s)
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

    if [ -z "${ACTION}" ]; then
        error "ACTION must be provided"
        usage
        exit 1
    fi

    configure

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
        test)
            info "Testing helm charts from ${SCRIPT_DIR}/helm with config ${KUBECONFIG}"
            test_helm
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
}

main "$@"