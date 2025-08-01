//+------------------------------------------------------------------+
//|                                 PatternRecognition.mqh           |
//|                        Pattern Recognition Helper Functions      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Advanced Bullish Reversal Pattern Detection                      |
//+------------------------------------------------------------------+
bool IsBullishReversalPatternAdvanced(string symbol)
{
   double open[], close[], high[], low[];
   
   if(CopyOpen(symbol, PERIOD_M5, 1, 3, open) <= 0) return false;
   if(CopyClose(symbol, PERIOD_M5, 1, 3, close) <= 0) return false;
   if(CopyHigh(symbol, PERIOD_M5, 1, 3, high) <= 0) return false;
   if(CopyLow(symbol, PERIOD_M5, 1, 3, low) <= 0) return false;
   
   // Pin Bar Pattern
   if(IsBullishPinBar(open[2], close[2], high[2], low[2])) return true;
   
   // Engulfing Pattern
   if(IsBullishEngulfing(open, close, high, low)) return true;
   
   // Hammer Pattern
   if(IsBullishHammer(open[2], close[2], high[2], low[2])) return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Advanced Bearish Reversal Pattern Detection                      |
//+------------------------------------------------------------------+
bool IsBearishReversalPatternAdvanced(string symbol)
{
   double open[], close[], high[], low[];
   
   if(CopyOpen(symbol, PERIOD_M5, 1, 3, open) <= 0) return false;
   if(CopyClose(symbol, PERIOD_M5, 1, 3, close) <= 0) return false;
   if(CopyHigh(symbol, PERIOD_M5, 1, 3, high) <= 0) return false;
   if(CopyLow(symbol, PERIOD_M5, 1, 3, low) <= 0) return false;
   
   // Pin Bar Pattern
   if(IsBearishPinBar(open[2], close[2], high[2], low[2])) return true;
   
   // Engulfing Pattern
   if(IsBearishEngulfing(open, close, high, low)) return true;
   
   // Shooting Star Pattern
   if(IsBearishShootingStar(open[2], close[2], high[2], low[2])) return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Bullish Pin Bar Detection                                        |
//+------------------------------------------------------------------+
bool IsBullishPinBar(double open, double close, double high, double low)
{
   double body = MathAbs(close - open);
   double upperShadow = high - MathMax(open, close);
   double lowerShadow = MathMin(open, close) - low;
   double totalRange = high - low;
   
   // Pin bar criteria:
   // 1. Lower shadow is at least 2/3 of total range
   // 2. Upper shadow is less than 1/3 of body
   // 3. Body is small relative to total range
   
   return (lowerShadow >= totalRange * 0.67 && 
           upperShadow <= body * 0.33 && 
           body <= totalRange * 0.33 &&
           close >= open); // Bullish close
}

//+------------------------------------------------------------------+
//| Bearish Pin Bar Detection                                        |
//+------------------------------------------------------------------+
bool IsBearishPinBar(double open, double close, double high, double low)
{
   double body = MathAbs(close - open);
   double upperShadow = high - MathMax(open, close);
   double lowerShadow = MathMin(open, close) - low;
   double totalRange = high - low;
   
   // Pin bar criteria:
   // 1. Upper shadow is at least 2/3 of total range
   // 2. Lower shadow is less than 1/3 of body
   // 3. Body is small relative to total range
   
   return (upperShadow >= totalRange * 0.67 && 
           lowerShadow <= body * 0.33 && 
           body <= totalRange * 0.33 &&
           close <= open); // Bearish close
}

//+------------------------------------------------------------------+
//| Bullish Engulfing Pattern Detection                             |
//+------------------------------------------------------------------+
bool IsBullishEngulfing(const double &open[], const double &close[], 
                        const double &high[], const double &low[])
{
   // Previous candle (index 1) should be bearish
   bool prevBearish = close[1] < open[1];
   
   // Current candle (index 2) should be bullish
   bool currBullish = close[2] > open[2];
   
   // Current candle should engulf previous candle
   bool engulfs = (open[2] < close[1] && close[2] > open[1]);
   
   // Volume confirmation (if available)
   // Additional check: current candle's body should be significantly larger
   double prevBody = MathAbs(close[1] - open[1]);
   double currBody = MathAbs(close[2] - open[2]);
   bool bodyLarger = currBody > prevBody * 1.2;
   
   return prevBearish && currBullish && engulfs && bodyLarger;
}

//+------------------------------------------------------------------+
//| Bearish Engulfing Pattern Detection                             |
//+------------------------------------------------------------------+
bool IsBearishEngulfing(const double &open[], const double &close[], 
                        const double &high[], const double &low[])
{
   // Previous candle (index 1) should be bullish
   bool prevBullish = close[1] > open[1];
   
   // Current candle (index 2) should be bearish
   bool currBearish = close[2] < open[2];
   
   // Current candle should engulf previous candle
   bool engulfs = (open[2] > close[1] && close[2] < open[1]);
   
   // Additional check: current candle's body should be significantly larger
   double prevBody = MathAbs(close[1] - open[1]);
   double currBody = MathAbs(close[2] - open[2]);
   bool bodyLarger = currBody > prevBody * 1.2;
   
   return prevBullish && currBearish && engulfs && bodyLarger;
}

//+------------------------------------------------------------------+
//| Bullish Hammer Pattern Detection                                |
//+------------------------------------------------------------------+
bool IsBullishHammer(double open, double close, double high, double low)
{
   double body = MathAbs(close - open);
   double upperShadow = high - MathMax(open, close);
   double lowerShadow = MathMin(open, close) - low;
   double totalRange = high - low;
   
   // Hammer criteria:
   // 1. Small body at the upper end of the trading range
   // 2. Long lower shadow (at least twice the body)
   // 3. Little or no upper shadow
   
   return (body <= totalRange * 0.3 && 
           lowerShadow >= body * 2.0 && 
           upperShadow <= body * 0.1 &&
           (high - MathMax(open, close)) <= totalRange * 0.1);
}

//+------------------------------------------------------------------+
//| Bearish Shooting Star Pattern Detection                         |
//+------------------------------------------------------------------+
bool IsBearishShootingStar(double open, double close, double high, double low)
{
   double body = MathAbs(close - open);
   double upperShadow = high - MathMax(open, close);
   double lowerShadow = MathMin(open, close) - low;
   double totalRange = high - low;
   
   // Shooting Star criteria:
   // 1. Small body at the lower end of the trading range
   // 2. Long upper shadow (at least twice the body)
   // 3. Little or no lower shadow
   
   return (body <= totalRange * 0.3 && 
           upperShadow >= body * 2.0 && 
           lowerShadow <= body * 0.1 &&
           (MathMin(open, close) - low) <= totalRange * 0.1);
}

//+------------------------------------------------------------------+
//| Doji Pattern Detection                                           |
//+------------------------------------------------------------------+
bool IsDoji(double open, double close, double high, double low)
{
   double body = MathAbs(close - open);
   double totalRange = high - low;
   
   // Doji criteria: body is very small relative to the total range
   return (body <= totalRange * 0.05);
}

//+------------------------------------------------------------------+
//| Inside Bar Pattern Detection                                     |
//+------------------------------------------------------------------+
bool IsInsideBar(const double &high[], const double &low[])
{
   // Current bar (index 1) should be inside previous bar (index 0)
   return (high[1] < high[0] && low[1] > low[0]);
}

//+------------------------------------------------------------------+
//| Outside Bar Pattern Detection                                    |
//+------------------------------------------------------------------+
bool IsOutsideBar(const double &high[], const double &low[])
{
   // Current bar (index 1) should engulf previous bar (index 0)
   return (high[1] > high[0] && low[1] < low[0]);
}