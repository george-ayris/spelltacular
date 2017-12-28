import json
import psycopg2
import os


def handler(event, context):
    connection_string = os.environ['DB_CONNECTION_STRING']
    conn = psycopg2.connect(connection_string)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT spelling_list_id, name
        FROM spelltacular.spelling_list SL
        LIMIT 100""")
    results = cursor.fetchall()
    spelling_lists = [{ 
        'spellingListId': r[0],
        'name': r[1]
    } for r in results]

    response = {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*' # This should probably be restricted
        },
        'body': json.dumps({
            'spellingLists': spelling_lists
        })
    }
    return response

