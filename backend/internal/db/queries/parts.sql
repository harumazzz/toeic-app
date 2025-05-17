-- name: CreatePart :one
INSERT INTO parts (
    exam_id,
    title
) VALUES (
    $1, $2
) RETURNING *;

-- name: GetPart :one
SELECT * FROM parts
WHERE part_id = $1 LIMIT 1;

-- name: ListPartsByExam :many
SELECT * FROM parts
WHERE exam_id = $1
ORDER BY part_id;

-- name: UpdatePart :one
UPDATE parts
SET
    exam_id = $2,
    title = $3
WHERE part_id = $1
RETURNING *;

-- name: DeletePart :exec
DELETE FROM parts
WHERE part_id = $1;
