#!/bin/bash
source utils/helper.sh
source utils/ccloud_library.sh

## Validations to run this script
ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1

#if [ -n "$EMAIL" ]; then
#  ccloud::validate_required_params_for_user $EMAIL $ENVIRONMENT_NAME $ROLE || exit 1
#  LOWER_EMAIL_ADDRESS=$(echo "$EMAIL" | awk '{print tolower($0)}')
#  EMAIL_ADDRESS=$(echo "$LOWER_EMAIL_ADDRESS" | sed "s/marks-and-spencer.com/mnscorp.net/g")
#  echo "$EMAIL_ADDRESS"
#else
#  ccloud::validate_required_params_for_user_no_email $ENVIRONMENT_NAME $ROLE || exit 1
#  sed -i 's/marks-and-spencer.com/mnscorp.net/' users.txt
#  EDITED=$(grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' users.txt)
#  EDITED_EMAIL=$(echo "$EDITED" | awk '{print tolower($0)}')
#  EMAIL_ADDRESS="${EDITED_EMAIL//$'\n'/';'}"
#  echo "$EMAIL_ADDRESS"
#fi

ENV_NAME=$(echo "$ENVIRONMENT_NAME" | awk '{print tolower($0)}')
echo "Environment Name: $ENV_NAME"
ALL_SA_NAMES=$(echo "$SA_NAMES" | awk '{print tolower($0)}')
echo "All Service Account Names: $ALL_SA_NAMES"

ENVIRONMENT_ID=$(ccloud::get_environment_from_name $ENV_NAME)
ccloud::use_environment $ENVIRONMENT_ID
CLUSTERS=$(ccloud::get_clusters)

for cluster_id in $(echo "${CLUSTERS}" | jq -r '.[] | .id'); do
  echo "Cluster: $cluster_id"
  echo "Service Account Names: $ALL_SA_NAMES"

  while [ "$ALL_SA_NAMES" != "$sa_name" ] ;do
    # extract the substring from start of string up to delimiter.
    sa_name=${ALL_SA_NAMES%%;*}
    echo "SA_NAME: $sa_name"
    prefixed_name=$( echo "$sa_name" | cut -d - -f -3 )
    echo "PREFIXED_NAME: $prefixed_name"
    # delete this first "element" AND next separator, from $IN.
    ALL_SA_NAMES="${ALL_SA_NAMES#$sa_name;}"
    echo "ALL_SA_NAMES: $ALL_SA_NAMES"

    # Gets service account resource using service account name
    SA_RESOURCE_ID=$(ccloud::get_service_account_resource_by_name $sa_name)
    echo "Service Account: $SA_RESOURCE_ID"

    if [[ $sa_name == *-read_only ]]; then
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation READ --consumer-group '*' --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --consumer-group '*' --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation READ --topic $prefixed_name --prefix --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --topic $prefixed_name --prefix --environment ENVIRONMENT_ID --cluster $cluster_id
    elif [[ $sa_name == *-read_write ]]; then
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation READ --consumer-group '*' --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --consumer-group '*' --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation READ --topic $prefixed_name --prefix --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --topic $prefixed_name --prefix --environment ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation WRITE --topic $prefixed_name --prefix --environment ENVIRONMENT_ID --cluster $cluster_id
    else
      echo "No further ACLS need to be defined"
    fi

    ACL_LIST=$( confluent kafka acl list --service-account $SA_RESOURCE_ID --environment ENVIRONMENT_ID --cluster $cluster_id )

    echo $ACL_LIST

  done
done
#while [ "$EMAIL_ADDRESS" != "$email_addr" ] ;do
#  # extract the substring from start of string up to delimiter.
#  email_addr=${EMAIL_ADDRESS%%;*}
#  # delete this first "element" AND next separator, from $IN.
#  EMAIL_ADDRESS="${EMAIL_ADDRESS#$email_addr;}"
#
#  echo "Progressing script for email: $email_addr"
#  ## Invites user if user does not exist, else finds the existing user
#  EMAIL_EXISTS=$(confluent iam user invitation list -o json | jq -c -r '.[] | select(.email == "'"$email_addr"'")')
#  if [ -z "$EMAIL_EXISTS" ]; then
#    ccloud::invite_user $email_addr
#  fi
#
#  ## Gets user resource using email address
#  USER_RESOURCE_ID=$(ccloud::get_user_resource_by_email $email_addr)
#  echo "User: $USER_RESOURCE_ID"
#
#  ## Gets environment id using environment name
#  ENVIRONMENT_ID=$(ccloud::get_environment_from_name $ENVIRONMENT_NAME)
#  ccloud::use_environment $ENVIRONMENT_ID
#
#  ## Sets role for user
#  echo "About to set role $ROLE for User $USER_RESOURCE_ID with email $email_addr in environment $ENVIRONMENT_ID"
#  if [ "OrganizationAdmin" == $ROLE ] || [ "MetricsViewer" == $ROLE ]; then
#    ccloud::set_organization_level_role_for_user $USER_RESOURCE_ID $ROLE
#  elif [ "EnvironmentAdmin" == $ROLE ]; then
#    ccloud::set_environment_level_role_for_user $USER_RESOURCE_ID $ROLE $ENVIRONMENT_ID
#  elif [ "CloudClusterAdmin" == $ROLE ]; then
#    CLUSTERS=$(ccloud::get_clusters)
#    for cluster_id in $(echo "${CLUSTERS}" | jq -r '.[] | .id'); do
#      echo "Cluster: $cluster_id"
#      ccloud::set_cluster_level_role_for_user $USER_RESOURCE_ID $ROLE $ENVIRONMENT_ID $cluster_id
#    done
#  else
#    echo "$ROLE is not a valid role. Please retry with one of the valid roles: [OrganizationAdmin or MetricsViewer or EnvironmentAdmin or CloudClusterAdmin]"
#  fi
#done
