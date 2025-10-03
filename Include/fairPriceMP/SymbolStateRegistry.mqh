//+------------------------------------------------------------------+
//|                                        SymbolStateRegistry.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

#include "DTO/SymbolConfigEntry.mqh"
#include "DTO/SymbolRuntimeState.mqh"

//+------------------------------------------------------------------+
//| Symbol State Registry                                             |
//| In-memory registry storing runtime state for all symbols         |
//| Provides consistent snapshots to all modules                      |
//+------------------------------------------------------------------+
class SymbolStateRegistry
{
private:
   SymbolRuntimeState m_states[];
   int                m_stateCount;

   //+------------------------------------------------------------------+
   //| Find index of symbol in registry                                 |
   //+------------------------------------------------------------------+
   int FindSymbolIndex(string symbol)
   {
      for(int i = 0; i < m_stateCount; i++)
      {
         if(m_states[i].Symbol == symbol)
            return i;
      }
      return -1;
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                       |
   //+------------------------------------------------------------------+
   SymbolStateRegistry()
   {
      m_stateCount = 0;
      ArrayResize(m_states, 0);
   }

   //+------------------------------------------------------------------+
   //| Initialize registry from configuration                            |
   //+------------------------------------------------------------------+
   bool InitFromConfig(const SymbolConfigEntry &configs[])
   {
      int count = ArraySize(configs);
      ArrayResize(m_states, count);
      m_stateCount = 0;

      for(int i = 0; i < count; i++)
      {
         if(!configs[i].Enabled)
            continue;

         SymbolRuntimeState state;
         state.InitFromConfig(configs[i]);
         m_states[m_stateCount++] = state;
      }

      return m_stateCount > 0;
   }

   //+------------------------------------------------------------------+
   //| Get runtime state for a symbol (by reference)                    |
   //+------------------------------------------------------------------+
   bool GetState(string symbol, SymbolRuntimeState &state)
   {
      int idx = FindSymbolIndex(symbol);
      if(idx < 0)
         return false;

      state = m_states[idx];
      return true;
   }

   //+------------------------------------------------------------------+
   //| Update runtime state for a symbol                                 |
   //+------------------------------------------------------------------+
   bool UpdateState(const SymbolRuntimeState &state)
   {
      int idx = FindSymbolIndex(state.Symbol);
      if(idx < 0)
         return false;

      m_states[idx] = state;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Mark symbol as ready (market data subscribed)                     |
   //+------------------------------------------------------------------+
   bool MarkReady(string symbol)
   {
      int idx = FindSymbolIndex(symbol);
      if(idx < 0)
         return false;

      m_states[idx].IsReady = true;
      return true;
   }

   //+------------------------------------------------------------------+
   //| Get all states (snapshot for modules)                             |
   //+------------------------------------------------------------------+
   void GetAllStates(SymbolRuntimeState &dest[])
   {
      ArrayResize(dest, m_stateCount);
      for(int i = 0; i < m_stateCount; i++)
         dest[i] = m_states[i];
   }

   //+------------------------------------------------------------------+
   //| Get count of registered symbols                                   |
   //+------------------------------------------------------------------+
   int GetCount() const { return m_stateCount; }

   //+------------------------------------------------------------------+
   //| Check if symbol is registered                                     |
   //+------------------------------------------------------------------+
   bool IsRegistered(string symbol)
   {
      return FindSymbolIndex(symbol) >= 0;
   }

   //+------------------------------------------------------------------+
   //| Get symbol at index (for iteration)                               |
   //+------------------------------------------------------------------+
   bool GetStateAt(int index, SymbolRuntimeState &state)
   {
      if(index < 0 || index >= m_stateCount)
         return false;

      state = m_states[index];
      return true;
   }
};
