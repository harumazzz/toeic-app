-- Add performance indexes for faster search and query operations

-- Enable pg_trgm extension for full-text search if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Words table indexes for search optimization
CREATE INDEX IF NOT EXISTS idx_words_word_trgm ON words USING gin (word gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_words_short_mean_trgm ON words USING gin (short_mean gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_words_level ON words(level);
CREATE INDEX IF NOT EXISTS idx_words_freq ON words(freq DESC);
CREATE INDEX IF NOT EXISTS idx_words_word_lower ON words(LOWER(word));
CREATE INDEX IF NOT EXISTS idx_words_short_mean_lower ON words(LOWER(short_mean));
CREATE INDEX IF NOT EXISTS idx_words_means_gin ON words USING gin (means);
CREATE INDEX IF NOT EXISTS idx_words_snym_gin ON words USING gin (snym);

-- Grammar table indexes for search optimization
CREATE INDEX IF NOT EXISTS idx_grammars_title_trgm ON grammars USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_grammars_grammar_key_trgm ON grammars USING gin (grammar_key gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_grammars_level ON grammars(level);
CREATE INDEX IF NOT EXISTS idx_grammars_tag_gin ON grammars USING gin (tag);
CREATE INDEX IF NOT EXISTS idx_grammars_title_lower ON grammars(LOWER(title));
CREATE INDEX IF NOT EXISTS idx_grammars_grammar_key_lower ON grammars(LOWER(grammar_key));

-- User and authentication related indexes
CREATE INDEX IF NOT EXISTS idx_users_email_lower ON users(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users(LOWER(username));
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- User word progress indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_word_progress_user_word ON user_word_progress(user_id, word_id);
CREATE INDEX IF NOT EXISTS idx_user_word_progress_next_review ON user_word_progress(user_id, next_review_at) WHERE next_review_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_word_progress_last_reviewed ON user_word_progress(last_reviewed_at DESC) WHERE last_reviewed_at IS NOT NULL;

-- Question and content indexes
CREATE INDEX IF NOT EXISTS idx_questions_content_id ON questions(content_id);
CREATE INDEX IF NOT EXISTS idx_questions_keywords_trgm ON questions USING gin (keywords gin_trgm_ops) WHERE keywords IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contents_part_id ON contents(part_id);
CREATE INDEX IF NOT EXISTS idx_parts_exam_id ON parts(exam_id);

-- Exam and test related indexes
CREATE INDEX IF NOT EXISTS idx_exams_is_unlocked ON exams(is_unlocked) WHERE is_unlocked = true;

-- Create composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_words_level_freq ON words(level, freq DESC);
CREATE INDEX IF NOT EXISTS idx_grammars_level_id ON grammars(level, id);
CREATE INDEX IF NOT EXISTS idx_user_word_progress_composite ON user_word_progress(user_id, next_review_at, word_id) WHERE next_review_at <= NOW();
