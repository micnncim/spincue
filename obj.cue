package spin

import (
	"list"
	"strings"
)

base: #Base

pipeline: [ID=_]: #Pipeline & {id: ID} & base

spinPipelines: {
	for k, x in pipeline {
		"\(k)": (_spinPipeline & {X: x}).X.spin
	}
}

_spinPipeline: X: spin: {
	name:        X.id
	application: base.application
	stages: [
		for k, x in X.stages {
			if x._type == "deploy" {
				(_stageDeploy & {X: x.deploy} & {X: refId: k} & {X: name: x.name} & {X: kubernetesAccount: base.kubernetesAccount}).X.spin
			}
			if x._type == "manualJudgement" {
				(_stageManualJudgement & {X: x.manualJudgement} & {X: refId: k} & {X: name: x.name}).X.spin
			}
			if x._type == "wait" {
				(_stageWait & {X: x.wait} & {X: refId: k} & {X: name: x.name}).X.spin
			}
		},
	]
	expectedArtifacts: list.FlattenN([
				for k, x in X.stages {
			if x._type == "deploy" {
				[
					(_expectedArtifactDocker & {X: x.deploy} & {X: refId: k}).X.spin,
					(_expectedArtifactGCS & {X:    x.deploy} & {X: refId: k} & {X: gcsAccount: base.gcsAccount}).X.spin,
				]
			}
		},
	], 1)
	triggers: [
		if len(X.triggers) > 0 {
			for k, x in X.triggers {
				if x._type == "docker" {
					for j, y in X.stages {
						if y._type == "deploy" {
							if y.deploy.image == x.docker.image {
								(_triggerDocker & {X: x.docker} & {X: refId: j} & {X: dockerAccount: base.dockerAccount}).X.spin
							}
						}
					}
				}
			}
		},
	]
	notifications: [
		if len(X.notifications) > 0 {
			for k, x in X.notifications {
				(_notificationPipeline & {X: x}).X.spin
			}
		},
	]
	lastModifiedBy: "fake@spincue.io"
}

_stageDeploy: X: spin: {
	type:               "deployManifest"
	name:               X.name
	cloudProvider:      string | *"kubernetes"
	account:            X.kubernetesAccount
	manifestArtifactId: "\(X.refId)-gcs"
	requiredArtifactIds: ["\(X.refId)-docker"]
	refId: "\(X.refId)"
	if X.refId > 0 {
		requisiteStageRefIds: ["\(X.refId-1)"]
	}
	if X.refId <= 0 {
		requisiteStageRefIds: []
	}
}

_stageManualJudgement: X: spin: {
	type:         "manualJudgment"
	name:         X.name
	failPipeline: bool | *true
	refId:        "\(X.refId)"
	if X.refId > 0 {
		requisiteStageRefIds: ["\(X.refId-1)"]
	}
	if X.refId <= 0 {
		requisiteStageRefIds: []
	}
}

_stageWait: X: spin: {
	type:     "wait"
	name:     X.name
	waitTime: X.duration
	refId:    "\(X.refId)"
	if X.refId > 0 {
		requisiteStageRefIds: ["\(X.refId-1)"]
	}
	if X.refId <= 0 {
		requisiteStageRefIds: []
	}
}

_expectedArtifactDocker: X: spin: {
	displayName: X.image
	id:          "\(X.refId)-docker"
	matchArtifact: {
		type:            "docker/image"
		artifactAccount: "docker-registry"
		name:            X.image
		id:              "id"
	}
	defaultArtifact: {
		customKind: bool | *true
		id:         "id"
	}
}

_expectedArtifactGCS: X: spin: {
	displayName: X.manifest
	id:          "\(X.refId)-gcs"
	matchArtifact: {
		type:            "gcs/object"
		artifactAccount: X.gcsAccount
		name:            X.manifest
		id:              "id"
	}
	defaultArtifact: {
		type:            matchArtifact.type
		artifactAccount: matchArtifact.artifactAccount
		name:            X.manifest
		reference:       X.manifest
		id:              "id"
	}
}

_triggerDocker: X: spin: {
	type:    "docker"
	tag:     X.tag
	account: X.dockerAccount
	expectedArtifactIds: ["\(X.refId)-docker"]
	enabled: true

	_slugs: strings.Split(X.image, "/")
	if len(_slugs) == 1 {
		registry:   "docker.io"
		repository: _slugs[0]
	}
	if len(_slugs) > 1 {
		registry:   _slugs[0]
		repository: strings.Join(_slugs[1:], "/")
	}
}

_triggerPubSub: X: spin: {
	type:             "pubsub"
	pubsubSystem:     X.pubsubSystem
	subscriptionName: X.subscriptionName
	payloadConstraints: {
		action: X.action
		tag:    X.tag
	}
	enabled: true
}

_notificationPipeline: X: spin: {
	type:    X.type
	level:   "pipeline"
	address: X.address
	if len(X.messages) > 0 {
		when: [
			for k, x in X.messages {"pipeline.\(k)"},
		]
		message: {
			for k, x in X.messages {
				if x != "" {
					"pipeline.\(k)": text: x
				}
			}
		}
	}
}

_notificationStage: X: spin: {
	type:    X.type
	level:   "stage"
	address: X.address
	if len(X.messages) > 0 {
		when: [
			for k, x in X.messages {"pipeline.\(k)"},
		]
		message: {
			for k, x in X.messages {
				if x != "" {
					"pipeline.\(k)": text: x
				}
			}
		}
	}
}
