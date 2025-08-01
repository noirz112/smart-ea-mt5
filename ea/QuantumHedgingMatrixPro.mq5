//+------------------------------------------------------------------+
//|                                 QuantumHedgingMatrixPro.mq5      |
//|                        Copyright 2025, Developed by QuantEdge.ai |
//|                                            https://quantedge.ai  |
//+------------------------------------------------------------------+
#property copyright "Quantum Hedging Matrix EA"
#property version   "1.20"
#property description "AI-Powered Portfolio Management System"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include "PatternRecognition.mqh"

//=== ENUMS ===
enum ENUM_MARKET_REGIME
{
   REGIME_TREND,     // Trend mode (ADX > 25)
   REGIME_SIDEWAYS,  // Sideways mode (ADX < 20)
   REGIME_NEUTRAL    // Neutral mode (20 <= ADX <= 25)
};

//=== RISK MANAGEMENT PARAMETERS ===
input group "=== RISK MANAGEMENT ==="
input double   RiskPerTrade         = 0.5;     // Risk % per trade (0.1-2.0)
input double   MaxDrawdown          = 15.0;    // Max equity drawdown % (5-30)
input int      MaxConsecutiveLoss   = 3;       // Circuit breaker trigger
input int      PauseDuration        = 60;      // Minutes (circuit break)
input int      MaxPositions         = 20;      // Maximum open positions

//=== STRATEGY PARAMETERS ===
input group "=== STRATEGY PARAMS ==="
input int      ADX_Period           = 14;      // ADX period
input double   ADX_TrendThreshold   = 25.0;    // Min ADX for trend
input double   ADX_SidewaysThreshold = 20.0;   // Max ADX for sideways
input int      RSI_TrendPeriod      = 5;       // RSI period (trend)
input int      RSI_SidewaysPeriod   = 7;       // RSI period (sideways)
input double   VolumeSpikeFactor    = 2.0;     // Volume multiplier

//=== FILTERS ===
input group "=== FILTERS ==="
input bool     EnableNewsFilter     = true;    // Enable news filter
input bool     EnableSessionFilter  = true;    // Enable session filter
input int      PreNewsMinutes       = 30;      // Minutes before news
input int      PostNewsMinutes      = 30;      // Minutes after news

//=== GLOBAL VARIABLES ===
int            magicNumber = 202501;
double         initialBalance;
datetime       lastTradeTime;
int            consecutiveLosses;
datetime       pauseUntil = 0;
string         csvFileName;
int            totalTrades = 0;
double         maxEquityDrawdown = 0;
datetime       lastSymbolScan = 0;
string         activeSymbols[];

// Indicator handles
int            adx_handle_h4;
int            ema3_handle_m5, ema8_handle_m5, ema200_handle_h1;
int            rsi_trend_handle, rsi_sideways_handle;
int            bb_handle_m5;
int            atr_handle;
int            volume_handle;

// Trade objects
CTrade         trade;
CSymbolInfo    symbolInfo;
CPositionInfo  positionInfo;

// News events structure
struct NewsEvent
{
   datetime time;
   string   currency;
   int      impact; // 1=low, 2=medium, 3=high
   string   event;
};

NewsEvent newsEvents[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== QuantumHedgingMatrixPro EA Initializing ===");
   
   // Initialize variables
   initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   csvFileName = StringFormat("QHM_Log_%s.csv", TimeToString(TimeCurrent(), TIME_DATE));
   
   // Initialize trade object
   trade.SetExpertMagicNumber(magicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   // Initialize indicator handles
   if(!InitializeIndicators())
   {
      Print("Failed to initialize indicators");
      return INIT_FAILED;
   }
   
   // Initialize news events
   InitializeNewsEvents();
   
   // Initialize active symbols list
   UpdateActiveSymbolsList();
   
   // Create CSV header
   CreateCSVHeader();
   
   Print("QuantumHedgingMatrixPro EA initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Initialize indicator handles                                     |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
   // ADX on H4
   adx_handle_h4 = iADX(NULL, PERIOD_H4, ADX_Period);
   if(adx_handle_h4 == INVALID_HANDLE) return false;
   
   // EMAs
   ema3_handle_m5 = iMA(NULL, PERIOD_M5, 3, 0, MODE_EMA, PRICE_CLOSE);
   ema8_handle_m5 = iMA(NULL, PERIOD_M5, 8, 0, MODE_EMA, PRICE_CLOSE);
   ema200_handle_h1 = iMA(NULL, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   
   if(ema3_handle_m5 == INVALID_HANDLE || ema8_handle_m5 == INVALID_HANDLE || 
      ema200_handle_h1 == INVALID_HANDLE) return false;
   
   // RSI indicators
   rsi_trend_handle = iRSI(NULL, PERIOD_M5, RSI_TrendPeriod, PRICE_CLOSE);
   rsi_sideways_handle = iRSI(NULL, PERIOD_M5, RSI_SidewaysPeriod, PRICE_CLOSE);
   
   if(rsi_trend_handle == INVALID_HANDLE || rsi_sideways_handle == INVALID_HANDLE) return false;
   
   // Bollinger Bands
   bb_handle_m5 = iBands(NULL, PERIOD_M5, 10, 0, 1.5, PRICE_CLOSE);
   if(bb_handle_m5 == INVALID_HANDLE) return false;
   
   // ATR
   atr_handle = iATR(NULL, PERIOD_M5, 14);
   if(atr_handle == INVALID_HANDLE) return false;
   
   // Volume
   volume_handle = iVolumes(NULL, PERIOD_M5);
   if(volume_handle == INVALID_HANDLE) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize news events database                                  |
//+------------------------------------------------------------------+
void InitializeNewsEvents()
{
   // Comprehensive high impact news events database
   ArrayResize(newsEvents, 50);
   
   datetime today = TimeCurrent();
   MqlDateTime time_struct;
   TimeToStruct(today, time_struct);
   
   int eventIndex = 0;
   
   // US Events (High Impact)
   CreateNewsEvent(eventIndex++, 1, 8, 30, "USD", 3, "Non-Farm Payrolls"); // First Friday
   CreateNewsEvent(eventIndex++, 1, 14, 0, "USD", 3, "FOMC Decision"); // FOMC meetings
   CreateNewsEvent(eventIndex++, 15, 13, 30, "USD", 3, "CPI (Consumer Price Index)");
   CreateNewsEvent(eventIndex++, 15, 13, 30, "USD", 3, "PPI (Producer Price Index)");
   CreateNewsEvent(eventIndex++, 1, 13, 30, "USD", 3, "GDP Quarterly");
   CreateNewsEvent(eventIndex++, 1, 13, 30, "USD", 3, "Retail Sales");
   CreateNewsEvent(eventIndex++, 1, 14, 15, "USD", 3, "Fed Chair Speech");
   
   // EUR Events (High Impact)
   CreateNewsEvent(eventIndex++, 1, 9, 0, "EUR", 3, "ECB Interest Rate Decision");
   CreateNewsEvent(eventIndex++, 15, 10, 0, "EUR", 3, "ECB Press Conference");
   CreateNewsEvent(eventIndex++, 1, 10, 0, "EUR", 3, "German CPI");
   CreateNewsEvent(eventIndex++, 1, 10, 0, "EUR", 3, "German GDP");
   CreateNewsEvent(eventIndex++, 1, 9, 0, "EUR", 3, "Eurozone CPI");
   
   // GBP Events (High Impact)
   CreateNewsEvent(eventIndex++, 1, 12, 0, "GBP", 3, "BOE Interest Rate Decision");
   CreateNewsEvent(eventIndex++, 1, 9, 30, "GBP", 3, "UK CPI");
   CreateNewsEvent(eventIndex++, 1, 9, 30, "GBP", 3, "UK GDP");
   CreateNewsEvent(eventIndex++, 1, 9, 30, "GBP", 3, "UK Employment");
   
   // JPY Events (High Impact)
   CreateNewsEvent(eventIndex++, 1, 6, 0, "JPY", 3, "BOJ Interest Rate Decision");
   CreateNewsEvent(eventIndex++, 1, 23, 30, "JPY", 3, "Japan CPI");
   CreateNewsEvent(eventIndex++, 1, 23, 50, "JPY", 3, "Japan GDP");
   
   // CAD Events (High Impact)
   CreateNewsEvent(eventIndex++, 1, 13, 30, "CAD", 3, "BOC Interest Rate Decision");
   CreateNewsEvent(eventIndex++, 1, 13, 30, "CAD", 3, "Canada CPI");
   CreateNewsEvent(eventIndex++, 1, 13, 30, "CAD", 3, "Canada Employment");
   
   // AUD Events (High Impact)
   CreateNewsEvent(eventIndex++, 1, 4, 30, "AUD", 3, "RBA Interest Rate Decision");
   CreateNewsEvent(eventIndex++, 1, 1, 30, "AUD", 3, "Australia CPI");
   CreateNewsEvent(eventIndex++, 1, 1, 30, "AUD", 3, "Australia GDP");
   
   // Resize array to actual size
   ArrayResize(newsEvents, eventIndex);
}

//+------------------------------------------------------------------+
//| Helper function to create news events                            |
//+------------------------------------------------------------------+
void CreateNewsEvent(int index, int day, int hour, int minute, string currency, int impact, string eventName)
{
   if(index >= ArraySize(newsEvents)) return;
   
   datetime today = TimeCurrent();
   MqlDateTime time_struct;
   TimeToStruct(today, time_struct);
   
   time_struct.day = day;
   time_struct.hour = hour;
   time_struct.min = minute;
   time_struct.sec = 0;
   
   newsEvents[index].time = StructToTime(time_struct);
   newsEvents[index].currency = currency;
   newsEvents[index].impact = impact;
   newsEvents[index].event = eventName;
}

//+------------------------------------------------------------------+
//| Create CSV header                                                |
//+------------------------------------------------------------------+
void CreateCSVHeader()
{
   string header = "Timestamp,Symbol,Type,EntryPrice,Volume,Regime,RSI_Value,Profit,Drawdown\n";
   int file_handle = FileOpen(csvFileName, FILE_WRITE|FILE_CSV);
   if(file_handle != INVALID_HANDLE)
   {
      FileWriteString(file_handle, header);
      FileClose(file_handle);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Skip if in pause mode
   if(TimeCurrent() < pauseUntil) 
   {
      DisplayInfo("Status: PAUSED (Circuit Breaker Active)");
      return;
   }
   
   // Portfolio protection checks
   if(CheckDrawdownProtection()) 
   {
      DisplayInfo("Status: STOPPED (Max Drawdown Reached)");
      return;
   }
   
   if(CheckCircuitBreaker()) 
   {
      DisplayInfo("Status: PAUSED (Circuit Breaker Triggered)");
      return;
   }
   
   // News filter check
   if(EnableNewsFilter && IsHighImpactNews()) 
   {
      DisplayInfo("Status: PAUSED (High Impact News)");
      return;
   }
   
   // Session filter check
   if(EnableSessionFilter && !IsValidTradingSession()) 
   {
      DisplayInfo("Status: OUTSIDE TRADING HOURS");
      return;
   }
   
   // Multi-symbol analysis and trading
   ProcessMultiSymbolTrading();
   
   // Auto scan symbols every 15 minutes
   if(TimeCurrent() - lastSymbolScan >= 900) // 15 minutes
   {
      UpdateActiveSymbolsList();
      lastSymbolScan = TimeCurrent();
   }
   
   // Update monitoring display
   UpdateMonitoringDisplay();
}

//+------------------------------------------------------------------+
//| Process multi-symbol trading                                     |
//+------------------------------------------------------------------+
void ProcessMultiSymbolTrading()
{
   int symbolCount = ArraySize(activeSymbols);
   
   for(int i = 0; i < symbolCount && CountTotalPositions() < MaxPositions; i++)
   {
      string symbol = activeSymbols[i];
      if(symbol == NULL || symbol == "") continue;
      
      // Skip if already have position on this symbol
      if(HasPositionOnSymbol(symbol)) continue;
      
      // Skip if symbol affected by news
      if(EnableNewsFilter && IsSymbolAffectedByNews(symbol)) continue;
      
      // Set current symbol for analysis
      if(!SymbolSelect(symbol, true)) continue;
      
      // Market regime analysis for current symbol
      ENUM_MARKET_REGIME regime = AnalyzeMarketRegime(symbol);
      
      // Execute trading logic based on regime
      switch(regime)
      {
         case REGIME_TREND:
            ProcessTrendMode(symbol);
            break;
         case REGIME_SIDEWAYS:
            ProcessSidewaysMode(symbol);
            break;
         default:
            // No trading in neutral regime
            break;
      }
   }
}

//+------------------------------------------------------------------+
//| Update active symbols list                                       |
//+------------------------------------------------------------------+
void UpdateActiveSymbolsList()
{
   ArrayResize(activeSymbols, 0);
   int count = 0;
   
   // Scan all symbols in Market Watch
   int totalSymbols = SymbolsTotal(true);
   
   for(int i = 0; i < totalSymbols; i++)
   {
      string symbol = SymbolName(i, true);
      if(symbol == NULL || symbol == "") continue;
      
      // Filter symbols based on criteria
      if(IsSymbolSuitable(symbol))
      {
         ArrayResize(activeSymbols, count + 1);
         activeSymbols[count] = symbol;
         count++;
      }
   }
   
   Print(StringFormat("Updated active symbols list: %d symbols", count));
}

//+------------------------------------------------------------------+
//| Check if symbol is suitable for trading                          |
//+------------------------------------------------------------------+
bool IsSymbolSuitable(string symbol)
{
   // Check if symbol is tradeable
   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE)) return false;
   
   // Check minimum volume
   double minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   if(minVolume <= 0) return false;
   
   // Check spread (skip if too wide)
   double spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double maxSpread = 30 * point; // Max 3 pips spread
   
   if(spread * point > maxSpread) return false;
   
   // Check if there's sufficient price history
   datetime rates[];
   if(CopyTime(symbol, PERIOD_M5, 0, 200, rates) < 200) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Analyze market regime for symbol                                 |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME AnalyzeMarketRegime(string symbol)
{
   double adx_values[];
   if(CopyBuffer(adx_handle_h4, 0, 0, 1, adx_values) <= 0) return REGIME_NEUTRAL;
   
   double adx_value = adx_values[0];
   
   if(adx_value > ADX_TrendThreshold) return REGIME_TREND;
   if(adx_value < ADX_SidewaysThreshold) return REGIME_SIDEWAYS;
   
   return REGIME_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Process trend mode trading                                       |
//+------------------------------------------------------------------+
void ProcessTrendMode(string symbol)
{
   // Get indicator values
   double ema3[], ema8[], ema200[], rsi[], volume[], atr_values[];
   
   if(CopyBuffer(ema3_handle_m5, 0, 0, 2, ema3) <= 0) return;
   if(CopyBuffer(ema8_handle_m5, 0, 0, 2, ema8) <= 0) return;
   if(CopyBuffer(ema200_handle_h1, 0, 0, 1, ema200) <= 0) return;
   if(CopyBuffer(rsi_trend_handle, 0, 0, 1, rsi) <= 0) return;
   if(CopyBuffer(volume_handle, 0, 0, 21, volume) <= 0) return;
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_values) <= 0) return;
   
   // Calculate volume moving average
   double volume_ma = 0;
   for(int i = 1; i <= 20; i++) volume_ma += volume[i];
   volume_ma /= 20;
   
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Volatility filter for trend mode
   if(atr_values[0] > 15 * SymbolInfoDouble(symbol, SYMBOL_POINT)) return;
   
   // Buy conditions
   if(ema3[0] > ema8[0] && 
      rsi[0] > 55 && 
      volume[0] > volume_ma * VolumeSpikeFactor &&
      current_price > ema200[0] &&
      CandelCloseAboveEMA8(symbol))
   {
      ExecuteTrade(symbol, ORDER_TYPE_BUY, REGIME_TREND, rsi[0]);
   }
   // Sell conditions
   else if(ema3[0] < ema8[0] && 
           rsi[0] < 45 && 
           volume[0] > volume_ma * VolumeSpikeFactor &&
           current_price < ema200[0] &&
           CandelCloseBelowEMA8(symbol))
   {
      ExecuteTrade(symbol, ORDER_TYPE_SELL, REGIME_TREND, rsi[0]);
   }
}

//+------------------------------------------------------------------+
//| Process sideways mode trading                                    |
//+------------------------------------------------------------------+
void ProcessSidewaysMode(string symbol)
{
   // Get indicator values
   double bb_upper[], bb_lower[], rsi[], volume[], atr_values[];
   
   if(CopyBuffer(bb_handle_m5, 1, 0, 1, bb_upper) <= 0) return; // Upper band
   if(CopyBuffer(bb_handle_m5, 2, 0, 1, bb_lower) <= 0) return; // Lower band
   if(CopyBuffer(rsi_sideways_handle, 0, 0, 1, rsi) <= 0) return;
   if(CopyBuffer(volume_handle, 0, 0, 21, volume) <= 0) return;
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_values) <= 0) return;
   
   // Calculate volume moving average
   double volume_ma = 0;
   for(int i = 1; i <= 20; i++) volume_ma += volume[i];
   volume_ma /= 20;
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Volatility filter for sideways mode
   if(atr_values[0] < 5 * SymbolInfoDouble(symbol, SYMBOL_POINT)) return;
   
   // Buy conditions (touch lower BB)
   if(ask <= bb_lower[0] && 
      rsi[0] < 35 && 
      volume[0] > volume_ma * VolumeSpikeFactor &&
      IsBullishReversalPattern(symbol))
   {
      ExecuteTrade(symbol, ORDER_TYPE_BUY, REGIME_SIDEWAYS, rsi[0]);
   }
   // Sell conditions (touch upper BB)
   else if(bid >= bb_upper[0] && 
           rsi[0] > 65 && 
           volume[0] > volume_ma * VolumeSpikeFactor &&
           IsBearishReversalPattern(symbol))
   {
      ExecuteTrade(symbol, ORDER_TYPE_SELL, REGIME_SIDEWAYS, rsi[0]);
   }
}

//+------------------------------------------------------------------+
//| Execute trade with risk management                               |
//+------------------------------------------------------------------+
void ExecuteTrade(string symbol, ENUM_ORDER_TYPE orderType, ENUM_MARKET_REGIME regime, double rsi_value)
{
   // Calculate dynamic lot size
   double lot = CalculateDynamicLot(symbol, regime);
   if(lot <= 0) return;
   
   // Calculate SL and TP based on regime
   double sl, tp;
   CalculateSLTP(symbol, orderType, regime, sl, tp);
   
   double price = (orderType == ORDER_TYPE_BUY) ? 
                  SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                  SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Execute trade
   if(trade.PositionOpen(symbol, orderType, lot, price, sl, tp, 
      StringFormat("QHM_%s", EnumToString(regime))))
   {
      totalTrades++;
      
      // Log to CSV
      LogTradeToCSV(symbol, orderType, price, lot, regime, rsi_value, 0, GetCurrentDrawdown());
      
      Print(StringFormat("Trade executed: %s %s %.2f lots, SL: %.5f, TP: %.5f", 
            symbol, EnumToString(orderType), lot, sl, tp));
   }
   else
   {
      Print(StringFormat("Trade failed: %s - Error: %d", symbol, GetLastError()));
   }
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size                                        |
//+------------------------------------------------------------------+
double CalculateDynamicLot(string symbol, ENUM_MARKET_REGIME regime)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPerTrade / 100.0;
   
   // Get symbol info
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   // Calculate SL distance based on regime
   double slDistance;
   if(regime == REGIME_TREND)
      slDistance = 3 * SymbolInfoDouble(symbol, SYMBOL_POINT) * 10; // 3 pips
   else
      slDistance = 4 * SymbolInfoDouble(symbol, SYMBOL_POINT) * 10; // 4 pips
   
   // Calculate lot size
   double lot = riskAmount / (slDistance * tickValue / tickSize);
   
   // Normalize lot size
   lot = MathFloor(lot / lotStep) * lotStep;
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   
   return lot;
}

//+------------------------------------------------------------------+
//| Calculate SL and TP                                              |
//+------------------------------------------------------------------+
void CalculateSLTP(string symbol, ENUM_ORDER_TYPE orderType, ENUM_MARKET_REGIME regime, 
                   double &sl, double &tp)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double price = (orderType == ORDER_TYPE_BUY) ? 
                  SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                  SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(regime == REGIME_TREND)
   {
      // Trend mode: SL 3 pips, TP 12 pips (1:4 RR)
      if(orderType == ORDER_TYPE_BUY)
      {
         sl = price - 30 * point; // 3 pips
         tp = price + 120 * point; // 12 pips
      }
      else
      {
         sl = price + 30 * point;
         tp = price - 120 * point;
      }
   }
   else // REGIME_SIDEWAYS
   {
      // Sideways mode: SL 4 pips, TP 6 pips (1:1.5 RR)
      if(orderType == ORDER_TYPE_BUY)
      {
         sl = price - 40 * point; // 4 pips
         tp = price + 60 * point; // 6 pips
      }
      else
      {
         sl = price + 40 * point;
         tp = price - 60 * point;
      }
   }
}

//+------------------------------------------------------------------+
//| Check drawdown protection                                        |
//+------------------------------------------------------------------+
bool CheckDrawdownProtection()
{
   double currentDrawdown = GetCurrentDrawdown();
   
   if(currentDrawdown >= MaxDrawdown)
   {
      CloseAllPositions();
      Print(StringFormat("EMERGENCY: Max drawdown reached (%.2f%%). All positions closed.", currentDrawdown));
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check circuit breaker                                            |
//+------------------------------------------------------------------+
bool CheckCircuitBreaker()
{
   if(consecutiveLosses >= MaxConsecutiveLoss)
   {
      pauseUntil = TimeCurrent() + PauseDuration * 60;
      consecutiveLosses = 0;
      Print(StringFormat("Circuit breaker activated. Trading paused for %d minutes.", PauseDuration));
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get current drawdown percentage                                  |
//+------------------------------------------------------------------+
double GetCurrentDrawdown()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   return ((balance - equity) / balance) * 100.0;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Magic() == magicNumber)
         {
            trade.PositionClose(positionInfo.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if high impact news is approaching                         |
//+------------------------------------------------------------------+
bool IsHighImpactNews()
{
   datetime current = TimeCurrent();
   string currentSymbol = _Symbol;
   
   // Extract currencies from current symbol
   string baseCurrency = StringSubstr(currentSymbol, 0, 3);
   string quoteCurrency = StringSubstr(currentSymbol, 3, 3);
   
   for(int i = 0; i < ArraySize(newsEvents); i++)
   {
      if(newsEvents[i].impact >= 3) // High impact only
      {
         // Check if news affects current trading pair
         bool affectsSymbol = (newsEvents[i].currency == baseCurrency || 
                              newsEvents[i].currency == quoteCurrency);
         
         if(affectsSymbol)
         {
            datetime newsTime = newsEvents[i].time;
            int minutesBefore = (int)((newsTime - current) / 60);
            int minutesAfter = (int)((current - newsTime) / 60);
            
            if((minutesBefore <= PreNewsMinutes && minutesBefore >= 0) ||
               (minutesAfter <= PostNewsMinutes && minutesAfter >= 0))
            {
               Print(StringFormat("News filter active: %s %s in %d minutes", 
                     newsEvents[i].currency, newsEvents[i].event, minutesBefore));
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if symbol is affected by upcoming news                     |
//+------------------------------------------------------------------+
bool IsSymbolAffectedByNews(string symbol)
{
   datetime current = TimeCurrent();
   
   // Extract currencies from symbol
   string baseCurrency = StringSubstr(symbol, 0, 3);
   string quoteCurrency = StringSubstr(symbol, 3, 3);
   
   for(int i = 0; i < ArraySize(newsEvents); i++)
   {
      if(newsEvents[i].impact >= 3) // High impact only
      {
         // Check if news affects this symbol
         bool affectsSymbol = (newsEvents[i].currency == baseCurrency || 
                              newsEvents[i].currency == quoteCurrency);
         
         if(affectsSymbol)
         {
            datetime newsTime = newsEvents[i].time;
            int minutesBefore = (int)((newsTime - current) / 60);
            int minutesAfter = (int)((current - newsTime) / 60);
            
            if((minutesBefore <= PreNewsMinutes && minutesBefore >= 0) ||
               (minutesAfter <= PostNewsMinutes && minutesAfter >= 0))
            {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if valid trading session                                   |
//+------------------------------------------------------------------+
bool IsValidTradingSession()
{
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   
   // GMT 05:00-22:00 for sideways mode, always valid for trend mode
   return (time.hour >= 5 && time.hour < 22);
}

//+------------------------------------------------------------------+
//| Helper functions                                                 |
//+------------------------------------------------------------------+
bool CandelCloseAboveEMA8(string symbol)
{
   double close_price = iClose(symbol, PERIOD_M5, 1);
   double ema8[];
   if(CopyBuffer(ema8_handle_m5, 0, 1, 1, ema8) <= 0) return false;
   return close_price > ema8[0];
}

bool CandelCloseBelowEMA8(string symbol)
{
   double close_price = iClose(symbol, PERIOD_M5, 1);
   double ema8[];
   if(CopyBuffer(ema8_handle_m5, 0, 1, 1, ema8) <= 0) return false;
   return close_price < ema8[0];
}

bool IsBullishReversalPattern(string symbol)
{
   return IsBullishReversalPatternAdvanced(symbol);
}

bool IsBearishReversalPattern(string symbol)
{
   return IsBearishReversalPatternAdvanced(symbol);
}

int CountTotalPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Magic() == magicNumber)
            count++;
      }
   }
   return count;
}

bool HasPositionOnSymbol(string symbol)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Magic() == magicNumber && positionInfo.Symbol() == symbol)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Log trade to CSV                                                 |
//+------------------------------------------------------------------+
void LogTradeToCSV(string symbol, ENUM_ORDER_TYPE orderType, double price, double volume,
                   ENUM_MARKET_REGIME regime, double rsi_value, double profit, double drawdown)
{
   int file_handle = FileOpen(csvFileName, FILE_WRITE|FILE_CSV|FILE_READ);
   if(file_handle != INVALID_HANDLE)
   {
      FileSeek(file_handle, 0, SEEK_END);
      
      string log_line = StringFormat("%s,%s,%s,%.5f,%.2f,%s,%.2f,%.2f,%.2f\n",
                                    TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
                                    symbol,
                                    EnumToString(orderType),
                                    price,
                                    volume,
                                    EnumToString(regime),
                                    rsi_value,
                                    profit,
                                    drawdown);
      
      FileWriteString(file_handle, log_line);
      FileClose(file_handle);
   }
}

//+------------------------------------------------------------------+
//| Display info on chart                                            |
//+------------------------------------------------------------------+
void DisplayInfo(string status)
{
   string info = StringFormat("QuantumHedgingMatrixPro v1.20\n%s\nPositions: %d/%d\nDrawdown: %.2f%%\nConsecutive Losses: %d\nTotal Trades: %d",
                             status,
                             CountTotalPositions(),
                             MaxPositions,
                             GetCurrentDrawdown(),
                             consecutiveLosses,
                             totalTrades);
   
   Comment(info);
}

//+------------------------------------------------------------------+
//| Update monitoring display                                         |
//+------------------------------------------------------------------+
void UpdateMonitoringDisplay()
{
   ENUM_MARKET_REGIME regime = AnalyzeMarketRegime(_Symbol);
   string regimeText = "";
   
   switch(regime)
   {
      case REGIME_TREND: regimeText = "TREND"; break;
      case REGIME_SIDEWAYS: regimeText = "SIDEWAYS"; break;
      default: regimeText = "NEUTRAL"; break;
   }
   
   string status = StringFormat("Status: ACTIVE | Regime: %s", regimeText);
   DisplayInfo(status);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(adx_handle_h4 != INVALID_HANDLE) IndicatorRelease(adx_handle_h4);
   if(ema3_handle_m5 != INVALID_HANDLE) IndicatorRelease(ema3_handle_m5);
   if(ema8_handle_m5 != INVALID_HANDLE) IndicatorRelease(ema8_handle_m5);
   if(ema200_handle_h1 != INVALID_HANDLE) IndicatorRelease(ema200_handle_h1);
   if(rsi_trend_handle != INVALID_HANDLE) IndicatorRelease(rsi_trend_handle);
   if(rsi_sideways_handle != INVALID_HANDLE) IndicatorRelease(rsi_sideways_handle);
   if(bb_handle_m5 != INVALID_HANDLE) IndicatorRelease(bb_handle_m5);
   if(atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
   if(volume_handle != INVALID_HANDLE) IndicatorRelease(volume_handle);
   
   Comment("");
   Print("QuantumHedgingMatrixPro EA deinitialized");
}

//+------------------------------------------------------------------+
//| Trade event handler                                              |
//+------------------------------------------------------------------+
void OnTrade()
{
   // Update consecutive losses counter
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      if(HistoryDealSelect(i))
      {
         if(HistoryDealGetInteger(i, DEAL_MAGIC) == magicNumber &&
            HistoryDealGetInteger(i, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            double profit = HistoryDealGetDouble(i, DEAL_PROFIT);
            
            if(profit < 0)
               consecutiveLosses++;
            else
               consecutiveLosses = 0;
            
            // Log closed trade to CSV
            string symbol = HistoryDealGetString(i, DEAL_SYMBOL);
            double volume = HistoryDealGetDouble(i, DEAL_VOLUME);
            double price = HistoryDealGetDouble(i, DEAL_PRICE);
            
            LogTradeToCSV(symbol, ORDER_TYPE_BUY, price, volume, REGIME_NEUTRAL, 0, profit, GetCurrentDrawdown());
            break;
         }
      }
   }
}