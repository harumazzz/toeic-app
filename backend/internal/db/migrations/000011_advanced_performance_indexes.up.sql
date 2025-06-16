-- Advanced Performance Indexes Migration
-- This migration adds comprehensive indexing optimization for the TOEIC app

-- 1. Enhanced User and Authentication Indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email_hash ON users USING hash(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_username_hash ON users USING hash(username);

-- User roles optimization for RBAC system
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_roles_user_id_expires ON user_roles(user_id, expires_at) 
WHERE expires_at IS NULL OR expires_at > NOW();
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_permissions_resource_action ON permissions(resource, action);

-- 2. Advanced Word Search and Learning Optimization
-- Composite index for level-based word filtering with frequency
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_words_level_freq_id ON words(level, freq DESC, id) 
WHERE level IS NOT NULL;

-- Optimize word progress tracking for spaced repetition
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_word_progress_review_due ON user_word_progress(user_id, next_review_at, difficulty_level) 
WHERE next_review_at <= NOW() + INTERVAL '1 day';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_word_progress_mastery ON user_word_progress(user_id, mastery_level, last_reviewed_at) 
WHERE mastery_level < 5;

-- Full-text search optimization for words
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_words_search_vector ON words USING gin(
    to_tsvector('english', COALESCE(word, '') || ' ' || COALESCE(short_mean, '') || ' ' || 
    COALESCE(means::text, '') || ' ' || COALESCE(snym::text, ''))
);

-- 3. Exam Performance Optimization
-- Composite indexes for exam attempts with status filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_attempts_user_status_time ON exam_attempts(user_id, status, start_time DESC)
WHERE status IN ('completed', 'in_progress');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_attempts_exam_status_score ON exam_attempts(exam_id, status, score DESC NULLS LAST)
WHERE status = 'completed' AND score IS NOT NULL;

-- User answers performance for exam grading
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_answers_attempt_correct ON user_answers(attempt_id, is_correct, answer_time);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_answers_question_stats ON user_answers(question_id, is_correct, created_at);

-- 4. Content and Question Optimization
-- Hierarchical content navigation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contents_part_order ON contents(part_id, display_order) 
WHERE display_order IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_questions_content_order ON questions(content_id, question_order) 
WHERE question_order IS NOT NULL;

-- Question difficulty and performance tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_questions_difficulty_type ON questions(difficulty_level, question_type)
WHERE difficulty_level IS NOT NULL;

-- 5. Grammar and Examples Optimization
-- Grammar search with level filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_grammars_level_title_trgm ON grammars(level, title) 
WHERE level IS NOT NULL;

-- Examples linked to grammar and words
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_examples_grammar_word ON examples(grammar_id, word_id)
WHERE grammar_id IS NOT NULL OR word_id IS NOT NULL;

-- 6. Speaking and Writing Assessment Optimization
-- Writing submissions with evaluation status
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_writings_user_status_submitted ON writings(user_id, status, submitted_at DESC)
WHERE status IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_writings_evaluator_status ON writings(evaluator_id, status, submitted_at)
WHERE evaluator_id IS NOT NULL AND status IN ('pending', 'in_review');

-- Speaking sessions optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_speakings_user_status_created ON speakings(user_id, status, created_at DESC)
WHERE status IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_speakings_evaluator_status ON speakings(evaluator_id, status, created_at)
WHERE evaluator_id IS NOT NULL AND status IN ('pending', 'in_review');

-- 7. Temporal and Analytics Indexes
-- Daily/weekly/monthly analytics optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_attempts_date_score ON exam_attempts(DATE(start_time), score)
WHERE score IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_word_progress_date_reviewed ON user_word_progress(user_id, DATE(last_reviewed_at))
WHERE last_reviewed_at IS NOT NULL;

-- User activity tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_last_login ON users(last_login_at DESC NULLS LAST)
WHERE last_login_at IS NOT NULL;

-- 8. Partial Indexes for Common Filters
-- Active exams only
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exams_active_unlocked ON exams(exam_id, title)
WHERE is_unlocked = true AND is_active = true;

-- Incomplete user progress for recommendations
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_word_progress_incomplete ON user_word_progress(user_id, word_id, difficulty_level)
WHERE mastery_level < 3 OR next_review_at <= NOW();

-- Recent activities for dashboard
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recent_activities ON (
    SELECT 'exam' as activity_type, user_id, start_time as activity_time, exam_id as reference_id
    FROM exam_attempts 
    WHERE start_time >= NOW() - INTERVAL '30 days'
    UNION ALL
    SELECT 'writing' as activity_type, user_id, submitted_at as activity_time, writing_id as reference_id
    FROM writings 
    WHERE submitted_at >= NOW() - INTERVAL '30 days'
);

-- 9. Covering Indexes for Frequent Queries
-- User profile information with roles
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_profile_covering ON users(id, username, email, created_at, last_login_at);

-- Word basic info covering index
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_words_basic_covering ON words(id, word, short_mean, level, freq)
WHERE level IS NOT NULL;

-- Question basic info for exam display
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_questions_exam_covering ON questions(question_id, content_id, title, question_type, difficulty_level);

-- 10. Statistics and Monitoring Indexes
-- Performance monitoring
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pg_stat_user_tables_monitoring ON pg_stat_user_tables(schemaname, relname, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch);

-- Index usage statistics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pg_stat_user_indexes_monitoring ON pg_stat_user_indexes(schemaname, relname, indexrelname, idx_scan, idx_tup_read);
