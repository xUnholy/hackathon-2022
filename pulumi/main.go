package main

import (
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"

	"github.com/xunholy/hackathon-2022/pkg/talos"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		// Create a GCP resource (Storage Bucket)
		_, err := talos.TalosImageSync(ctx)
		if err != nil {
			return err
		}

		return nil
	})
}
