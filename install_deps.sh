#!/bin/bash
#
# Script to install required packages on both Linux and Mac.
#

set -e

REQUIRED_DEPS=( docker minikube helm )
OPTIONAL_DEPS=( k9s )

usage() {
    # Print usage information about this script to STDOUT.
    echo
    echo "Usage: ${BASH_SOURCE[0]}"
    echo 
    echo "  Install missing dependencies"
    echo
    echo "  -o | --optional      Install optional dependencies along with required"
    echo "  -h | --help          Display this help message"
    echo
}

DEPS_TO_INSTALL=( "${REQUIRED_DEPS[@]}" )

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -o|--optional)
            DEPS_TO_INSTALL+=( "${OPTIONAL_DEPS[@]}" )
            shift
            ;;
        *)
            error "Unexpected parameter ${1}"
            usage
            exit 1
            ;;
    esac
done

if [[ "$(uname -s)" == "Darwin" ]]; then
    for dep in "${DEPS_TO_INSTALL[@]}"; do
        if ! command -v "${dep}" > /dev/null; then
            echo "Installing ${dep} with homebrew"
            if [[ "${dep}" == "docker" ]]; then
                brew cask install docker
            else
                brew install "${dep}"
            fi
        else
            echo "${dep} already installed"
        fi
    done
elif [[ "$(uname -s)" == "Linux" ]]; then
    echo "Automatic installation not yet supported for Linux."
    echo "Please install the following packages with your preferred package manager:"
    for dep in "${DEPS_TO_INSTALL[@]}"; do
        echo -e "\t${dep}"
    done
fi
