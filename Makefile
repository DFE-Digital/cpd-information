ARM_TEMPLATE_TAG=1.1.10
RG_TAGS={"Product" : "Register for National Professional Qualifications (NPQ)"}
REGION=UK South
SERVICE_NAME=cpd-information
SERVICE_SHORT=cpdinf

help:
	@grep -E '^[a-zA-Z\._\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

production:
	$(if $(or ${SKIP_CONFIRM}, ${CONFIRM_PRODUCTION}), , $(error Missing CONFIRM_PRODUCTION=yes))
	$(eval include global_config/production.sh)

domains:
	$(eval include global_config/domains.sh)

composed-variables:
	$(eval RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg)
	$(eval KEYVAULT_NAMES='["${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-kv"]')
	$(eval STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}${CONFIG_SHORT}tfsa)
	$(eval LOG_ANALYTICS_WORKSPACE_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-log)

set-azure-account:
	[ "${SKIP_AZURE_LOGIN}" != "true" ] && az account set -s ${AZURE_SUBSCRIPTION} || true

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: composed-variables set-azure-account
	$(if ${DISABLE_KEYVAULTS},, $(eval KV_ARG=keyVaultNames=${KEYVAULT_NAMES}))
	$(if ${ENABLE_KV_DIAGNOSTICS}, $(eval KV_DIAG_ARG=enableDiagnostics=${ENABLE_KV_DIAGNOSTICS} logAnalyticsWorkspaceName=${LOG_ANALYTICS_WORKSPACE_NAME}),)

	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "${REGION}" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_GROUP_NAME}" 'tags=${RG_TAGS}' \
		"tfStorageAccountName=${STORAGE_ACCOUNT_NAME}" "tfStorageContainerName=terraform-state" \
		${KV_ARG} \
		${KV_DIAG_ARG} \
		"enableKVPurgeProtection=${KV_PURGE_PROTECTION}" \
		${WHAT_IF}

deploy-arm-resources: arm-deployment

validate-arm-resources: set-what-if arm-deployment

domains-infra-init: domains composed-variables set-azure-account
	rm -rf terraform/domains/infrastructure/vendor/modules/domains
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git terraform/domains/infrastructure/vendor/modules/domains

	terraform -chdir=terraform/domains/infrastructure init -reconfigure -upgrade \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=domains_infrastructure.tfstate

domains-infra-plan: domains domains-infra-init ## Terraform plan for DNS infrastructure (zone and front door. Usage: make domains-infra-plan
	terraform -chdir=terraform/domains/infrastructure plan -var-file config/zones.tfvars.json

domains-infra-apply: domains domains-infra-init ## Terraform apply for DNS infrastructure (zone and front door). Usage: make domains-infra-apply
	terraform -chdir=terraform/domains/infrastructure apply -var-file config/zones.tfvars.json ${AUTO_APPROVE}

domains-init: domains composed-variables set-azure-account
	rm -rf terraform/domains/environment_domains/vendor/modules/domains
	git -c advice.detachedHead=false clone --depth=1 --single-branch --branch ${TERRAFORM_MODULES_TAG} https://github.com/DFE-Digital/terraform-modules.git terraform/domains/environment_domains/vendor/modules/domains

	terraform -chdir=terraform/domains/environment_domains init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${ENVIRONMENT}.tfstate

	$(eval export TF_VAR_azure_resource_prefix=${AZURE_RESOURCE_PREFIX})
	$(eval export TF_VAR_config_short=${CONFIG_SHORT})
	$(eval export TF_VAR_service_short=${SERVICE_SHORT})

domains-plan: domains-init ## Terraform plan for DNS environment domains. Usage: make production domains domains-plan
	terraform -chdir=terraform/domains/environment_domains plan -var-file config/${CONFIG}.tfvars.json

domains-apply: domains-init ## Terraform apply for DNS environment domains. Usage: make production domains domains-apply
	terraform -chdir=terraform/domains/environment_domains apply -var-file config/${CONFIG}.tfvars.json ${AUTO_APPROVE}
