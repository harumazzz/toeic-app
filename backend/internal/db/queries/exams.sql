-- name: CreateExam :one
INSERT INTO exams (
    title,
    time_limit_minutes,
    is_unlocked
) VALUES (
    $1, $2, $3
) RETURNING *;

-- name: GetExam :one
SELECT * FROM exams
WHERE exam_id = $1 LIMIT 1;

-- name: ListExams :many
SELECT * FROM exams
ORDER BY exam_id;

-- name: UpdateExam :one
UPDATE exams
SET
    title = $2,
    time_limit_minutes = $3,
    is_unlocked = $4
WHERE exam_id = $1
RETURNING *;

-- name: DeleteExam :exec
DELETE FROM exams
WHERE exam_id = $1;
