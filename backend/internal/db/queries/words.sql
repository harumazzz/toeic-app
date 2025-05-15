-- name: CreateWord :one
INSERT INTO words (
    word,
    pronounce,
    level,
    descript_level,
    short_mean,
    means,
    snym,
    freq,
    conjugation
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
) RETURNING *;

-- name: GetWord :one
SELECT * FROM words
WHERE id = $1 LIMIT 1;

-- name: ListWords :many
SELECT * FROM words
ORDER BY id
LIMIT $1
OFFSET $2;

-- name: UpdateWord :one
UPDATE words
SET
    word = $2,
    pronounce = $3,
    level = $4,
    descript_level = $5,
    short_mean = $6,
    means = $7,
    snym = $8,
    freq = $9,
    conjugation = $10
WHERE id = $1
RETURNING *;

-- name: DeleteWord :exec
DELETE FROM words
WHERE id = $1;
