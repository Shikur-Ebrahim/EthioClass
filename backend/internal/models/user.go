package models

type SignupRequest struct {
	FullName    string `json:"fullName" binding:"required"`
	Email       string `json:"email" binding:"required,email"`
	PhoneNumber string `json:"phoneNumber" binding:"required"`
	Password    string `json:"password" binding:"required,min=6"`
	DeviceId    string `json:"deviceId,omitempty"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	DeviceId string `json:"deviceId,omitempty"`
}

type ResetPasswordRequest struct {
	Email      string `json:"email" binding:"required,email"`
	RedirectTo string `json:"redirectTo,omitempty"`
}

type UpdatePasswordRequest struct {
	Password string `json:"password" binding:"required,min=6"`
}

type UpdateProfileRequest struct {
	FullName    string `json:"fullName" binding:"required"`
	PhoneNumber string `json:"phoneNumber" binding:"required"`
	Email       string `json:"email"`
}
