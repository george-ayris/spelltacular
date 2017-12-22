#!env/bin/python
import sys
import psycopg2


if len(sys.argv) < 2:
    print('Must supply a file to load')
    sys.exit(1) 

file_name = sys.argv[1]
print('Loading spellings from', file_name)
file = open(file_name)
contents = file.read()
spellings = contents.split('\n')

list_name = spellings[0]
spellings = [s.strip() for s in spellings[2:] if s]

if len(sys.argv) > 2:
    connection_string = sys.argv[2]
else:
    connection_string = "dbname=spelltacular user=postgres password=Password123 host=localhost port=5432"

conn = psycopg2.connect(connection_string)
cursor = conn.cursor()

cursor.execute(
    """INSERT INTO spelltacular.spelling_list (name)
       VALUES (%s)
       RETURNING spelling_list_id;""", [list_name])
spelling_list_id = cursor.fetchone()[0]

spellings_with_list_id = [(spelling_list_id, s) for s in spellings]
cursor.executemany(
    """INSERT INTO spelltacular.spelling_list_entry (spelling_list_id, spelling)
       VALUES (%s, %s);""", spellings_with_list_id)

conn.commit()
