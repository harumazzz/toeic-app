-- Performance indexes for TOEIC app database
-- Run this script manually in your PostgreSQL database

-- Enable pg_trgm extension first
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Basic indexes for words table
CREATE INDEX IF NOT EXISTS idx_words_level ON words(level);
CREATE INDEX IF NOT EXISTS idx_words_freq ON words(freq DESC);
CREATE INDEX IF NOT EXISTS idx_words_means_gin ON words USING gin (means);
CREATE INDEX IF NOT EXISTS idx_words_snym_gin ON words USING gin (snym);

-- Grammar table basic indexes
CREATE INDEX IF NOT EXISTS idx_grammars_level ON grammars(level);
CREATE INDEX IF NOT EXISTS idx_grammars_tag_gin ON grammars USING gin (tag);

-- User and authentication related indexes
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- User word progress indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_word_progress_user_word ON user_word_progress(user_id, word_id);
CREATE INDEX IF NOT EXISTS idx_user_word_progress_next_review ON user_word_progress(user_id, next_review_at);
CREATE INDEX IF NOT EXISTS idx_user_word_progress_last_reviewed ON user_word_progress(last_reviewed_at DESC);

-- Question and content indexes
CREATE INDEX IF NOT EXISTS idx_questions_content_id ON questions(content_id);
CREATE INDEX IF NOT EXISTS idx_contents_part_id ON contents(part_id);
CREATE INDEX IF NOT EXISTS idx_parts_exam_id ON parts(exam_id);

-- Exam and test related indexes
CREATE INDEX IF NOT EXISTS idx_exams_is_unlocked ON exams(is_unlocked);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_words_level_freq ON words(level, freq DESC);
CREATE INDEX IF NOT EXISTS idx_grammars_level_id ON grammars(level, id);
CREATE INDEX IF NOT EXISTS idx_user_word_progress_composite ON user_word_progress(user_id, next_review_at, word_id);

-- Trigram indexes for fast text search (after pg_trgm extension is enabled)
CREATE INDEX IF NOT EXISTS idx_words_word_trgm ON words USING gin (word gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_words_short_mean_trgm ON words USING gin (short_mean gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_grammars_title_trgm ON grammars USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_grammars_grammar_key_trgm ON grammars USING gin (grammar_key gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_questions_keywords_trgm ON questions USING gin (keywords gin_trgm_ops);

-- Performance analysis query to check index usage
-- Run this after creating indexes to verify they are being used
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
