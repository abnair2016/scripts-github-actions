export XX_CCLOUD_EMAIL=$CCLOUD_EMAIL
export XX_CCLOUD_PASSWORD=$CCLOUD_PASSWORD

unzip \*.zip
chmod +x kafka-gitops
mv kafka-gitops /usr/local/bin

#mkdir ccloud
#curl -L --http1.1 https://cnfl.io/ccloud-cli | sh -s -- -b ./ccloud
#export PATH=./ccloud:$PATH;
#ccloud login

export CCLOUD_MIN_VERSION=2.0.0
export CONFLUENT_CLOUD_EMAIL=${{ secrets.CCLOUD_EMAIL }}
export CONFLUENT_CLOUD_PASSWORD=${{ secrets.CCLOUD_PASSWORD }}

mkdir confluent
curl -sL --http1.1 https://cnfl.io/cli | sh -s -- -b ./confluent v2.3.1
export PATH=./confluent:$PATH;
confluent login

VALIDATE_STATE=$(kafka-gitops --no-delete --file state.yaml validate)
echo "State file validation status: $VALIDATE_STATE"
if [[ "$VALIDATE_STATE" =~ .*"[VALID]".* ]]; then
  kafka-gitops --no-delete --file state.yaml validate
else
  echo "Error occurred during State file validation: $VALIDATE_STATE"
  exit 1
fi

SA_CREATED_STATE=$(kafka-gitops account)
if [[ "$SA_CREATED_STATE" =~ .*"[SUCCESS] Successfully created service account".* ]]; then
  echo "Service account creation status: $SA_CREATED_STATE"
elif [[ "$SA_CREATED_STATE" =~ .*"[SUCCESS] No service accounts were created as there are no new service accounts.".* ]]; then
  echo "Service account creation status: SKIPPED. Service accounts already exist."
else
  echo "Error occurred during service account creation: $SA_CREATED_STATE"
  exit 1
fi

PLAN_OUTPUT_STATE=$(kafka-gitops --no-delete --file state.yaml plan -o plan.json)
if [[ "$PLAN_OUTPUT_STATE" =~ .*"[ERROR]".* ]]; then
  echo "Deploy status: ERROR occurred during plan output creation: $PLAN_OUTPUT_STATE"
  exit 1
elif [[ "$PLAN_OUTPUT_STATE" =~ .*"There are no necessary changes; the actual state matches the desired state.".* ]]; then
  echo "Deploy status: SKIPPED. Actual state matches the desired state."
else
  echo "Executing plan and applying state..."
  kafka-gitops --no-delete --file state.yaml plan -o plan.json
  kafka-gitops --no-delete --file state.yaml apply -p plan.json
  echo "Successfully completed executing plan and applying state"
fi
