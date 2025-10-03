//+------------------------------------------------------------------+
//|                                        Test_EquityStop_Demo.mq5 |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property strict

#include "Engines/SymbolEngine.mqh"
#include "Services/StructuredLogger.mqh"

input double TestDrawdownThreshold = 10.0;  // Drawdown threshold % for testing

SymbolEngine* g_engine = NULL;
StructuredLogger* g_logger = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize logger
   g_logger = new StructuredLogger();
   g_logger.InitFileLogging("fairPriceMP/test_equity_stop_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log");

   // Create test config
   SymbolConfigEntry config;
   config.Symbol = _Symbol;
   config.Enabled = true;
   config.MaxDrawdownPercent = TestDrawdownThreshold;
   config.FastEMAPeriod = 20;
   config.SlowEMAPeriod = 50;
   config.TriggerPips = 10.0;
   config.LotSize = 0.01;
   config.GridCount = 3;
   config.GridSpacing = 100.0;
   config.ExitOnEMA = true;

   // Create engine
   g_engine = new SymbolEngine(config, g_logger);

   if(!g_engine.Init())
   {
      Print("ERROR: Failed to initialize SymbolEngine");
      return INIT_FAILED;
   }

   Print("=== Test_EquityStop_Demo Started ===");
   Print("Symbol: ", _Symbol);
   Print("Drawdown Threshold: ", TestDrawdownThreshold, "%");
   Print("Monitoring equity tracking and stop logic...");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_engine != NULL)
      delete g_engine;

   if(g_logger != NULL)
      delete g_logger;

   Print("=== Test_EquityStop_Demo Stopped ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   // Process tick through engine
   g_engine.ProcessTick(tick);

   // Get runtime state to display on chart
   SymbolRuntimeState state;
   g_engine.GetRuntimeState(state);

   // Display state on chart comment
   string info = StringFormat(
      "=== Equity Stop Test Dashboard ===\n" +
      "Symbol: %s\n" +
      "Signal: %s\n" +
      "Open Trades: %d\n" +
      "Active Grid Levels: %d\n" +
      "Peak Equity: %.2f\n" +
      "Current Equity: %.2f\n" +
      "Drawdown: %.2f%%\n" +
      "Threshold: %.2f%%\n" +
      "Blocked: %s\n" +
      "Block Reason: %s\n",
      state.Symbol,
      EnumToString(state.SignalState),
      state.OpenTrades,
      state.ActiveGridLevels,
      state.PeakEquity,
      state.CurrentEquity,
      state.DrawdownPercent,
      TestDrawdownThreshold,
      state.IsBlocked ? "YES" : "NO",
      state.BlockReason
   );

   Comment(info);
}
