#!/bin/bash
source ./scripts/utils/helper.sh
source ./scripts/utils/ccloud_library.sh

## Validations to run this script
ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1

if [ -n "$EMAIL" ]; then
  ccloud::validate_required_params_for_user $EMAIL $ENVIRONMENT_NAME $ROLE || exit 1
  EMAIL_ADDRESS=$(echo "$EMAIL" | awk '{print tolower($0)}')
  echo "$EMAIL_ADDRESS"
else
  ENVIRONMENT_NAME="dev"
  ROLE="CloudClusterAdmin"
  CLUSTER_NAME="cluster_0"
  CLUSTER_CLOUD="azure"
  CLUSTER_REGION="eastus"
  ccloud::validate_required_params_for_user_no_email $ENVIRONMENT_NAME $ROLE || exit 1
  sed -i 's/marks-and-spencer.com/gmail.com/' users.txt
  EDITED=$(grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' users.txt)
  EDITED_EMAIL=$(echo "$EDITED" | awk '{print tolower($0)}')
  EMAIL_ADDRESS="${EDITED_EMAIL//$'\n'/';'}"
  echo "$EMAIL_ADDRESS"
fi

while [ "$EMAIL_ADDRESS" != "$email_addr" ] ;do
  # extract the substring from start of string up to delimiter.
  email_addr=${EMAIL_ADDRESS%%;*}
  # delete this first "element" AND next separator, from $IN.
  EMAIL_ADDRESS="${EMAIL_ADDRESS#$email_addr;}"

  echo "Progressing script for email: $email_addr"
  ## Invites user if user does not exist, else finds the existing user
  EMAIL_EXISTS=$(ccloud admin user list -o json | jq -c -r '.[] | select(.email == "'"$email_addr"'")')
  if [ -z "$EMAIL_EXISTS" ]; then
    ccloud::invite_user $email_addr
  fi

  ## Gets user resource using email address
  USER_RESOURCE_ID=$(ccloud::get_user_resource_by_email $email_addr)
  echo "$USER_RESOURCE_ID"

  ## Gets environment id using environment name
  ENVIRONMENT=$(ccloud::get_environment_from_name $ENVIRONMENT_NAME)
  ccloud::use_environment $ENVIRONMENT

  ## Gets cluster id given the cluster name, cloud provider and cloud region
  if [ -n "$CLUSTER_NAME" ] && [ -n "$CLUSTER_CLOUD" ] && [ -n "$CLUSTER_REGION" ]; then
    CLUSTER_ID=$(ccloud::use_cluster $CLUSTER_NAME $CLUSTER_CLOUD $CLUSTER_REGION)
    echo $CLUSTER_ID
  fi

  ## Sets role for user
  echo "About to set role $ROLE for User $USER_RESOURCE_ID with email $email_addr in environment $ENVIRONMENT"
  if [ "OrganizationAdmin" == $ROLE ] || [ "MetricsViewer" == $ROLE ]; then
    ccloud::set_organization_level_role_for_user $USER_RESOURCE_ID $ROLE
  elif [ "EnvironmentAdmin" == $ROLE ]; then
    ccloud::set_environment_level_role_for_user $USER_RESOURCE_ID $ROLE $ENVIRONMENT
  elif [ "CloudClusterAdmin" == $ROLE ]; then
    ccloud::set_cluster_level_role_for_user $USER_RESOURCE_ID $ROLE $ENVIRONMENT $CLUSTER_ID
  else
    echo "$ROLE is not a valid role. Please retry with one of the valid roles: [OrganizationAdmin or MetricsViewer or EnvironmentAdmin or CloudClusterAdmin]"
  fi
done
