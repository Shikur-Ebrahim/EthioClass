package storage

import (
	"context"
	"fmt"
	"mime/multipart"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	appConfig "github.com/EthioClass/backend/internal/config"
)

type R2Service struct {
	client     *s3.Client
	presignCli *s3.PresignClient
	bucketName string
	accountID  string
}

func NewR2Service(cfg *appConfig.Config) (*R2Service, error) {
	// Cloudflare R2 requires a custom endpoint resolver
	r2Resolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL: fmt.Sprintf("https://%s.r2.cloudflarestorage.com", cfg.R2AccountID),
		}, nil
	})

	awsCfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithEndpointResolverWithOptions(r2Resolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(cfg.R2AccessKey, cfg.R2SecretKey, "")),
		config.WithRegion("auto"), // R2 uses "auto" for region
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config for R2: %w", err)
	}

	client := s3.NewFromConfig(awsCfg)
	presignCli := s3.NewPresignClient(client)

	return &R2Service{
		client:     client,
		presignCli: presignCli,
		bucketName: cfg.R2BucketName,
		accountID:  cfg.R2AccountID,
	}, nil
}

// UploadFile uploads a file stream to R2
func (s *R2Service) UploadFile(ctx context.Context, file multipart.File, objectKey string, contentType string) error {
	_, err := s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(objectKey),
		Body:        file,
		ContentType: aws.String(contentType),
	})
	return err
}

// GeneratePresignedURL generates a temporary URL to access the private file
func (s *R2Service) GeneratePresignedURL(ctx context.Context, objectKey string, expiration time.Duration) (string, error) {
	req, err := s.presignCli.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(objectKey),
	}, s3.WithPresignExpires(expiration))

	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}
	return req.URL, nil
}
