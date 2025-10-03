//+------------------------------------------------------------------+
//|                                                ConfigLoader.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

#include "DTO/SymbolConfigEntry.mqh"

//+------------------------------------------------------------------+
//| Configuration Loader                                              |
//| Parses EA inputs, validates symbols, returns configuration DTOs  |
//+------------------------------------------------------------------+
class ConfigLoader
{
private:
   SymbolConfigEntry m_configs[];
   int               m_configCount;

   //+------------------------------------------------------------------+
   //| Check if symbol is supported by broker                           |
   //+------------------------------------------------------------------+
   bool IsSymbolSupported(string symbol)
   {
      // Try to select the symbol
      if(!SymbolSelect(symbol, true))
         return false;

      // Verify symbol exists in Market Watch
      if(SymbolInfoInteger(symbol, SYMBOL_SELECT) == 0)
         return false;

      return true;
   }

   //+------------------------------------------------------------------+
   //| Validate ASCII-only string                                        |
   //+------------------------------------------------------------------+
   bool IsASCII(string text)
   {
      for(int i = 0; i < StringLen(text); i++)
      {
         ushort ch = StringGetCharacter(text, i);
         if(ch > 127)
            return false;
      }
      return true;
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                       |
   //+------------------------------------------------------------------+
   ConfigLoader()
   {
      m_configCount = 0;
      ArrayResize(m_configs, 0);
   }

   //+------------------------------------------------------------------+
   //| Validate symbol list for duplicates and unsupported symbols      |
   //+------------------------------------------------------------------+
   bool ValidateSymbolList(const string &symbols[], string &errorMsg)
   {
      int count = ArraySize(symbols);

      // Check for duplicates
      for(int i = 0; i < count; i++)
      {
         if(StringLen(symbols[i]) == 0)
            continue;

         // ASCII validation
         if(!IsASCII(symbols[i]))
         {
            errorMsg = StringFormat("Symbol '%s' contains non-ASCII characters", symbols[i]);
            return false;
         }

         // Check for duplicates
         for(int j = i + 1; j < count; j++)
         {
            if(symbols[i] == symbols[j])
            {
               errorMsg = StringFormat("Duplicate symbol detected: '%s' at positions %d and %d",
                                      symbols[i], i, j);
               return false;
            }
         }

         // Check if symbol is supported by broker
         if(!IsSymbolSupported(symbols[i]))
         {
            errorMsg = StringFormat("Unsupported symbol: '%s' not available with broker", symbols[i]);
            return false;
         }
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Load configuration from arrays (from EA inputs)                  |
   //+------------------------------------------------------------------+
   bool LoadConfig(const string &symbols[],
                   const bool &enabled[],
                   double globalGridSize,
                   int globalMaxLevels,
                   double globalRisk,
                   double globalMaxDD,
                   double globalLotSize,
                   int globalGridCount,
                   double globalTriggerPips,
                   int globalFastEMA,
                   string &errorMsg)
   {
      int count = ArraySize(symbols);

      // Validate symbol list first
      if(!ValidateSymbolList(symbols, errorMsg))
         return false;

      // Resize config array
      ArrayResize(m_configs, count);
      m_configCount = 0;

      // Build configuration entries
      for(int i = 0; i < count; i++)
      {
         if(StringLen(symbols[i]) == 0)
            continue;

         SymbolConfigEntry config;
         config.Symbol = symbols[i];
         config.Enabled = (ArraySize(enabled) > i) ? enabled[i] : false;

         // Use global defaults (overrides would be added here later)
         config.GridSizePoints = globalGridSize;
         config.MaxGridLevels = globalMaxLevels;
         config.GridCount = globalGridCount;
         config.GridSpacing = globalGridSize;  // Same as grid size by default
         config.LotSize = globalLotSize;
         config.RiskPercent = globalRisk;
         config.MaxDrawdownPercent = globalMaxDD;
         config.CatastropheSL = 500.0;  // Default 500 points

         // Trade filters (permissive defaults)
         config.MaxSpread = 0.0;  // No limit
         config.SlippageTolerance = 10.0;  // 10 points
         config.TradingHourStart = -1;  // All hours
         config.TradingHourEnd = -1;

         // Entry/Exit settings
         config.TriggerPips = globalTriggerPips;
         config.FastEMAPeriod = globalFastEMA;
         config.SlowEMAPeriod = 0;  // Disabled by default
         config.ExitOnEMA = true;   // Enabled by default

         // Correlation settings
         config.EnableCorrelation = true;
         config.CorrelationThreshold = 0.7; // Default

         // Dashboard settings
         config.DisplayColor = clrWhite;
         config.DisplayRow = i; // Sequential by default

         // Validate entry
         if(!config.IsValid())
         {
            errorMsg = StringFormat("Invalid configuration for symbol '%s'", symbols[i]);
            return false;
         }

         m_configs[m_configCount++] = config;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Get configuration array                                           |
   //+------------------------------------------------------------------+
   void GetConfigs(SymbolConfigEntry &dest[])
   {
      ArrayResize(dest, m_configCount);
      for(int i = 0; i < m_configCount; i++)
         dest[i] = m_configs[i];
   }

   //+------------------------------------------------------------------+
   //| Get number of loaded configs                                      |
   //+------------------------------------------------------------------+
   int GetConfigCount() const { return m_configCount; }
};
