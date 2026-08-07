package storage

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type R2Storage struct {
	Client     *s3.Client
	BucketName string
}

func ConnectCloudflareR2(accountID, accessKey, secretKey, bucketName string) (*R2Storage, error) {
	if accountID == "" || accessKey == "" || secretKey == "" {
		log.Println("Cloudflare R2 credentials are not fully set")
		return nil, nil
	}

	r2Resolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL: fmt.Sprintf("https://%s.r2.cloudflarestorage.com", accountID),
		}, nil
	})

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithEndpointResolverWithOptions(r2Resolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
		config.WithRegion("auto"),
	)
	if err != nil {
		return nil, err
	}

	client := s3.NewFromConfig(cfg)
	log.Println("Successfully connected to Cloudflare R2 Storage")

	return &R2Storage{
		Client:     client,
		BucketName: bucketName,
	}, nil
}
