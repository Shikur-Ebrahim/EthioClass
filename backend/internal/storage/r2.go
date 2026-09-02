package storage

import (
	"context"
	"fmt"
	"io"
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
	AccountID  string
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
		AccountID:  accountID,
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

// UploadFile uploads a file to R2 and returns only the object key (relative path).
// The full URL is constructed by the caller or served via the /media/ proxy endpoint.
func (r *R2Client) UploadFile(ctx context.Context, file io.Reader, key string, contentType string) (string, error) {
	if r.Client == nil {
		return "", fmt.Errorf("R2 client not initialized")
	}

	_, err := r.Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(r.BucketName),
		Key:         aws.String(key),
		Body:        file,
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to R2: %w", err)
	}

	// Return just the key; full URL is served via GET /media/*key
	return key, nil
}

// GeneratePresignedURL generates a temporary upload URL for a specific key.
func (r *R2Client) GeneratePresignedURL(ctx context.Context, key string, contentType string, expire time.Duration) (string, error) {
	if r.Client == nil {
		return "", fmt.Errorf("R2 client not initialized")
	}

	presignClient := s3.NewPresignClient(r.Client)

	req, err := presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(r.BucketName),
		Key:         aws.String(key),
		ContentType: aws.String(contentType),
	}, func(opts *s3.PresignOptions) {
		opts.Expires = expire
	})

	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return req.URL, nil
}


// GetObject streams an object from R2 by key and returns its size.
func (r *R2Client) GetObject(ctx context.Context, key string) (io.ReadCloser, string, int64, error) {
	if r.Client == nil {
		return nil, "", 0, fmt.Errorf("R2 client not initialized")
	}

	result, err := r.Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(r.BucketName),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, "", 0, fmt.Errorf("failed to get object from R2: %w", err)
	}

	contentType := "application/octet-stream"
	if result.ContentType != nil {
		contentType = *result.ContentType
	}

	var size int64 = -1
	if result.ContentLength != nil {
		size = *result.ContentLength
	}

	return result.Body, contentType, size, nil
}

// HeadObject retrieves metadata for an object without downloading its body.
func (r *R2Client) HeadObject(ctx context.Context, key string) (string, int64, error) {
	if r.Client == nil {
		return "", 0, fmt.Errorf("R2 client not initialized")
	}

	result, err := r.Client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(r.BucketName),
		Key:    aws.String(key),
	})
	if err != nil {
		return "", 0, fmt.Errorf("failed to head object from R2: %w", err)
	}

	contentType := "application/octet-stream"
	if result.ContentType != nil {
		contentType = *result.ContentType
	}

	var size int64 = -1
	if result.ContentLength != nil {
		size = *result.ContentLength
	}

	return contentType, size, nil
}
