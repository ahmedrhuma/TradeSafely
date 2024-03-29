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
   if(reason!=REASON_CHARTCHANGE){
      Trades.Shutdown();
      delete Trades;
      Controlled.Shutdown();
      delete Controlled;
      Panel.Destroy(reason);
      _DONT=false;
      ObjectDelete(0, "AHMEDR_VIS_ST");
      ObjectDelete(0, "AHMEDR_VIS_AC");
   }
   else _DONT=true;
  }
void ReloadPanel(void){
   CreateLines();
   Panel.OnClickBack();
}

void CreateLines(void){
   ObjectCreate(ChartID(), "AHMEDR_VIS_ST", OBJ_HLINE, 0, TimeCurrent(), Bid);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_COLOR, C'255,83,83');
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_SELECTED, true);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_HIDDEN, true);
   ObjectSetString(ChartID(), "AHMEDR_VIS_ST", OBJPROP_TEXT, "Move Stop to");
   ObjectSetString(ChartID(), "AHMEDR_VIS_ST", OBJPROP_TOOLTIP, "Move Stop to");
   
   ObjectCreate(ChartID(), "AHMEDR_VIS_AC", OBJ_HLINE, 0, TimeCurrent(), Ask);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_SELECTED, true);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_HIDDEN, true);
   ObjectSetString(ChartID(), "AHMEDR_VIS_AC", OBJPROP_TEXT, "When Price");
   ObjectSetString(ChartID(), "AHMEDR_VIS_AC", OBJPROP_TOOLTIP, "When Price");
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
   if(_ENABLED && (id==CHARTEVENT_OBJECT_DRAG||id==CHARTEVENT_OBJECT_CHANGE||id==CHARTEVENT_OBJECT_ENDEDIT)) Panel.DoMoves(sparam);
  }
//+------------------------------------------------------------------+
