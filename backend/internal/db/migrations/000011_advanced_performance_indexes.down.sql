-- Rollback advanced performance indexes

-- 10. Statistics and Monitoring Indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_pg_stat_user_indexes_monitoring;
DROP INDEX CONCURRENTLY IF EXISTS idx_pg_stat_user_tables_monitoring;

-- 9. Covering Indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_questions_exam_covering;
DROP INDEX CONCURRENTLY IF EXISTS idx_words_basic_covering;
DROP INDEX CONCURRENTLY IF EXISTS idx_users_profile_covering;

-- 8. Partial Indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_user_word_progress_incomplete;
DROP INDEX CONCURRENTLY IF EXISTS idx_exams_active_unlocked;

-- 7. Temporal and Analytics Indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_users_last_login;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_word_progress_date_reviewed;
DROP INDEX CONCURRENTLY IF EXISTS idx_exam_attempts_date_score;

-- 6. Speaking and Writing Assessment Optimization
DROP INDEX CONCURRENTLY IF EXISTS idx_speakings_evaluator_status;
DROP INDEX CONCURRENTLY IF EXISTS idx_speakings_user_status_created;
DROP INDEX CONCURRENTLY IF EXISTS idx_writings_evaluator_status;
DROP INDEX CONCURRENTLY IF EXISTS idx_writings_user_status_submitted;

-- 5. Grammar and Examples Optimization
DROP INDEX CONCURRENTLY IF EXISTS idx_examples_grammar_word;
DROP INDEX CONCURRENTLY IF EXISTS idx_grammars_level_title_trgm;

-- 4. Content and Question Optimization
DROP INDEX CONCURRENTLY IF EXISTS idx_questions_difficulty_type;
DROP INDEX CONCURRENTLY IF EXISTS idx_questions_content_order;
DROP INDEX CONCURRENTLY IF EXISTS idx_contents_part_order;

-- 3. Exam Performance Optimization
DROP INDEX CONCURRENTLY IF EXISTS idx_user_answers_question_stats;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_answers_attempt_correct;
DROP INDEX CONCURRENTLY IF EXISTS idx_exam_attempts_exam_status_score;
DROP INDEX CONCURRENTLY IF EXISTS idx_exam_attempts_user_status_time;

-- 2. Advanced Word Search and Learning Optimization
DROP INDEX CONCURRENTLY IF EXISTS idx_words_search_vector;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_word_progress_mastery;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_word_progress_review_due;
DROP INDEX CONCURRENTLY IF EXISTS idx_words_level_freq_id;

-- 1. Enhanced User and Authentication Indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_permissions_resource_action;
DROP INDEX CONCURRENTLY IF EXISTS idx_role_permissions_role_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_roles_role_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_roles_user_id_expires;
DROP INDEX CONCURRENTLY IF EXISTS idx_users_username_hash;
DROP INDEX CONCURRENTLY IF EXISTS idx_users_email_hash;
