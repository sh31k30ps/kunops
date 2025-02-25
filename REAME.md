# Kunops

Universal Kubernetes for Ops is for development, testing and production respecting my point of view for GitOps implementation.

With this project, you can have the definition of all your necessary components on a single cluster.

This project is a boilerplate, you can use it as a starting point for your own configuration.

## Prerequisites

This project use the following tools:

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/installing/)
- [yq](https://github.com/mikefarah/yq)
- [kustomize](https://kubernetes-sigs.github.io/kustomize/)
- [docker](https://docs.docker.com/engine/install/)
- [awk](https://www.grymoire.com/Unix/awk.html)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets)

## Setup

I'm using Homebrew for package management on macOS.

1. Install [kind](https://kind.sigs.k8s.io/docs/user/quick-start/):
```bash
brew install kind
```
2. Install [kubectl](https://kubernetes.io/docs/tasks/tools/):
```bash
brew install kubectl
```
3. Install [helm](https://helm.sh/docs/intro/installing/):
```bash
brew install helm
```
4. Install [yq](https://github.com/mikefarah/yq):
```bash
brew install yq
```
5. Install [kustomize](https://kubernetes-sigs.github.io/kustomize/):
```bash
brew install kustomize
```
6. Install [docker](https://docs.docker.com/engine/install/):
```bash
brew install docker
```
7. Install [kubeseal](https://github.com/bitnami-labs/sealed-secrets):
```bash
brew install kubeseal
```

## Usage
First of all, you need to have a Kubernetes cluster up and running.
To help you with that, this project into the makefile the way to easily install your cluster.

```bash
make install
```

This command use the kind tool to create a Kubernetes cluster and initiate and apply all enabled components.
The cluster configuration is stored in the `kind-config.yaml` file.
The default configuration is for one control plane and one worker.
The control plane is also used as Egress and is exposed on port 80 of your localhost.
To be fully functional, you should expose your selected ingress manager on the control plane node port 30080.
In our boilerplate, we use Traefik with all preset values to be functionnal but you can easily customize it or use an other one like nginx.

## Clean up 
```bash
make uninstall  
```

## Specific commands

To install all, the local environment and enabled components.
```bash
make install
```

To install only the local environment.
```bash
make install-env
```

To initialize all components.
```bash
make components-init
```
Initialisation of a component depends on `component.yaml` spécifications.
Currently this boilerplate only support `Helm` charts.

To initialize only one component.
```bash
make components/traefik/component.yaml
```

To apply all enabled components on a cluster.
The `ENV` parameter is to target a cluster. By default it is `local`.
```bash
make components-apply [ENV=local]
```

To apply a specific component:
```bash
make component-apply COMPONENT=traefik [ENV=local]
```
