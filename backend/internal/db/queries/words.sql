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

-- name: SearchWords :many
SELECT * FROM words
WHERE
    word ILIKE '%' || $1 || '%' OR
    short_mean ILIKE '%' || $1 || '%' OR
    means::text ILIKE '%' || $1 || '%' OR
    snym::text ILIKE '%' || $1 || '%'
ORDER BY 
    CASE 
        WHEN LOWER(word) = LOWER($1) THEN 1
        WHEN word ILIKE $1 || '%' THEN 2
        WHEN word ILIKE '%' || $1 || '%' THEN 3
        WHEN short_mean ILIKE $1 || '%' THEN 4
        WHEN short_mean ILIKE '%' || $1 || '%' THEN 5
        ELSE 6
    END,
    level, freq DESC, id
LIMIT $2
OFFSET $3;

-- name: SearchWordsFullText :many
SELECT *, 
       ts_rank(to_tsvector('english', word || ' ' || short_mean || ' ' || COALESCE(means::text, '') || ' ' || COALESCE(snym::text, '')), 
               plainto_tsquery('english', $1)) as rank
FROM words
WHERE to_tsvector('english', word || ' ' || short_mean || ' ' || COALESCE(means::text, '') || ' ' || COALESCE(snym::text, '')) 
      @@ plainto_tsquery('english', $1)
ORDER BY rank DESC, level, freq DESC, id
LIMIT $2
OFFSET $3;

-- name: SearchWordsFast :many
SELECT id, word, pronounce, level, descript_level, short_mean, means, snym, freq, conjugation FROM words
WHERE
    word % $1 OR
    short_mean % $1 OR
    word ILIKE $1 || '%' OR
    short_mean ILIKE $1 || '%'
ORDER BY 
    similarity(word, $1) DESC,
    similarity(short_mean, $1) DESC,
    level, freq DESC
LIMIT $2
OFFSET $3;

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

-- name: GetWordsByLevel :many
SELECT * FROM words
WHERE level = $1
ORDER BY freq DESC, id
LIMIT $2
OFFSET $3;

-- name: GetPopularWords :many
SELECT * FROM words
ORDER BY freq DESC, level
LIMIT $1
OFFSET $2;
