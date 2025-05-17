CREATE TABLE exams (
    exam_id SERIAL NOT NULL PRIMARY KEY,
    title TEXT NOT NULL,
    time_limit_minutes INTEGER NOT NULL,
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE 
);

CREATE TABLE parts (
    part_id SERIAL NOT NULL PRIMARY KEY,
    exam_id INTEGER NOT NULL REFERENCES exams(exam_id) ON DELETE CASCADE,
    title TEXT NOT NULL
);

CREATE TABLE contents (
    content_id SERIAL NOT NULL PRIMARY KEY,
    part_id INTEGER NOT NULL REFERENCES parts(part_id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE questions (
    question_id SERIAL NOT NULL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES contents(content_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    media_url TEXT, 
    image_url TEXT, 
    possible_answers TEXT[] NOT NULL,
    true_answer TEXT NOT NULL,
    explanation TEXT NOT NULL,
    keywords TEXT
);