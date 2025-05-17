DROP INDEX IF EXISTS idx_user_writings_prompt_id;
DROP INDEX IF EXISTS idx_user_writings_user_id;

DROP INDEX IF EXISTS idx_writing_prompts_user_id;

DROP TRIGGER IF EXISTS update_user_writings_updated_at ON user_writings;
DROP TABLE IF EXISTS user_writings;
DROP TABLE IF EXISTS writing_prompts;