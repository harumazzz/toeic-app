package i18n

// loadDefaultMessages loads default messages for all supported languages
func (i *I18n) loadDefaultMessages() {
	// Load English messages (default)
	i.loadEnglishMessages()

	// Load Vietnamese messages
	i.loadVietnameseMessages()
}

// loadEnglishMessages loads all English messages
func (i *I18n) loadEnglishMessages() {
	messages := map[string]string{
		// Common messages
		"success":               "Success",
		"error":                 "Error",
		"not_found":             "Not found",
		"internal_server_error": "Internal server error",
		"bad_request":           "Bad request",
		"unauthorized":          "Unauthorized",
		"forbidden":             "Forbidden",
		"validation_error":      "Validation error",
		"invalid_request":       "Invalid request",
		"operation_successful":  "Operation completed successfully",
		"operation_failed":      "Operation failed",

		// Authentication messages
		"login_successful":          "Login successful",
		"login_failed":              "Login failed",
		"invalid_credentials":       "Invalid email or password",
		"registration_successful":   "Registration successful",
		"registration_failed":       "Registration failed",
		"user_already_exists":       "User already exists",
		"token_expired":             "Token has expired",
		"token_invalid":             "Invalid token",
		"logout_successful":         "Logout successful",
		"password_reset_required":   "Password reset required",
		"authentication_required":   "Authentication required",
		"access_denied":             "Access denied",
		"admin_privileges_required": "Admin privileges required",

		// User management
		"user_created_successfully":    "User created successfully",
		"user_updated_successfully":    "User updated successfully",
		"user_deleted_successfully":    "User deleted successfully",
		"user_not_found":               "User not found",
		"users_retrieved_successfully": "Users retrieved successfully",
		"invalid_user_id":              "Invalid user ID",
		"user_profile_updated":         "User profile updated successfully",
		"current_user_retrieved":       "Current user profile retrieved successfully",

		// Exam management
		"exam_created_successfully":    "Exam created successfully",
		"exam_updated_successfully":    "Exam updated successfully",
		"exam_deleted_successfully":    "Exam deleted successfully",
		"exam_not_found":               "Exam not found",
		"exams_retrieved_successfully": "Exams retrieved successfully",
		"invalid_exam_id":              "Invalid exam ID",
		"exam_time_limit_invalid":      "Invalid exam time limit",

		// Part management
		"part_created_successfully":    "Part created successfully",
		"part_updated_successfully":    "Part updated successfully",
		"part_deleted_successfully":    "Part deleted successfully",
		"part_not_found":               "Part not found",
		"parts_retrieved_successfully": "Parts retrieved successfully",
		"invalid_part_id":              "Invalid part ID",

		// Question management
		"question_created_successfully":    "Question created successfully",
		"question_updated_successfully":    "Question updated successfully",
		"question_deleted_successfully":    "Question deleted successfully",
		"question_not_found":               "Question not found",
		"questions_retrieved_successfully": "Questions retrieved successfully",
		"invalid_question_id":              "Invalid question ID",

		// Content management
		"content_created_successfully":    "Content created successfully",
		"content_updated_successfully":    "Content updated successfully",
		"content_deleted_successfully":    "Content deleted successfully",
		"content_not_found":               "Content not found",
		"contents_retrieved_successfully": "Contents retrieved successfully",
		"invalid_content_id":              "Invalid content ID",

		// Word management
		"word_created_successfully":    "Word created successfully",
		"word_updated_successfully":    "Word updated successfully",
		"word_deleted_successfully":    "Word deleted successfully",
		"word_not_found":               "Word not found",
		"words_retrieved_successfully": "Words retrieved successfully",
		"words_search_completed":       "Word search completed successfully",
		"invalid_word_id":              "Invalid word ID",

		// Grammar management
		"grammar_created_successfully":    "Grammar created successfully",
		"grammar_updated_successfully":    "Grammar updated successfully",
		"grammar_deleted_successfully":    "Grammar deleted successfully",
		"grammar_not_found":               "Grammar not found",
		"grammars_retrieved_successfully": "Grammars retrieved successfully",
		"grammar_search_completed":        "Grammar search completed successfully",
		"invalid_grammar_id":              "Invalid grammar ID",
		"random_grammar_retrieved":        "Random grammar retrieved successfully",

		// Example management
		"example_created_successfully":    "Example created successfully",
		"example_updated_successfully":    "Example updated successfully",
		"example_deleted_successfully":    "Example deleted successfully",
		"example_not_found":               "Example not found",
		"examples_retrieved_successfully": "Examples retrieved successfully",
		"invalid_example_id":              "Invalid example ID",

		// Writing management
		"writing_prompt_created_successfully":    "Writing prompt created successfully",
		"writing_prompt_updated_successfully":    "Writing prompt updated successfully",
		"writing_prompt_deleted_successfully":    "Writing prompt deleted successfully",
		"writing_prompt_not_found":               "Writing prompt not found",
		"writing_prompts_retrieved_successfully": "Writing prompts retrieved successfully",
		"user_writing_created_successfully":      "Writing submission created successfully",
		"user_writing_updated_successfully":      "Writing submission updated successfully",
		"user_writing_deleted_successfully":      "Writing submission deleted successfully",
		"user_writing_not_found":                 "Writing submission not found",
		"user_writings_retrieved_successfully":   "Writing submissions retrieved successfully",

		// Speaking management
		"speaking_session_created_successfully":    "Speaking session created successfully",
		"speaking_session_updated_successfully":    "Speaking session updated successfully",
		"speaking_session_deleted_successfully":    "Speaking session deleted successfully",
		"speaking_session_not_found":               "Speaking session not found",
		"speaking_sessions_retrieved_successfully": "Speaking sessions retrieved successfully",
		"speaking_turn_created_successfully":       "Speaking turn created successfully",
		"speaking_turn_updated_successfully":       "Speaking turn updated successfully",
		"speaking_turn_deleted_successfully":       "Speaking turn deleted successfully",
		"speaking_turn_not_found":                  "Speaking turn not found",
		"speaking_turns_retrieved_successfully":    "Speaking turns retrieved successfully",

		// Word Progress management
		"word_progress_created_successfully":   "Word progress created successfully",
		"word_progress_updated_successfully":   "Word progress updated successfully",
		"word_progress_deleted_successfully":   "Word progress deleted successfully",
		"word_progress_not_found":              "Word progress not found",
		"word_progress_retrieved_successfully": "Word progress retrieved successfully",
		"words_for_review_retrieved":           "Words for review retrieved successfully",
		"word_with_progress_retrieved":         "Word with progress retrieved successfully",

		// File upload
		"file_uploaded_successfully": "File uploaded successfully",
		"file_upload_failed":         "File upload failed",
		"invalid_file_format":        "Invalid file format",
		"file_too_large":             "File too large",
		"no_file_provided":           "No file provided",

		// Cache management
		"cache_cleared_successfully": "Cache cleared successfully",
		"cache_pattern_cleared":      "Cache pattern cleared successfully",
		"cache_stats_retrieved":      "Cache statistics retrieved successfully",
		"failed_to_clear_cache":      "Failed to clear cache",

		// Backup management
		"backup_created_successfully":    "Database backup created successfully",
		"backup_deleted_successfully":    "Backup deleted successfully",
		"backup_restored_successfully":   "Database restored successfully",
		"backups_retrieved_successfully": "Backups retrieved successfully",
		"backup_not_found":               "Backup file not found",
		"backup_creation_failed":         "Failed to create database backup",
		"backup_restoration_failed":      "Failed to restore database",

		// Health and monitoring
		"health_check_successful":        "Health check successful",
		"api_is_running":                 "API is running",
		"metrics_retrieved_successfully": "System metrics retrieved successfully",
		"performance_stats_retrieved":    "Performance statistics retrieved successfully",

		// WebSocket and upgrades
		"websocket_connected":               "Connected to TOEIC app upgrade notifications",
		"upgrade_subscription_successful":   "Successfully subscribed to upgrade notifications",
		"upgrade_unsubscription_successful": "Successfully unsubscribed from upgrade notifications",
		"upgrade_check_completed":           "Update check completed",
		"upgrade_notification_sent":         "Upgrade notification sent successfully",

		// Rate limiting
		"rate_limit_exceeded": "Rate limit exceeded. Please try again later",
		"too_many_requests":   "Too many requests",

		// Validation errors
		"required_field_missing":   "Required field is missing",
		"invalid_email_format":     "Invalid email format",
		"password_too_short":       "Password is too short",
		"password_too_weak":        "Password is too weak",
		"invalid_id_format":        "Invalid ID format",
		"invalid_query_parameters": "Invalid query parameters",
		"invalid_request_body":     "Invalid request body",

		// Database errors
		"database_connection_failed": "Database connection failed",
		"database_query_failed":      "Database query failed",
		"database_update_failed":     "Database update failed",
		"database_delete_failed":     "Database delete failed",
		"database_create_failed":     "Database create failed",

		// Generic CRUD operations
		"created_successfully":          "Created successfully",
		"updated_successfully":          "Updated successfully",
		"deleted_successfully":          "Deleted successfully",
		"retrieved_successfully":        "Retrieved successfully",
		"search_completed_successfully": "Search completed successfully",
		"failed_to_create":              "Failed to create",
		"failed_to_update":              "Failed to update",
		"failed_to_delete":              "Failed to delete",
		"failed_to_retrieve":            "Failed to retrieve",
		"failed_to_search":              "Failed to search",

		// Server errors
		"server_temporarily_unavailable": "Server temporarily unavailable",
		"service_under_maintenance":      "Service under maintenance",
		"request_timeout":                "Request timeout",
		"server_overloaded":              "Server is overloaded. Please try again later",
	}

	i.AddMessages(LanguageEnglish, messages)
}

// loadVietnameseMessages loads all Vietnamese messages
func (i *I18n) loadVietnameseMessages() {
	messages := map[string]string{
		// Common messages
		"success":               "Thành công",
		"error":                 "Lỗi",
		"not_found":             "Không tìm thấy",
		"internal_server_error": "Lỗi máy chủ nội bộ",
		"bad_request":           "Yêu cầu không hợp lệ",
		"unauthorized":          "Không được phép",
		"forbidden":             "Bị cấm",
		"validation_error":      "Lỗi xác thực",
		"invalid_request":       "Yêu cầu không hợp lệ",
		"operation_successful":  "Thao tác hoàn thành thành công",
		"operation_failed":      "Thao tác thất bại",

		// Authentication messages
		"login_successful":          "Đăng nhập thành công",
		"login_failed":              "Đăng nhập thất bại",
		"invalid_credentials":       "Email hoặc mật khẩu không đúng",
		"registration_successful":   "Đăng ký thành công",
		"registration_failed":       "Đăng ký thất bại",
		"user_already_exists":       "Người dùng đã tồn tại",
		"token_expired":             "Token đã hết hạn",
		"token_invalid":             "Token không hợp lệ",
		"logout_successful":         "Đăng xuất thành công",
		"password_reset_required":   "Cần đặt lại mật khẩu",
		"authentication_required":   "Cần xác thực",
		"access_denied":             "Truy cập bị từ chối",
		"admin_privileges_required": "Cần quyền quản trị viên",

		// User management
		"user_created_successfully":    "Tạo người dùng thành công",
		"user_updated_successfully":    "Cập nhật người dùng thành công",
		"user_deleted_successfully":    "Xóa người dùng thành công",
		"user_not_found":               "Không tìm thấy người dùng",
		"users_retrieved_successfully": "Lấy danh sách người dùng thành công",
		"invalid_user_id":              "ID người dùng không hợp lệ",
		"user_profile_updated":         "Cập nhật hồ sơ người dùng thành công",
		"current_user_retrieved":       "Lấy thông tin người dùng hiện tại thành công",

		// Exam management
		"exam_created_successfully":    "Tạo bài thi thành công",
		"exam_updated_successfully":    "Cập nhật bài thi thành công",
		"exam_deleted_successfully":    "Xóa bài thi thành công",
		"exam_not_found":               "Không tìm thấy bài thi",
		"exams_retrieved_successfully": "Lấy danh sách bài thi thành công",
		"invalid_exam_id":              "ID bài thi không hợp lệ",
		"exam_time_limit_invalid":      "Thời gian làm bài không hợp lệ",

		// Part management
		"part_created_successfully":    "Tạo phần thi thành công",
		"part_updated_successfully":    "Cập nhật phần thi thành công",
		"part_deleted_successfully":    "Xóa phần thi thành công",
		"part_not_found":               "Không tìm thấy phần thi",
		"parts_retrieved_successfully": "Lấy danh sách phần thi thành công",
		"invalid_part_id":              "ID phần thi không hợp lệ",

		// Question management
		"question_created_successfully":    "Tạo câu hỏi thành công",
		"question_updated_successfully":    "Cập nhật câu hỏi thành công",
		"question_deleted_successfully":    "Xóa câu hỏi thành công",
		"question_not_found":               "Không tìm thấy câu hỏi",
		"questions_retrieved_successfully": "Lấy danh sách câu hỏi thành công",
		"invalid_question_id":              "ID câu hỏi không hợp lệ",

		// Content management
		"content_created_successfully":    "Tạo nội dung thành công",
		"content_updated_successfully":    "Cập nhật nội dung thành công",
		"content_deleted_successfully":    "Xóa nội dung thành công",
		"content_not_found":               "Không tìm thấy nội dung",
		"contents_retrieved_successfully": "Lấy danh sách nội dung thành công",
		"invalid_content_id":              "ID nội dung không hợp lệ",

		// Word management
		"word_created_successfully":    "Tạo từ vựng thành công",
		"word_updated_successfully":    "Cập nhật từ vựng thành công",
		"word_deleted_successfully":    "Xóa từ vựng thành công",
		"word_not_found":               "Không tìm thấy từ vựng",
		"words_retrieved_successfully": "Lấy danh sách từ vựng thành công",
		"words_search_completed":       "Tìm kiếm từ vựng hoàn thành thành công",
		"invalid_word_id":              "ID từ vựng không hợp lệ",

		// Grammar management
		"grammar_created_successfully":    "Tạo ngữ pháp thành công",
		"grammar_updated_successfully":    "Cập nhật ngữ pháp thành công",
		"grammar_deleted_successfully":    "Xóa ngữ pháp thành công",
		"grammar_not_found":               "Không tìm thấy ngữ pháp",
		"grammars_retrieved_successfully": "Lấy danh sách ngữ pháp thành công",
		"grammar_search_completed":        "Tìm kiếm ngữ pháp hoàn thành thành công",
		"invalid_grammar_id":              "ID ngữ pháp không hợp lệ",
		"random_grammar_retrieved":        "Lấy ngữ pháp ngẫu nhiên thành công",

		// Example management
		"example_created_successfully":    "Tạo ví dụ thành công",
		"example_updated_successfully":    "Cập nhật ví dụ thành công",
		"example_deleted_successfully":    "Xóa ví dụ thành công",
		"example_not_found":               "Không tìm thấy ví dụ",
		"examples_retrieved_successfully": "Lấy danh sách ví dụ thành công",
		"invalid_example_id":              "ID ví dụ không hợp lệ",

		// Writing management
		"writing_prompt_created_successfully":    "Tạo đề bài viết thành công",
		"writing_prompt_updated_successfully":    "Cập nhật đề bài viết thành công",
		"writing_prompt_deleted_successfully":    "Xóa đề bài viết thành công",
		"writing_prompt_not_found":               "Không tìm thấy đề bài viết",
		"writing_prompts_retrieved_successfully": "Lấy danh sách đề bài viết thành công",
		"user_writing_created_successfully":      "Tạo bài viết thành công",
		"user_writing_updated_successfully":      "Cập nhật bài viết thành công",
		"user_writing_deleted_successfully":      "Xóa bài viết thành công",
		"user_writing_not_found":                 "Không tìm thấy bài viết",
		"user_writings_retrieved_successfully":   "Lấy danh sách bài viết thành công",

		// Speaking management
		"speaking_session_created_successfully":    "Tạo phiên nói thành công",
		"speaking_session_updated_successfully":    "Cập nhật phiên nói thành công",
		"speaking_session_deleted_successfully":    "Xóa phiên nói thành công",
		"speaking_session_not_found":               "Không tìm thấy phiên nói",
		"speaking_sessions_retrieved_successfully": "Lấy danh sách phiên nói thành công",
		"speaking_turn_created_successfully":       "Tạo lượt nói thành công",
		"speaking_turn_updated_successfully":       "Cập nhật lượt nói thành công",
		"speaking_turn_deleted_successfully":       "Xóa lượt nói thành công",
		"speaking_turn_not_found":                  "Không tìm thấy lượt nói",
		"speaking_turns_retrieved_successfully":    "Lấy danh sách lượt nói thành công",

		// Word Progress management
		"word_progress_created_successfully":   "Tạo tiến độ từ vựng thành công",
		"word_progress_updated_successfully":   "Cập nhật tiến độ từ vựng thành công",
		"word_progress_deleted_successfully":   "Xóa tiến độ từ vựng thành công",
		"word_progress_not_found":              "Không tìm thấy tiến độ từ vựng",
		"word_progress_retrieved_successfully": "Lấy tiến độ từ vựng thành công",
		"words_for_review_retrieved":           "Lấy danh sách từ cần ôn tập thành công",
		"word_with_progress_retrieved":         "Lấy từ vựng với tiến độ thành công",

		// File upload
		"file_uploaded_successfully": "Tải lên tệp thành công",
		"file_upload_failed":         "Tải lên tệp thất bại",
		"invalid_file_format":        "Định dạng tệp không hợp lệ",
		"file_too_large":             "Tệp quá lớn",
		"no_file_provided":           "Không có tệp được cung cấp",

		// Cache management
		"cache_cleared_successfully": "Xóa cache thành công",
		"cache_pattern_cleared":      "Xóa cache theo mẫu thành công",
		"cache_stats_retrieved":      "Lấy thống kê cache thành công",
		"failed_to_clear_cache":      "Không thể xóa cache",

		// Backup management
		"backup_created_successfully":    "Tạo bản sao lưu cơ sở dữ liệu thành công",
		"backup_deleted_successfully":    "Xóa bản sao lưu thành công",
		"backup_restored_successfully":   "Khôi phục cơ sở dữ liệu thành công",
		"backups_retrieved_successfully": "Lấy danh sách bản sao lưu thành công",
		"backup_not_found":               "Không tìm thấy tệp sao lưu",
		"backup_creation_failed":         "Không thể tạo bản sao lưu cơ sở dữ liệu",
		"backup_restoration_failed":      "Không thể khôi phục cơ sở dữ liệu",

		// Health and monitoring
		"health_check_successful":        "Kiểm tra sức khỏe thành công",
		"api_is_running":                 "API đang hoạt động",
		"metrics_retrieved_successfully": "Lấy thông số hệ thống thành công",
		"performance_stats_retrieved":    "Lấy thống kê hiệu suất thành công",

		// WebSocket and upgrades
		"websocket_connected":               "Đã kết nối đến thông báo nâng cấp ứng dụng TOEIC",
		"upgrade_subscription_successful":   "Đăng ký thông báo nâng cấp thành công",
		"upgrade_unsubscription_successful": "Hủy đăng ký thông báo nâng cấp thành công",
		"upgrade_check_completed":           "Kiểm tra cập nhật hoàn thành",
		"upgrade_notification_sent":         "Gửi thông báo nâng cấp thành công",

		// Rate limiting
		"rate_limit_exceeded": "Vượt quá giới hạn tốc độ. Vui lòng thử lại sau",
		"too_many_requests":   "Quá nhiều yêu cầu",

		// Validation errors
		"required_field_missing":   "Thiếu trường bắt buộc",
		"invalid_email_format":     "Định dạng email không hợp lệ",
		"password_too_short":       "Mật khẩu quá ngắn",
		"password_too_weak":        "Mật khẩu quá yếu",
		"invalid_id_format":        "Định dạng ID không hợp lệ",
		"invalid_query_parameters": "Tham số truy vấn không hợp lệ",
		"invalid_request_body":     "Nội dung yêu cầu không hợp lệ",

		// Database errors
		"database_connection_failed": "Kết nối cơ sở dữ liệu thất bại",
		"database_query_failed":      "Truy vấn cơ sở dữ liệu thất bại",
		"database_update_failed":     "Cập nhật cơ sở dữ liệu thất bại",
		"database_delete_failed":     "Xóa dữ liệu thất bại",
		"database_create_failed":     "Tạo dữ liệu thất bại",

		// Generic CRUD operations
		"created_successfully":          "Tạo thành công",
		"updated_successfully":          "Cập nhật thành công",
		"deleted_successfully":          "Xóa thành công",
		"retrieved_successfully":        "Lấy dữ liệu thành công",
		"search_completed_successfully": "Tìm kiếm hoàn thành thành công",
		"failed_to_create":              "Không thể tạo",
		"failed_to_update":              "Không thể cập nhật",
		"failed_to_delete":              "Không thể xóa",
		"failed_to_retrieve":            "Không thể lấy dữ liệu",
		"failed_to_search":              "Không thể tìm kiếm",

		// Server errors
		"server_temporarily_unavailable": "Máy chủ tạm thời không khả dụng",
		"service_under_maintenance":      "Dịch vụ đang bảo trì",
		"request_timeout":                "Hết thời gian chờ yêu cầu",
		"server_overloaded":              "Máy chủ đang quá tải. Vui lòng thử lại sau",
	}

	i.AddMessages(LanguageVietnamese, messages)
}
