package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// GetCourseReviewsHandler returns all reviews for a course with rating summary
func GetCourseReviewsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		courseID := c.Param("id")
		if courseID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Course ID is required"})
			return
		}

		// Get reviews
		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, user_name, rating, comment, created_at
			 FROM reviews
			 WHERE course_id = $1
			 ORDER BY created_at DESC
			 LIMIT 50`, courseID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch reviews"})
			return
		}
		defer rows.Close()

		type Review struct {
			ID        string    `json:"id"`
			UserName  string    `json:"user_name"`
			Rating    int       `json:"rating"`
			Comment   string    `json:"comment"`
			CreatedAt time.Time `json:"created_at"`
		}

		reviews := []Review{}
		starCounts := [6]int{} // index 1-5
		totalRating := 0.0

		for rows.Next() {
			var r Review
			var comment sql.NullString
			if err := rows.Scan(&r.ID, &r.UserName, &r.Rating, &comment, &r.CreatedAt); err != nil {
				continue
			}
			if comment.Valid {
				r.Comment = comment.String
			}
			reviews = append(reviews, r)
			if r.Rating >= 1 && r.Rating <= 5 {
				starCounts[r.Rating]++
				totalRating += float64(r.Rating)
			}
		}

		// Calculate average - default 4.89 if no reviews
		avgRating := 4.89
		if len(reviews) > 0 {
			avgRating = totalRating / float64(len(reviews))
			// Round to 2 decimal places
			avgRating = float64(int(avgRating*100+0.5)) / 100
		}

		c.JSON(http.StatusOK, gin.H{
			"reviews":      reviews,
			"avg_rating":   avgRating,
			"total_reviews": len(reviews),
			"star_counts": gin.H{
				"5": starCounts[5],
				"4": starCounts[4],
				"3": starCounts[3],
				"2": starCounts[2],
				"1": starCounts[1],
			},
		})
	}
}

// SubmitCourseReviewHandler allows a user to submit a review
func SubmitCourseReviewHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		courseID := c.Param("id")
		if courseID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Course ID is required"})
			return
		}

		var body struct {
			UserName string `json:"user_name"`
			Rating   int    `json:"rating"`
			Comment  string `json:"comment"`
		}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		if body.Rating < 1 || body.Rating > 5 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Rating must be between 1 and 5"})
			return
		}

		if body.UserName == "" {
			body.UserName = "Anonymous"
		}

		_, err := db.ExecContext(c.Request.Context(),
			`INSERT INTO reviews (course_id, user_name, rating, comment)
			 VALUES ($1, $2, $3, $4)`,
			courseID, body.UserName, body.Rating, body.Comment)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to submit review: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Review submitted successfully"})
	}
}
