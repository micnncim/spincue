package spin

#Base: {
	dockerAccount?:     string
	kubernetesAccount?: string
	gcsAccount?:        string
	...
}

#Pipeline: {
	#Base

	id: string

	stages: [...#Stage]
	triggers: [...#Trigger]
	notifications: [...#NotificationPipeline]
	...
}

#Stage: #StageDeploy | #StageManualJudgement | #StageWait

// StageDeploy represent the stage "deployManifest".
#StageDeploy: {
	_type: "deploy"
	name:  string | *"Deploy \(deploy.image)"

	deploy: {
		image:    string
		manifest: string
	}
}

// StageManualJudgement represent the stage "manualJudgment".
#StageManualJudgement: {
	_type: "manualJudgement"
	name:  string | *"Manual Judgement"

	manualJudgement: {}
}

// StageWait represent the stage "wait".
#StageWait: {
	_type: "wait"
	name:  string | *"Wait \(wait.duration)s"

	wait: duration: int | *30
}

#Trigger: #TriggerDocker | #TriggerPubSub

#TriggerDocker: {
	_type: "docker"

	docker: {
		tag:   string | *".*"
		image: string
	}
}

#TriggerPubSub: {
	_type: "pubsub"

	pubsub: {
		pubsubSystem:     string | *"google"
		action:           string | *"INSERT"
		tag:              string
		subscriptionName: string
	}
}

#Notification: {
	type:    #NotificationType
	address: string
	...
}

#NotificationPipeline: {
	#Notification

	messages: [#NotificationPipelineWhen]: string
}

#NotificationStage: {
	#Notification

	messages: [#NotificationStageWhen]: string
}

#NotificationType: string | "email" | *"slack" | "microsoftteams" | "twilio"

#NotificationPipelineWhen: "starting" | "complete" | "failed"

#NotificationStageWhen: string
