#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Source library
source $DIR/../utils/helper.sh
source $DIR/../utils/ccloud_library.sh

ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1
check_jq || exit 1

if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './ccloud_stack_create.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  CONFIG_FILE=$1
fi

if [[ -z "$ENVIRONMENT_NAME" ]]; then
  echo
  echo "Environment name is a required input parameter. Please retry using: ENVIRONMENT_NAME=<environment name> ./destroy-sa.sh stack-configs/<service_account_id.config>"
  exit 1
fi

ACCESS=${ACCESS:-"DEV"}
ccloud::validate_ccloud_config $CONFIG_FILE || exit 1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
ccloud::generate_configs $CONFIG_FILE > /dev/null
source delta_configs/env.delta
SERVICE_ACCOUNT_ID=$(ccloud::get_service_account $CLOUD_KEY) || exit 1

echo
ccloud::delete_service_account_and_permissions $SERVICE_ACCOUNT_ID $ENVIRONMENT_NAME $ACCESS
