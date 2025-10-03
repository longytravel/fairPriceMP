//+------------------------------------------------------------------+
//|                                           Test_ConfigLoader.mq5 |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property strict
#property script_show_inputs

#include <fairPriceMP/ConfigLoader.mqh>
#include <fairPriceMP/SymbolStateRegistry.mqh>

//+------------------------------------------------------------------+
//| Test result tracking                                              |
//+------------------------------------------------------------------+
int g_totalTests = 0;
int g_passedTests = 0;
int g_failedTests = 0;

//+------------------------------------------------------------------+
//| Script program start function                                     |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("========================================");
   Print("  ConfigLoader Unit Test Suite");
   Print("========================================");
   Print("");

   // Run all tests
   TestDuplicateDetection();
   TestUnsupportedSymbol();
   TestNonASCIISymbol();
   TestValidConfiguration();
   TestEmptySymbolHandling();
   TestDTOPropagation();
   TestStateRegistryInit();

   // Print summary
   Print("");
   Print("========================================");
   Print("  Test Results Summary");
   Print("========================================");
   Print("Total Tests:  ", g_totalTests);
   Print("Passed:       ", g_passedTests, " (", (g_totalTests > 0 ? (g_passedTests * 100.0 / g_totalTests) : 0), "%)");
   Print("Failed:       ", g_failedTests);
   Print("========================================");
}

//+------------------------------------------------------------------+
//| Test: Duplicate symbol detection                                  |
//+------------------------------------------------------------------+
void TestDuplicateDetection()
{
   Print("--- Test: Duplicate Symbol Detection ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "GBPUSD", "EURUSD"};  // EURUSD appears twice
   bool enabled[] = {true, true, true};
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);

   Assert(!result, "Should reject duplicate symbols", errorMsg);
   AssertContains(errorMsg, "Duplicate", "Error message should mention duplicate");
   Print("");
}

//+------------------------------------------------------------------+
//| Test: Unsupported symbol rejection                                |
//+------------------------------------------------------------------+
void TestUnsupportedSymbol()
{
   Print("--- Test: Unsupported Symbol Rejection ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "FAKESYMBOL123", "GBPUSD"};  // FAKESYMBOL123 doesn't exist
   bool enabled[] = {true, true, true};
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);

   Assert(!result, "Should reject unsupported symbols", errorMsg);
   AssertContains(errorMsg, "Unsupported", "Error message should mention unsupported symbol");
   Print("");
}

//+------------------------------------------------------------------+
//| Test: Non-ASCII character rejection                               |
//+------------------------------------------------------------------+
void TestNonASCIISymbol()
{
   Print("--- Test: Non-ASCII Character Rejection ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "EUR\xD0USD"};  // Contains non-ASCII character
   bool enabled[] = {true, true};
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);

   Assert(!result, "Should reject non-ASCII symbols", errorMsg);
   AssertContains(errorMsg, "ASCII", "Error message should mention ASCII");
   Print("");
}

//+------------------------------------------------------------------+
//| Test: Valid configuration loading                                 |
//+------------------------------------------------------------------+
void TestValidConfiguration()
{
   Print("--- Test: Valid Configuration Loading ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "GBPUSD", "USDJPY"};
   bool enabled[] = {true, true, true};
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);

   Assert(result, "Should load valid configuration", errorMsg);
   Assert(loader.GetConfigCount() == 3, "Should have 3 configs", IntegerToString(loader.GetConfigCount()));

   SymbolConfigEntry configs[];
   loader.GetConfigs(configs);

   Assert(configs[0].Symbol == "EURUSD", "First symbol should be EURUSD", configs[0].Symbol);
   Assert(configs[0].Enabled == true, "First symbol should be enabled", "");
   Assert(configs[0].GridSizePoints == 100.0, "Grid size should match", DoubleToString(configs[0].GridSizePoints));
   Assert(configs[1].Symbol == "GBPUSD", "Second symbol should be GBPUSD", configs[1].Symbol);
   Assert(configs[2].Symbol == "USDJPY", "Third symbol should be USDJPY", configs[2].Symbol);

   Print("");
}

//+------------------------------------------------------------------+
//| Test: Empty symbol handling                                       |
//+------------------------------------------------------------------+
void TestEmptySymbolHandling()
{
   Print("--- Test: Empty Symbol Handling ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "", "GBPUSD"};  // Empty symbol in middle
   bool enabled[] = {true, true, true};
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);

   Assert(result, "Should handle empty symbols gracefully", errorMsg);
   Assert(loader.GetConfigCount() == 2, "Should skip empty symbols", IntegerToString(loader.GetConfigCount()));

   Print("");
}

//+------------------------------------------------------------------+
//| Test: DTO propagation to registry                                 |
//+------------------------------------------------------------------+
void TestDTOPropagation()
{
   Print("--- Test: DTO Propagation to Registry ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "GBPUSD"};
   bool enabled[] = {true, true};
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);
   Assert(result, "Config should load", errorMsg);

   SymbolConfigEntry configs[];
   loader.GetConfigs(configs);

   Assert(ArraySize(configs) == 2, "Should have 2 config entries", IntegerToString(ArraySize(configs)));
   Assert(configs[0].GridSizePoints == 100.0, "First config should have correct grid size", "");
   Assert(configs[1].GridSizePoints == 100.0, "Second config should have correct grid size", "");

   Print("");
}

//+------------------------------------------------------------------+
//| Test: State registry initialization from config                   |
//+------------------------------------------------------------------+
void TestStateRegistryInit()
{
   Print("--- Test: State Registry Initialization ---");

   ConfigLoader loader;
   string symbols[] = {"EURUSD", "GBPUSD"};
   bool enabled[] = {true, false};  // GBPUSD disabled
   string errorMsg;

   bool result = loader.LoadConfig(symbols, enabled, 100.0, 5, 1.0, 10.0, 0.01, 3, 5.0, 20, errorMsg);
   Assert(result, "Config should load", errorMsg);

   SymbolConfigEntry configs[];
   loader.GetConfigs(configs);

   SymbolStateRegistry registry;
   bool initResult = registry.InitFromConfig(configs);

   Assert(initResult, "Registry should initialize", "");
   Assert(registry.GetCount() == 1, "Registry should only have enabled symbols", IntegerToString(registry.GetCount()));

   SymbolRuntimeState state;
   bool foundEUR = registry.GetState("EURUSD", state);
   bool foundGBP = registry.GetState("GBPUSD", state);

   Assert(foundEUR, "Should find EURUSD in registry", "");
   Assert(!foundGBP, "Should NOT find disabled GBPUSD in registry", "");

   Print("");
}

//+------------------------------------------------------------------+
//| Assert helper                                                      |
//+------------------------------------------------------------------+
void Assert(bool condition, string testName, string details)
{
   g_totalTests++;

   if(condition)
   {
      g_passedTests++;
      Print("[PASS] ", testName);
   }
   else
   {
      g_failedTests++;
      Print("[FAIL] ", testName, " - Details: ", details);
   }
}

//+------------------------------------------------------------------+
//| Assert string contains substring                                  |
//+------------------------------------------------------------------+
void AssertContains(string text, string substring, string testName)
{
   g_totalTests++;

   if(StringFind(text, substring) >= 0)
   {
      g_passedTests++;
      Print("[PASS] ", testName);
   }
   else
   {
      g_failedTests++;
      Print("[FAIL] ", testName, " - '", substring, "' not found in: ", text);
   }
}
