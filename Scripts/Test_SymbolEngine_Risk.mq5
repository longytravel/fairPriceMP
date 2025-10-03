//+------------------------------------------------------------------+
//|                                        Test_SymbolEngine_Risk.mq5 |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property script_show_inputs
#property strict

#include <fairPriceMP\DTO\SymbolConfigEntry.mqh>
#include <fairPriceMP\DTO\SymbolRuntimeState.mqh>

//+------------------------------------------------------------------+
//| Test Suite for Symbol Engine Risk Management                     |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== Test_SymbolEngine_Risk: Starting Test Suite ===");

   int passedTests = 0;
   int totalTests = 0;

   // Test 1: Equity tracking calculations
   if(Test_EquityTracking())
   {
      passedTests++;
      Print("[PASS] Test_EquityTracking");
   }
   else
      Print("[FAIL] Test_EquityTracking");
   totalTests++;

   // Test 2: Drawdown percentage formula
   if(Test_DrawdownCalculation())
   {
      passedTests++;
      Print("[PASS] Test_DrawdownCalculation");
   }
   else
      Print("[FAIL] Test_DrawdownCalculation");
   totalTests++;

   // Test 3: Symbol runtime state initialization
   if(Test_SymbolRuntimeStateInit())
   {
      passedTests++;
      Print("[PASS] Test_SymbolRuntimeStateInit");
   }
   else
      Print("[FAIL] Test_SymbolRuntimeStateInit");
   totalTests++;

   // Test 4: Symbol isolation (state caches)
   if(Test_SymbolIsolation())
   {
      passedTests++;
      Print("[PASS] Test_SymbolIsolation");
   }
   else
      Print("[FAIL] Test_SymbolIsolation");
   totalTests++;

   // Test 5: Configuration entry validation
   if(Test_ConfigEntryValidation())
   {
      passedTests++;
      Print("[PASS] Test_ConfigEntryValidation");
   }
   else
      Print("[FAIL] Test_ConfigEntryValidation");
   totalTests++;

   Print(StringFormat("=== Test Results: %d/%d passed ===", passedTests, totalTests));
}

//+------------------------------------------------------------------+
//| Test: Equity Tracking Calculations                               |
//+------------------------------------------------------------------+
bool Test_EquityTracking()
{
   SymbolRuntimeState state;

   // Simulate equity growth
   state.PeakEquity = 1000.0;
   state.CurrentEquity = 1200.0;

   // Peak should update when current exceeds
   if(state.CurrentEquity > state.PeakEquity)
      state.PeakEquity = state.CurrentEquity;

   if(state.PeakEquity != 1200.0)
   {
      Print("ERROR: Peak equity not updated correctly");
      return false;
   }

   // Simulate drawdown
   state.CurrentEquity = 1000.0;

   // Calculate drawdown
   double drawdown = 0.0;
   if(state.PeakEquity > 0.0)
      drawdown = ((state.PeakEquity - state.CurrentEquity) / state.PeakEquity) * 100.0;

   // Expected: (1200 - 1000) / 1200 * 100 = 16.67%
   double expected = 16.666666;
   if(MathAbs(drawdown - expected) > 0.01)
   {
      Print(StringFormat("ERROR: Drawdown calculation incorrect. Got: %.2f%%, Expected: %.2f%%",
                        drawdown, expected));
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Test: Drawdown Calculation Formula                               |
//+------------------------------------------------------------------+
bool Test_DrawdownCalculation()
{
   // Test case 1: No drawdown
   double peak1 = 1000.0;
   double current1 = 1000.0;
   double dd1 = ((peak1 - current1) / peak1) * 100.0;

   if(MathAbs(dd1 - 0.0) > 0.01)
   {
      Print("ERROR: Zero drawdown test failed");
      return false;
   }

   // Test case 2: 50% drawdown
   double peak2 = 1000.0;
   double current2 = 500.0;
   double dd2 = ((peak2 - current2) / peak2) * 100.0;

   if(MathAbs(dd2 - 50.0) > 0.01)
   {
      Print("ERROR: 50% drawdown test failed");
      return false;
   }

   // Test case 3: 100% drawdown
   double peak3 = 1000.0;
   double current3 = 0.0;
   double dd3 = ((peak3 - current3) / peak3) * 100.0;

   if(MathAbs(dd3 - 100.0) > 0.01)
   {
      Print("ERROR: 100% drawdown test failed");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Test: Symbol Runtime State Initialization                        |
//+------------------------------------------------------------------+
bool Test_SymbolRuntimeStateInit()
{
   SymbolConfigEntry config;
   config.Symbol = "EURUSD";
   config.Enabled = true;
   config.MaxDrawdownPercent = 20.0;

   SymbolRuntimeState state;
   state.InitFromConfig(config);

   // Verify fields initialized correctly
   if(state.Symbol != "EURUSD")
   {
      Print("ERROR: Symbol not initialized");
      return false;
   }

   if(state.PeakEquity != 0.0 || state.CurrentEquity != 0.0 || state.DrawdownPercent != 0.0)
   {
      Print("ERROR: Equity fields not initialized to zero");
      return false;
   }

   if(state.OpenTrades != 0 || state.ActiveGridLevels != 0)
   {
      Print("ERROR: Trade counters not initialized to zero");
      return false;
   }

   if(state.IsBlocked || state.CorrelationBlocked)
   {
      Print("ERROR: Block flags not initialized correctly");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Test: Symbol Isolation (State Independence)                      |
//+------------------------------------------------------------------+
bool Test_SymbolIsolation()
{
   // Create two separate states for different symbols
   SymbolConfigEntry config1;
   config1.Symbol = "EURUSD";
   config1.MaxDrawdownPercent = 10.0;

   SymbolConfigEntry config2;
   config2.Symbol = "GBPUSD";
   config2.MaxDrawdownPercent = 15.0;

   SymbolRuntimeState state1;
   state1.InitFromConfig(config1);

   SymbolRuntimeState state2;
   state2.InitFromConfig(config2);

   // Modify state1
   state1.PeakEquity = 1000.0;
   state1.CurrentEquity = 800.0;
   state1.DrawdownPercent = 20.0;
   state1.OpenTrades = 5;
   state1.SignalState = SIGNAL_BUY;

   // Verify state2 remains unaffected
   if(state2.PeakEquity != 0.0 || state2.CurrentEquity != 0.0)
   {
      Print("ERROR: State2 equity contaminated by state1 changes");
      return false;
   }

   if(state2.OpenTrades != 0)
   {
      Print("ERROR: State2 trade count contaminated by state1 changes");
      return false;
   }

   if(state2.SignalState != SIGNAL_IDLE)
   {
      Print("ERROR: State2 signal state contaminated by state1 changes");
      return false;
   }

   if(state2.Symbol != "GBPUSD")
   {
      Print("ERROR: State2 symbol contaminated by state1 changes");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Test: Config Entry Validation                                    |
//+------------------------------------------------------------------+
bool Test_ConfigEntryValidation()
{
   // Test valid config
   SymbolConfigEntry validConfig;
   validConfig.Symbol = "EURUSD";
   validConfig.Enabled = true;
   validConfig.MaxDrawdownPercent = 20.0;
   validConfig.LotSize = 0.1;

   if(!validConfig.IsValid())
   {
      Print("ERROR: Valid config rejected");
      return false;
   }

   // Test invalid config (negative drawdown)
   SymbolConfigEntry invalidConfig;
   invalidConfig.Symbol = "EURUSD";
   invalidConfig.Enabled = true;
   invalidConfig.MaxDrawdownPercent = -10.0;  // Invalid

   if(invalidConfig.IsValid())
   {
      Print("ERROR: Invalid config (negative drawdown) accepted");
      return false;
   }

   // Test empty symbol when enabled
   SymbolConfigEntry emptySymbol;
   emptySymbol.Symbol = "";
   emptySymbol.Enabled = true;

   if(emptySymbol.IsValid())
   {
      Print("ERROR: Empty symbol when enabled accepted");
      return false;
   }

   return true;
}
