package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

type AddLessonBookmarkReq struct {
	UserID    string `json:"user_id" binding:"required"`
	LessonID  string `json:"lesson_id" binding:"required"`
	CourseID  string `json:"course_id" binding:"required"`
	ChapterID string `json:"chapter_id" binding:"required"`
}

type AddCourseBookmarkReq struct {
	UserID   string `json:"user_id" binding:"required"`
	CourseID string `json:"course_id" binding:"required"`
}

type BookmarkCourseRow struct {
	ID              string  `json:"id"`
	CategoryID      string  `json:"category_id"`
	CategoryName    *string `json:"category_name"`
	Title           string  `json:"title"`
	Description     string  `json:"description"`
	InstructorName  string  `json:"instructor_name"`
	ThumbnailURL    *string `json:"thumbnail_url"`
	LessonCount     int     `json:"lesson_count"`
	DurationMinutes int     `json:"duration_minutes"`
}

// AddLessonBookmarkHandler adds a lesson to bookmarks
func AddLessonBookmarkHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		var req AddLessonBookmarkReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(),
			`INSERT INTO bookmarked_lessons (user_id, lesson_id, course_id, chapter_id) VALUES ($1, $2, $3, $4) ON CONFLICT (user_id, lesson_id) DO NOTHING`,
			req.UserID, req.LessonID, req.CourseID, req.ChapterID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to bookmark lesson: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Lesson bookmarked successfully"})
	}
}

// RemoveLessonBookmarkHandler removes a lesson from bookmarks
func RemoveLessonBookmarkHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		userID := c.Query("user_id")
		lessonID := c.Param("id")

		if userID == "" || lessonID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user_id and lesson_id are required"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(),
			`DELETE FROM bookmarked_lessons WHERE user_id = $1 AND lesson_id = $2`,
			userID, lessonID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove bookmark: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Lesson bookmark removed"})
	}
}

// AddCourseBookmarkHandler adds a course to bookmarks
func AddCourseBookmarkHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		var req AddCourseBookmarkReq
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(),
			`INSERT INTO bookmarked_courses (user_id, course_id) VALUES ($1, $2) ON CONFLICT (user_id, course_id) DO NOTHING`,
			req.UserID, req.CourseID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to bookmark course: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Course bookmarked successfully"})
	}
}

// RemoveCourseBookmarkHandler removes a course from bookmarks
func RemoveCourseBookmarkHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		userID := c.Query("user_id")
		courseID := c.Param("id")

		if userID == "" || courseID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user_id and course_id are required"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(),
			`DELETE FROM bookmarked_courses WHERE user_id = $1 AND course_id = $2`,
			userID, courseID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove bookmark: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Course bookmark removed"})
	}
}

// GetBookmarksHandler returns all bookmarked courses and lessons for a user
func GetBookmarksHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		userID := c.Query("user_id")
		if userID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
			return
		}

		// 1. Fetch bookmarked courses
		cRows, err := db.QueryContext(c.Request.Context(),
			`SELECT c.id, c.category_id, cat.name as category_name, c.title, c.description, 
			        c.instructor_name, c.thumbnail_url, c.lesson_count, c.duration_minutes
			 FROM bookmarked_courses bc
			 JOIN courses c ON bc.course_id = c.id
			 LEFT JOIN categories cat ON c.category_id = cat.id
			 WHERE bc.user_id = $1 ORDER BY bc.created_at DESC`, userID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch course bookmarks: " + err.Error()})
			return
		}
		defer cRows.Close()

		var courses []BookmarkCourseRow
		for cRows.Next() {
			var course BookmarkCourseRow
			var catName sql.NullString
			if err := cRows.Scan(&course.ID, &course.CategoryID, &catName, &course.Title, &course.Description, 
				&course.InstructorName, &course.ThumbnailURL, &course.LessonCount, &course.DurationMinutes); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse course: " + err.Error()})
				return
			}
			if catName.Valid {
				course.CategoryName = &catName.String
			}
			courses = append(courses, course)
		}
		if courses == nil { courses = []BookmarkCourseRow{} }

		// 2. Fetch bookmarked lessons (with course/chapter details)
		lRows, err := db.QueryContext(c.Request.Context(),
			`SELECT l.id, l.chapter_id, l.title, l.thumbnail_url, l.video_url, l.notes_url, 
			        l.lesson_number, l.duration_minutes, l.created_at,
			        c.title as course_title, c.thumbnail_url as course_thumb, ch.title as chapter_title
			 FROM bookmarked_lessons bl
			 JOIN lessons l ON bl.lesson_id = l.id
			 JOIN courses c ON bl.course_id = c.id
			 JOIN chapters ch ON bl.chapter_id = ch.id
			 WHERE bl.user_id = $1 ORDER BY bl.created_at DESC`, userID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch lesson bookmarks: " + err.Error()})
			return
		}
		defer lRows.Close()

		type BookmarkedLessonRow struct {
			LessonRow
			CourseTitle        string  `json:"course_title"`
			CourseThumbnailURL *string `json:"course_thumbnail_url"`
			ChapterTitle       string  `json:"chapter_title"`
		}

		var lessons []BookmarkedLessonRow
		for lRows.Next() {
			var l BookmarkedLessonRow
			if err := lRows.Scan(&l.ID, &l.ChapterID, &l.Title, &l.ThumbnailURL, &l.VideoURL, &l.NotesURL, 
				&l.LessonNumber, &l.DurationMinutes, &l.CreatedAt,
				&l.CourseTitle, &l.CourseThumbnailURL, &l.ChapterTitle); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse lesson: " + err.Error()})
				return
			}
			lessons = append(lessons, l)
		}
		if lessons == nil { lessons = []BookmarkedLessonRow{} }

		c.JSON(http.StatusOK, gin.H{
			"courses": courses,
			"lessons": lessons,
		})
	}
}
