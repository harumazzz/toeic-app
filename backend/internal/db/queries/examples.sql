-- name: CreateExample :one
INSERT INTO examples (
    title,
    meaning
) VALUES (
    $1, $2
) RETURNING *;

-- name: GetExample :one
SELECT * FROM examples
WHERE id = $1 LIMIT 1;

-- name: BatchGetExamples :many
SELECT * FROM examples
WHERE id = ANY($1::int[])
ORDER BY id;

-- name: ListExamples :many
SELECT * FROM examples
ORDER BY id;

-- name: UpdateExample :one
UPDATE examples
SET title = $2,
    meaning = $3
WHERE id = $1
RETURNING *;

-- name: DeleteExample :exec
DELETE FROM examples
WHERE id = $1;
