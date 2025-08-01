# QuantumHedgingMatrixPro EA Documentation

## Overview
QuantumHedgingMatrixPro is an advanced Expert Advisor for MetaTrader 5 that implements a dual-regime trading strategy with comprehensive risk management and portfolio protection features.

## Key Features

### 1. Dual Regime Detection
- **Trend Mode**: Activated when ADX(14) > 25 on H4 timeframe
- **Sideways Mode**: Activated when ADX(14) < 20 on H4 timeframe
- **Neutral Mode**: When ADX is between 20-25 (no trading)

### 2. Trading Strategies

#### Trend Mode Entry Conditions
**Buy Signals:**
- EMA(3) > EMA(8) on M5
- RSI(5) > 55
- Volume > 2x VMA(20)
- Price > EMA(200) on H1
- Candle closes above EMA(8)

**Sell Signals:**
- EMA(3) < EMA(8) on M5
- RSI(5) < 45
- Volume > 2x VMA(20)
- Price < EMA(200) on H1
- Candle closes below EMA(8)

#### Sideways Mode Entry Conditions
**Buy Signals:**
- Price touches Lower BB(10,1.5) on M5
- RSI(7) < 35
- Volume > 2x VMA(20)
- Bullish reversal pattern (pin bar/engulfing)
- Trading hours: GMT 05:00-22:00

**Sell Signals:**
- Price touches Upper BB(10,1.5) on M5
- RSI(7) > 65
- Volume > 2x VMA(20)
- Bearish reversal pattern (pin bar/engulfing)
- Trading hours: GMT 05:00-22:00

### 3. Risk Management

#### Portfolio Protection
- **Max Drawdown**: Auto-stop when drawdown ≥ MaxDrawdown% (default 15%)
- **Circuit Breaker**: 60-minute pause after 3 consecutive losses
- **Position Limits**: Maximum 20 open positions, 1 per symbol

#### Per-Trade Risk
- **Dynamic Lot Sizing**: (Balance × RiskPerTrade%) / (SL × TickValue)
- **Stop Loss**:
  - Trend mode: 3 pips
  - Sideways mode: 4 pips
- **Take Profit**:
  - Trend mode: 12 pips (1:4 Risk/Reward)
  - Sideways mode: 6 pips (1:1.5 Risk/Reward)

### 4. Advanced Filters

#### Volatility Filter
- Skip trades if ATR(14) > 15 pips (trend mode)
- Skip trades if ATR(14) < 5 pips (sideways mode)

#### News Filter
- Auto-pause 30 minutes before/after high-impact news
- Built-in news database for major events

#### Time Filter
- Sideways mode only active during GMT 05:00-22:00

### 5. Monitoring & Logging

#### CSV Output
Daily CSV files with columns:
- Timestamp
- Symbol
- Trade Type
- Entry Price
- Volume
- Market Regime
- RSI Value
- Profit
- Current Drawdown

#### On-Chart Display
- Real-time regime indicator
- Portfolio statistics
- Position count
- Current drawdown
- Consecutive losses

## Installation

1. Copy `QuantumHedgingMatrixPro.mq5` to your MT5 `Experts` folder
2. Copy `PatternRecognition.mqh` to your MT5 `Include` folder or same directory as EA
3. Compile the EA in MetaEditor
4. Attach to any chart (works on all symbols in Market Watch)

## Input Parameters

### Risk Management
- **RiskPerTrade** (0.5): Risk percentage per trade (0.1-2.0)
- **MaxDrawdown** (15.0): Maximum equity drawdown % (5-30)
- **MaxConsecutiveLoss** (3): Circuit breaker trigger
- **PauseDuration** (60): Pause duration in minutes
- **MaxPositions** (20): Maximum open positions

### Strategy Parameters
- **ADX_Period** (14): ADX calculation period
- **ADX_TrendThreshold** (25.0): Minimum ADX for trend mode
- **ADX_SidewaysThreshold** (20.0): Maximum ADX for sideways mode
- **RSI_TrendPeriod** (5): RSI period for trend mode
- **RSI_SidewaysPeriod** (7): RSI period for sideways mode
- **VolumeSpikeFactor** (2.0): Volume spike multiplier

### Filters
- **EnableNewsFilter** (true): Enable news filtering
- **EnableSessionFilter** (true): Enable session filtering
- **PreNewsMinutes** (30): Minutes before news to pause
- **PostNewsMinutes** (30): Minutes after news to pause

## Technical Requirements

### MetaTrader 5 Settings
- Allow automated trading
- Allow DLL imports (if using external libraries)
- Sufficient margin for multiple positions

### Recommended Account Settings
- Minimum balance: $1,000 (for proper lot sizing)
- ECN or low-spread account
- Reliable internet connection
- VPS recommended for 24/7 operation

## Pattern Recognition

The EA includes advanced pattern recognition:
- **Pin Bars**: High probability reversal patterns
- **Engulfing Patterns**: Strong momentum continuation/reversal
- **Hammer/Shooting Star**: Classical reversal patterns
- **Doji**: Indecision patterns
- **Inside/Outside Bars**: Breakout patterns

## Risk Warnings

1. **High-Frequency Trading**: This EA can generate 20-30 trades per day
2. **Market Volatility**: Performance varies with market conditions
3. **Drawdown Risk**: Maximum 15% drawdown protection, but losses can occur
4. **News Events**: Major news can cause rapid price movements
5. **Broker Dependency**: Performance may vary with different brokers

## Backtesting Recommendations

### Test Conditions
- **High Volatility**: XAU/USD during news events
- **Low Volatility**: EUR/USD during Asian session
- **Time Period**: Minimum 3 months historical data
- **Quality**: Every tick or 1-minute OHLC data

### Key Metrics to Monitor
- **Win Rate**: Target >60%
- **Profit Factor**: Target >1.5
- **Maximum Drawdown**: Should not exceed 15%
- **Sharpe Ratio**: Target >1.0
- **Recovery Factor**: Profit/Max Drawdown ratio

## Optimization Guidelines

1. **Start Conservative**: Use default parameters initially
2. **Gradual Adjustment**: Change one parameter at a time
3. **Market Adaptation**: Adjust for different market conditions
4. **Regular Review**: Monitor performance weekly
5. **Drawdown Management**: Reduce risk if approaching limits

## Support and Updates

- Check for updates regularly
- Monitor performance and adjust parameters as needed
- Keep detailed trading logs for analysis
- Consider market condition changes when optimizing

## Disclaimer

This EA is for educational and research purposes. Past performance does not guarantee future results. Always test thoroughly on demo accounts before live trading. The developer is not responsible for any trading losses.