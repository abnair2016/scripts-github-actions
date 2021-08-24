#!/bin/bash
source ../utils/helper.sh
source ../utils/ccloud_library.sh

## Validations to run this script
ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1
ccloud::validate_required_params_for_sa $CLUSTER_NAME $CLUSTER_CLOUD $CLUSTER_REGION $ENVIRONMENT_NAME || exit 1

enable_ksqldb=false
read -p "Do you also want to create a Confluent Cloud ksqlDB app (hourly charges may apply)? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  enable_ksqldb=true
fi

if [[ -z "$ENVIRONMENT_NAME" ]]; then
  STMT=""
else
  ## Gets environment id using environment name
  ENVIRONMENT=$(ccloud::get_environment_from_name $ENVIRONMENT_NAME)
  ccloud::use_environment $ENVIRONMENT
  STMT="PRESERVE_ENVIRONMENT=true"
fi

export EXAMPLE="events-platform-script"

echo
ccloud::create_ccloud_stack $enable_ksqldb || exit 1

echo
echo "Validating..."
echo "Service Account ID: $SERVICE_ACCOUNT_ID"
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
echo "Config File: $CONFIG_FILE"
ccloud::validate_ccloud_config $CONFIG_FILE || exit 1
ccloud::generate_configs $CONFIG_FILE > /dev/null
source delta_configs/env.delta

if $enable_ksqldb ; then
  MAX_WAIT=720
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
  retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT || exit 1
fi

ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE $enable_ksqldb || exit 1

echo
echo "ACLs in this cluster:"
ccloud kafka acl list

echo
echo "Local client configuration file written to $CONFIG_FILE"
echo

echo
echo "To destroy this Confluent Cloud stack run ->"
echo "    $STMT ./destroy-sa.sh $CONFIG_FILE"
echo

echo
echo "Tip: 'ccloud' CLI is already set to the existing environment $ENVIRONMENT"
