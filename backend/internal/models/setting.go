package models

type UserSettings struct {
	Theme              string `json:"theme"`
	DownloadQuality    string `json:"downloadQuality"`
	PushNotifications  bool   `json:"pushNotifications"`
	EmailNotifications bool   `json:"emailNotifications"`
	Language           string `json:"language"`
}
