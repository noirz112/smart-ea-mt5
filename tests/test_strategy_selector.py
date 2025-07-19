import pytest
import sys
import os
import unittest.mock
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from ai.strategy_selector import StrategySelector

@pytest.fixture
def selector():
    return StrategySelector()

def test_select_strategy(selector):
    with unittest.mock.patch.object(selector, 'get_market_regime', return_value='trending'):
        with unittest.mock.patch.object(selector, 'get_news_sentiment', return_value='positive'):
            with unittest.mock.patch.object(selector, 'get_graph_data', return_value='breakout'):
                strategy, confidence = selector.select_strategy()
                assert strategy in selector.strategies
                assert 0 <= confidence <= 1

def test_update_win_rate(selector):
    selector.update_win_rate('scalping', True)
    assert selector.win_rates['scalping'] > 0.5  # Win rate increases after win