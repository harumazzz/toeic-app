package uploader

import (
	"context"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
	"github.com/toeic-app/internal/config"
)

type CloudinaryUploader struct {
	cld *cloudinary.Cloudinary
}

func NewCloudinaryUploader(cfg config.Config) (*CloudinaryUploader, error) {
	cld, err := cloudinary.NewFromURL(cfg.CloudinaryURL)
	if err != nil {
		return nil, err
	}
	return &CloudinaryUploader{cld: cld}, nil
}

func (cu *CloudinaryUploader) UploadImage(ctx context.Context, file interface{}, filename string) (string, error) {
	uploadParams := uploader.UploadParams{
		PublicID: filename,
	}

	uploadResult, err := cu.cld.Upload.Upload(ctx, file, uploadParams)
	if err != nil {
		return "", err
	}
	return uploadResult.SecureURL, nil
}

func (cu *CloudinaryUploader) UploadAudio(ctx context.Context, file interface{}, filename string) (string, error) {
	uploadParams := uploader.UploadParams{
		PublicID:     filename,
		ResourceType: "video", // Cloudinary uses "video" for audio files as well
	}

	uploadResult, err := cu.cld.Upload.Upload(ctx, file, uploadParams)
	if err != nil {
		return "", err
	}
	return uploadResult.SecureURL, nil
}
