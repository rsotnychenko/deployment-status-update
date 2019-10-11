#!/bin/ash -xe

if [ "${GITHUB_EVENT_NAME}" != "deployment" ]; then
  echo "Expected GITHUB_EVENT_NAME=deployment, got [${GITHUB_EVENT_NAME}]"
  exit 1
fi

get_from_event() {
  echo "$(jq -r "$1" ${GITHUB_EVENT_PATH})"
}

GITHUB_API_DEPELOYMENTS_URL="$(get_from_event '.deployment.statuses_url')"
GITHUB_ACTIONS_URL="$(get_from_event '.repository.html_url')/actions"

curl --fail \
    -X POST "${GITHUB_API_DEPELOYMENTS_URL}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: text/json; charset=utf-8" \
    -H "Accept: application/vnd.github.ant-man-preview+json, application/vnd.github.flash-preview+json" \
    -d @- <<EOF
{
    "state": "${INPUT_STATUS}",
    "log_url": "${GITHUB_ACTIONS_URL}",
    "description": "${INPUT_DESCRIPTION}",
    "auto_inactive": ${INPUT_AUTO_INACTIVE},
    "environment_url": "${INPUT_ENVIRONMENT_URL}"
}
EOF

echo ::set-output name=deployment_id::$(get_from_event '.deployment.id')
echo ::set-output name=description::$(get_from_event '.deployment.description')
echo ::set-output name=state::${INPUT_STATUS}
echo ::set-output name=ref::$(get_from_event '.deployment.ref')
echo ::set-output name=sha::$(get_from_event '.deployment.sha')
echo ::set-output name=environment::$(get_from_event '.deployment.environment')
echo ::set-output name=payload::$(get_from_event '.deployment.payload')

