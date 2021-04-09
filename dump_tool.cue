package spin

import (
	"encoding/json"
	"tool/cli"
)

command: dump: {
	var: {
		pipeline: string @tag(pipeline)
	}

	task: print: cli.Print & {
		text: json.Marshal(spinPipelines[var.pipeline])
	}
}
