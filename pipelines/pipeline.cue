package spin

base: {
	dockerAccount:     "docker-account-1"
	kubernetesAccount: "kubernetes-account-1"
	gcsAccount:        "gcs-account-1"
}

pipeline: minimal: stages: [{manualJudgement: {}}]

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
