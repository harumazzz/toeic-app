-- name: CreateContent :one
INSERT INTO contents (
    part_id,
    type,
    description
) VALUES (
    $1, $2, $3
) RETURNING *;

-- name: GetContent :one
SELECT * FROM contents
WHERE content_id = $1 LIMIT 1;

-- name: ListContentsByPart :many
SELECT * FROM contents
WHERE part_id = $1
ORDER BY content_id;

-- name: UpdateContent :one
UPDATE contents
SET
    part_id = $2,
    type = $3,
    description = $4
WHERE content_id = $1
RETURNING *;

-- name: DeleteContent :exec
DELETE FROM contents
WHERE content_id = $1;
