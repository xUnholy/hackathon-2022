package talos

import (
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/storage"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// TalosImageSync should get all available releases of Talos and ensure they're stored in the GCS bucket
func TalosImageSync(ctx *pulumi.Context) (*storage.Bucket, error) {
	bucket, err := storage.NewBucket(ctx, "talos-images", &storage.BucketArgs{
		Location: pulumi.String("ASIA"),
	})
	if err != nil {
		return nil, err
	}

	release, err := GetLatestRelease(ctx)
	if err != nil {
		return nil, err
	}

	ctx.Export("bucketName", bucket.Url)
	ctx.Export("releaseName", pulumi.String(release.Name))

	return bucket, nil
}
