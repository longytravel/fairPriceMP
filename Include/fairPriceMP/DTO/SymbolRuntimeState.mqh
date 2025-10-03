//+------------------------------------------------------------------+
//|                                         SymbolRuntimeState.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

#include "SymbolConfigEntry.mqh"

//+------------------------------------------------------------------+
//| Signal State Enumeration                                          |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STATE
{
   SIGNAL_IDLE = 0,      // No active signal
   SIGNAL_BUY = 1,       // Buy signal active
   SIGNAL_SELL = -1,     // Sell signal active
   SIGNAL_BLOCKED = 99   // Signal blocked (correlation or other)
};

//+------------------------------------------------------------------+
//| Symbol Runtime State DTO                                          |
//| Maintains live telemetry and status for each symbol              |
//+------------------------------------------------------------------+
struct SymbolRuntimeState
{
   // Symbol identification
   string            Symbol;              // Symbol name
   bool              IsReady;             // Market data subscribed and ready

   // Signal state
   ENUM_SIGNAL_STATE SignalState;         // Current signal state
   datetime          LastSignalTime;      // Timestamp of last signal change

   // Grid and position tracking
   int               ActiveGridLevels;    // Number of active grid levels
   int               OpenTrades;          // Count of open trades for this symbol
   double            CurrentDrawdown;     // Current drawdown in account currency
   double            CurrentDrawdownPct;  // Current drawdown as percentage

   // Equity tracking for equity stop logic
   double            PeakEquity;          // Peak equity observed for this symbol
   double            CurrentEquity;       // Current equity for this symbol
   double            DrawdownPercent;     // Calculated drawdown percentage from peak

   // Risk management state
   bool              IsBlocked;           // Trading blocked for this symbol
   string            BlockReason;         // Reason for blocking (if blocked)
   datetime          BlockedSince;        // When symbol was blocked

   // Performance metrics
   double            TotalProfit;         // Total realized profit for this symbol
   int               TotalTrades;         // Total trades executed
   double            WinRate;             // Win rate percentage

   // Correlation data
   double            CorrelationValue;    // Current correlation coefficient (-1 to 1)
   bool              CorrelationBlocked;  // Blocked due to correlation threshold

   //+------------------------------------------------------------------+
   //| Constructor with defaults                                         |
   //+------------------------------------------------------------------+
   SymbolRuntimeState()
   {
      Symbol = "";
      IsReady = false;
      SignalState = SIGNAL_IDLE;
      LastSignalTime = 0;
      ActiveGridLevels = 0;
      OpenTrades = 0;
      CurrentDrawdown = 0.0;
      CurrentDrawdownPct = 0.0;
      PeakEquity = 0.0;
      CurrentEquity = 0.0;
      DrawdownPercent = 0.0;
      IsBlocked = false;
      BlockReason = "";
      BlockedSince = 0;
      TotalProfit = 0.0;
      TotalTrades = 0;
      WinRate = 0.0;
      CorrelationValue = 0.0;
      CorrelationBlocked = false;
   }

   //+------------------------------------------------------------------+
   //| Initialize from configuration entry                               |
   //+------------------------------------------------------------------+
   void InitFromConfig(const SymbolConfigEntry &config)
   {
      Symbol = config.Symbol;
      IsReady = false;  // Will be set true after subscription
      // Reset all runtime metrics
      SignalState = SIGNAL_IDLE;
      LastSignalTime = 0;
      ActiveGridLevels = 0;
      OpenTrades = 0;
      CurrentDrawdown = 0.0;
      CurrentDrawdownPct = 0.0;
      PeakEquity = 0.0;
      CurrentEquity = 0.0;
      DrawdownPercent = 0.0;
      IsBlocked = false;
      BlockReason = "";
      BlockedSince = 0;
      TotalProfit = 0.0;
      TotalTrades = 0;
      WinRate = 0.0;
      CorrelationValue = 0.0;
      CorrelationBlocked = false;
   }

   //+------------------------------------------------------------------+
   //| Check if symbol can trade                                         |
   //+------------------------------------------------------------------+
   bool CanTrade() const
   {
      return IsReady && !IsBlocked && !CorrelationBlocked;
   }

   //+------------------------------------------------------------------+
   //| Block symbol with reason                                          |
   //+------------------------------------------------------------------+
   void Block(string reason)
   {
      IsBlocked = true;
      BlockReason = reason;
      BlockedSince = TimeCurrent();
   }

   //+------------------------------------------------------------------+
   //| Unblock symbol                                                    |
   //+------------------------------------------------------------------+
   void Unblock()
   {
      IsBlocked = false;
      BlockReason = "";
      BlockedSince = 0;
   }
};
