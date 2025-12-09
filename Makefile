.PHONY: help init plan apply destroy validate fmt clean

.DEFAULT_GOAL := help

TERRAFORM := terraform
TF_VARS_FILE := terraform.tfvars

## help: Show this help message
help:
	@echo 'Usage:'
	@echo '  make <target>'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## init: Initialize Terraform
init:
	@echo "Initializing Terraform..."
	@$(TERRAFORM) init

## validate: Validate configuration
validate:
	@echo "Validating..."
	@$(TERRAFORM) validate

## fmt: Format Terraform files
fmt:
	@echo "Formatting..."
	@$(TERRAFORM) fmt -recursive

## plan: Generate execution plan
plan:
	@echo "Planning..."
	@$(TERRAFORM) plan -out=tfplan

## apply: Apply the plan
apply:
	@echo "Applying..."
	@$(TERRAFORM) apply tfplan

## destroy: Destroy infrastructure
destroy:
	@echo "Destroying..."
	@$(TERRAFORM) destroy

## clean: Remove Terraform files
clean:
	@echo "Cleaning..."
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f tfplan

## setup: Copy example files
setup:
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "Created terraform.tfvars"; \
	fi
	@if [ ! -f backend.tf ]; then \
		cp backend.tf.example backend.tf; \
		echo "Created backend.tf"; \
	fi

## migrate-provider-v1: Migrate to provider v1.0
migrate-provider-v1:
	@./scripts/migrate-provider-v1.sh

## show-provider-info: Display provider information
show-provider-info:
	@echo "Provider Information:"
	@grep -A 3 "octopusdeploy" terraform/versions.tf
