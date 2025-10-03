//+------------------------------------------------------------------+
//|                                                SymbolEngine.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

#include <fairPriceMP\DTO\SymbolConfigEntry.mqh>
#include <fairPriceMP\DTO\SymbolRuntimeState.mqh>
#include "..\Services\TradeProxy.mqh"
#include "..\Services\StructuredLogger.mqh"

//+------------------------------------------------------------------+
//| Symbol Engine                                                     |
//| Executes fairPrice trade lifecycle independently per symbol      |
//+------------------------------------------------------------------+
class SymbolEngine
{
private:
   SymbolConfigEntry    m_config;
   SymbolRuntimeState   m_state;
   TradeProxy*          m_tradeProxy;
   StructuredLogger*    m_logger;

   // Indicator handles
   int                  m_fastEMAHandle;
   int                  m_slowEMAHandle;

   // Cached EMA values
   double               m_fastEMA;
   double               m_slowEMA;
   double               m_prevFastEMA;

   // Internal flags
   bool                 m_gridSeeded;
   datetime             m_lastActionTime;

   //+------------------------------------------------------------------+
   //| Calculate EMA deviation in pips                                   |
   //+------------------------------------------------------------------+
   double CalculateEMADeviationPips(double price, double ema)
   {
      double deviation = MathAbs(price - ema);
      double point = SymbolInfoDouble(m_config.Symbol, SYMBOL_POINT);
      return deviation / (point * 10.0);  // Convert to pips
   }

   //+------------------------------------------------------------------+
   //| Check if trend filter allows trade                                |
   //+------------------------------------------------------------------+
   bool CheckTrendFilter(bool isBuySignal)
   {
      // If slow EMA not configured, trend filter disabled
      if(m_config.SlowEMAPeriod <= 0)
         return true;

      // Buy: price must be above slow EMA
      // Sell: price must be below slow EMA
      double price = SymbolInfoDouble(m_config.Symbol, SYMBOL_BID);

      if(isBuySignal && price > m_slowEMA)
         return true;

      if(!isBuySignal && price < m_slowEMA)
         return true;

      return false;
   }

   //+------------------------------------------------------------------+
   //| Update EMA indicator values                                       |
   //+------------------------------------------------------------------+
   bool UpdateEMAValues()
   {
      double fastBuffer[];
      double slowBuffer[];
      ArraySetAsSeries(fastBuffer, true);
      ArraySetAsSeries(slowBuffer, true);

      // Copy fast EMA
      if(CopyBuffer(m_fastEMAHandle, 0, 0, 2, fastBuffer) < 2)
      {
         m_logger.LogError("EMA_FAIL", m_config.Symbol, "Failed to copy fast EMA buffer", GetLastError());
         return false;
      }

      m_prevFastEMA = m_fastEMA;
      m_fastEMA = fastBuffer[0];

      // Copy slow EMA if configured
      if(m_config.SlowEMAPeriod > 0)
      {
         if(CopyBuffer(m_slowEMAHandle, 0, 0, 1, slowBuffer) < 1)
         {
            m_logger.LogError("EMA_FAIL", m_config.Symbol, "Failed to copy slow EMA buffer", GetLastError());
            return false;
         }
         m_slowEMA = slowBuffer[0];
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Evaluate entry signal                                             |
   //+------------------------------------------------------------------+
   ENUM_SIGNAL_STATE EvaluateEntrySignal()
   {
      double bid = SymbolInfoDouble(m_config.Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_config.Symbol, SYMBOL_ASK);

      // Calculate deviation from fast EMA
      double deviationPips = CalculateEMADeviationPips(bid, m_fastEMA);

      // Check if deviation exceeds trigger threshold
      if(deviationPips < m_config.TriggerPips)
         return SIGNAL_IDLE;

      // Determine signal direction
      bool isBuySignal = (bid < m_fastEMA);  // Price below EMA = buy signal
      bool isSellSignal = (bid > m_fastEMA); // Price above EMA = sell signal

      // Apply trend filter
      if(isBuySignal && !CheckTrendFilter(true))
         return SIGNAL_IDLE;

      if(isSellSignal && !CheckTrendFilter(false))
         return SIGNAL_IDLE;

      return isBuySignal ? SIGNAL_BUY : SIGNAL_SELL;
   }

   //+------------------------------------------------------------------+
   //| Check spread filter                                               |
   //+------------------------------------------------------------------+
   bool CheckSpreadFilter()
   {
      if(m_config.MaxSpread <= 0)
         return true;  // No limit

      long spreadValue = SymbolInfoInteger(m_config.Symbol, SYMBOL_SPREAD);
      double point = SymbolInfoDouble(m_config.Symbol, SYMBOL_POINT);
      double spreadPoints = (double)spreadValue;

      if(spreadPoints > m_config.MaxSpread)
      {
         m_logger.LogEvent("FILTER_BLOCK", m_config.Symbol,
                          StringFormat("Spread too high: %.1f > %.1f", spreadPoints, m_config.MaxSpread));
         return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Check trading hours filter                                        |
   //+------------------------------------------------------------------+
   bool CheckTradingHoursFilter()
   {
      if(m_config.TradingHourStart == -1 || m_config.TradingHourEnd == -1)
         return true;  // No restriction

      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int currentHour = dt.hour;

      bool inRange = false;

      if(m_config.TradingHourStart <= m_config.TradingHourEnd)
      {
         // Normal range (e.g., 9-17)
         inRange = (currentHour >= m_config.TradingHourStart && currentHour <= m_config.TradingHourEnd);
      }
      else
      {
         // Overnight range (e.g., 22-6)
         inRange = (currentHour >= m_config.TradingHourStart || currentHour <= m_config.TradingHourEnd);
      }

      if(!inRange)
      {
         m_logger.LogEvent("FILTER_BLOCK", m_config.Symbol,
                          StringFormat("Outside trading hours: %d not in %d-%d",
                                      currentHour, m_config.TradingHourStart, m_config.TradingHourEnd));
         return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Execute market entry and seed grid                                |
   //+------------------------------------------------------------------+
   bool ExecuteEntry(ENUM_SIGNAL_STATE signal)
   {
      // Determine order type
      ENUM_ORDER_TYPE orderType = (signal == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      // Calculate SL if configured
      double sl = 0;
      if(m_config.CatastropheSL > 0)
      {
         double point = SymbolInfoDouble(m_config.Symbol, SYMBOL_POINT);
         double slDistance = m_config.CatastropheSL * point;

         if(orderType == ORDER_TYPE_BUY)
         {
            double bid = SymbolInfoDouble(m_config.Symbol, SYMBOL_BID);
            sl = bid - slDistance;
         }
         else
         {
            double ask = SymbolInfoDouble(m_config.Symbol, SYMBOL_ASK);
            sl = ask + slDistance;
         }
      }

      // Open market order
      if(!m_tradeProxy.OpenMarketOrder(orderType, m_config.LotSize, sl, 0))
         return false;

      // Seed pending grid
      if(!SeedPendingGrid(signal))
      {
         m_logger.LogEvent("GRID_FAIL", m_config.Symbol, "Grid seeding incomplete");
         // Don't return false - market order already placed
      }

      m_gridSeeded = true;
      m_lastActionTime = TimeCurrent();

      return true;
   }

   //+------------------------------------------------------------------+
   //| Seed pending order grid                                           |
   //+------------------------------------------------------------------+
   bool SeedPendingGrid(ENUM_SIGNAL_STATE signal)
   {
      if(m_config.GridCount <= 0)
         return true;  // No grid configured

      double point = SymbolInfoDouble(m_config.Symbol, SYMBOL_POINT);
      double gridSpacing = m_config.GridSpacing * point;
      double entryPrice = (signal == SIGNAL_BUY) ? SymbolInfoDouble(m_config.Symbol, SYMBOL_ASK)
                                                  : SymbolInfoDouble(m_config.Symbol, SYMBOL_BID);

      // Calculate SL if configured
      double sl = 0;
      if(m_config.CatastropheSL > 0)
      {
         double slDistance = m_config.CatastropheSL * point;
         sl = (signal == SIGNAL_BUY) ? (entryPrice - slDistance) : (entryPrice + slDistance);
      }

      // Place pending orders
      ENUM_ORDER_TYPE pendingType = (signal == SIGNAL_BUY) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;

      for(int i = 1; i <= m_config.GridCount; i++)
      {
         double orderPrice = (signal == SIGNAL_BUY) ? (entryPrice - i * gridSpacing)
                                                     : (entryPrice + i * gridSpacing);

         if(!m_tradeProxy.PlacePendingOrder(pendingType, m_config.LotSize, orderPrice, sl, 0))
         {
            m_logger.LogEvent("GRID_FAIL", m_config.Symbol,
                             StringFormat("Failed to place grid level %d of %d", i, m_config.GridCount));
         }
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Check exit condition (price touches fast EMA)                     |
   //+------------------------------------------------------------------+
   bool CheckExitCondition()
   {
      if(!m_config.ExitOnEMA)
         return false;

      if(!m_gridSeeded)
         return false;  // No position to exit

      double bid = SymbolInfoDouble(m_config.Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_config.Symbol, SYMBOL_ASK);

      // Check if price crossed fast EMA
      bool priceTouchedEMA = (bid <= m_fastEMA && bid >= m_prevFastEMA) ||
                             (bid >= m_fastEMA && bid <= m_prevFastEMA) ||
                             (ask <= m_fastEMA && ask >= m_prevFastEMA) ||
                             (ask >= m_fastEMA && ask <= m_prevFastEMA);

      return priceTouchedEMA;
   }

   //+------------------------------------------------------------------+
   //| Execute exit (close all positions and pending orders)             |
   //+------------------------------------------------------------------+
   void ExecuteExit()
   {
      int closedCount = m_tradeProxy.CloseAll();

      m_logger.LogEvent("EXIT_EMA", m_config.Symbol,
                       StringFormat("Exit triggered | Closed: %d trades", closedCount));

      // Reset state
      m_state.SignalState = SIGNAL_IDLE;
      m_state.ActiveGridLevels = 0;
      m_gridSeeded = false;
      m_lastActionTime = TimeCurrent();
   }

   //+------------------------------------------------------------------+
   //| Update equity tracking for this symbol                            |
   //+------------------------------------------------------------------+
   void UpdateEquity()
   {
      // Get current equity by filtering symbol-specific positions
      double currentEquity = 0.0;
      int total = PositionsTotal();

      for(int i = 0; i < total; i++)
      {
         if(PositionGetSymbol(i) == m_config.Symbol)
         {
            currentEquity += PositionGetDouble(POSITION_PROFIT);
         }
      }

      // Store current equity
      m_state.CurrentEquity = currentEquity;

      // Update peak equity if current exceeds peak
      if(m_state.CurrentEquity > m_state.PeakEquity)
      {
         m_state.PeakEquity = m_state.CurrentEquity;
      }

      // Calculate drawdown percentage
      if(m_state.PeakEquity > 0.0)
      {
         m_state.DrawdownPercent = ((m_state.PeakEquity - m_state.CurrentEquity) / m_state.PeakEquity) * 100.0;
      }
      else
      {
         m_state.DrawdownPercent = 0.0;
      }

      // Log equity update
      m_logger.LogEvent("EQY_UPD", m_config.Symbol,
                       StringFormat("Equity: %.2f | Peak: %.2f | DD: %.2f%%",
                                   m_state.CurrentEquity, m_state.PeakEquity, m_state.DrawdownPercent));
   }

   //+------------------------------------------------------------------+
   //| Check equity stop and close positions if threshold breached       |
   //+------------------------------------------------------------------+
   bool CheckEquityStop()
   {
      // If no max drawdown configured, skip check
      if(m_config.MaxDrawdownPercent <= 0.0)
         return false;

      // Check if drawdown threshold breached
      if(m_state.DrawdownPercent >= m_config.MaxDrawdownPercent)
      {
         // Count positions before closing
         int posCount = m_tradeProxy.GetPositionCount();
         int ordCount = m_tradeProxy.GetPendingOrderCount();
         int totalClosed = posCount + ordCount;

         // Close all positions and pending orders for this symbol
         m_tradeProxy.CloseAll();

         // Log equity stop event
         m_logger.LogEvent("EQY_STOP", m_config.Symbol,
                          StringFormat("Equity stop triggered | DD: %.2f%% | Closed: %d trades",
                                      m_state.DrawdownPercent, totalClosed));

         // Block symbol from further trading
         m_state.Block(StringFormat("Equity stop: %.2f%% drawdown", m_state.DrawdownPercent));

         // Reset grid state
         m_gridSeeded = false;
         m_state.SignalState = SIGNAL_IDLE;
         m_state.ActiveGridLevels = 0;

         // Emit MT5 alert
         string alertMsg = StringFormat("[%s] EQUITY STOP: %.2f%% drawdown | %d trades closed",
                                       m_config.Symbol, m_state.DrawdownPercent, totalClosed);
         Alert(alertMsg);

         return true;
      }

      return false;
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   SymbolEngine(const SymbolConfigEntry &config, StructuredLogger* logger)
   {
      m_config = config;
      m_logger = logger;

      m_state.InitFromConfig(config);

      m_tradeProxy = new TradeProxy(config.Symbol, logger);

      m_fastEMAHandle = INVALID_HANDLE;
      m_slowEMAHandle = INVALID_HANDLE;
      m_fastEMA = 0;
      m_slowEMA = 0;
      m_prevFastEMA = 0;
      m_gridSeeded = false;
      m_lastActionTime = 0;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                         |
   //+------------------------------------------------------------------+
   ~SymbolEngine()
   {
      if(m_tradeProxy != NULL)
         delete m_tradeProxy;

      if(m_fastEMAHandle != INVALID_HANDLE)
         IndicatorRelease(m_fastEMAHandle);

      if(m_slowEMAHandle != INVALID_HANDLE)
         IndicatorRelease(m_slowEMAHandle);
   }

   //+------------------------------------------------------------------+
   //| Initialize engine                                                 |
   //+------------------------------------------------------------------+
   bool Init()
   {
      // Create fast EMA indicator
      m_fastEMAHandle = iMA(m_config.Symbol, PERIOD_CURRENT, m_config.FastEMAPeriod,
                            0, MODE_EMA, PRICE_CLOSE);

      if(m_fastEMAHandle == INVALID_HANDLE)
      {
         m_logger.LogError("INIT_FAIL", m_config.Symbol, "Failed to create fast EMA indicator", GetLastError());
         return false;
      }

      // Create slow EMA indicator if configured
      if(m_config.SlowEMAPeriod > 0)
      {
         m_slowEMAHandle = iMA(m_config.Symbol, PERIOD_CURRENT, m_config.SlowEMAPeriod,
                               0, MODE_EMA, PRICE_CLOSE);

         if(m_slowEMAHandle == INVALID_HANDLE)
         {
            m_logger.LogError("INIT_FAIL", m_config.Symbol, "Failed to create slow EMA indicator", GetLastError());
            return false;
         }
      }

      // Set slippage tolerance
      if(m_config.SlippageTolerance > 0)
         m_tradeProxy.SetSlippage(m_config.SlippageTolerance);

      m_logger.LogEvent("ENG_INIT", m_config.Symbol, "Engine initialized successfully");
      return true;
   }

   //+------------------------------------------------------------------+
   //| Process tick                                                       |
   //+------------------------------------------------------------------+
   void ProcessTick(const MqlTick &tick)
   {
      // Update EMA values
      if(!UpdateEMAValues())
         return;

      // Update equity tracking
      UpdateEquity();

      // Check equity stop
      if(CheckEquityStop())
         return;

      // Check if symbol can trade
      if(!m_state.CanTrade())
         return;

      // Check for exit condition first
      if(CheckExitCondition())
      {
         ExecuteExit();
         return;
      }

      // If already in position, skip entry logic
      if(m_gridSeeded)
         return;

      // Evaluate entry signal
      ENUM_SIGNAL_STATE newSignal = EvaluateEntrySignal();

      // Log signal state change
      if(newSignal != m_state.SignalState)
      {
         string signalStr = (newSignal == SIGNAL_BUY) ? "BUY" :
                           (newSignal == SIGNAL_SELL) ? "SELL" : "IDLE";

         m_logger.LogEvent("SIG_UPD", m_config.Symbol,
                          StringFormat("Signal changed: %s | Deviation: %.1f pips",
                                      signalStr, CalculateEMADeviationPips(tick.bid, m_fastEMA)));

         m_state.SignalState = newSignal;
         m_state.LastSignalTime = TimeCurrent();
      }

      // If no valid signal, return
      if(newSignal == SIGNAL_IDLE)
         return;

      // Apply pre-trade filters
      if(!CheckSpreadFilter())
         return;

      if(!CheckTradingHoursFilter())
         return;

      // Execute entry
      ExecuteEntry(newSignal);
   }

   //+------------------------------------------------------------------+
   //| Apply correlation block                                           |
   //+------------------------------------------------------------------+
   void ApplyCorrelationBlock(bool blocked)
   {
      m_state.CorrelationBlocked = blocked;

      if(blocked)
      {
         m_logger.LogEvent("CORR_BLOCK", m_config.Symbol, "Correlation block applied");
         m_state.SignalState = SIGNAL_BLOCKED;
      }
      else
      {
         m_logger.LogEvent("CORR_UNBLK", m_config.Symbol, "Correlation block removed");
         m_state.SignalState = SIGNAL_IDLE;
      }
   }

   //+------------------------------------------------------------------+
   //| Get runtime state                                                 |
   //+------------------------------------------------------------------+
   void GetRuntimeState(SymbolRuntimeState &state)
   {
      // Update trade counts from proxy with validation
      int actualPosCount = m_tradeProxy.GetPositionCount();
      int actualOrdCount = m_tradeProxy.GetPendingOrderCount();

      m_state.OpenTrades = actualPosCount;
      m_state.ActiveGridLevels = actualPosCount + actualOrdCount;

      // Verify counts match actual MT5 state (isolation check)
      int verifyPosCount = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionGetSymbol(i) == m_config.Symbol)
            verifyPosCount++;
      }

      if(verifyPosCount != actualPosCount)
      {
         m_logger.LogEvent("COUNT_WARN", m_config.Symbol,
                          StringFormat("Position count mismatch: proxy=%d actual=%d",
                                      actualPosCount, verifyPosCount));
      }

      state = m_state;
   }
};
