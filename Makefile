.PHONY: $(PHONY) FORCE

# ARGS := "KIND_EXPERIMENTAL_PROVIDER=podman "
ARGS?= 
COMPONENT?=
ENV?=local
MODE?=all
COMPONENTS:=$(shell ls -1 components)

default: help

PHONY += install
install: install-env components-init components-apply ## Install all (env and components)

PHONY += install-env
install-env: ## Install local environment
	@echo "Installing local environment"
	@${ARGS}kind create cluster --name local-env --config kind-config.yaml
	@kubectl cluster-info --context kind-local-env

PHONY += uninstall
uninstall: ## Uninstall local environment
	@echo "Uninstalling local environment"
	@${ARGS}kind delete cluster --name local-env

PHONY += components-init
components-init: ## Init components
	@$(foreach component,$(COMPONENTS),make components/$(component)/component.yaml;)

components/%/component.yaml: FORCE
	@./bin/components/init.sh $@

PHONY += components-apply
components-apply: ## Apply components on kube cluster
	@$(foreach component,$(COMPONENTS),make component-apply COMPONENT=$(component) ENV=$(ENV) MODE=crd;)
	@$(foreach component,$(COMPONENTS),make component-apply COMPONENT=$(component) ENV=$(ENV) MODE=manifests;)

PHONY += component-apply
component-apply: ## Apply specific component on kube cluster
	@./bin/components/apply.sh $(COMPONENT) $(ENV) $(MODE)

PHONY += help
help: ## Display available commands
	@grep -E '^[a-zA-Z_0-9-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
