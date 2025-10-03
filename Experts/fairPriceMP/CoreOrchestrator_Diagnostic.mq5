//+------------------------------------------------------------------+
//|                               CoreOrchestrator_Diagnostic.mq5    |
//|                                     Diagnostic version            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("DIAGNOSTIC: OnInit() started");
   Print("DIAGNOSTIC: Test successful - EA is loading");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("DIAGNOSTIC: OnDeinit() called");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Nothing
}
