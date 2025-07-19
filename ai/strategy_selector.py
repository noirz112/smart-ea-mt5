import requests
import json
import os
import random  # Untuk simulasi regime
import subprocess  # Untuk memanggil MCP via command line atau API
import time  # Untuk caching

# Assume BytePlus API for NLP sentiment
BYTEPLUS_API = 'https://api.byteplus.com/nlp/sentiment'

import requests
import json
import os
import random
import subprocess
from .logger import log_to_db  # Import logger

class StrategySelector:
    def __init__(self):
        self.strategies = ['scalping', 'breakout', 'reversal', 'news', 'trend_following']
        self.active = {s: True for s in self.strategies}
        self.confidence = {s: 0.0 for s in self.strategies}
        self.win_rates = {s: 0.5 for s in self.strategies}  # Initial win-rate
        self.last_sentiment_time = 0
        self.cached_sentiment = 'neutral'

    def get_market_regime(self):
        # Enhanced regime detection (simulated)
        volatility = random.uniform(0, 1)  # Placeholder for real volatility calc
        if volatility > 0.7: return 'high_volatility'
        elif volatility > 0.4: return 'trending'
        else: return 'ranging'

    def get_news_sentiment(self):
        current_time = time.time()
        if current_time - self.last_sentiment_time < 300:  # Cache for 5 minutes
            return self.cached_sentiment
        
        try:
            # Use MCP Fetch to get news from multiple sources
            news_sources = [
                'https://forexnewsapi.com/api/v1/news?section=general&items=1&token=YOUR_FOREXNEWSAPI_TOKEN',
                'https://another-news-api.com/latest'  # Add more sources
            ]
            latest_news = ''
            for source in news_sources:
                # Simulate MCP Fetch call; in real, use run_mcp
                response = requests.get(source)
                response.raise_for_status()
                data = response.json()
                news_item = data.get('data', [{}])[0]
                latest_news += news_item.get('title', '') + ' ' + news_item.get('snippet', '') + ' '
            
            # Enhanced prompt for BytePlus
            api_key = os.environ.get('BYTEPLUS_API_KEY')
            if not api_key:
                raise ValueError("BYTEPLUS_API_KEY not set")
            headers = {'Authorization': f'Bearer {api_key}', 'Content-Type': 'application/json'}
            prompt = f"Analyze the sentiment of this forex news text in detail and classify as positive, negative, or neutral with reasoning: {latest_news[:1000]}"
            payload = {'prompt': prompt, 'model': 'skylark'}
            sentiment_response = requests.post('https://api.byteplus.com/modelark/analyze', json=payload, headers=headers)
            sentiment_response.raise_for_status()
            result = sentiment_response.json()
            sentiment = result.get('sentiment', 'neutral')
            reasoning = result.get('reasoning', '')
            
            # Log to database with more details
            log_to_db({'event': 'sentiment_analysis', 'sentiment': sentiment, 'reasoning': reasoning, 'news': latest_news[:200]})
            print(f"BytePlus ModelArk Sentiment: {sentiment} (Reason: {reasoning})")
            
            self.cached_sentiment = sentiment
            self.last_sentiment_time = current_time
            return sentiment
        except Exception as e:
            print(f"Error in sentiment analysis: {e}")
            return 'neutral'

    def get_graph_data(self, regime):
        # Use run_mcp to query Persistent Knowledge Graph
        try:
            # Assuming run_mcp is available; in practice, integrate via Trae.ai agent
            graph_response = run_mcp('mcp.config.usrlocalmcp.Persistent Knowledge Graph', 'read_graph', {})
            # Parse graph to find suitable strategy for regime (simplified)
            # For real impl, extract from graph_response
            graph_data = {  # Fallback to simulated if error
                'high_volatility': 'scalping',
                'trending': 'breakout',
                'ranging': 'reversal'
            }
            return graph_data.get(regime, 'scalping')
        except Exception as e:
            print(f'MCP query error: {e}')
            return 'scalping'  # Default

    def calculate_confidence(self):
        regime = self.get_market_regime()
        sentiment = self.get_news_sentiment()
        suitable_strategy = self.get_graph_data(regime)
        for s in self.strategies:
            score = 0.5  # Base
            if s == suitable_strategy: score += 0.4  # Boost from graph
            if regime == 'trending' and s == 'trend_following': score += 0.3
            if regime == 'high_volatility' and s == 'scalping': score += 0.3
            if regime == 'ranging' and s == 'reversal': score += 0.3
            if sentiment == 'positive' and s == 'breakout': score += 0.2
            elif sentiment == 'negative' and s == 'reversal': score += 0.2
            if sentiment == 'positive' and s == 'news': score += 0.2
            elif sentiment == 'negative' and s == 'news': score -= 0.1
            self.confidence[s] = min(1.0, score * self.win_rates[s])

    def select_strategy(self):
        self.calculate_confidence()
        active_strats = [s for s in self.strategies if self.active[s] and self.confidence[s] > 0.5]
        if not active_strats:
            return 'none', 0.0
        best = max(active_strats, key=lambda s: self.confidence[s])
        return best, self.confidence[best]

    def update_win_rate(self, strategy, win):
        self.win_rates[strategy] = (self.win_rates[strategy] * 0.9) + (0.1 if win else 0)
        if self.win_rates[strategy] < 0.4:
            self.active[strategy] = False
            print(f"Deactivated {strategy} due to low win-rate")
        elif self.win_rates[strategy] > 0.6:
            self.active[strategy] = True
            print(f"Activated {strategy} due to high win-rate")

if __name__ == '__main__':
    selector = StrategySelector()
    strategy, conf = selector.select_strategy()
    print(f'Selected: {strategy} with confidence {conf}')