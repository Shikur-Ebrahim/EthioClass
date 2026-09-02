with open('backend/internal/handlers/course.go', 'r', encoding='utf-8') as f:
    content = f.read()

old_enroll_logic = '''		_, err := db.ExecContext(c.Request.Context(), \UPDATE courses SET students = students + 1 WHERE id = \\, courseID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to enroll in course: " + err.Error()})
			return
		}'''

new_enroll_logic = '''		// Increment students count in courses table
		_, err := db.ExecContext(c.Request.Context(), \UPDATE courses SET students = students + 1 WHERE id = \\, courseID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to enroll in course: " + err.Error()})
			return
		}
		
		// Also increment students count in categories table
		var catID string
		err = db.QueryRowContext(c.Request.Context(), \SELECT category_id FROM courses WHERE id = \\, courseID).Scan(&catID)
		if err == nil && catID != "" {
			db.ExecContext(c.Request.Context(), \UPDATE categories SET students = students + 1 WHERE id = \\, catID)
		}'''

content = content.replace(old_enroll_logic, new_enroll_logic)

with open('backend/internal/handlers/course.go', 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated EnrollCourseHandler.')
