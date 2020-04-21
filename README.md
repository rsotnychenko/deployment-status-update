# Deployment Status Update Action

This action lets you easily update status of a Deployment on GitHub. Learn more at [GitHub Documentation](https://developer.github.com/v3/repos/deployments/#create-a-deployment-status).

## Action inputs

| Name            | Required | Default value  | Description                                                                                                                                                                                                                                               |
|-----------------|----------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| run_id          | **yes**  |                | Set this to `${{ github.run_id }}` so the deployment status log URL can be properly set.                                                                                                                                                                  |
| status          | no       | `in_progress`  | Desired status of the Deployment. Can be one of `error`, `failure`, `inactive`, `in_progress`, `queued`, `pending` or `success`                                                                                                                           |
| description     | no       | <empty string> | A short description of the status. The maximum description length is 140 characters.                                                                                                                                                                      |
| auto_inactive   | no       | true           | Adds a new inactive status to all prior non-transient, non-production environment deployments with the same repository and environment name as the created status's deployment. An inactive status is only added to deployments that had a success state. |
| environment_url | no       | <empty string> | Sets the URL for accessing your environment.                                                                                                                                                                                                              |
| deployment_status_url | no       | (loaded from event) | Explicitly specify the deployment status URL to post the deployment status to. Normally, this will be auto-detected from the GitHub Actions [`DeploymentEvent`](https://developer.github.com/v3/activity/events/types/#deploymentevent) payload. However, if you are runnning from another event type or want to override the deployment to update, you can manually specify the full `https://api.github.com/repos/:owner/:repo/deployments/:deployment_id/statuses` URL here. |

## Action outputs

| Name          | Sample value                             | Description                              |
|---------------|------------------------------------------|------------------------------------------|
| deployment_id | 172882398                                | An ID of the deployment in GitHub        |
| description   | A sample deployment                      | Description of the deployment            |
| state         | queued                                   | Deployment state                         |
| ref           | release/1.0.62                           | Branch/tag name of the deployment source |
| sha           | 1c13ba1c6fbebaf06f188e2b1704fe1706204ef4 | Revision of the deployment source        |
| environment   | production                               | Environment name                         |
| payload       | {"canary": "false"}                      | Payload                                  |

## Example
This example demonstrates a simple delivery pipeline that updates deployment status.

```yml
name: Delivery pipeline

on: [deployment]

jobs:
  deploy:
    runs-on: ubuntu-18.04
    steps:
      - uses: actions/checkout@v1
      - id: set_state_in_progress
        name: Set deployment status to [in_progress]
        uses: rsotnychenko/deployment-status-update@0.2.0
        with:
          run_id: ${{ github.run_id }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Deploy to GAE
        uses: exelban/gcloud@264.0.0
        env:
          PROJECT_ID: ${{ secrets.GCLOUD_PROJECT }}
          APPLICATION_CREDENTIALS: ${{ secrets.GCLOUD_TOKEN }}
        with:
          args: app deploy
      - id: set_state_final
        if: always()
        name: Set deployment status
        uses: rsotnychenko/deployment-status-update@0.2.0
        with:
          status: ${{ job.status }}
          run_id: ${{ github.run_id }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      # TODO: Add rollback operations

```
