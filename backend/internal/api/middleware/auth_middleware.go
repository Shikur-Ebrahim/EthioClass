package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	supa "github.com/supabase-community/supabase-go"
)

func AuthMiddleware(client *supa.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header format must be: Bearer {token}"})
			c.Abort()
			return
		}

		token := parts[1]

		// Validate the JWT token with Supabase Auth
		user, err := client.Auth.WithToken(token).GetUser()
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Attach user ID and token to context for downstream handlers
		c.Set("user_id", user.ID.String())
		c.Set("token", token)
		c.Next()
	}
}
