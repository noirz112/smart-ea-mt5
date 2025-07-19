from flask import Flask, request, jsonify
from strategy_selector import StrategySelector
from risk_engine import RiskEngine
import logger  # Add import for logger
import json  # For handling JSON data in dashboard

app = Flask(__name__)
selector = StrategySelector()
risk = RiskEngine()

@app.route('/strategy', methods=['GET'])
def get_strategy():
    strategy, confidence = selector.select_strategy()
    return jsonify({'strategy': strategy, 'confidence': confidence})

@app.route('/risk/lot', methods=['POST'])
def get_lot():
    data = request.json
    balance = data.get('balance', 10000)
    lot = risk.calculate_lot(balance)
    return jsonify({'lot': lot})

@app.route('/update', methods=['POST'])
def update():
    data = request.json
    strategy = data['strategy']
    win = data['win']
    selector.update_win_rate(strategy, win)
    risk.update_win_rate(selector.win_rates[strategy])
    return jsonify({'status': 'updated'})

@app.route('/log', methods=['POST'])
def log():
    data = request.json
    level = data.get('level', 'INFO')
    message = data.get('message')
    log_data = data.get('data')
    logger.log_to_db(level, message, log_data)
    return jsonify({'status': 'logged'})

@app.route('/', methods=['GET'])
def dashboard():
    # Simulate fetching data for dashboard
    strategies = selector.strategies
    win_rates = selector.win_rates
    current_risk = risk.current_risk_level
    # For logs, assume a function to fetch recent logs (simulated)
    recent_logs = [
        {'level': 'INFO', 'message': 'Trade opened', 'data': {'strategy': 'Scalping'}},
        {'level': 'WARNING', 'message': 'High volatility detected', 'data': {}}
    ]  # In real, fetch from database via logger
    
    # Modern HTML dashboard with CSS for beautiful UI
    html = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Smart EA Dashboard</title>
        <style>
            body { font-family: Arial, sans-serif; background-color: #f0f4f8; color: #333; margin: 0; padding: 20px; }
            .container { max-width: 1200px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #007bff; }
            .section { margin-bottom: 20px; }
            table { width: 100%; border-collapse: collapse; }
            th, td { padding: 10px; border: 1px solid #ddd; text-align: left; }
            th { background-color: #007bff; color: white; }
            .status { font-weight: bold; color: #28a745; }
            /* Responsive design */
            @media (max-width: 768px) { .container { padding: 10px; } }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Smart EA Monitoring Dashboard</h1>
            
            <div class="section">
                <h2>Current Status</h2>
                <p>Risk Level: <span class="status">{current_risk}</span></p>
            </div>
            
            <div class="section">
                <h2>Strategies & Win Rates</h2>
                <table>
                    <tr><th>Strategy</th><th>Win Rate</th></tr>
                    {strategy_rows}
                </table>
            </div>
            
            <div class="section">
                <h2>Recent Logs</h2>
                <table>
                    <tr><th>Level</th><th>Message</th><th>Data</th></tr>
                    {log_rows}
                </table>
            </div>
        </div>
    </body>
    </html>
    '''
    
    # Generate table rows
    strategy_rows = ''.join([f'<tr><td>{s}</td><td>{win_rates.get(s, 0.0):.2%}</td></tr>' for s in strategies])
    log_rows = ''.join([f'<tr><td>{log["level"]}</td><td>{log["message"]}</td><td>{json.dumps(log["data"])}</td></tr>' for log in recent_logs])
    
    return html.format(current_risk=current_risk, strategy_rows=strategy_rows, log_rows=log_rows)

# Remove duplicated routes below

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)