import requests
import json
import datetime
import logging  # Untuk standard logging

POSTGREST_URL = 'http://localhost:3000/logs'  # Adjust as needed
HEADERS = {'Content-Type': 'application/json'}

def log_to_db(level, message, data=None):
    payload = {
        'level': level,
        'message': message,
        'data': json.dumps(data) if data else None,
        'timestamp': datetime.datetime.now().isoformat()
    }
    try:
        response = requests.post(POSTGREST_URL, headers=HEADERS, json=payload)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        logging.error(f'Logging to DB failed: {e}')
        # Fallback to local file
        with open('fallback_logs.txt', 'a') as f:
            f.write(json.dumps(payload) + '\n')
    # Integrate with Persistent Knowledge Graph for critical logs
    if level in ['ERROR', 'CRITICAL']:
        entities = [{'name': f'Log_{datetime.datetime.now().isoformat()}', 'entityType': 'ErrorLog', 'observations': [message, json.dumps(data)]}]
        run_mcp('mcp.config.usrlocalmcp.Persistent Knowledge Graph', 'create_entities', {'entities': entities})

# Example integration in other modules
# In smart_ea.mq5 or via API, call this function

if __name__ == '__main__':
    log_to_db('INFO', 'Test log', {'trade_id': 123})

def log_trade(strategy, profit, other_data=None):
    data = {'strategy': strategy, 'profit': profit, **(other_data or {})}
    log_to_db('INFO', f'Trade executed with strategy {strategy}', data)