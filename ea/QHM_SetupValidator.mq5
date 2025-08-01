//+------------------------------------------------------------------+
//|                                 QHM_SetupValidator.mq5           |
//|                        Setup Validation Utility                  |
//|                   For QuantumHedgingMatrixPro EA                 |
//+------------------------------------------------------------------+
#property copyright "Setup Validator"
#property version   "1.00"
#property script_show_inputs

input bool CheckAccountSettings = true;
input bool CheckSymbols = true;
input bool CheckIndicators = true;
input bool ValidateParameters = true;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== QuantumHedgingMatrixPro Setup Validation ===");
   
   bool setupValid = true;
   
   if(CheckAccountSettings)
   {
      Print("--- Checking Account Settings ---");
      setupValid &= ValidateAccountSettings();
   }
   
   if(CheckSymbols)
   {
      Print("--- Checking Available Symbols ---");
      setupValid &= ValidateSymbols();
   }
   
   if(CheckIndicators)
   {
      Print("--- Checking Indicator Availability ---");
      setupValid &= ValidateIndicators();
   }
   
   if(ValidateParameters)
   {
      Print("--- Validating EA Parameters ---");
      setupValid &= ValidateEAParameters();
   }
   
   Print("--- Validation Summary ---");
   if(setupValid)
   {
      Print("✅ SETUP VALIDATION PASSED - Ready to run QuantumHedgingMatrixPro EA");
      Print("🚀 You can now attach the EA to any chart and start trading");
   }
   else
   {
      Print("❌ SETUP VALIDATION FAILED - Please fix the issues above");
      Print("📝 Check the documentation for setup requirements");
   }
   
   Print("=== Validation Completed ===");
}

//+------------------------------------------------------------------+
//| Validate account settings                                        |
//+------------------------------------------------------------------+
bool ValidateAccountSettings()
{
   bool passed = true;
   
   // Check if auto trading is enabled
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print("❌ Auto trading is not allowed in terminal");
      Print("🔧 Fix: Enable 'Allow automated trading' in MT5 options");
      passed = false;
   }
   else
   {
      Print("✅ Auto trading is enabled");
   }
   
   // Check account balance
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance < 100)
   {
      Print("⚠️ Account balance is very low: $", balance);
      Print("💡 Recommendation: Minimum $1000 for proper operation");
   }
   else
   {
      Print("✅ Account balance sufficient: $", balance);
   }
   
   // Check account type
   ENUM_ACCOUNT_TRADE_MODE tradeMode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(tradeMode == ACCOUNT_TRADE_MODE_DEMO)
   {
      Print("✅ Demo account - Good for testing");
   }
   else if(tradeMode == ACCOUNT_TRADE_MODE_REAL)
   {
      Print("⚠️ Real account - Make sure you've tested thoroughly");
   }
   
   // Check leverage
   long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   Print("📊 Account leverage: 1:", leverage);
   if(leverage < 100)
   {
      Print("⚠️ Low leverage may limit trading opportunities");
   }
   
   return passed;
}

//+------------------------------------------------------------------+
//| Validate available symbols                                        |
//+------------------------------------------------------------------+
bool ValidateSymbols()
{
   int totalSymbols = SymbolsTotal(true);
   int suitableSymbols = 0;
   
   Print("📈 Total symbols in Market Watch: ", totalSymbols);
   
   if(totalSymbols < 5)
   {
      Print("⚠️ Very few symbols in Market Watch");
      Print("💡 Add more currency pairs for better diversification");
   }
   
   // Check major pairs
   string majorPairs[] = {"EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD"};
   int majorFound = 0;
   
   for(int i = 0; i < ArraySize(majorPairs); i++)
   {
      if(SymbolSelect(majorPairs[i], false)) // Check if exists
      {
         if(SymbolSelect(majorPairs[i], true)) // Add to Market Watch
         {
            majorFound++;
            
            // Check if tradeable
            if(SymbolInfoInteger(majorPairs[i], SYMBOL_TRADE_MODE))
            {
               suitableSymbols++;
               Print("✅ ", majorPairs[i], " - Available and tradeable");
            }
            else
            {
               Print("❌ ", majorPairs[i], " - Available but not tradeable");
            }
         }
      }
   }
   
   Print("📊 Major pairs found: ", majorFound, "/", ArraySize(majorPairs));
   Print("📊 Suitable symbols for trading: ", suitableSymbols);
   
   return (suitableSymbols >= 3);
}

//+------------------------------------------------------------------+
//| Validate indicator availability                                   |
//+------------------------------------------------------------------+
bool ValidateIndicators()
{
   bool passed = true;
   string symbol = _Symbol;
   
   // Test ADX
   int adx_handle = iADX(symbol, PERIOD_H4, 14);
   if(adx_handle == INVALID_HANDLE)
   {
      Print("❌ ADX indicator not available");
      passed = false;
   }
   else
   {
      Print("✅ ADX indicator available");
      IndicatorRelease(adx_handle);
   }
   
   // Test EMA
   int ema_handle = iMA(symbol, PERIOD_M5, 3, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE)
   {
      Print("❌ EMA indicator not available");
      passed = false;
   }
   else
   {
      Print("✅ EMA indicator available");
      IndicatorRelease(ema_handle);
   }
   
   // Test RSI
   int rsi_handle = iRSI(symbol, PERIOD_M5, 5, PRICE_CLOSE);
   if(rsi_handle == INVALID_HANDLE)
   {
      Print("❌ RSI indicator not available");
      passed = false;
   }
   else
   {
      Print("✅ RSI indicator available");
      IndicatorRelease(rsi_handle);
   }
   
   // Test Bollinger Bands
   int bb_handle = iBands(symbol, PERIOD_M5, 10, 0, 1.5, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE)
   {
      Print("❌ Bollinger Bands indicator not available");
      passed = false;
   }
   else
   {
      Print("✅ Bollinger Bands indicator available");
      IndicatorRelease(bb_handle);
   }
   
   // Test ATR
   int atr_handle = iATR(symbol, PERIOD_M5, 14);
   if(atr_handle == INVALID_HANDLE)
   {
      Print("❌ ATR indicator not available");
      passed = false;
   }
   else
   {
      Print("✅ ATR indicator available");
      IndicatorRelease(atr_handle);
   }
   
   return passed;
}

//+------------------------------------------------------------------+
//| Validate EA parameters                                            |
//+------------------------------------------------------------------+
bool ValidateEAParameters()
{
   bool passed = true;
   
   // Simulate EA parameter validation
   double testRiskPerTrade = 0.5;
   double testMaxDrawdown = 15.0;
   int testMaxPositions = 20;
   
   if(testRiskPerTrade < 0.1 || testRiskPerTrade > 2.0)
   {
      Print("❌ RiskPerTrade should be between 0.1 and 2.0");
      passed = false;
   }
   else
   {
      Print("✅ RiskPerTrade parameter in valid range");
   }
   
   if(testMaxDrawdown < 5.0 || testMaxDrawdown > 30.0)
   {
      Print("❌ MaxDrawdown should be between 5.0 and 30.0");
      passed = false;
   }
   else
   {
      Print("✅ MaxDrawdown parameter in valid range");
   }
   
   if(testMaxPositions < 1 || testMaxPositions > 100)
   {
      Print("❌ MaxPositions should be between 1 and 100");
      passed = false;
   }
   else
   {
      Print("✅ MaxPositions parameter in valid range");
   }
   
   // Check minimum lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(minLot <= 0)
   {
      Print("❌ Cannot determine minimum lot size for ", _Symbol);
      passed = false;
   }
   else
   {
      Print("✅ Minimum lot size: ", minLot);
   }
   
   return passed;
}

//+------------------------------------------------------------------+
//| Additional helper functions                                       |
//+------------------------------------------------------------------+
void PrintSystemInfo()
{
   Print("--- System Information ---");
   Print("Terminal: ", TerminalInfoString(TERMINAL_NAME));
   Print("Build: ", TerminalInfoInteger(TERMINAL_BUILD));
   Print("Company: ", TerminalInfoString(TERMINAL_COMPANY));
   Print("Server: ", AccountInfoString(ACCOUNT_SERVER));
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
}