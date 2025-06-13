-- Drop tables in reverse order due to foreign key dependencies
DROP TABLE IF EXISTS user_answers CASCADE;
DROP TABLE IF EXISTS exam_attempts CASCADE;

-- Drop the enum type
DROP TYPE IF EXISTS exam_status_enum CASCADE;
