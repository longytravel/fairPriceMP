//+------------------------------------------------------------------+
//|                                           Test_SymbolEngine.mq5 |
//|                                     Copyright 2025, fairPriceMP |
//|                                DTO Validation and Config Tests   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property script_show_inputs
#property strict

#include <fairPriceMP\DTO\SymbolConfigEntry.mqh>
#include <fairPriceMP\DTO\SymbolRuntimeState.mqh>

//+------------------------------------------------------------------+
//| Test Configuration                                                |
//+------------------------------------------------------------------+
input string InpTestSymbol = "EURUSD";    // Test Symbol
input bool   InpVerbose = true;            // Verbose Output

//+------------------------------------------------------------------+
//| Test Results Tracker                                              |
//+------------------------------------------------------------------+
struct TestResult
{
   string testName;
   bool   passed;
   string message;
};

TestResult g_testResults[];
int g_testCount = 0;

//+------------------------------------------------------------------+
//| Add test result                                                   |
//+------------------------------------------------------------------+
void AddTestResult(string name, bool passed, string message = "")
{
   int size = ArraySize(g_testResults);
   ArrayResize(g_testResults, size + 1);
   g_testResults[size].testName = name;
   g_testResults[size].passed = passed;
   g_testResults[size].message = message;
   g_testCount++;
}

//+------------------------------------------------------------------+
//| Assert helper                                                     |
//+------------------------------------------------------------------+
void Assert(string testName, bool condition, string message)
{
   if(!condition)
   {
      Print("FAIL: ", testName, " - ", message);
      AddTestResult(testName, false, message);
   }
   else
   {
      if(InpVerbose)
         Print("PASS: ", testName);
      AddTestResult(testName, true, "");
   }
}

//+------------------------------------------------------------------+
//| Create test configuration                                         |
//+------------------------------------------------------------------+
SymbolConfigEntry CreateTestConfig(string symbol)
{
   SymbolConfigEntry config;
   config.Symbol = symbol;
   config.Enabled = true;
   config.LotSize = 0.01;
   config.GridCount = 3;
   config.GridSpacing = 100.0;
   config.GridSizePoints = 100.0;
   config.MaxGridLevels = 5;
   config.CatastropheSL = 500.0;
   config.TriggerPips = 5.0;
   config.FastEMAPeriod = 20;
   config.SlowEMAPeriod = 50;
   config.ExitOnEMA = true;
   config.MaxSpread = 50.0;
   config.SlippageTolerance = 10.0;
   config.TradingHourStart = -1;
   config.TradingHourEnd = -1;
   config.EnableCorrelation = false;
   config.RiskPercent = 1.0;
   config.MaxDrawdownPercent = 10.0;
   config.CorrelationThreshold = 0.7;
   config.DisplayColor = clrWhite;
   config.DisplayRow = 0;

   return config;
}

//+------------------------------------------------------------------+
//| Test 1: DTO Validation - Valid Configuration                      |
//+------------------------------------------------------------------+
void Test_ValidConfiguration()
{
   Print("--- Test 1: Valid Configuration ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);
   Assert("ValidConfig", config.IsValid(), "Valid config should pass validation");
   Assert("SymbolSet", config.Symbol == InpTestSymbol, "Symbol should be set correctly");
   Assert("LotSizeSet", config.LotSize == 0.01, "Lot size should be 0.01");
   Assert("GridCountSet", config.GridCount == 3, "Grid count should be 3");

   Print("--- Test 1 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 2: DTO Validation - Invalid Lot Size                         |
//+------------------------------------------------------------------+
void Test_InvalidLotSize()
{
   Print("--- Test 2: Invalid Lot Size ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);
   config.LotSize = -1.0;
   Assert("NegativeLotSize", !config.IsValid(), "Negative lot size should fail validation");

   config.LotSize = -0.01;
   Assert("NegativeLotSize2", !config.IsValid(), "Negative lot size should fail validation");

   Print("--- Test 2 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 3: DTO Validation - Invalid Trading Hours                    |
//+------------------------------------------------------------------+
void Test_InvalidTradingHours()
{
   Print("--- Test 3: Invalid Trading Hours ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);

   config.TradingHourStart = 25;  // Invalid hour
   Assert("InvalidStartHour", !config.IsValid(), "Hour 25 should fail validation");

   config.TradingHourStart = -2;  // Invalid (not -1)
   Assert("InvalidStartHourNeg", !config.IsValid(), "Hour -2 should fail validation");

   config.TradingHourStart = 10;
   config.TradingHourEnd = 30;    // Invalid hour
   Assert("InvalidEndHour", !config.IsValid(), "Hour 30 should fail validation");

   Print("--- Test 3 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 4: DTO Validation - Invalid Grid Parameters                  |
//+------------------------------------------------------------------+
void Test_InvalidGridParameters()
{
   Print("--- Test 4: Invalid Grid Parameters ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);

   config.GridCount = -1;
   Assert("NegativeGridCount", !config.IsValid(), "Negative grid count should fail");

   config.GridCount = 3;
   config.GridSpacing = -10.0;
   Assert("NegativeGridSpacing", !config.IsValid(), "Negative grid spacing should fail");

   config.GridSpacing = 100.0;
   config.CatastropheSL = -50.0;
   Assert("NegativeSL", !config.IsValid(), "Negative SL should fail");

   Print("--- Test 4 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 5: DTO Validation - Invalid EMA Periods                      |
//+------------------------------------------------------------------+
void Test_InvalidEMAPeriods()
{
   Print("--- Test 5: Invalid EMA Periods ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);

   config.FastEMAPeriod = -1;
   Assert("NegativeFastEMA", !config.IsValid(), "Negative fast EMA should fail");

   config.FastEMAPeriod = 20;
   config.SlowEMAPeriod = -5;
   Assert("NegativeSlowEMA", !config.IsValid(), "Negative slow EMA should fail");

   config.SlowEMAPeriod = 0;  // 0 is valid (disabled)
   Assert("ZeroSlowEMAValid", config.IsValid(), "Zero slow EMA should be valid (disabled)");

   Print("--- Test 5 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 6: DTO Validation - Correlation Threshold                    |
//+------------------------------------------------------------------+
void Test_CorrelationThreshold()
{
   Print("--- Test 6: Correlation Threshold ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);

   config.CorrelationThreshold = -0.1;
   Assert("NegativeCorrelation", !config.IsValid(), "Negative correlation should fail");

   config.CorrelationThreshold = 1.5;
   Assert("CorrelationAbove1", !config.IsValid(), "Correlation > 1.0 should fail");

   config.CorrelationThreshold = 0.0;
   Assert("CorrelationZero", config.IsValid(), "Correlation 0.0 should be valid");

   config.CorrelationThreshold = 1.0;
   Assert("CorrelationOne", config.IsValid(), "Correlation 1.0 should be valid");

   config.CorrelationThreshold = 0.5;
   Assert("CorrelationMid", config.IsValid(), "Correlation 0.5 should be valid");

   Print("--- Test 6 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 7: DTO Validation - ASCII Symbol Name                        |
//+------------------------------------------------------------------+
void Test_ASCIISymbolName()
{
   Print("--- Test 7: ASCII Symbol Name ---");

   SymbolConfigEntry config = CreateTestConfig("EURUSD");
   Assert("ASCIISymbol", config.IsValid(), "ASCII symbol should be valid");

   // Note: Testing actual non-ASCII requires inserting Unicode characters
   // which is complex in MQL5 strict mode. The validation function exists
   // in the DTO and will catch non-ASCII at runtime.

   config.Symbol = "";
   config.Enabled = true;
   Assert("EmptySymbol", !config.IsValid(), "Empty enabled symbol should fail");

   config.Enabled = false;
   config.Symbol = "";
   Assert("EmptyDisabledSymbol", config.IsValid(), "Empty disabled symbol should pass");

   Print("--- Test 7 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 8: SymbolRuntimeState Initialization                         |
//+------------------------------------------------------------------+
void Test_RuntimeStateInit()
{
   Print("--- Test 8: Runtime State Initialization ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);
   SymbolRuntimeState state;

   state.InitFromConfig(config);

   Assert("StateSymbol", state.Symbol == InpTestSymbol, "State symbol should match config");
   Assert("StateNotReady", !state.IsReady, "State should not be ready initially");
   Assert("StateSignalIdle", state.SignalState == SIGNAL_IDLE, "Initial signal should be IDLE");
   Assert("StateNotBlocked", !state.IsBlocked, "State should not be blocked initially");
   Assert("StateNoCorrelationBlock", !state.CorrelationBlocked, "No correlation block initially");
   Assert("StateZeroGridLevels", state.ActiveGridLevels == 0, "No active grid levels initially");

   Print("--- Test 8 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 9: SymbolRuntimeState CanTrade Method                        |
//+------------------------------------------------------------------+
void Test_RuntimeStateCanTrade()
{
   Print("--- Test 9: Runtime State CanTrade ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);
   SymbolRuntimeState state;
   state.InitFromConfig(config);

   Assert("CantTradeNotReady", !state.CanTrade(), "Cannot trade when not ready");

   state.IsReady = true;
   Assert("CanTradeWhenReady", state.CanTrade(), "Can trade when ready");

   state.Block("Test block");
   Assert("CantTradeWhenBlocked", !state.CanTrade(), "Cannot trade when blocked");

   state.Unblock();
   Assert("CanTradeAfterUnblock", state.CanTrade(), "Can trade after unblock");

   state.CorrelationBlocked = true;
   Assert("CantTradeWhenCorrelationBlocked", !state.CanTrade(), "Cannot trade when correlation blocked");

   Print("--- Test 9 Complete ---");
}

//+------------------------------------------------------------------+
//| Test 10: SymbolRuntimeState Block/Unblock                         |
//+------------------------------------------------------------------+
void Test_RuntimeStateBlockUnblock()
{
   Print("--- Test 10: Runtime State Block/Unblock ---");

   SymbolConfigEntry config = CreateTestConfig(InpTestSymbol);
   SymbolRuntimeState state;
   state.InitFromConfig(config);

   state.Block("Drawdown exceeded");
   Assert("IsBlocked", state.IsBlocked, "State should be blocked");
   Assert("BlockReasonSet", state.BlockReason == "Drawdown exceeded", "Block reason should be set");
   Assert("BlockTimeSet", state.BlockedSince > 0, "Block time should be set");

   state.Unblock();
   Assert("IsUnblocked", !state.IsBlocked, "State should be unblocked");
   Assert("BlockReasonCleared", state.BlockReason == "", "Block reason should be cleared");
   Assert("BlockTimeCleared", state.BlockedSince == 0, "Block time should be cleared");

   Print("--- Test 10 Complete ---");
}

//+------------------------------------------------------------------+
//| Print Test Summary                                                |
//+------------------------------------------------------------------+
void PrintTestSummary()
{
   Print("========================================");
   Print("TEST SUMMARY");
   Print("========================================");

   int passCount = 0;
   int failCount = 0;

   for(int i = 0; i < g_testCount; i++)
   {
      if(g_testResults[i].passed)
      {
         passCount++;
         if(InpVerbose)
            Print("[PASS] ", g_testResults[i].testName);
      }
      else
      {
         failCount++;
         Print("[FAIL] ", g_testResults[i].testName, " - ", g_testResults[i].message);
      }
   }

   Print("----------------------------------------");
   Print("Total Tests: ", g_testCount);
   Print("Passed: ", passCount);
   Print("Failed: ", failCount);
   Print("Success Rate: ", (g_testCount > 0 ? (passCount * 100.0 / g_testCount) : 0), "%");
   Print("========================================");

   if(failCount == 0)
   {
      Print("ALL TESTS PASSED!");
   }
   else
   {
      Print("SOME TESTS FAILED - Review output above");
   }
}

//+------------------------------------------------------------------+
//| Script program start function                                     |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("========================================");
   Print("SYMBOL ENGINE DTO UNIT TESTS");
   Print("Test Symbol: ", InpTestSymbol);
   Print("========================================");

   // Run all tests
   Test_ValidConfiguration();
   Test_InvalidLotSize();
   Test_InvalidTradingHours();
   Test_InvalidGridParameters();
   Test_InvalidEMAPeriods();
   Test_CorrelationThreshold();
   Test_ASCIISymbolName();
   Test_RuntimeStateInit();
   Test_RuntimeStateCanTrade();
   Test_RuntimeStateBlockUnblock();

   // Print summary
   PrintTestSummary();

   Print("");
   Print("NOTE: These tests validate DTO structures and configuration.");
   Print("Full engine integration tests require running the CoreOrchestrator EA.");
}
