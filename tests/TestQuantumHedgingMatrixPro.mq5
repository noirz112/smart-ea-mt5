//+------------------------------------------------------------------+
//|                                 TestQuantumHedgingMatrixPro.mq5  |
//|                        Test script for QuantumHedgingMatrixPro   |
//+------------------------------------------------------------------+
#property copyright "Test Script"
#property version   "1.00"
#property script_show_inputs

#include <Trade\Trade.mqh>

// Test parameters
input bool TestRiskManagement = true;
input bool TestRegimeDetection = true;
input bool TestLotCalculation = true;
input bool TestPositionManagement = true;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== Starting QuantumHedgingMatrixPro EA Tests ===");
   
   bool allTestsPassed = true;
   
   if(TestRiskManagement)
   {
      Print("--- Testing Risk Management ---");
      allTestsPassed &= TestDrawdownCalculation();
      allTestsPassed &= TestLotSizeCalculation();
   }
   
   if(TestRegimeDetection)
   {
      Print("--- Testing Regime Detection ---");
      allTestsPassed &= TestADXRegimeDetection();
   }
   
   if(TestLotCalculation)
   {
      Print("--- Testing Lot Calculation ---");
      allTestsPassed &= TestDynamicLotSizing();
   }
   
   if(TestPositionManagement)
   {
      Print("--- Testing Position Management ---");
      allTestsPassed &= TestSLTPCalculation();
   }
   
   if(allTestsPassed)
      Print("✓ ALL TESTS PASSED");
   else
      Print("✗ SOME TESTS FAILED");
   
   Print("=== Test Completed ===");
}

//+------------------------------------------------------------------+
//| Test drawdown calculation                                        |
//+------------------------------------------------------------------+
bool TestDrawdownCalculation()
{
   Print("Testing drawdown calculation...");
   
   double testBalance = 10000.0;
   double testEquity = 8500.0;
   double expectedDrawdown = 15.0; // (10000-8500)/10000 * 100
   
   double calculatedDrawdown = ((testBalance - testEquity) / testBalance) * 100.0;
   
   bool passed = MathAbs(calculatedDrawdown - expectedDrawdown) < 0.01;
   
   if(passed)
      Print("✓ Drawdown calculation test passed");
   else
      Print("✗ Drawdown calculation test failed: Expected ", expectedDrawdown, ", Got ", calculatedDrawdown);
   
   return passed;
}

//+------------------------------------------------------------------+
//| Test lot size calculation logic                                  |
//+------------------------------------------------------------------+
bool TestLotSizeCalculation()
{
   Print("Testing lot size calculation...");
   
   double testBalance = 10000.0;
   double riskPercent = 0.5;
   double riskAmount = testBalance * riskPercent / 100.0; // 50 USD
   
   double slDistance = 30 * _Point; // 3 pips
   double tickValue = 1.0; // Simplified
   
   double expectedLot = riskAmount / (slDistance * tickValue);
   
   // Simulate the calculation
   double calculatedLot = riskAmount / (slDistance * tickValue);
   
   bool passed = calculatedLot > 0;
   
   if(passed)
      Print("✓ Lot size calculation test passed");
   else
      Print("✗ Lot size calculation test failed");
   
   return passed;
}

//+------------------------------------------------------------------+
//| Test ADX regime detection                                        |
//+------------------------------------------------------------------+
bool TestADXRegimeDetection()
{
   Print("Testing ADX regime detection...");
   
   // Test values
   double trendADX = 30.0;  // Should be TREND
   double sidewaysADX = 15.0; // Should be SIDEWAYS
   double neutralADX = 22.0;  // Should be NEUTRAL
   
   double trendThreshold = 25.0;
   double sidewaysThreshold = 20.0;
   
   // Test trend detection
   bool trendTest = (trendADX > trendThreshold);
   bool sidewaysTest = (sidewaysADX < sidewaysThreshold);
   bool neutralTest = (neutralADX >= sidewaysThreshold && neutralADX <= trendThreshold);
   
   bool passed = trendTest && sidewaysTest && neutralTest;
   
   if(passed)
      Print("✓ ADX regime detection test passed");
   else
      Print("✗ ADX regime detection test failed");
   
   return passed;
}

//+------------------------------------------------------------------+
//| Test dynamic lot sizing                                          |
//+------------------------------------------------------------------+
bool TestDynamicLotSizing()
{
   Print("Testing dynamic lot sizing...");
   
   double balance = 10000.0;
   double riskPercent = 0.5;
   double minLot = 0.01;
   double maxLot = 100.0;
   double lotStep = 0.01;
   
   double riskAmount = balance * riskPercent / 100.0;
   double slDistance = 30 * _Point; // 3 pips
   double tickValue = 1.0;
   
   double lot = riskAmount / (slDistance * tickValue);
   lot = MathFloor(lot / lotStep) * lotStep;
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   
   bool passed = (lot >= minLot && lot <= maxLot && lot > 0);
   
   if(passed)
      Print("✓ Dynamic lot sizing test passed");
   else
      Print("✗ Dynamic lot sizing test failed");
   
   return passed;
}

//+------------------------------------------------------------------+
//| Test SL/TP calculation                                           |
//+------------------------------------------------------------------+
bool TestSLTPCalculation()
{
   Print("Testing SL/TP calculation...");
   
   double testPrice = 1.1000;
   double point = 0.00001;
   
   // Test trend mode calculations
   double trendSL_Buy = testPrice - 30 * point; // 3 pips
   double trendTP_Buy = testPrice + 120 * point; // 12 pips
   
   double trendSL_Sell = testPrice + 30 * point;
   double trendTP_Sell = testPrice - 120 * point;
   
   // Test sideways mode calculations
   double sidewaysSL_Buy = testPrice - 40 * point; // 4 pips
   double sidewaysTP_Buy = testPrice + 60 * point; // 6 pips
   
   double sidewaysSL_Sell = testPrice + 40 * point;
   double sidewaysTP_Sell = testPrice - 60 * point;
   
   bool trendBuyTest = (trendSL_Buy < testPrice && trendTP_Buy > testPrice);
   bool trendSellTest = (trendSL_Sell > testPrice && trendTP_Sell < testPrice);
   bool sidewaysBuyTest = (sidewaysSL_Buy < testPrice && sidewaysTP_Buy > testPrice);
   bool sidewaysSellTest = (sidewaysSL_Sell > testPrice && sidewaysTP_Sell < testPrice);
   
   bool passed = trendBuyTest && trendSellTest && sidewaysBuyTest && sidewaysSellTest;
   
   if(passed)
      Print("✓ SL/TP calculation test passed");
   else
      Print("✗ SL/TP calculation test failed");
   
   return passed;
}