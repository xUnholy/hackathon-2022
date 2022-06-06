package talos

import (
	github "github.com/pulumi/pulumi-github/sdk/v4/go/github"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func GetReleases(ctx *pulumi.Context) (*github.GetReleaseResult, error) {
	release, err := github.GetRelease(ctx, &github.GetReleaseArgs{
		Owner:      "siderolabs",
		Repository: "talos",
		RetrieveBy: "latest",
	}, nil)
	if err != nil {
		return nil, err
	}
	return release, nil
}
