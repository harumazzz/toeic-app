-- name: CreateQuestion :one
INSERT INTO questions (
    content_id,
    title,
    media_url,
    image_url,
    possible_answers,
    true_answer,
    explanation,
    keywords
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
) RETURNING *;

-- name: GetQuestion :one
SELECT * FROM questions
WHERE question_id = $1 LIMIT 1;

-- name: ListQuestionsByContent :many
SELECT * FROM questions
WHERE content_id = $1
ORDER BY question_id;

-- name: UpdateQuestion :one
UPDATE questions
SET
    content_id = $2,
    title = $3,
    media_url = $4,
    image_url = $5,
    possible_answers = $6,
    true_answer = $7,
    explanation = $8,
    keywords = $9
WHERE question_id = $1
RETURNING *;

-- name: DeleteQuestion :exec
DELETE FROM questions
WHERE question_id = $1;
