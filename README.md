# infrastructure-hw

## Getting Started

This sample cluster runs in minikube with a Docker build backend.
Helm charts are used for provisioning resources.

This project requires Docker, minikube and helm to be installed. k9s may also be installed for managing the cluster.

```log
# Minimum installation
$ ./install_deps

# Full installation
$ ./install_deps --optional
```

`./run.sh` is the primary entrypoint for managing this cluster. The script handles Kubernetes API configuration and provides helpful
macros for various cluster operations, see usage for full list

```log
$ ./run.sh --help
Usage: ./run.sh [ACTION]

  When run without [ACTION] this script will automatically create all resources needed.

  [ACTION]     Action to perform
    Allowed options:
       - start:  Start k8s cluster
       - build:  Build Docker images
       - deploy: Deploy Helm charts to running cluster
       - delete: Stop cluster and remove any created resources
       - k9s:    Start k9s terminal for running cluster

  -q | --quiet         Print less messages from this script
  -h | --help          Display this help message
```

However the entire infrastructure may be created and run by simply calling `./run.sh` with no parameters.

```log
$ ./run.sh
...
Helm charts successfully deployed! The deployed webapp can be viewed from the following URL (CTRL-C to quit)
http://127.0.0.1:61842
```

## Your mission

For this assignment, you're going to create the infrastructure for an application with a small set of services.

- One service needs to broadcast `Hello world` at random intervals. Make the interval anywhere from 1 to 10 seconds, with each the time until the next broadcast each chosen randomly.

- Another service needs to receive the `Hello world` broadcasts.

- Then a user should be able to view the `Hello world` broadcasts, as they arrive, from a web browser.

### Other requirements

- Use whatever languages and frameworks you want to create the services.
- We're aiming to just run this application on an engineer's local machine, not the cloud; design your solution for `minikube`
- Your solution should have the minimum number of manual setup steps necessary.
- Use any adjacent infrastructure tools you think make for a more elegant solution.

## Submission

- Fork this repository on GitHub. Develop a solution on your fork. Extra points for good git hygiene.
- Include specific instructions in your README about pre-requisites and setup steps. Another engineer should be able to go from zero to running your solution on their local machine.
- Either send us the link to your repository (if you make it public) or email us a zipped-up folder.
