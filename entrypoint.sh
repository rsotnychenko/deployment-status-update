#!/bin/ash -xe

get_from_event() {
  jq -r "$1" "${GITHUB_EVENT_PATH}"
}

# Test required inputs are set
if [ -z "${INPUT_STATUS}" ]; then
  echo "Missing input status"
  exit 1
fi
if [ -z "${INPUT_RUN_ID:-}" ]; then
    echo "Missing input run_id"
    exit 1
fi
if [ -n "${INPUT_DEPLOYMENT_STATUS_URL:-}" ]; then
    GITHUB_API_DEPLOYMENTS_URL=$INPUT_DEPLOYMENT_STATUS_URL
else
    GITHUB_API_DEPLOYMENTS_URL="$(get_from_event '.deployment.statuses_url')"
    if [ "$GITHUB_API_DEPLOYMENTS_URL" = "null" ]; then
      echo "Couldn't detect deployment URL from the GitHub Actions workflow event. If you aren't running from a 'deployment' event, you must set the 'deployment_status_url' input."
      exit 1
    fi
fi

# Set variables
GITHUB_ACTIONS_RUN_URL="$(get_from_event '.repository.html_url')/actions/runs/$INPUT_RUN_ID"
INPUT_STATUS=$(echo "$INPUT_STATUS" | tr '[:upper:]' '[:lower:]')
if [ "$INPUT_STATUS" = cancelled ] ; then
    echo "Rewriting status from cancelled to error"
    INPUT_STATUS=error
fi

curl --fail \
    -X POST "${GITHUB_API_DEPLOYMENTS_URL}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: text/json; charset=utf-8" \
    -H "Accept: application/vnd.github.ant-man-preview+json, application/vnd.github.flash-preview+json" \
    -d @- <<EOF
{
    "state": "${INPUT_STATUS}",
    "log_url": "${GITHUB_ACTIONS_RUN_URL}",
    "description": "${INPUT_DESCRIPTION}",
    "auto_inactive": ${INPUT_AUTO_INACTIVE},
    "environment_url": "${INPUT_ENVIRONMENT_URL}"
}
EOF

echo "deployment_id=$(get_from_event '.deployment.id')" >> $GITHUB_OUTPUT
echo "description=$(get_from_event '.deployment.description')" >> $GITHUB_OUTPUT
echo "state=${INPUT_STATUS}" >> $GITHUB_OUTPUT
echo "ref=$(get_from_event '.deployment.ref')" >> $GITHUB_OUTPUT
echo "sha=$(get_from_event '.deployment.sha')" >> $GITHUB_OUTPUT
echo "environment=$(get_from_event '.deployment.environment')" >> $GITHUB_OUTPUT
echo "payload=$(get_from_event '.deployment.payload')" >> $GITHUB_OUTPUT
