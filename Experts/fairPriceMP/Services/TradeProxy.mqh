//+------------------------------------------------------------------+
//|                                                  TradeProxy.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

#include <Trade\Trade.mqh>
#include "StructuredLogger.mqh"

//+------------------------------------------------------------------+
//| Trade Proxy Service                                               |
//| Wraps MT5 trade API with normalization and error handling        |
//+------------------------------------------------------------------+
class TradeProxy
{
private:
   CTrade*           m_trade;
   StructuredLogger* m_logger;
   string            m_symbol;

   //+------------------------------------------------------------------+
   //| Normalize price using symbol's _Point                            |
   //+------------------------------------------------------------------+
   double NormalizePrice(double price)
   {
      double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSize > 0)
         return MathRound(price / tickSize) * tickSize;
      return NormalizeDouble(price, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
   }

   //+------------------------------------------------------------------+
   //| Normalize lot size using symbol's volume step                    |
   //+------------------------------------------------------------------+
   double NormalizeLot(double lots)
   {
      double volumeStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      if(volumeStep > 0)
         lots = MathRound(lots / volumeStep) * volumeStep;

      double minVolume = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxVolume = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);

      if(lots < minVolume)
         lots = minVolume;
      if(lots > maxVolume)
         lots = maxVolume;

      int volumeDigits = 2;
      if(volumeStep < 0.01)
         volumeDigits = 3;

      return NormalizeDouble(lots, volumeDigits);
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   TradeProxy(string symbol, StructuredLogger* logger)
   {
      m_symbol = symbol;
      m_logger = logger;
      m_trade = new CTrade();
      m_trade.SetExpertMagicNumber(202503);  // fairPriceMP magic number
      m_trade.SetDeviationInPoints(10);      // Default slippage
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                         |
   //+------------------------------------------------------------------+
   ~TradeProxy()
   {
      if(m_trade != NULL)
         delete m_trade;
   }

   //+------------------------------------------------------------------+
   //| Set slippage tolerance                                            |
   //+------------------------------------------------------------------+
   void SetSlippage(double slippagePoints)
   {
      m_trade.SetDeviationInPoints((ulong)slippagePoints);
   }

   //+------------------------------------------------------------------+
   //| Open market order (Buy or Sell)                                   |
   //+------------------------------------------------------------------+
   bool OpenMarketOrder(ENUM_ORDER_TYPE orderType, double lots, double sl = 0, double tp = 0)
   {
      // Normalize parameters
      double normalizedLots = NormalizeLot(lots);
      double normalizedSL = (sl > 0) ? NormalizePrice(sl) : 0;
      double normalizedTP = (tp > 0) ? NormalizePrice(tp) : 0;

      bool result = false;

      if(orderType == ORDER_TYPE_BUY)
      {
         double price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         result = m_trade.Buy(normalizedLots, m_symbol, price, normalizedSL, normalizedTP);
      }
      else if(orderType == ORDER_TYPE_SELL)
      {
         double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         result = m_trade.Sell(normalizedLots, m_symbol, price, normalizedSL, normalizedTP);
      }

      // Log result
      int resultCode = (int)m_trade.ResultRetcode();
      string orderTypeStr = (orderType == ORDER_TYPE_BUY) ? "BUY" : "SELL";
      string details = StringFormat("Lots: %.2f | SL: %.5f | TP: %.5f", normalizedLots, normalizedSL, normalizedTP);

      if(result)
         m_logger.LogTradeResult("TRADE_EXEC", m_symbol, orderTypeStr, resultCode, details);
      else
         m_logger.LogError("TRADE_FAIL", m_symbol, orderTypeStr + " failed", resultCode);

      return result;
   }

   //+------------------------------------------------------------------+
   //| Place pending order                                               |
   //+------------------------------------------------------------------+
   bool PlacePendingOrder(ENUM_ORDER_TYPE orderType, double lots, double price, double sl = 0, double tp = 0)
   {
      // Normalize parameters
      double normalizedLots = NormalizeLot(lots);
      double normalizedPrice = NormalizePrice(price);
      double normalizedSL = (sl > 0) ? NormalizePrice(sl) : 0;
      double normalizedTP = (tp > 0) ? NormalizePrice(tp) : 0;

      bool result = m_trade.OrderOpen(m_symbol, orderType, normalizedLots, 0, normalizedPrice,
                                      normalizedSL, normalizedTP);

      // Log result
      int resultCode = (int)m_trade.ResultRetcode();
      string orderTypeStr = EnumToString(orderType);
      string details = StringFormat("Lots: %.2f | Price: %.5f | SL: %.5f | TP: %.5f",
                                    normalizedLots, normalizedPrice, normalizedSL, normalizedTP);

      if(result)
         m_logger.LogTradeResult("GRID_PLACE", m_symbol, orderTypeStr, resultCode, details);
      else
         m_logger.LogError("GRID_FAIL", m_symbol, orderTypeStr + " failed", resultCode);

      return result;
   }

   //+------------------------------------------------------------------+
   //| Close all positions and pending orders for symbol                 |
   //+------------------------------------------------------------------+
   int CloseAll()
   {
      int closedCount = 0;

      // Close all positions
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;

         if(PositionGetString(POSITION_SYMBOL) == m_symbol)
         {
            if(m_trade.PositionClose(ticket))
            {
               closedCount++;
               m_logger.LogTradeResult("CLOSE_POS", m_symbol, "Position closed", (int)m_trade.ResultRetcode(),
                                      StringFormat("Ticket: %I64u", ticket));
            }
            else
            {
               m_logger.LogError("CLOSE_FAIL", m_symbol, "Failed to close position", (int)m_trade.ResultRetcode());
            }
         }
      }

      // Delete all pending orders
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;

         if(OrderGetString(ORDER_SYMBOL) == m_symbol)
         {
            if(m_trade.OrderDelete(ticket))
            {
               closedCount++;
               m_logger.LogTradeResult("DEL_ORDER", m_symbol, "Pending order deleted", (int)m_trade.ResultRetcode(),
                                      StringFormat("Ticket: %I64u", ticket));
            }
            else
            {
               m_logger.LogError("DEL_FAIL", m_symbol, "Failed to delete pending order", (int)m_trade.ResultRetcode());
            }
         }
      }

      return closedCount;
   }

   //+------------------------------------------------------------------+
   //| Get open positions count for symbol                               |
   //+------------------------------------------------------------------+
   int GetPositionCount()
   {
      int count = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionGetSymbol(i) == m_symbol)
            count++;
      }
      return count;
   }

   //+------------------------------------------------------------------+
   //| Get pending orders count for symbol                               |
   //+------------------------------------------------------------------+
   int GetPendingOrderCount()
   {
      int count = 0;
      for(int i = 0; i < OrdersTotal(); i++)
      {
         ulong ticket = OrderGetTicket(i);
         if(ticket > 0 && OrderGetString(ORDER_SYMBOL) == m_symbol)
            count++;
      }
      return count;
   }
};
