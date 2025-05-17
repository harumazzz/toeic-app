import csv
import json

def read_csv(file_path):
    with open(file_path, mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        next(reader)  # Skip header row
        data = [row for row in reader]
    return data

def escape_sql_string(value):
    """Properly escape single quotes for SQL by replacing ' with ''"""
    if value.lower() == 'null':
        return 'NULL'
    return value.replace("'", "''")

def replace_array(input_string):
  # Check if the string starts with '[' and ends with ']'
  if input_string.startswith('[') and input_string.endswith(']'):
    # Check if the string is just "[]"
    if input_string == '[]':
        return '{}'
    else:
        # Return the string with the first and last characters replaced
        return '{' + input_string[1:-1] + '}'
  else:
    if input_string.startswith('\'[') and input_string.endswith(']\''):
        # Check if the string is just "[]"
        if input_string == '\'[]\'':
            return '\'{}\''
        else:
            # Return the string with the first and last characters replaced
            return '\'{' + input_string[2:-2] + '}\''
    return input_string

if __name__ == "__main__":
    file_path = './examples.csv'
    data = read_csv(file_path)
    output = ''
    for row in data:
        # Convert each value to have proper SQL escaping
        values = []
        for i, val in enumerate(row):
            if i in [0, 3, 8]:  # Numeric fields (id, level, freq)
                values.append(val if val.lower() != 'null' else 'NULL')
            else:  # String fields that need quotes and escaping
                if val.lower() == 'null':
                    values.append('NULL')
                else:
                    values.append(f"'{escape_sql_string(val)}'")
        
        # Construct the SQL statement
        output += f"INSERT INTO examples (id, title, meaning) VALUES ({values[0]}, {values[1]}, {values[2] if values[2] != 'NULL' else '\'\''});"
        output += '\n'
    
    with open('./output.sql', 'w', encoding='utf-8') as file:
        file.write(output)