//+------------------------------------------------------------------+
//|                                  Test_MultiSymbol_Isolation.mq5 |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property strict

#include "Engines/SymbolEngine.mqh"
#include "Services/StructuredLogger.mqh"
#include "UI/DashboardRenderer.mqh"

input string Symbol1 = "EURUSD";
input string Symbol2 = "GBPUSD";
input double Drawdown1 = 10.0;
input double Drawdown2 = 15.0;

SymbolEngine* g_engine1 = NULL;
SymbolEngine* g_engine2 = NULL;
StructuredLogger* g_logger = NULL;
DashboardRenderer* g_dashboard = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_logger = new StructuredLogger();
   g_logger.InitFileLogging("fairPriceMP/test_multi_symbol_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log");

   g_dashboard = new DashboardRenderer("TEST_DASH");

   // Config for Symbol 1
   SymbolConfigEntry config1;
   config1.Symbol = Symbol1;
   config1.Enabled = true;
   config1.MaxDrawdownPercent = Drawdown1;
   config1.FastEMAPeriod = 20;
   config1.TriggerPips = 10.0;
   config1.LotSize = 0.01;

   // Config for Symbol 2
   SymbolConfigEntry config2;
   config2.Symbol = Symbol2;
   config2.Enabled = true;
   config2.MaxDrawdownPercent = Drawdown2;
   config2.FastEMAPeriod = 20;
   config2.TriggerPips = 10.0;
   config2.LotSize = 0.01;

   // Create engines
   g_engine1 = new SymbolEngine(config1, g_logger);
   g_engine2 = new SymbolEngine(config2, g_logger);

   if(!g_engine1.Init() || !g_engine2.Init())
   {
      Print("ERROR: Failed to initialize engines");
      return INIT_FAILED;
   }

   Print("=== Multi-Symbol Isolation Test Started ===");
   Print("Symbol 1: ", Symbol1, " | Drawdown Threshold: ", Drawdown1, "%");
   Print("Symbol 2: ", Symbol2, " | Drawdown Threshold: ", Drawdown2, "%");
   Print("Testing symbol isolation...");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_engine1 != NULL) delete g_engine1;
   if(g_engine2 != NULL) delete g_engine2;
   if(g_logger != NULL) delete g_logger;
   if(g_dashboard != NULL) delete g_dashboard;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Process ticks for both symbols
   MqlTick tick1, tick2;

   if(SymbolInfoTick(Symbol1, tick1))
      g_engine1.ProcessTick(tick1);

   if(SymbolInfoTick(Symbol2, tick2))
      g_engine2.ProcessTick(tick2);

   // Get states
   SymbolRuntimeState state1, state2;
   g_engine1.GetRuntimeState(state1);
   g_engine2.GetRuntimeState(state2);

   // Render dashboard
   g_dashboard.RenderSummary(2,
                             state1.ActiveGridLevels + state2.ActiveGridLevels,
                             MathMax(state1.DrawdownPercent, state2.DrawdownPercent),
                             (state1.IsBlocked ? 1 : 0) + (state2.IsBlocked ? 1 : 0));

   g_dashboard.RenderSymbolRow(0, state1);
   g_dashboard.RenderSymbolRow(1, state2);

   // Detailed comment
   string info = StringFormat(
      "=== Multi-Symbol Isolation Test ===\n\n" +
      "[%s]\n" +
      "  Trades: %d | Grid: %d | Peak: %.2f | Current: %.2f | DD: %.2f%% | Blocked: %s\n\n" +
      "[%s]\n" +
      "  Trades: %d | Grid: %d | Peak: %.2f | Current: %.2f | DD: %.2f%% | Blocked: %s\n\n" +
      "ISOLATION CHECK:\n" +
      "  - Each engine maintains independent state\n" +
      "  - Equity stop on one symbol should NOT affect the other\n" +
      "  - Position counts are symbol-specific\n",
      Symbol1, state1.OpenTrades, state1.ActiveGridLevels,
      state1.PeakEquity, state1.CurrentEquity, state1.DrawdownPercent,
      state1.IsBlocked ? "YES" : "NO",
      Symbol2, state2.OpenTrades, state2.ActiveGridLevels,
      state2.PeakEquity, state2.CurrentEquity, state2.DrawdownPercent,
      state2.IsBlocked ? "YES" : "NO"
   );

   Comment(info);
}
