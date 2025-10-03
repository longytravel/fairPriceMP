//+------------------------------------------------------------------+
//|                                            CoreOrchestrator.mq5 |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property strict

#include <fairPriceMP/ConfigLoader.mqh>
#include <fairPriceMP/SymbolStateRegistry.mqh>
#include "Engines/SymbolEngine.mqh"
#include "Services/StructuredLogger.mqh"

//+------------------------------------------------------------------+
//| EA Input Parameters                                               |
//+------------------------------------------------------------------+
input group "=== Symbol Configuration ==="
input string   InpSymbols = "EURUSD,GBPUSD,USDJPY";  // Symbol List (comma-separated, max 28)
input bool     InpEnabled = true;                     // Enable All Symbols

input group "=== Global Defaults ==="
input double   InpLotSize = 0.01;                     // Lot Size
input double   InpGridSize = 100.0;                   // Grid Size (points)
input int      InpMaxLevels = 5;                      // Max Grid Levels
input int      InpGridCount = 3;                      // Grid Count (pending orders)
input double   InpRiskPercent = 1.0;                  // Risk Per Trade (%)
input double   InpMaxDrawdown = 10.0;                 // Max Drawdown (%)

input group "=== Entry/Exit Settings ==="
input double   InpTriggerPips = 5.0;                  // EMA Trigger Distance (pips)
input int      InpFastEMA = 20;                       // Fast EMA Period
input int      InpSlowEMA = 0;                        // Slow EMA Period (0=disabled)
input bool     InpExitOnEMA = true;                   // Exit On EMA Touch

input group "=== Correlation Settings ==="
input bool     InpEnableCorrelation = true;           // Enable Correlation Checks
input double   InpCorrelationThreshold = 0.7;         // Correlation Threshold (0-1)

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
ConfigLoader*         g_configLoader = NULL;
SymbolStateRegistry*  g_stateRegistry = NULL;
StructuredLogger*     g_logger = NULL;
SymbolEngine*         g_engines[];
int                   g_engineCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== fairPriceMP CoreOrchestrator Initialization ===");

   // Initialize logger
   g_logger = new StructuredLogger();
   if(!g_logger.InitFileLogging("fairPriceMP\\logs\\engine_log.txt"))
   {
      Print("ERROR: Failed to initialize logger");
      return INIT_FAILED;
   }

   // Parse symbol list from input
   string symbolArray[];
   ParseSymbolList(InpSymbols, symbolArray);

   int symbolCount = ArraySize(symbolArray);
   Print("Parsed ", symbolCount, " symbols from input");

   // Create enabled array (all true or all false based on InpEnabled)
   bool enabledArray[];
   ArrayResize(enabledArray, symbolCount);
   ArrayInitialize(enabledArray, InpEnabled);

   // Initialize configuration loader
   g_configLoader = new ConfigLoader();

   // Load and validate configuration
   string errorMsg = "";
   if(!g_configLoader.LoadConfig(symbolArray, enabledArray,
                                  InpGridSize, InpMaxLevels,
                                  InpRiskPercent, InpMaxDrawdown,
                                  InpLotSize, InpGridCount,
                                  InpTriggerPips, InpFastEMA,
                                  errorMsg))
   {
      Print("ERROR: Configuration validation failed: ", errorMsg);
      Print("EA initialization HALTED");
      return INIT_FAILED;
   }

   Print("Configuration loaded successfully: ", g_configLoader.GetConfigCount(), " symbols configured");

   // Initialize state registry
   g_stateRegistry = new SymbolStateRegistry();

   SymbolConfigEntry configs[];
   g_configLoader.GetConfigs(configs);

   if(!g_stateRegistry.InitFromConfig(configs))
   {
      Print("ERROR: Failed to initialize state registry");
      return INIT_FAILED;
   }

   Print("State registry initialized: ", g_stateRegistry.GetCount(), " symbols registered");

   // Subscribe symbols and mark ready
   if(!SubscribeSymbols())
   {
      Print("ERROR: Symbol subscription failed");
      return INIT_FAILED;
   }

   // Initialize symbol engines
   if(!InitializeEngines(configs))
   {
      Print("ERROR: Engine initialization failed");
      return INIT_FAILED;
   }

   // Log readiness for each symbol
   LogSymbolReadiness();

   Print("=== fairPriceMP CoreOrchestrator Ready ===");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== fairPriceMP CoreOrchestrator Shutdown ===");
   Print("Reason: ", reason);

   // Cleanup engines
   for(int i = 0; i < g_engineCount; i++)
   {
      if(g_engines[i] != NULL)
      {
         delete g_engines[i];
         g_engines[i] = NULL;
      }
   }
   g_engineCount = 0;

   // Cleanup config and registry
   if(g_configLoader != NULL)
   {
      delete g_configLoader;
      g_configLoader = NULL;
   }

   if(g_stateRegistry != NULL)
   {
      delete g_stateRegistry;
      g_stateRegistry = NULL;
   }

   if(g_logger != NULL)
   {
      delete g_logger;
      g_logger = NULL;
   }

   Print("=== Shutdown Complete ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Get current tick info
   MqlTick tick;
   string currentSymbol = _Symbol;

   if(!SymbolInfoTick(currentSymbol, tick))
      return;

   // Dispatch tick to corresponding engine
   DispatchTick(currentSymbol, tick);

   // Update state registry with engine states
   UpdateStateRegistry();
}

//+------------------------------------------------------------------+
//| Dispatch tick to symbol engine                                    |
//+------------------------------------------------------------------+
void DispatchTick(string symbol, const MqlTick &tick)
{
   for(int i = 0; i < g_engineCount; i++)
   {
      SymbolRuntimeState state;
      g_engines[i].GetRuntimeState(state);

      if(state.Symbol == symbol)
      {
         g_engines[i].ProcessTick(tick);
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Update state registry from engines                                |
//+------------------------------------------------------------------+
void UpdateStateRegistry()
{
   for(int i = 0; i < g_engineCount; i++)
   {
      SymbolRuntimeState state;
      g_engines[i].GetRuntimeState(state);
      g_stateRegistry.UpdateState(state);
   }
}

//+------------------------------------------------------------------+
//| Initialize symbol engines                                         |
//+------------------------------------------------------------------+
bool InitializeEngines(const SymbolConfigEntry &configs[])
{
   int count = ArraySize(configs);
   ArrayResize(g_engines, count);
   g_engineCount = 0;

   for(int i = 0; i < count; i++)
   {
      if(!configs[i].Enabled)
         continue;

      // Create engine
      g_engines[g_engineCount] = new SymbolEngine(configs[i], g_logger);

      // Initialize engine
      if(!g_engines[g_engineCount].Init())
      {
         Print("ERROR: Failed to initialize engine for ", configs[i].Symbol);
         return false;
      }

      Print("Engine initialized for: ", configs[i].Symbol);
      g_engineCount++;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Parse comma-separated symbol list                                 |
//+------------------------------------------------------------------+
void ParseSymbolList(string inputStr, string &output[])
{
   ArrayResize(output, 0);

   string symbols[];
   ushort separator = StringGetCharacter(",", 0);
   int count = StringSplit(inputStr, separator, symbols);

   for(int i = 0; i < count; i++)
   {
      string symbol = symbols[i];
      StringTrimLeft(symbol);
      StringTrimRight(symbol);

      if(StringLen(symbol) > 0)
      {
         int size = ArraySize(output);
         ArrayResize(output, size + 1);
         output[size] = symbol;
      }
   }
}

//+------------------------------------------------------------------+
//| Subscribe symbols and mark ready                                  |
//+------------------------------------------------------------------+
bool SubscribeSymbols()
{
   Print("--- Subscribing Symbols ---");

   SymbolRuntimeState states[];
   g_stateRegistry.GetAllStates(states);

   for(int i = 0; i < ArraySize(states); i++)
   {
      string symbol = states[i].Symbol;

      // Select symbol (ensures it's in Market Watch)
      if(!SymbolSelect(symbol, true))
      {
         Print("ERROR: Failed to select symbol: ", symbol);
         return false;
      }

      // Subscribe to market data (this happens automatically in MT5)
      // Just verify symbol is available
      if(SymbolInfoInteger(symbol, SYMBOL_SELECT) == 0)
      {
         Print("ERROR: Symbol not available: ", symbol);
         return false;
      }

      // Mark as ready
      if(!g_stateRegistry.MarkReady(symbol))
      {
         Print("ERROR: Failed to mark symbol ready: ", symbol);
         return false;
      }

      Print("Subscribed: ", symbol);
   }

   return true;
}

//+------------------------------------------------------------------+
//| Log readiness status for all symbols                              |
//+------------------------------------------------------------------+
void LogSymbolReadiness()
{
   Print("--- Symbol Readiness Report ---");

   SymbolRuntimeState states[];
   g_stateRegistry.GetAllStates(states);

   for(int i = 0; i < ArraySize(states); i++)
   {
      Print(StringFormat("[%s] Ready: %s | CanTrade: %s",
                        states[i].Symbol,
                        states[i].IsReady ? "YES" : "NO",
                        states[i].CanTrade() ? "YES" : "NO"));
   }

   Print("--- End Readiness Report ---");
}
