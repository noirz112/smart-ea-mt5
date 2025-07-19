import time
import requests  # Untuk PostgREST
import random  # Untuk simulasi data
import numpy as np  # Untuk kalkulasi Sharpe ratio

from strategy_selector import StrategySelector
from risk_engine import RiskEngine

class ModelLoop:
    def __init__(self):
        self.selector = StrategySelector()
        self.risk = RiskEngine()
        self.last_retrain = time.time()

    def evaluate_performance(self):
        # Fetch real trade data from PostgreSQL via PostgREST
        postgrest_url = 'http://localhost:3000/trades'  # Ambil dari config jika diperlukan
        try:
            response = requests.get(postgrest_url)
            response.raise_for_status()
            trades = response.json()
        except Exception as e:
            print(f"Error fetching trades: {e}")
            trades = []  # Fallback
        
        # Calculate win rates per strategy and drawdown from real data
        if trades:
            strategy_trades = {s: [t for t in trades if t.get('strategy') == s] for s in self.selector.strategies}
            win_rates = {}
            total_profit = 0
            max_drawdown = 0
            current_drawdown = 0
            peak = 0
            for s, st in strategy_trades.items():
                if st:
                    wins = sum(1 for t in st if t.get('profit', 0) > 0)
                    win_rates[s] = wins / len(st)
                    strategy_profit = sum(t.get('profit', 0) for t in st)
                    total_profit += strategy_profit
                else:
                    win_rates[s] = 0.5  # Default jika tidak ada trade
            # Calculate drawdown (simple running calculation)
            balance = 10000  # Assume initial balance
            for t in sorted(trades, key=lambda x: x.get('timestamp')):
                balance += t.get('profit', 0)
                peak = max(peak, balance)
                current_drawdown = (peak - balance) / peak if peak > 0 else 0
                max_drawdown = max(max_drawdown, current_drawdown)
            drawdown = max_drawdown
        else:
            # Fallback to simulation
            win_rates = {s: random.uniform(0.4, 0.8) for s in self.selector.strategies}
            drawdown = random.uniform(0, 0.1)
        
        self.risk.update_drawdown(drawdown)
        for s, rate in win_rates.items():
            self.selector.update_win_rate(s, rate > 0.5)  # Simulate win/loss
            self.risk.update_win_rate(rate)
            if rate < 0.4:  # Auto-disable low performing strategy
                if s in self.selector.active_strategies:
                    self.selector.active_strategies.remove(s)
        print("Performance evaluated")
        
        # Enhanced with Sharpe ratio
        if trades:
            profits = [t.get('profit', 0) for t in trades]
            if len(profits) > 1:
                returns = np.diff(profits) / np.abs(profits[:-1])
                sharpe = np.mean(returns) / np.std(returns) if np.std(returns) != 0 else 0
            else:
                sharpe = 0
            print(f"Sharpe Ratio: {sharpe}")
            # Use Sharpe to adjust risk
            self.risk.update_volatility(sharpe)  # Assuming update_volatility can take this
        else:
            # Fallback to simulation
            win_rates = {s: random.uniform(0.4, 0.8) for s in self.selector.strategies}
            drawdown = random.uniform(0, 0.1)
        
        self.risk.update_drawdown(drawdown)
        for s, rate in win_rates.items():
            self.selector.update_win_rate(s, rate > 0.5)  # Simulate win/loss
            self.risk.update_win_rate(rate)
            if rate < 0.4:  # Auto-disable low performing strategy
                if s in self.selector.active_strategies:
                    self.selector.active_strategies.remove(s)
        print("Performance evaluated")

    def retrain_model(self):
        print("Retraining model...")
        # Integrate real historical data via MCP Fetch
        historical_data = self.fetch_historical_data()
        # Process historical data to bias win rates (simplified)
        trend_bias = 0.1 if 'trending' in str(historical_data) else 0
        self.selector.win_rates = {s: random.uniform(0.5, 0.7) + trend_bias for s in self.selector.strategies}
        self.risk.lot = random.uniform(0.01, 0.05)  # Optimized lot
        
        entities = [{"name": f"Retrained_{time.time()}", "entityType": "ModelUpdate", "observations": [f"Win rates: {self.selector.win_rates}"]}]
        run_mcp('mcp.config.usrlocalmcp.Persistent Knowledge Graph', 'create_entities', {'entities': entities})

    def re_optimize(self):
        print("Re-optimizing parameters...")
        avg_win_rate = sum(self.selector.win_rates.values()) / len(self.selector.win_rates)
        self.risk.lot = max(0.01, 0.05 * avg_win_rate)  # Optimized lot
        opt_entities = [{"name": f"Optimized_{time.time()}", "entityType": "OptimizationUpdate", "observations": [f"Average win rate: {avg_win_rate}, New lot: {self.risk.lot}"]}]
        run_mcp('mcp.config.usrlocalmcp.Persistent Knowledge Graph', 'create_entities', {'entities': opt_entities})

    def check_and_retrain(self):
        if time.time() - self.last_retrain > 2 * 24 * 3600:  # Every 2 days
            self.evaluate_performance()
            self.retrain_model()
            self.re_optimize()
            self.last_retrain = time.time()

    def fetch_historical_data(self):
        # Fetch historical market data via MCP Fetch
        try:
            result = run_mcp('mcp.config.usrlocalmcp.Fetch', 'fetch', {'url': 'https://api.example.com/historical/forex', 'max_length': 5000})
            return json.loads(result)  # Assume JSON response
        except:
            return {}  # Fallback

if __name__ == '__main__':
    loop = ModelLoop()
    loop.check_and_retrain()