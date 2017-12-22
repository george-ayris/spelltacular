import json
import psycopg2
import os
import random


def handler(event, context):
    print('event', event)
    print('context', context)
   
    connection_string = os.environ['DB_CONNECTION_STRING']
    conn = psycopg2.connect(connection_string)
    cursor = conn.cursor()
    spelling_list_name = "Year 3 and 4"
    cursor.execute("""
        SELECT spelling
        FROM spelltacular.spelling_list SL
        JOIN spelltacular.spelling_list_entry SLE 
            ON SL.spelling_list_id = SLE.spelling_list_id
        WHERE SL.name = %s;""", [spelling_list_name])
    results = cursor.fetchall()

    spellings = []
    spelling_count = 5
    for r in range(spelling_count):
        index = random.randint(0, len(results))
        spellings.append(results.pop(index)[0])
    
    response = {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*' # This should probably be restricted
        },
        'body': json.dumps(spellings)
    }
    return response

