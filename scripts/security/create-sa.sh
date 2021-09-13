#!/bin/bash
source ../utils/helper.sh
source ../utils/ccloud_library.sh

## Validations to run this script
ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1

enable_ksqldb=false
SERVICE_ACCOUNT_NAME=$1
ACCESS=${ACCESS:-"DEV"}

if [[ -z "$ENVIRONMENT_NAME" ]]; then
  echo
  echo "Environment name is a required input parameter. Please retry using: ENVIRONMENT_NAME=<environment name> ./create-sa.sh <service-account-name>"
  exit 1
fi

## Gets environment id using environment name
ENVIRONMENT=$(ccloud::get_environment_from_name $ENVIRONMENT_NAME)
ccloud::use_environment $ENVIRONMENT

CLUSTER_NAME=$(ccloud::get_cluster_name)
CLUSTER_CLOUD=$(ccloud::get_cluster_provider)
CLUSTER_REGION=$(ccloud::get_cluster_region)

ccloud::use_cluster $CLUSTER_NAME $CLUSTER_CLOUD $CLUSTER_REGION

export EXAMPLE="events-platform-script"
export SERVICE_NAME="$SERVICE_ACCOUNT_NAME"
export CLUSTER_NAME="$CLUSTER_NAME"
export CLUSTER_CLOUD="$CLUSTER_CLOUD"
export CLUSTER_REGION="$CLUSTER_REGION"

echo
ccloud::create_service_account_and_permissions $enable_ksqldb $ENVIRONMENT_NAME $ACCESS || exit 1

echo
echo "Validating..."
echo "Service Account ID: $SERVICE_ACCOUNT_ID"
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
echo "Config File: $CONFIG_FILE"
ccloud::validate_ccloud_config $CONFIG_FILE || exit 1
ccloud::generate_configs $CONFIG_FILE > /dev/null
source delta_configs/env.delta

ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE $enable_ksqldb || exit 1

echo
echo "ACLs in this cluster:"
ccloud kafka acl list

echo
echo "Local client configuration file written to $CONFIG_FILE"
echo

echo
echo "To destroy this Confluent Cloud stack run ->"
if [ "${ACCESS}" == "DEV" ]; then
  echo "    ENVIRONMENT_NAME=$ENVIRONMENT_NAME ./destroy-sa.sh $CONFIG_FILE"
else
  echo "    ACCESS=$ACCESS ENVIRONMENT_NAME=$ENVIRONMENT_NAME ./destroy-sa.sh $CONFIG_FILE"
fi
echo
echo
echo "Tip: 'ccloud' CLI is already set to the existing environment $ENVIRONMENT"
