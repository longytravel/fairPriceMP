//+------------------------------------------------------------------+
//|                                           SymbolConfigEntry.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

//+------------------------------------------------------------------+
//| Symbol Configuration Entry DTO                                    |
//| Stores per-symbol configuration including overrides and styles   |
//+------------------------------------------------------------------+
struct SymbolConfigEntry
{
   // Core identification
   string            Symbol;              // Symbol name (e.g., "EURUSD")
   bool              Enabled;             // Whether this symbol is active

   // Grid configuration overrides
   double            GridSizePoints;      // Grid size in points (0 = use global default)
   int               MaxGridLevels;       // Maximum grid levels (0 = use global default)
   int               GridCount;           // Number of pending orders in grid (0 = use global default)
   double            GridSpacing;         // Grid spacing in points (0 = use global default)

   // Risk management overrides
   double            LotSize;             // Fixed lot size for this symbol (0 = use global default)
   double            RiskPercent;         // Risk per trade as % (0 = use global default)
   double            MaxDrawdownPercent;  // Max drawdown threshold (0 = use global default)
   double            CatastropheSL;       // Catastrophe stop loss in points (0 = use global default)

   // Trade filters
   double            MaxSpread;           // Maximum allowed spread in points (0 = no limit)
   double            SlippageTolerance;   // Max allowed slippage in points (0 = no limit)
   int               TradingHourStart;    // Trading start hour (0-23, -1 = all hours)
   int               TradingHourEnd;      // Trading end hour (0-23, -1 = all hours)

   // Entry/Exit settings
   double            TriggerPips;         // EMA deviation trigger in pips (0 = use global default)
   int               FastEMAPeriod;       // Fast EMA period (0 = use global default)
   int               SlowEMAPeriod;       // Slow EMA period for trend filter (0 = disabled)
   bool              ExitOnEMA;           // Exit when price touches fast EMA

   // Correlation settings
   bool              EnableCorrelation;   // Enable correlation checks for this symbol
   double            CorrelationThreshold; // Correlation threshold (0 = use global default)

   // Dashboard display settings
   color             DisplayColor;        // Color for this symbol in dashboard
   int               DisplayRow;          // Row position in dashboard (-1 = auto)

   //+------------------------------------------------------------------+
   //| Constructor with defaults                                         |
   //+------------------------------------------------------------------+
   SymbolConfigEntry()
   {
      Symbol = "";
      Enabled = false;
      GridSizePoints = 0.0;
      MaxGridLevels = 0;
      GridCount = 0;
      GridSpacing = 0.0;
      LotSize = 0.0;
      RiskPercent = 0.0;
      MaxDrawdownPercent = 0.0;
      CatastropheSL = 0.0;
      MaxSpread = 0.0;
      SlippageTolerance = 0.0;
      TradingHourStart = -1;
      TradingHourEnd = -1;
      TriggerPips = 0.0;
      FastEMAPeriod = 0;
      SlowEMAPeriod = 0;
      ExitOnEMA = false;
      EnableCorrelation = true;
      CorrelationThreshold = 0.0;
      DisplayColor = clrWhite;
      DisplayRow = -1;
   }

   //+------------------------------------------------------------------+
   //| Validate symbol configuration                                     |
   //+------------------------------------------------------------------+
   bool IsValid() const
   {
      // Symbol name must be ASCII-only and non-empty if enabled
      if(Enabled)
      {
         if(StringLen(Symbol) == 0)
            return false;

         // Check ASCII-only characters
         for(int i = 0; i < StringLen(Symbol); i++)
         {
            ushort ch = StringGetCharacter(Symbol, i);
            if(ch > 127)
               return false;
         }
      }

      // Validate numeric ranges (negative values not allowed for overrides)
      if(GridSizePoints < 0.0 || MaxGridLevels < 0 || GridCount < 0 || GridSpacing < 0.0 ||
         LotSize < 0.0 || RiskPercent < 0.0 || MaxDrawdownPercent < 0.0 || CatastropheSL < 0.0 ||
         MaxSpread < 0.0 || SlippageTolerance < 0.0 || TriggerPips < 0.0 ||
         FastEMAPeriod < 0 || SlowEMAPeriod < 0 ||
         CorrelationThreshold < 0.0 || CorrelationThreshold > 1.0)
         return false;

      // Validate trading hours
      if(TradingHourStart != -1 && (TradingHourStart < 0 || TradingHourStart > 23))
         return false;
      if(TradingHourEnd != -1 && (TradingHourEnd < 0 || TradingHourEnd > 23))
         return false;

      return true;
   }
};
