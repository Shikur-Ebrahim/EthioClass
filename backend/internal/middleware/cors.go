package middleware

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORS returns a CORS middleware.
//
// TODO: Before going to production, restrict AllowOrigins to your actual
// application domains (e.g. https://ethioclass.com, your Flutter web build).
// Do NOT leave AllowAllOrigins = true in production.
func CORS() gin.HandlerFunc {
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true // TODO: restrict before production
	config.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Authorization"}
	return cors.New(config)
}
