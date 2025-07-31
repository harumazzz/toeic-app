-- Drop vocabulary learning features

DROP INDEX IF EXISTS idx_vocabulary_stats_mastery;
DROP INDEX IF EXISTS idx_vocabulary_stats_user_id;
DROP INDEX IF EXISTS idx_learning_attempts_word_id;
DROP INDEX IF EXISTS idx_learning_attempts_session_id;
DROP INDEX IF EXISTS idx_learning_sessions_type;
DROP INDEX IF EXISTS idx_learning_sessions_user_id;
DROP INDEX IF EXISTS idx_study_set_words_word_id;
DROP INDEX IF EXISTS idx_study_set_words_study_set_id;
DROP INDEX IF EXISTS idx_study_sets_public;
DROP INDEX IF EXISTS idx_study_sets_user_id;

DROP TABLE IF EXISTS vocabulary_stats;
DROP TABLE IF EXISTS learning_attempts;
DROP TABLE IF EXISTS learning_sessions;
DROP TABLE IF EXISTS study_set_words;
DROP TABLE IF EXISTS study_sets;
