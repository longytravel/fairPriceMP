//+------------------------------------------------------------------+
//|                                                  fairPrice.mq5 |
//|                          Copyright 2025, Gemini CLI & User |
//|                                      https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Gemini CLI & User"
#property link      "https://www.google.com"
#property version   "1.00"
#property strict

//--- EA Description
#property description "Grid Entry Expert Advisor based on distance from a Moving Average."
#property description "Opens a market order when price is far from the MA, then places a grid of pending orders."
#property description "Closes all trades when price returns to the MA."
#property description "MT5 Version - Converted from MT4"

//--- Include MT5 Trade Library
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Expert Advisor Input Parameters                                  |
//+------------------------------------------------------------------+
//--- Core Settings
input int      MagicNumber             = 12345;  // Unique number to identify trades
input double   Lots                    = 0.01;   // Lot size for all orders
input int      Slippage                = 3;      // Max slippage in pips

//--- Moving Average Settings
input int      MA_Period               = 200;    // Moving Average Period
input ENUM_MA_METHOD MA_Method         = MODE_EMA; // MA method (Simple, Exponential, etc.)
input ENUM_APPLIED_PRICE MA_Price      = PRICE_CLOSE; // MA price (Close, Open, etc.)

//--- Slow Moving Average for Trend Filter
input bool     UseTrendFilter          = true;   // Enable/Disable the trend filter
input int      Slow_MA_Period          = 800;    // Period for the slow (trend) MA
input ENUM_MA_METHOD Slow_MA_Method    = MODE_EMA; // Method for the slow MA

//--- Trade Entry Grid Settings
input int      Initial_Trigger_Pips    = 100;    // Min distance from MA to open first trade
input int      NumberOfPendingOrders   = 10;     // Number of pending orders in the grid
input int      PendingOrderRangePips   = 50;     // Pip range to spread pending orders over

//--- Exit and Money Management
input bool     CloseOnMA_Touch         = true;   // Close all trades when price touches the MA
input bool     UseEquityStop           = true;   // Use a hard equity stop loss
input double   EquityStopPercentage    = 2.0;    // Close all trades if drawdown reaches this % of account balance
input int      CatastropheSLPips       = 800;    // Catastrophe stop loss per order (wide safety net)

//--- Risk Management Filters
input double   MaxSpreadPips           = 2.0;    // Max spread in pips (reject entries if exceeded)
input int      TradeStartHour          = 1;      // Don't trade before this hour (server time)
input int      TradeEndHour            = 22;     // Don't trade after this hour (server time)

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;                    // Trade object for MT5
int fastMA_Handle;              // Handle for fast MA indicator
int slowMA_Handle;              // Handle for slow MA indicator
double fastMA_Buffer[];         // Buffer to store fast MA values
double slowMA_Buffer[];         // Buffer to store slow MA values
double equityPeak = 0;          // Track peak equity for real drawdown calculation

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- Set trade parameters
   trade.SetExpertMagicNumber(MagicNumber);

//--- Convert slippage from pips to points (handle 3/5-digit brokers)
   int slippagePips = Slippage;
   int deviationPoints = (_Digits == 3 || _Digits == 5) ? slippagePips * 10 : slippagePips;
   trade.SetDeviationInPoints(deviationPoints);
   Print("Slippage set to ", slippagePips, " pips (", deviationPoints, " points)");

//--- Query broker's supported filling modes for this symbol
   long fillingModes = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   Print("Raw SYMBOL_FILLING_MODE value: ", fillingModes);

//--- Set filling type to what broker actually supports (priority: FOK > IOC > RETURN)
   ENUM_ORDER_TYPE_FILLING chosenFilling = ORDER_FILLING_RETURN;
   if((fillingModes & ORDER_FILLING_FOK) == ORDER_FILLING_FOK)
   {
      chosenFilling = ORDER_FILLING_FOK;
   }
   else if((fillingModes & ORDER_FILLING_IOC) == ORDER_FILLING_IOC)
   {
      chosenFilling = ORDER_FILLING_IOC;
   }

   trade.SetTypeFilling(chosenFilling);
   Print("Filling mode set to: ", (int)chosenFilling, " (FOK=1, IOC=2, RETURN=4)");

   trade.SetAsyncMode(false);

//--- Create MA indicator handles
   fastMA_Handle = iMA(_Symbol, PERIOD_CURRENT, MA_Period, 0, MA_Method, MA_Price);
   if(fastMA_Handle == INVALID_HANDLE)
   {
      Print("Error creating fast MA indicator handle. Error: ", GetLastError());
      return(INIT_FAILED);
   }

   slowMA_Handle = iMA(_Symbol, PERIOD_CURRENT, Slow_MA_Period, 0, Slow_MA_Method, MA_Price);
   if(slowMA_Handle == INVALID_HANDLE)
   {
      Print("Error creating slow MA indicator handle. Error: ", GetLastError());
      return(INIT_FAILED);
   }

//--- Set buffer as series
   ArraySetAsSeries(fastMA_Buffer, true);
   ArraySetAsSeries(slowMA_Buffer, true);

//--- Check account type (require hedging mode)
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      Print("ERROR: This EA requires a hedging account. Current account is netting mode.");
      Print("Multiple positions per symbol are not supported in netting mode.");
      return(INIT_FAILED);
   }

//--- Initialize equity peak for drawdown tracking
   equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);

//--- Initialization successful
   Print("fairPrice EA MT5 Initialized.");
   Print("Magic Number: ", MagicNumber);
   Print("Initial Trigger Pips: ", Initial_Trigger_Pips);
   Print("Using Equity Stop: ", UseEquityStop ? "Yes" : "No");
   if(UseEquityStop)
   {
      Print("Equity Stop Percentage: ", EquityStopPercentage, "%");
   }
   Print("Using Trend Filter: ", UseTrendFilter ? "Yes" : "No");
   if(UseTrendFilter)
   {
      Print("Slow MA Period: ", Slow_MA_Period);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- Release indicator handles
   if(fastMA_Handle != INVALID_HANDLE)
      IndicatorRelease(fastMA_Handle);
   if(slowMA_Handle != INVALID_HANDLE)
      IndicatorRelease(slowMA_Handle);

   Print("fairPrice EA MT5 Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//--- Session filter: Check trading hours
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   int currentHour = timeStruct.hour;

   if(currentHour < TradeStartHour || currentHour >= TradeEndHour)
   {
      return; // Outside trading hours, exit OnTick
   }

//--- Spread filter: Check if spread is within acceptable limits
   double point_multiplier_spread = (_Digits == 3 || _Digits == 5) ? 10.0 : 1.0;
   long currentSpreadPts = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double currentSpreadPips = currentSpreadPts / point_multiplier_spread;
   double maxSpreadPts = MaxSpreadPips * point_multiplier_spread;

   if(currentSpreadPts > maxSpreadPts)
   {
      // Don't print every tick to avoid spam
      static datetime lastSpreadWarning = 0;
      if(TimeCurrent() - lastSpreadWarning > 300) // Warn once per 5 minutes
      {
         Print("Spread too wide: ", NormalizeDouble(currentSpreadPips, 2),
               " pips (max: ", MaxSpreadPips, " pips). Skipping entry checks.");
         lastSpreadWarning = TimeCurrent();
      }
      return; // Spread too wide, exit OnTick
   }

//--- Do not trade if parameters are invalid
   if(Initial_Trigger_Pips <= 0 || NumberOfPendingOrders < 0 || PendingOrderRangePips < 0)
   {
      Print("Error: Invalid input parameters for distances or order counts. Please check EA settings.");
      return;
   }

//--- Copy MA values to buffers
   if(CopyBuffer(fastMA_Handle, 0, 0, 1, fastMA_Buffer) <= 0)
   {
      Print("Error copying fast MA buffer. Error: ", GetLastError());
      return;
   }
   if(CopyBuffer(slowMA_Handle, 0, 0, 1, slowMA_Buffer) <= 0)
   {
      Print("Error copying slow MA buffer. Error: ", GetLastError());
      return;
   }

   double fastMA = fastMA_Buffer[0];
   double slowMA = slowMA_Buffer[0];

//--- Get current prices
   double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

//--- Calculate point multiplier for pip conversion
   double point_multiplier = (_Digits == 3 || _Digits == 5) ? 10.0 : 1.0;

//--- Calculate distance from MA in pips
   double distancePips;
   if(ask < fastMA)
      distancePips = (fastMA - ask) / (_Point * point_multiplier);
   else
      distancePips = (ask - fastMA) / (_Point * point_multiplier);

//--- Check if any trades for this EA are currently open or pending
   int totalTrades = CountEATrades();

//--- === ENTRY LOGIC ===
   if(totalTrades == 0)
   {
      // Determine the trend direction if the filter is enabled
      bool isUptrend = (!UseTrendFilter || fastMA > slowMA);
      bool isDowntrend = (!UseTrendFilter || fastMA < slowMA);

      // Check for BUY signal
      if(isUptrend && ask < fastMA && distancePips >= Initial_Trigger_Pips)
      {
         OpenInitialTradeAndGrid(ORDER_TYPE_BUY, ask, fastMA);
         return;
      }

      // Check for SELL signal
      if(isDowntrend && ask > fastMA && distancePips >= Initial_Trigger_Pips)
      {
         OpenInitialTradeAndGrid(ORDER_TYPE_SELL, bid, fastMA);
         return;
      }
   }
//--- === EXIT LOGIC ===
   else if(totalTrades > 0 && CloseOnMA_Touch)
   {
      bool closeSignal = false;
      if(CountEATrades(POSITION_TYPE_BUY) > 0 && bid >= fastMA)
      {
         closeSignal = true;
      }
      else if(CountEATrades(POSITION_TYPE_SELL) > 0 && ask <= fastMA)
      {
         closeSignal = true;
      }

      if(closeSignal)
      {
         Print("Price has returned to the MA. Closing all trades for ", _Symbol);
         CloseAllEATrades();
         return;
      }
   }

//--- === MONEY MANAGEMENT LOGIC ===
   if(UseEquityStop && totalTrades > 0)
   {
      CheckEquityStop();
   }
}

//+------------------------------------------------------------------+
//| Counts open positions and pending orders managed by this EA     |
//+------------------------------------------------------------------+
int CountEATrades(int type = -1)
{
   int count = 0;

//--- Count open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            if(type == -1 || PositionGetInteger(POSITION_TYPE) == type)
            {
               count++;
            }
         }
      }
   }

//--- Count pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
            OrderGetInteger(ORDER_MAGIC) == MagicNumber)
         {
            if(type == -1)
            {
               count++;
            }
            else if(type == POSITION_TYPE_BUY &&
                    (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT))
            {
               count++;
            }
            else if(type == POSITION_TYPE_SELL &&
                    (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT))
            {
               count++;
            }
         }
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Opens initial market order and grid of pending orders           |
//+------------------------------------------------------------------+
void OpenInitialTradeAndGrid(ENUM_ORDER_TYPE type, double price, double takeProfit)
{
//--- Normalize TP to be valid
   double normalizedTP = NormalizeDouble(takeProfit, _Digits);

//--- Calculate point multiplier for pip conversion
   double point_multiplier = (_Digits == 3 || _Digits == 5) ? 10.0 : 1.0;

//--- Calculate catastrophe stop loss (wide safety net)
   double catastropheSL = 0;
   if(CatastropheSLPips > 0)
   {
      if(type == ORDER_TYPE_BUY)
         catastropheSL = price - (CatastropheSLPips * _Point * point_multiplier);
      else if(type == ORDER_TYPE_SELL)
         catastropheSL = price + (CatastropheSLPips * _Point * point_multiplier);

      catastropheSL = NormalizeDouble(catastropheSL, _Digits);
   }

//--- Open Initial Market Order with catastrophe SL
   bool result = false;
   if(type == ORDER_TYPE_BUY)
      result = trade.Buy(Lots, _Symbol, price, catastropheSL, normalizedTP, "fairPrice Initial");
   else if(type == ORDER_TYPE_SELL)
      result = trade.Sell(Lots, _Symbol, price, catastropheSL, normalizedTP, "fairPrice Initial");

   if(!result)
   {
      Print("Failed to open initial market order. Error: ", GetLastError(), ", RetCode: ", trade.ResultRetcode());
      return;
   }
   else
   {
      Print("Opened initial market order #", trade.ResultOrder(), " at ", price);
   }

//--- Place Pending Order Grid
   if(NumberOfPendingOrders > 0)
   {
      //--- Get broker minimum distance requirements
      int stopLevelPts = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int freezeLevelPts = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      double minDistanceMarket = MathMax(stopLevelPts, freezeLevelPts) * _Point;
      double minDistanceTP = stopLevelPts * _Point;

      Print("Broker StopLevel=", stopLevelPts, " pts, FreezeLevel=", freezeLevelPts, " pts");

      double stepPips = (double)PendingOrderRangePips / NumberOfPendingOrders;
      double pendingPrice;
      ENUM_ORDER_TYPE pendingType;

      for(int i = 1; i <= NumberOfPendingOrders; i++)
      {
         if(type == ORDER_TYPE_BUY)
         {
            pendingType = ORDER_TYPE_BUY_LIMIT;
            pendingPrice = price - (i * stepPips * _Point * point_multiplier);
         }
         else
         {
            pendingType = ORDER_TYPE_SELL_LIMIT;
            pendingPrice = price + (i * stepPips * _Point * point_multiplier);
         }

         double normalizedPendingPrice = NormalizeDouble(pendingPrice, _Digits);

         //--- Validate distance from current market price
         double currentPrice = (pendingType == ORDER_TYPE_BUY_LIMIT) ?
                               SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                               SymbolInfoDouble(_Symbol, SYMBOL_ASK);

         double distanceFromMarket = MathAbs(normalizedPendingPrice - currentPrice);

         if(distanceFromMarket < minDistanceMarket)
         {
            Print("Skipping pending order #", i, " - too close to market (",
                  NormalizeDouble(distanceFromMarket/_Point, 1), " pts < min ",
                  MathMax(stopLevelPts, freezeLevelPts), " pts)");
            continue;
         }

         //--- CRITICAL: Also validate TP distance from pending price
         double tpDistance = MathAbs(normalizedTP - normalizedPendingPrice);
         if(tpDistance < minDistanceTP)
         {
            Print("Skipping pending order #", i, " - TP too close to order price (",
                  NormalizeDouble(tpDistance/_Point, 1), " pts < min ", stopLevelPts, " pts)");
            continue;
         }

         //--- Calculate catastrophe SL for pending order
         double pendingCatastropheSL = 0;
         if(CatastropheSLPips > 0)
         {
            if(pendingType == ORDER_TYPE_BUY_LIMIT)
               pendingCatastropheSL = normalizedPendingPrice - (CatastropheSLPips * _Point * point_multiplier);
            else if(pendingType == ORDER_TYPE_SELL_LIMIT)
               pendingCatastropheSL = normalizedPendingPrice + (CatastropheSLPips * _Point * point_multiplier);

            pendingCatastropheSL = NormalizeDouble(pendingCatastropheSL, _Digits);
         }

         //--- Calculate expiry time (end of current trading day)
         datetime expiry = (datetime)(StringToTime(TimeToString(TimeCurrent(), TIME_DATE)) + 86400);

         //--- Place the pending order with daily expiry and catastrophe SL
         result = trade.OrderOpen(_Symbol, pendingType, Lots, 0, normalizedPendingPrice,
                                  pendingCatastropheSL, normalizedTP, ORDER_TIME_SPECIFIED, expiry, "fairPrice Grid");

         if(!result)
         {
            Print("Failed to place pending order #", i, ". Error: ", GetLastError(),
                  ", RetCode: ", trade.ResultRetcode());
         }
         else
         {
            Print("Placed pending order #", i, " at ", normalizedPendingPrice);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Closes all open positions and pending orders for this EA        |
//+------------------------------------------------------------------+
void CloseAllEATrades()
{
//--- Close all open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            bool result = trade.PositionClose(ticket);
            if(!result)
            {
               Print("Failed to close position #", ticket, ". Error: ", GetLastError(),
                     ", RetCode: ", trade.ResultRetcode());
            }
            else
            {
               Print("Successfully closed position #", ticket);
            }
         }
      }
   }

//--- Delete all pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
            OrderGetInteger(ORDER_MAGIC) == MagicNumber)
         {
            bool result = trade.OrderDelete(ticket);
            if(!result)
            {
               Print("Failed to delete pending order #", ticket, ". Error: ", GetLastError(),
                     ", RetCode: ", trade.ResultRetcode());
            }
            else
            {
               Print("Successfully deleted pending order #", ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Checks equity stop and closes all trades if triggered           |
//+------------------------------------------------------------------+
void CheckEquityStop()
{
   if(EquityStopPercentage <= 0) return;

//--- Track peak equity and calculate real drawdown
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

//--- Update equity peak if we've reached a new high
   if(currentEquity > equityPeak)
   {
      equityPeak = currentEquity;
   }

//--- Calculate drawdown from peak
   double drawdownPercent = 0;
   if(equityPeak > 0)
   {
      drawdownPercent = ((equityPeak - currentEquity) / equityPeak) * 100.0;
   }

//--- Check if drawdown exceeds threshold
   if(drawdownPercent >= EquityStopPercentage)
   {
      Print("Equity Stop Loss triggered! Drawdown from peak: ", NormalizeDouble(drawdownPercent, 2),
            "% (Peak: ", NormalizeDouble(equityPeak, 2), ", Current: ",
            NormalizeDouble(currentEquity, 2), "). Closing all trades.");
      CloseAllEATrades();

      // Reset equity peak after stop loss
      equityPeak = currentEquity;
   }
}
//+------------------------------------------------------------------+
