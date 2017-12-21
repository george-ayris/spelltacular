import json

def handler(event, context):
    print('event', event)
    print('context', context)
    
    response = {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*' # This should probably be restricted
        },
        'body': json.dumps(['accident', 'actual', 'address', 'answer'])
    }
    return response

