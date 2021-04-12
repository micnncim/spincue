package spin

import (
	"encoding/json"
	"tool/exec"
)

command: save: {
	var: {
		pipeline: string       @tag(pipeline)
		dryRun:   bool | *true @tag(dryrun,type=bool)
		config:   string       @tag(config)
	}

	task: spin: exec.Run & {
		cmd: [
			"spin", "pipeline",

			if var.dryRun {
				"plan"
			},
			if !var.dryRun {
				"save"
			},

			if var.config != "" {
				"--config=\(var.config)"
			},
		]
		stdin: json.Marshal(spinPipelines[var.pipeline])
	}
}
