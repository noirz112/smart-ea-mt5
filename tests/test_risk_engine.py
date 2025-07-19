import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from ai.risk_engine import RiskEngine

@pytest.fixture
def engine():
    return RiskEngine()

def test_calculate_lot(engine):
    lot = engine.calculate_lot(10000)
    assert 0.01 <= lot <= 1.0  # Assuming reasonable range

def test_update_win_rate(engine):
    initial_lot = engine.lot
    engine.update_win_rate(0.4)
    assert engine.lot < initial_lot  # Lot decreases if win rate low