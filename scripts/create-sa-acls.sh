#!/bin/bash
source utils/helper.sh
source utils/ccloud_library.sh

# Validations to run this script
ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1

ENV_NAME=$(echo "$ENVIRONMENT_NAME" | awk '{print tolower($0)}')
echo "Environment Name: $ENV_NAME"
ALL_SA_NAMES=$(echo "$SA_NAMES" | awk '{print tolower($0)}')
echo "All Service Account Names: $ALL_SA_NAMES"

ENVIRONMENT_ID=$(ccloud::get_environment_from_name $ENV_NAME)
echo "ENVIRONMENT_ID: $ENVIRONMENT_ID"
#ccloud::use_environment $ENVIRONMENT_ID
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

    # Assign READ ONLY ACLs by default
    confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation READ --consumer-group '*' --environment $ENVIRONMENT_ID --cluster $cluster_id
    confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --consumer-group '*' --environment $ENVIRONMENT_ID --cluster $cluster_id
    confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation READ --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
    confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id

    if [[ $sa_name == *-read_write ]]; then
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation WRITE --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
    elif [[ $sa_name == *-admin ]]; then
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DELETE --consumer-group '*' --environment $ENVIRONMENT_ID --cluster $cluster_id

      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation WRITE --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation CREATE --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation ALTER_CONFIGS --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation ALTER --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DELETE --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE_CONFIGS --topic $prefixed_name --prefix --environment $ENVIRONMENT_ID --cluster $cluster_id

      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE --cluster-scope --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation DESCRIBE_CONFIGS --cluster-scope --environment $ENVIRONMENT_ID --cluster $cluster_id
      confluent kafka acl create --allow --service-account $SA_RESOURCE_ID --operation CLUSTER_ACTION --cluster-scope --environment $ENVIRONMENT_ID --cluster $cluster_id
    fi

  done
done
