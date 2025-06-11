-- Drop performance indexes

DROP INDEX IF EXISTS idx_user_word_progress_composite;
DROP INDEX IF EXISTS idx_grammars_level_id;
DROP INDEX IF EXISTS idx_words_level_freq;

DROP INDEX IF EXISTS idx_exams_is_unlocked;

DROP INDEX IF EXISTS idx_parts_exam_id;
DROP INDEX IF EXISTS idx_contents_part_id;
DROP INDEX IF EXISTS idx_questions_keywords_trgm;
DROP INDEX IF EXISTS idx_questions_content_id;

DROP INDEX IF EXISTS idx_user_word_progress_last_reviewed;
DROP INDEX IF EXISTS idx_user_word_progress_next_review;
DROP INDEX IF EXISTS idx_user_word_progress_user_word;

DROP INDEX IF EXISTS idx_users_created_at;
DROP INDEX IF EXISTS idx_users_username_lower;
DROP INDEX IF EXISTS idx_users_email_lower;

DROP INDEX IF EXISTS idx_grammars_grammar_key_lower;
DROP INDEX IF EXISTS idx_grammars_title_lower;
DROP INDEX IF EXISTS idx_grammars_tag_gin;
DROP INDEX IF EXISTS idx_grammars_level;
DROP INDEX IF EXISTS idx_grammars_grammar_key_trgm;
DROP INDEX IF EXISTS idx_grammars_title_trgm;

DROP INDEX IF EXISTS idx_words_snym_gin;
DROP INDEX IF EXISTS idx_words_means_gin;
DROP INDEX IF EXISTS idx_words_short_mean_lower;
DROP INDEX IF EXISTS idx_words_word_lower;
DROP INDEX IF EXISTS idx_words_freq;
DROP INDEX IF EXISTS idx_words_level;
DROP INDEX IF EXISTS idx_words_short_mean_trgm;
DROP INDEX IF EXISTS idx_words_word_trgm;
