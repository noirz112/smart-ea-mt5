import schedule
import time
from model_loop import ModelLoop
import logging  # Untuk logging jadwal
from risk_engine import RiskEngine  # Untuk cek drawdown

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

loop = ModelLoop()
risk = RiskEngine()  # Instance untuk monitoring

def check_drawdown():
    current_dd = risk.current_drawdown
    if current_dd > 0.04:  # 4% threshold
        logging.warning(f'Drawdown alert: {current_dd * 100:.2f}%')
        # Integrate MCP for alert
        run_mcp('mcp.config.usrlocalmcp.Persistent Knowledge Graph', 'create_entities', {'entities': [{'name': f'Drawdown_Alert_{time.time()}', 'entityType': 'Alert', 'observations': [f'Drawdown exceeded 4%: {current_dd}']}]})

# Untuk kompatibilitas cloud, scheduler ini bisa dijalankan di MCP Trae.ai server
# dengan integrasi run_mcp untuk tugas terjadwal
schedule.every(1).days.do(loop.evaluate_performance)  # Daily performance evaluation
schedule.every(3).days.do(loop.retrain_model)  # Retrain every 3 days
schedule.every(7).days.do(loop.re_optimize)  # Re-optimize every week
schedule.every(1).days.do(lambda: run_mcp('mcp.config.usrlocalmcp.Persistent Knowledge Graph', 'create_entities', {'entities': [{'name': f'Schedule_Log_{time.time()}', 'entityType': 'ScheduleEvent', 'observations': ['Daily evaluation completed']}]}))  # Log to KG daily
schedule.every(1).hours.do(check_drawdown)  # Check drawdown every hour

while True:
    schedule.run_pending()
    logging.info('Scheduler checked pending tasks')
    time.sleep(3600)  # Sleep 1 hour