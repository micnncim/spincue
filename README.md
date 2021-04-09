# spincue

Spinnaker pipeline templates implemented by pure CUE.

*This is still experimental implementation, not guaranteeing production usage and can make breaking changes.*

## Commands

### save

`save` command runs `spin` command with CUE files.

- Save a pipeline:
    ```console
    $ cue -t pipeline=$PIPELINE -t dryrun=false save ./...
    ```
- Plan a pipeline:
    ```console
    $ cue -t pipeline=$PIPELINE save ./...
    ```
### dump

`dump` command displays a raw pipeline with JSON format.

- Dump a pipeline:
    ```console
    $ cue -t pipeline=$PIPELINE dump ./...
    ```

## Examples

```cue
pipeline: minimal: stages: [{manualJudgement: {}}]
```

<details>
<summary>JSON</summary>

```json
{
  "stages": [
    {
      "type": "manualJudgment",
      "name": "Manual Judgement",
      "failPipeline": true,
      "requisiteStageRefIds": [],
      "refId": "0"
    }
  ],
  "expectedArtifacts": [
    {}
  ],
  "triggers": [],
  "notifications": [],
  "lastModifiedBy": "fake@spincue.io"
}
```

</details>

```cue
base: {
    dockerAccount:     "docker-account-1"
    kubernetesAccount: "kubernetes-account-1"
    gcsAccount:        "gcs-account-1"
}

pipeline: nginx: {
    stages: [
        {
            manualJudgement: {}
        },
        {
            name: "Deploy app"
            deploy: {
                image:    "nginx"
                manifest: "gs://spincue/nginx/manifest.yaml"
            }
        },
        {
            wait: duration: 60
        },
    ]

    triggers: [{docker: image: "nginx"}]

    notifications: [{
        address: "development"
        messages: {
            complete: "Deploy complete!"
            failed:   "Deploy failed!"
        }
    }]
}
```

<details>
<summary>JSON</summary>

```json
{
  "stages": [
    {
      "type": "manualJudgment",
      "name": "Manual Judgement",
      "failPipeline": true,
      "requisiteStageRefIds": [],
      "refId": "0"
    },
    {
      "type": "deployManifest",
      "name": "Deploy app",
      "cloudProvider": "kubernetes",
      "account": "kubernetes-account-1",
      "manifestArtifactId": "1-gcs",
      "requiredArtifactIds": [
        "1-docker"
      ],
      "requisiteStageRefIds": [
        "0"
      ],
      "refId": "1"
    },
    {
      "type": "wait",
      "name": "Wait 60s",
      "waitTime": 60,
      "requisiteStageRefIds": [
        "1"
      ],
      "refId": "2"
    }
  ],
  "expectedArtifacts": [
    {},
    {
      "displayName": "nginx",
      "id": "1-docker",
      "matchArtifact": {
        "type": "docker/image",
        "artifactAccount": "docker-registry",
        "name": "nginx",
        "id": "id"
      },
      "defaultArtifact": {
        "customKind": true,
        "id": "id"
      }
    },
    {
      "displayName": "gs://spincue/nginx/manifest.yaml",
      "id": "1-gcs",
      "matchArtifact": {
        "type": "gcs/object",
        "artifactAccount": "gcs-account-1",
        "name": "gs://spincue/nginx/manifest.yaml",
        "id": "id"
      },
      "defaultArtifact": {
        "type": "gcs/object",
        "artifactAccount": "gcs-account-1",
        "name": "gs://spincue/nginx/manifest.yaml",
        "reference": "gs://spincue/nginx/manifest.yaml",
        "id": "id"
      }
    },
    {}
  ],
  "triggers": [
    {
      "type": "docker",
      "tag": ".*",
      "account": "docker-account-1",
      "expectedArtifactIds": [
        "1-docker"
      ],
      "enabled": true,
      "registry": "docker.io",
      "repository": "nginx"
    }
  ],
  "notifications": [
    {
      "type": "slack",
      "level": "pipeline",
      "when": [
        "pipeline.complete",
        "pipeline.failed"
      ],
      "address": "development",
      "message": {
        "pipeline.complete": {
          "text": "Deploy complete!"
        },
        "pipeline.failed": {
          "text": "Deploy failed!"
        }
      }
    }
  ],
  "lastModifiedBy": "fake@spincue.io"
}
```

</details>
