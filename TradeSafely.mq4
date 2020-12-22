//+------------------------------------------------------------------+
//|                                                  TradeSafely.mq4 |
//|                                                       AhmedRhuma |
//|                                            https://www.rhuma.net |
//+------------------------------------------------------------------+
#include "Global.mqh";
#include "TradeManager.mqh";
#include "Panel.mqh";
#include <Arrays\ArrayLong.mqh>
#include <Arrays\ArrayObj.mqh>
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TSPanel Panel;
CArrayObj *Trades=new CArrayObj();
CArrayLong* Controlled=new CArrayLong();
bool _DONT=false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!IsTradeAllowed()){
      MessageBox("يجب السماح للإكسبرت بالتداول من إعدادات الميتا تريدر حتى يعمل هذا الإكسبرت.", "خطــأ!",0);
      return(INIT_FAILED);
   }
   if(!_DONT) if(!Panel.Create(0, "Trade Safely - SCCMW/AR", 0, 100, 100, WINDOW_WIDTH+100,WINDOW_HEIGHT+100)) return(INIT_FAILED);
   Panel.Run();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(reason!=REASON_CHARTCHANGE) {
      Trades.Shutdown();
      delete Trades;
      Controlled.Shutdown();
      delete Controlled;
      Panel.Destroy(reason);
   }
   else _DONT=true;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Panel.LoadTrades();
   if(_ENABLED&&CheckPointer(Trades)!=POINTER_INVALID) for(int i=0;i<Trades.Total();i++) ((TradeManager*)Trades.At(i)).Handle();
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   Panel.ChartEvent(id, lparam, dparam, sparam);
   if(_ENABLED && (id==CHARTEVENT_OBJECT_DRAG||id==CHARTEVENT_OBJECT_CHANGE)) Panel.DoMoves(sparam);
  }
//+------------------------------------------------------------------+
