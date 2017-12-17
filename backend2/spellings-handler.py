import json

def handler(event, context):
    print('event', event)
    print('context', context)
    
    response = {
        'statusCode': 200,
        'headers': {},
        'body': json.dumps(['accident', 'actual', 'address', 'answer'])
    }
    return response

