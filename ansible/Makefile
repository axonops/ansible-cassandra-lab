#
#
#
.ONESHELL:
.SHELL := /bin/bash
.PHONY: common cassandra
.EXPORT_ALL_VARIABLES:
CURRENT_FOLDER=$(shell basename $(PWD))
ENVIRONMENT ?= lab
EXTRA ?= "-e makefile=true"
# Bug running on OSX
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
#ANSIBLE_VAULT_PASSWORD_FILE ?= ~/.ansible_vault_pass
INVENTORY=inventories/$(ENVIRONMENT)/hosts.ini
ANSIBLE_USER ?= root

# Default to use pipenv unless disabled
PIPENV ?= true
ifeq ($(PIPENV),true)
PIPENVCMD=pipenv run
else
PIPENVCMD=
endif

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check-env:
	@if [ ! "$(ANSIBLE_USER)" ]; then echo "$(BOLD)$(RED)ANSIBLE_USER is not set$(RESET)"; exit 1;fi

check-env-alerts:
	@if [ ! "$(AXONOPS_TOKEN)" ]; then echo "$(BOLD)$(RED)AXONOPS_TOKEN is not set$(RESET)"; exit 1;fi
	@if [ ! "$(AXONOPS_ORG)" ]; then echo "$(BOLD)$(RED)AXONOPS_ORG is not set$(RESET)"; exit 1;fi

check: ## run pre-commit tests
	@${PIPENVCMD} pre-commit run --all-files

fmt:
	@${PIPENVCMD} pre-commit run --all-files

prep:
	@${PIPENVCMD} ansible-galaxy install -r requirements.yml -p roles
	@${PIPENVCMD} ansible-galaxy collection install -r requirements.yml -p collections

common: check-env ## Common tasks for all environments and servers
	@${PIPENVCMD} ansible-playbook -i $(INVENTORY) common.yml --diff ${EXTRA} \
		-u ${ANSIBLE_USER} \
		-e env=${ENVIRONMENT}

cassandra: check-env ## Installs the cassandra cluster
	@${PIPENVCMD} ansible-playbook -i $(INVENTORY) cassandra.yml --diff ${EXTRA} \
		-u ${ANSIBLE_USER} \
		-e env=${ENVIRONMENT}

alerts: check-env-alerts ## Sets up AxonOps alerts
	@${PIPENVCMD} ansible-playbook -i $(INVENTORY) alerts.yml --diff ${EXTRA} \
		-u ${ANSIBLE_USER} \
		-e env=${ENVIRONMENT} --connection=local

rolling-restart: check-env ## Performs a rolling restart of the Cassandra Cluster
	@${PIPENVCMD} ansible-playbook -i $(INVENTORY) rolling-restart.yml ${EXTRA} \
		-u ${ANSIBLE_USER} \
		-e env=${ENVIRONMENT}

wipe: check-env ## Performs a wipe
	@${PIPENVCMD} ansible-playbook -i $(INVENTORY) wipe.yml ${EXTRA} \
		-u ${ANSIBLE_USER} \
		-e env=${ENVIRONMENT}

stop-nginx: check-env ## Stops nginx on the bastion host
	@${PIPENVCMD} ansible -i $(INVENTORY) -u $(ANSIBLE_USER) -m ansible.builtin.service -a "name=nginx state=stopped" cassandra

start-nginx: check-env ## Stops nginx on the bastion host
	@${PIPENVCMD} ansible -i $(INVENTORY) -u $(ANSIBLE_USER) -m ansible.builtin.service -a "name=nginx state=started" cassandra
