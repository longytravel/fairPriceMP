//+------------------------------------------------------------------+
//|                                            DashboardRenderer.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

#include <fairPriceMP\DTO\SymbolRuntimeState.mqh>

//+------------------------------------------------------------------+
//| Dashboard Renderer                                                |
//| Renders per-symbol telemetry on chart                            |
//+------------------------------------------------------------------+
class DashboardRenderer
{
private:
   string            m_prefix;          // Object name prefix
   datetime          m_lastUpdate;      // Last update timestamp
   int               m_updateInterval;  // Update interval in seconds (throttle to 1 Hz)

   //+------------------------------------------------------------------+
   //| Generate object name                                             |
   //+------------------------------------------------------------------+
   string GetObjectName(string suffix)
   {
      return m_prefix + "_" + suffix;
   }

   //+------------------------------------------------------------------+
   //| Create or update text label                                      |
   //+------------------------------------------------------------------+
   void RenderLabel(string name, int x, int y, string text, color clr = clrWhite, int fontSize = 8)
   {
      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      }

      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   DashboardRenderer(string prefix = "FP_DASH")
   {
      m_prefix = prefix;
      m_lastUpdate = 0;
      m_updateInterval = 1;  // 1 second throttle
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                         |
   //+------------------------------------------------------------------+
   ~DashboardRenderer()
   {
      ClearDashboard();
   }

   //+------------------------------------------------------------------+
   //| Clear all dashboard objects                                       |
   //+------------------------------------------------------------------+
   void ClearDashboard()
   {
      ObjectsDeleteAll(0, m_prefix, 0, OBJ_LABEL);
   }

   //+------------------------------------------------------------------+
   //| Render symbol row                                                 |
   //+------------------------------------------------------------------+
   void RenderSymbolRow(int row, const SymbolRuntimeState &state)
   {
      // Throttle updates
      datetime now = TimeCurrent();
      if(now - m_lastUpdate < m_updateInterval)
         return;

      int y = 20 + (row * 20);
      int x = 10;

      // Column 1: Symbol
      string symbolName = GetObjectName(state.Symbol + "_Symbol");
      RenderLabel(symbolName, x, y, state.Symbol, clrWhite, 9);

      // Column 2: Signal State
      x += 100;
      string signalText = "";
      color signalColor = clrGray;

      switch(state.SignalState)
      {
         case SIGNAL_BUY:
            signalText = "BUY";
            signalColor = clrLime;
            break;
         case SIGNAL_SELL:
            signalText = "SELL";
            signalColor = clrRed;
            break;
         case SIGNAL_BLOCKED:
            signalText = "BLOCKED";
            signalColor = clrOrange;
            break;
         default:
            signalText = "IDLE";
            signalColor = clrGray;
      }

      string signalLabel = GetObjectName(state.Symbol + "_Signal");
      RenderLabel(signalLabel, x, y, signalText, signalColor, 9);

      // Column 3: Open Trades
      x += 100;
      string tradesLabel = GetObjectName(state.Symbol + "_Trades");
      string tradesText = StringFormat("Trades: %d", state.OpenTrades);
      RenderLabel(tradesLabel, x, y, tradesText, clrWhite, 8);

      // Column 4: Exposure (from active grid levels)
      x += 120;
      string exposureLabel = GetObjectName(state.Symbol + "_Exposure");
      string exposureText = StringFormat("Grid: %d", state.ActiveGridLevels);
      RenderLabel(exposureLabel, x, y, exposureText, clrWhite, 8);

      // Column 5: Drawdown %
      x += 100;
      string ddLabel = GetObjectName(state.Symbol + "_DD");
      string ddText = StringFormat("DD: %.2f%%", state.DrawdownPercent);
      color ddColor = (state.DrawdownPercent > 5.0) ? clrRed : clrWhite;
      RenderLabel(ddLabel, x, y, ddText, ddColor, 8);

      // Column 6: Correlation Block Status
      x += 120;
      string corrLabel = GetObjectName(state.Symbol + "_Corr");
      string corrText = state.CorrelationBlocked ? "[CORR-BLOCK]" : "";
      color corrColor = clrOrange;
      RenderLabel(corrLabel, x, y, corrText, corrColor, 8);

      // Column 7: Last Action Time
      x += 120;
      string timeLabel = GetObjectName(state.Symbol + "_Time");
      string timeText = "";
      if(state.LastSignalTime > 0)
      {
         MqlDateTime dt;
         TimeToStruct(state.LastSignalTime, dt);
         timeText = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
      }
      RenderLabel(timeLabel, x, y, timeText, clrGray, 8);

      m_lastUpdate = now;
   }

   //+------------------------------------------------------------------+
   //| Render summary strip                                              |
   //+------------------------------------------------------------------+
   void RenderSummary(int totalSymbols, double totalExposure, double maxDrawdown, int blockedCount)
   {
      int y = 0;
      int x = 10;

      // Summary header
      string headerLabel = GetObjectName("Summary_Header");
      RenderLabel(headerLabel, x, y, "fairPriceMP Multi-Symbol Dashboard", clrYellow, 10);

      // Summary data
      y += 20;
      x = 10;

      string summaryLabel = GetObjectName("Summary_Data");
      string summaryText = StringFormat("Symbols: %d | Max DD: %.2f%% | Blocked: %d",
                                       totalSymbols, maxDrawdown, blockedCount);
      color summaryColor = (blockedCount > 0) ? clrOrange : clrWhite;
      RenderLabel(summaryLabel, x, y, summaryText, summaryColor, 9);
   }
};
