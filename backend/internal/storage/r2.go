package storage

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// R2Client wraps the S3-compatible Cloudflare R2 client.
type R2Client struct {
	Client     *s3.Client
	BucketName string
}

// New initialises the Cloudflare R2 S3-compatible client.
// This is NON-FATAL — if R2 is unreachable the server still starts.
func New(accountID, accessKey, secretKey, bucketName string) (*R2Client, error) {
	if accountID == "" || accessKey == "" || secretKey == "" {
		return nil, fmt.Errorf("R2 credentials not set — skipping R2 initialisation")
	}

	r2Endpoint := fmt.Sprintf("https://%s.r2.cloudflarestorage.com", accountID)

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
		config.WithRegion("auto"),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load R2 config: %w", err)
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(r2Endpoint)
		o.UsePathStyle = true
	})

	return &R2Client{
		Client:     client,
		BucketName: bucketName,
	}, nil
}

// Ping performs a minimal connectivity check (HeadBucket).
// Logs the result but does NOT crash the server on failure.
func (r *R2Client) Ping() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.Client.HeadBucket(ctx, &s3.HeadBucketInput{
		Bucket: aws.String(r.BucketName),
	})
	if err != nil {
		log.Printf("[R2] Connectivity check failed (non-fatal): %v", err)
		return
	}
	log.Println("[R2] Cloudflare R2 connected ✓")
}
