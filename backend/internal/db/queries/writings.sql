-- name: CreateWritingPrompt :one
INSERT INTO writing_prompts (
    user_id,
    prompt_text,
    topic,
    difficulty_level
) VALUES (
    $1, $2, $3, $4
) RETURNING *;

-- name: GetWritingPrompt :one
SELECT * FROM writing_prompts
WHERE id = $1 LIMIT 1;

-- name: ListWritingPrompts :many
SELECT * FROM writing_prompts
ORDER BY created_at DESC;

-- name: UpdateWritingPrompt :one
UPDATE writing_prompts
SET
    prompt_text = $2,
    topic = $3,
    difficulty_level = $4
WHERE id = $1
RETURNING *;

-- name: DeleteWritingPrompt :exec
DELETE FROM writing_prompts
WHERE id = $1;

-- name: CreateUserWriting :one
INSERT INTO user_writings (
    user_id,
    prompt_id,
    submission_text,
    ai_feedback,
    ai_score
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetUserWriting :one
SELECT * FROM user_writings
WHERE id = $1 LIMIT 1;

-- name: ListUserWritingsByUserID :many
SELECT * FROM user_writings
WHERE user_id = $1
ORDER BY submitted_at DESC;

-- name: ListUserWritingsByPromptID :many
SELECT * FROM user_writings
WHERE prompt_id = $1
ORDER BY submitted_at DESC;

-- name: UpdateUserWriting :one
UPDATE user_writings
SET
    submission_text = $2,
    ai_feedback = $3,
    ai_score = $4,
    evaluated_at = $5,
    updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: DeleteUserWriting :exec
DELETE FROM user_writings
WHERE id = $1;
