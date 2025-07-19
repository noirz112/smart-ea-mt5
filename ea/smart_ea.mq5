#property copyright "Smart EA"
#property link      ""
#property version   "2.60"  // Updated to version 2.60 for stage 26
#property strict

// Removed invalid include
#include <Trade\Trade.mqh> // For trade operations
#include <Trade\SymbolInfo.mqh> // For SymbolInfoDouble

// Input parameters
input double LotSize = 0.01;
input int MagicNumber = 12345;
input string ApiUrl = "http://localhost:5000/strategy";
input string RiskUrl = "http://localhost:5000/risk/lot";
input string UpdateUrl = "http://localhost:5000/update";
input string LogUrl = "http://localhost:5000/log";  // New for logging
input bool EnableHedging = false;  // Optional hedging feature

// Global variables
string Strategies[] = {"scalping", "breakout", "reversal", "news", "trend_following"};
bool ActiveStrategies[5] = {true, true, true, true, true};
double ConfidenceScores[5];
datetime lastTradeTime = 0;
int atrHandle;
int apiFailureCount = 0;
bool tradingEnabled = true;
double currentWinRate = 0.5;  // Default win rate

// Time filter for London/NY sessions (UTC)
int LondonOpen = 8; // 8:00 UTC
int NYOpen = 13; // 13:00 UTC
int SessionClose = 22; // 22:00 UTC

void OnInit() {
   Print("Smart EA Initialized - Stage 1 Upgrade");
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if (atrHandle == INVALID_HANDLE) Print("ATR Handle Invalid");
}

// New function for partial position management
void PartialClose() {
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
   if (atr == EMPTY_VALUE) return;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i))) {
         if (PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double profit = PositionGetDouble(POSITION_PROFIT);
            double volume = PositionGetDouble(POSITION_VOLUME);
            if (profit > atr * 2 * volume * _Point) {  // Partial close at 2x ATR profit
               trade.PositionClosePartial(PositionGetTicket(i), volume / 2);
               LogTrade("PARTIAL_CLOSE", PositionGetString(POSITION_COMMENT), profit, 0.0);
            }
         }
      }
   }
}

// New function to check if hedging is possible
bool CanHedge(long positionType) {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         if (PositionGetInteger(POSITION_TYPE) != positionType) {
            return true;
         }
      }
   }
   return false;
}

void OnTick() {
   if (!IsTradeTime() || !tradingEnabled) return;
   
   // Get strategy from AI
   string strategy = GetAIStrategy();
   double confidence = GetConfidence(strategy);
   if (confidence < 0.5) return;
   
   double lot = CalculateLotSize(AccountInfoDouble(ACCOUNT_BALANCE), 1.0);
   
   ulong ticket = 0;
   bool isBuy = false;
   bool isSell = false;
   
   if (strategy == "scalping") {
       ticket = ScalpingTrade(lot);
   } else if (strategy == "breakout") {
       ticket = BreakoutTrade(lot);
   } else if (strategy == "reversal") {
       ticket = ReversalTrade(lot);
   } else if (strategy == "news") {
       ticket = NewsTrade(lot);
   } else if (strategy == "trend_following") {
       ticket = TrendFollowingTrade(lot);
   }
   
   if (ticket > 0) {
      SetDynamicSLTP(ticket);
      LogTrade("TRADE_OPEN", strategy, lot, confidence);
      if (EnableHedging && confidence > 0.7) {
         // Check for hedging opportunity
         PositionSelectByTicket(ticket);
         long posType = PositionGetInteger(POSITION_TYPE);
         if (CanHedge(posType)) {
            double hedgeLot = lot * 0.5;  // Hedge with half lot
            CTrade trade;
            trade.SetExpertMagicNumber(MagicNumber);
            ulong hedgeTicket = (posType == POSITION_TYPE_BUY) ?
               trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, hedgeLot, 0, 0, 0, "hedge") :
               trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, hedgeLot, 0, 0, 0, "hedge");
            if (hedgeTicket > 0) {
               SetDynamicSLTP(hedgeTicket);
               LogTrade("HEDGE_OPEN", strategy, hedgeLot, confidence);
            }
         }
      }
   }
   
   TrailingStop();
   PartialClose();
   
   CheckClosedTrades();
}

void LogTrade(string level, string message, double lot, double confidence) {
   string request = StringFormat("level=%s&message=%s&data={\"lot\":%f,\"confidence\":%f}", level, message, lot, confidence);
   char postData[];
   StringToCharArray(request, postData);
   char result[];
   string headers = "Content-Type: application/x-www-form-urlencoded";
   string resultHeaders;
   int res = WebRequest("POST", LogUrl, headers, 10, postData, result, resultHeaders);
   if (res == -1) Print("Log failed: ", GetLastError());
}

string GetAIStrategy() {
   char result[];
   string headers;
   char data[];
   int res = WebRequest("GET", ApiUrl, "", 10000, data, result, headers);
   if (res == -1) {
      Print("API request failed: ", GetLastError());
      apiFailureCount++;
      if (apiFailureCount > 5) tradingEnabled = false;
      return "none";
   }
   string response = CharArrayToString(result);
   // Parse JSON (simplified, assume response is {"strategy": "scalping", "confidence": 0.8})
   int start = StringFind(response, "\"strategy\": \"", 0);
   if (start == -1) return "none";
   start += 13;
   int end = StringFind(response, "\"", start);
   string strategy = StringSubstr(response, start, end - start);
   start = StringFind(response, "\"confidence\": ", 0);
   if (start == -1) return strategy;
   start += 14;
   end = StringFind(response, "}", start);
   double conf = StringToDouble(StringSubstr(response, start, end - start));
   // Store confidence (simplified, use array index)
   for (int i = 0; i < ArraySize(Strategies); i++) {
      if (Strategies[i] == strategy) ConfidenceScores[i] = conf;
   }
   return strategy;
}

double GetConfidence(string strategy) {
   for (int i = 0; i < ArraySize(Strategies); i++) {
      if (Strategies[i] == strategy) return ConfidenceScores[i];
   }
   return 0.0;
}

double CalculateLotSize(double balance, double risk) {
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
   if (atr == EMPTY_VALUE) atr = 0.001;  // Fallback
   double volatilityFactor = (atr > 0.002) ? 0.5 : 1.0;  // Reduce lot in high volatility
   double winRateFactor = (currentWinRate > 0.6) ? 1.2 : 0.8;  // Adjust based on win rate
   
   char result[];
   string result_headers;
   string request = StringFormat("balance=%f&risk=%f", balance, risk);
   char data[];
   StringToCharArray(request, data);
   int res = WebRequest("POST", RiskUrl, "", 0, data, result, result_headers);
   if (res == -1) {
      Print("Risk API failed");
      return LotSize * volatilityFactor * winRateFactor; // Fallback with adjustments
   }
   double baseLot = StringToDouble(CharArrayToString(result));
   return baseLot * volatilityFactor * winRateFactor;
}

ulong ScalpingTrade(double lot) {
   double ma = iMA(_Symbol, PERIOD_M1, 5, 0, MODE_SMA, PRICE_CLOSE);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if (ma == EMPTY_VALUE) return 0;
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   if (ask > ma + 5 * _Point && CountOpenPositions() < 10) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lot, 0, 0, 0, "scalping");
   } else if (bid < ma - 5 * _Point && CountOpenPositions() < 10) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lot, 0, 0, 0, "scalping");
   }
   return 0;
}

ulong BreakoutTrade(double lot) {
   double high = iHigh(_Symbol, PERIOD_M5, 1);
   double low = iLow(_Symbol, PERIOD_M5, 1);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   if (ask > high && CountOpenPositions() < 5) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lot, 0, 0, 0, "breakout");
   } else if (bid < low && CountOpenPositions() < 5) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lot, 0, 0, 0, "breakout");
   }
   return 0;
}

ulong ReversalTrade(double lot) {
   double rsi = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE);
   if (rsi == EMPTY_VALUE) return 0;
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   if (rsi < 30 && CountOpenPositions() < 5) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lot, 0, 0, 0, "reversal");
   } else if (rsi > 70 && CountOpenPositions() < 5) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lot, 0, 0, 0, "reversal");
   }
   return 0;
}

ulong NewsTrade(double lot) {
   double atr = iATR(_Symbol, PERIOD_M1, 14);
   if (atr > 0.001 && CountOpenPositions() < 3) { // High volatility
      CTrade trade;
      trade.SetExpertMagicNumber(MagicNumber);
      if (MathRand() % 2 == 0) {
         return trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lot * 2, 0, 0, 0, "news"); // Aggressive lot
      } else {
         return trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lot * 2, 0, 0, 0, "news");
      }
   }
   return 0;
}

bool IsTradeTime() {
   MqlDateTime time;
   TimeCurrent(time);
   int hour = time.hour;
   // Focus on overlap hours for higher activity (e.g., 13:00-17:00 UTC for London/NY overlap)
   return (hour >= 13 && hour < 17);
}

void UpdateWinRate(string strategy, bool win) {
   string request = StringFormat("strategy=%s&win=%d", strategy, win ? 1 : 0);
   char data[];
   StringToCharArray(request, data);
   char result[];
   string resultHeaders;
   int res = WebRequest("POST", UpdateUrl, "", 10, data, result, resultHeaders);
   if (res == -1) Print("Update failed");
   else {
      // Assume API returns current win rate in response (simplified)
      currentWinRate = StringToDouble(CharArrayToString(result));
   }
}

void CheckClosedTrades() {
   for (int i = HistoryDealsTotal() - 1; i >= 0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if (ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber && HistoryDealGetInteger(ticket, DEAL_TIME) > lastTradeTime) {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         bool win = profit > 0;
         // Assume strategy from comment or something; simplified
         string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
         string strategy = (comment != "") ? comment : "unknown";
         UpdateWinRate(strategy, win);
         LogTrade("TRADE_CLOSE", strategy, profit, win ? 1.0 : 0.0);
         lastTradeTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      }
   }
}

// Enhanced TrailingStop with dynamic step based on ATR and confidence
void TrailingStop() {
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
   if (atr == EMPTY_VALUE) return;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionSelectByTicket(PositionGetTicket(i))) {
         if (PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            string strategy = PositionGetString(POSITION_COMMENT);
            double confidence = GetConfidence(strategy);
            double trailStep = atr * (0.5 + confidence); // Dynamic step: tighter for high confidence
            
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               if (currentPrice - openPrice > trailStep * 2) {
                  double newSL = currentPrice - trailStep;
                  if (newSL > currentSL) {
                     trade.PositionModify(PositionGetTicket(i), newSL, currentTP);
                  }
               }
            } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
               if (openPrice - currentPrice > trailStep * 2) {
                  double newSL = currentPrice + trailStep;
                  if (newSL < currentSL || currentSL == 0) {
                     trade.PositionModify(PositionGetTicket(i), newSL, currentTP);
                  }
               }
            }
         }
      }
   }
}

// Enhanced Dynamic TP/SL with better confidence integration
void SetDynamicSLTP(ulong ticket) {
   if (!PositionSelectByTicket(ticket)) return;
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
   if (atr == EMPTY_VALUE) return;
   string strategy = PositionGetString(POSITION_COMMENT);
   double confidence = GetConfidence(strategy);
   double sl_offset = atr * (2.0 - confidence); // Tighter SL for high confidence
   double tp_offset = atr * (4.0 * confidence); // Wider TP for high confidence
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   CTrade trade;
   if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
      double sl = open - sl_offset;
      double tp = open + tp_offset;
      trade.PositionModify(ticket, sl, tp);
   } else {
      double sl = open + sl_offset;
      double tp = open - tp_offset;
      trade.PositionModify(ticket, sl, tp);
   }
}


int CountOpenPositions() {
   int count = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         count++;
      }
   }
   return count;
}

void OnDeinit(const int reason) {
   IndicatorRelease(atrHandle);
   Print("Smart EA Deinitialized");
}

ulong TrendFollowingTrade(double lot) {
   double ma50 = iMA(_Symbol, PERIOD_M5, 50, 0, MODE_SMA, PRICE_CLOSE);
   double ma200 = iMA(_Symbol, PERIOD_M5, 200, 0, MODE_SMA, PRICE_CLOSE);
   if (ma50 == EMPTY_VALUE || ma200 == EMPTY_VALUE) return 0;
   CTrade trade;
   trade.SetExpertMagicNumber(MagicNumber);
   if (ma50 > ma200 && CountOpenPositions() < 5) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lot, 0, 0, 0, "trend_following");
   } else if (ma50 < ma200 && CountOpenPositions() < 5) {
      return trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lot, 0, 0, 0, "trend_following");
   }
   return 0;
}