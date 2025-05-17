import json

def escape_sql_string(value):
    """Escapes single quotes for SQL strings and normalizes newlines."""
    if value is None:
        return "NULL"
    # Normalize Windows-style newlines (\r\n) to Unix-style (\n)
    processed_value = str(value).replace("\r\n", "\n")
    # Escape single quotes for SQL
    return "'" + processed_value.replace("'", "''") + "'"

def format_sql_array(arr):
    """Formats a Python list into a PostgreSQL array string literal."""
    if arr is None or not arr: # Handles None and empty list
        return "'{}'" # TEXT[] NOT NULL implies empty array is '{}'

    processed_elements = []
    for item in arr:
        element_str = str(item)
        # Normalize Windows-style newlines (\r\n) to Unix-style (\n)
        element_str = element_str.replace("\r\n", "\n")
        # Escape backslashes (e.g., \\ -> \\\\) for PostgreSQL array elements
        element_str = element_str.replace('\\\\', '\\\\\\\\')
        # Escape double quotes (e.g., " -> \\") for PostgreSQL array elements
        element_str = element_str.replace('"', '\\\\"')
        # Escape single quotes (e.g., ' -> '') for SQL string context within the array
        element_str = element_str.replace("'", "''")
        processed_elements.append('"' + element_str + '"') # Surround each element with double quotes
    
    return "'{" + ",".join(processed_elements) + "}'" # Construct the array literal

def generate_sql_for_exams(data_file_path="exams.json", output_sql_file="import_exams.sql"):
    """
    Reads exam data from a JSON file and generates SQL INSERT statements.
    """
    try:
        with open(data_file_path, 'r', encoding='utf-8') as f:
            exams_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: The file {data_file_path} was not found.")
        return
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from {data_file_path}.")
        return

    sql_statements = []
    exam_id_counter = 1
    part_id_counter = 1
    content_id_counter = 1
    question_id_counter = 1 # Only used if we weren't using SERIAL

    sql_statements.append("-- Generated SQL statements for importing exams data\n")
    sql_statements.append("BEGIN;\n") # Start transaction

    for exam in exams_data:
        exam_title = escape_sql_string(exam.get("title"))
        # Assuming 'time' is in the root of the exam object, default to 0 if not present
        exam_time = exam.get("time", 0)
        exam_is_unlock = exam.get("isUnlock", False) # Renamed from isUnlock to is_unlocked in schema

        # Insert Exam
        sql_statements.append(
            f"INSERT INTO exams (exam_id, title, time_limit_minutes, is_unlocked) VALUES "
            f"({exam_id_counter}, {exam_title}, {exam_time}, {exam_is_unlock});"
        )
        current_exam_id = exam_id_counter
        exam_id_counter += 1

        for part in exam.get("parts", []):
            part_title = escape_sql_string(part.get("title"))

            # Insert Part
            sql_statements.append(
                f"INSERT INTO parts (part_id, exam_id, title) VALUES "
                f"({part_id_counter}, {current_exam_id}, {part_title});"
            )
            current_part_id = part_id_counter
            part_id_counter += 1

            for content in part.get("contents", []):
                content_type = escape_sql_string(content.get("type"))
                content_description = escape_sql_string(content.get("description"))

                # Insert Content
                sql_statements.append(
                    f"INSERT INTO contents (content_id, part_id, type, description) VALUES "
                    f"({content_id_counter}, {current_part_id}, {content_type}, {content_description});"
                )
                current_content_id = content_id_counter
                content_id_counter += 1

                for question in content.get("questions", []):
                    q_title = escape_sql_string(question.get("title"))
                    q_media = escape_sql_string(question.get("media") if question.get("media") else None)
                    q_img = escape_sql_string(question.get("img") if question.get("img") else None)
                    q_answers = format_sql_array(question.get("answers"))
                    q_true_answer = escape_sql_string(question.get("trueAnswer"))
                    q_explain = escape_sql_string(question.get("explain"))
                    q_key = escape_sql_string(question.get("key") if question.get("key") else None)

                    # Insert Question
                    sql_statements.append(
                        f"INSERT INTO questions (content_id, title, media_url, image_url, possible_answers, true_answer, explanation, keywords) VALUES "
                        f"({current_content_id}, {q_title}, {q_media}, {q_img}, {q_answers}, {q_true_answer}, {q_explain}, {q_key});"
                        # question_id is SERIAL, so we don't explicitly insert it.
                        # If not SERIAL, we would use: ({question_id_counter}, {current_content_id}, ...)
                    )
                    # question_id_counter +=1 # Only if not SERIAL

    # Update sequences if IDs were manually inserted (for SERIAL columns, this is good practice)
    # This ensures that future auto-incremented IDs don't clash if we inserted specific IDs.
    # If all IDs are truly SERIAL and we didn't specify them in INSERT, this might not be strictly necessary
    # but is safer if there's any doubt or if we switch to manual ID insertion.
    sql_statements.append(f"\n-- Update sequences to the next available ID\n")
    sql_statements.append(f"SELECT setval('exams_exam_id_seq', COALESCE((SELECT MAX(exam_id) FROM exams), 1));")
    sql_statements.append(f"SELECT setval('parts_part_id_seq', COALESCE((SELECT MAX(part_id) FROM parts), 1));")
    sql_statements.append(f"SELECT setval('contents_content_id_seq', COALESCE((SELECT MAX(content_id) FROM contents), 1));")
    sql_statements.append(f"SELECT setval('questions_question_id_seq', COALESCE((SELECT MAX(question_id) FROM questions), 1));\n")

    sql_statements.append("COMMIT;\n") # Commit transaction

    try:
        with open(output_sql_file, 'w', encoding='utf-8') as f_out:
            for stmt in sql_statements:
                f_out.write(stmt + "\n")
        print(f"SQL script generated successfully: {output_sql_file}")
    except IOError:
        print(f"Error: Could not write to the file {output_sql_file}.")

if __name__ == "__main__":
    # Assuming exams.json is in the same directory as this script
    # or provide the full/relative path to exams.json
    generate_sql_for_exams(data_file_path="c:/Github/toeic-app/data/exams.json",
                           output_sql_file="c:/Github/toeic-app/data/import_exams.sql")