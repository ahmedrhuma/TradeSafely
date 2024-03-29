#include <Object.mqh>
class TradeManager : public CObject{
   public:
   long ticket, _reversed_ticket;
   bool price_mode;
   double condition_1, action_1, condition_2, action_2, condition_3, action_3, close_1, close_2, close_3;
   bool is_1, is_2;
   bool valid_1, valid_2, valid_3;
   // used in rrr mode
   double _stop_diff, _next_target, _move_to_rrr, _original_stop;
   int _move_stop_counter;
   bool _not_first;
   // end used in rrr mode
   bool _DESTROY;
   bool _notify;
   bool _IS_BUY;
   bool _HAS_ERROR;
   int _counter, _CURRENT;
   double _open_price;
   bool _remove_reversed, _reversed_deleted;
   
   TradeManager(long t){
      this.ticket=t;
      this._not_first=false;
      this.price_mode=true;
      this.is_1=false;
      this.is_2=false;
      this.valid_1=false;
      this.valid_2=false;
      this.valid_3=false;
      this._DESTROY=false;
      this._notify=false;
      this._HAS_ERROR=false;
      this._reversed_ticket=NULL;
      this._remove_reversed=false;
      this._reversed_deleted=false;
      this._counter=0;
      this._CURRENT=0;
      this._move_stop_counter=1;
      this.ReloadRates();
      if(OrderSelect((int)t, SELECT_BY_TICKET)){
         this._IS_BUY=OrderType()==OP_BUY||OrderType()==OP_BUYLIMIT||OrderType()==OP_BUYSTOP;
      }
   }
   ~TradeManager(){
      int ix=Controlled.SearchLinear(this.ticket);
      if(ix>=0) Controlled.Delete(ix);
   }
   
   void UnsetRemoveOrder(){
      this._remove_reversed=false;
      this._reversed_ticket=NULL;
   }
   
   void SetRemoveOrder(long t){
      this._remove_reversed=true;
      this._reversed_ticket=t;
   }
   
   void FillEntries(){
      if(this.valid_1) {
         Panel.action_1.Text(DoubleToString(this.condition_1, Digits));
         Panel.move1.Text(DoubleToString(this.action_1, Digits));
         Panel.close_percentage1.Text(DoubleToString(this.close_1, 2));
      }
      else {
         Panel.action_1.Text("");
         Panel.move1.Text("");  
         Panel.close_percentage1.Text("");
      }
      
      if(this.valid_2){
         Panel.action_2.Text(DoubleToString(this.condition_2, Digits));
         Panel.move2.Text(DoubleToString(this.action_2, Digits));
         Panel.close_percentage2.Text(DoubleToString(this.close_2, 2));
      }
      else {
         Panel.action_2.Text("");
         Panel.move2.Text("");
         Panel.close_percentage2.Text("");
      }
      
      if(this.valid_3){
         Panel.sparator_3_text.Text("Move By Risk to Reward Ratio ("+DoubleToString(Panel.PointToPips(this._stop_diff),1)+") Pips");
         Panel.action_3.Text(DoubleToString(this.condition_3, 1));
         Panel.move3.Text(DoubleToString(this.action_3, 1));
         Panel.dont_close_first.Checked(this._not_first);
         Panel.close_percentage3.Text(DoubleToString(this.close_3, 2));
      }
      else {
         Panel.action_3.Text("");
         Panel.move3.Text("");
         Panel.close_percentage3.Text("");
         Panel.dont_close_first.Checked(false);
      }
      
      if(this.is_1){
         Panel.SetReadOnly(Panel.action_1, true);
         Panel.SetReadOnly(Panel.move1, true);
         Panel.SetReadOnly(Panel.close_percentage1, true);
      }
      if(this.is_2){
         Panel.SetReadOnly(Panel.action_2, true);
         Panel.SetReadOnly(Panel.move2, true);
         Panel.SetReadOnly(Panel.close_percentage2, true);
      }
      
      Panel.notify_me.Checked(this._notify);
      
      Panel.remove_reversed.Checked(this._remove_reversed);
      Panel.combo_box.SelectByValue(this._reversed_ticket);
   }
   
   bool IsTicketFound(long t){
      if(!OrderSelect((int)this.ticket, SELECT_BY_TICKET)){
         // try to find the new ticket
         if(this.TryReloadTicket()) return(this.ticket==t);
         return(false);
      }
      return(this.ticket==t);
   }
   
   bool TryReloadTicket(){
      for(int i=0; i<OrdersTotal();i++){
         if(OrderSelect(i, SELECT_BY_POS)){
            if(StringFind(OrderComment(), (string)this.ticket)>-1){
               int ix=Controlled.SearchFirst(this.ticket);
               this.ticket=OrderTicket();
               if(ix>=0) {
                  Controlled.Update(ix, this.ticket);
                  Controlled.Sort();
               }
               return(true);
            }
         }
      }
      this._DESTROY=true;
      return(false);
   }
   
   bool SelectTrade(){
      if(OrderSelect((int)this.ticket, SELECT_BY_TICKET)) return(true);
      return(this.TryReloadTicket());
   }
   
   void ReloadRates(){
      this._HAS_ERROR=false;
      this.valid_1=false;
      this.valid_2=false;
      this.valid_3=false;
      this._not_first=false;
      this.price_mode=true;
      this._counter=0;
      
      if(!this.SelectTrade()) return;
      
      if(!this.is_1) {
         this.condition_1=StringToDouble(Panel.action_1.Text());
         this.action_1=StringToDouble(Panel.move1.Text());
         this.close_1=StringToDouble(Panel.close_percentage1.Text());
      }
      if(!this.is_2) {
         this.condition_2=StringToDouble(Panel.action_2.Text());
         this.action_2=StringToDouble(Panel.move2.Text());
         this.close_2=StringToDouble(Panel.close_percentage2.Text());
      }
      this.condition_3=StringToDouble(Panel.action_3.Text());
      this.action_3=StringToDouble(Panel.move3.Text());
      this.close_3=StringToDouble(Panel.close_percentage3.Text());
      this._not_first=Panel.dont_close_first.Checked();
      this._IS_BUY=OrderType()==OP_BUY||OrderType()==OP_BUYLIMIT||OrderType()==OP_BUYSTOP;

      this._notify = Panel.notify_me.Checked();
      this._remove_reversed=Panel.remove_reversed.Checked();
      if(this._remove_reversed) this._reversed_ticket=Panel.combo_box.Value();
      else this._reversed_ticket=NULL;
      this.CheckValidation();
   }
   
   void CheckValidation(){
      if(this.condition_1>0 && this.action_1>0) {
         if(this._IS_BUY){
            if(this.condition_1<this.action_1){
               MessageBox("يجب أن يكون الشرط أعلى من الوقف، في الشرط الأول.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
            }
            else {
               this.valid_1=true;
               this._counter++;  
            }
         }
         else {
            if(this.condition_1>this.action_1){
               MessageBox("يجب أن يكون الشرط أدنى من الوقف، في الشرط الأول.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
            }
            else {
               this.valid_1=true;
               this._counter++;
            }
         }
         
         if(this.valid_1){
            if(this.close_1<0||this.close_1>=100){
               MessageBox("الإغلاق بالنسبة المئوية يجب أن يكون أعلى من الصفر وأقل من أو يساوي 100 في الشرط الأول.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
               this.valid_1=false;
               this._counter--;
            }
         }
      }
      if(this.condition_2>0 && this.action_2>0){
         if(this._IS_BUY){
            if(this.condition_2<this.action_2){
               MessageBox("يجب أن يكون الشرط أعلى من الوقف، في الشرط الثاني.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
            }
            else {
               this.valid_2=true;
               this._counter++;  
            }
         }
         else {
            if(this.condition_2>this.action_2){
               MessageBox("يجب أن يكون الشرط أدنى من الوقف، في الشرط الثاني.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
            }
            else {
               this.valid_2=true;
               this._counter++;
            }
         }
         
         if(this.valid_2){
            if(this.close_2<0||this.close_2>=100){
               MessageBox("الإغلاق بالنسبة المئوية يجب أن يكون أعلى من الصفر وأقل من أو يساوي 100 في الشرط الثاني.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
               this.valid_2=false;
               this._counter--;
            }
            if(this.close_1==100){
               MessageBox("منطقيا لن يتحقق الشرط الثاني لأنه سيتم إغلاق كامل الصفقة في الشرط الأول.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
               this.valid_2=false;
               this._counter--;
            }
         }
      }
      if(this.condition_3>0 && this.action_3>0) {
         if(this.action_3>this.condition_3){
            MessageBox("يجب أن لا يكون معدل الحركة أسرع من الشرط.", "خطـأ في الإعداد");
            this._HAS_ERROR=true;
         } else this.valid_3=true;
         
         if(this.valid_3){
            if(this.close_3<0||this.close_3>=100){
               MessageBox("الإغلاق بالنسبة المئوية يجب أن يكون أعلى من الصفر وأقل من أو يساوي 100 في الشرط الثالث.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
               this.valid_3=false;
               this._counter--;
            }
            else if(this.close_1==100 || this.close_2==100){
               MessageBox("منطقيا لن يتحقق الشرط الثالث لأنه سيتم إغلاق كامل الصفقة في الشرط الثاني.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
               this.valid_3=false;
               this._counter--;
            }
         }
      }
      
      if((this.valid_1||this.valid_2)&&this.valid_3){
         MessageBox("لا يمكن تشغيل الوضعين، يجب إما تشغيل وضع التحريك بالأسعار أو بالمضاعفات.", "خطأ في الإعداد");
         this._HAS_ERROR=true;
         return;
      }
      
      if(this.valid_3){ 
         this.price_mode=false;
         if(this._move_stop_counter==1){
            this._original_stop=OrderStopLoss();
            this._stop_diff=MathAbs(OrderStopLoss()-OrderOpenPrice());
            this._next_target=OrderOpenPrice();
            if(this._IS_BUY){
               this._move_to_rrr=this._original_stop+(this._stop_diff*this.action_3*this._move_stop_counter);
               this._next_target+=this._stop_diff*this.condition_3*this._move_stop_counter;
            }
            else {
               this._move_to_rrr=this._original_stop-(this._stop_diff*this.action_3*this._move_stop_counter);
               this._next_target-=this._stop_diff*this.condition_3*this._move_stop_counter;
            }
         }
      }
      else {
         this._move_stop_counter=1;
      }
      this._open_price=OrderOpenPrice();
      if(this.valid_1&&this.is_1&&!this.valid_2&&!this.valid_3) this._DESTROY=true;
      if(this.valid_2&&this.is_2&&!this.valid_1&&!this.valid_3) this._DESTROY=true;
      if(!this.valid_1&&!this.valid_2&&!this.valid_3) this._DESTROY=true;
   }
   
   bool HasError(){
      return(this._HAS_ERROR);
   }
   
   void Handle(){
      if(this._DESTROY) return;
      if(!this.SelectTrade()) return;
      // run only active trades
      if(OrderType()==OP_BUY||OrderType()==OP_SELL){
         if(this.price_mode){
            if(this.valid_1 && !this.is_1){
               if(this.PriceCrossed(this.condition_1)) {
                  this.MoveStop(this.action_1, this.close_1);
                  this._CURRENT++;
                  this.is_1=true; 
                  if(this._CURRENT==this._counter) this._DESTROY=true;
                  return;
               }
            }
            else if(this.valid_2 && !this.is_2){
               if(this.PriceCrossed(this.condition_2)) {
                  this.MoveStop(this.action_2, this.close_2);
                  this._CURRENT++;
                  this.is_2=true;
                  if(this._CURRENT==this._counter) this._DESTROY=true;
                  return;
               }
            }
         }
         else {
            if(this.valid_3){
               if(this.PriceCrossed(this._next_target)) {
                  this.MoveStop(this._move_to_rrr, this.close_3);
                  this._move_stop_counter++;
                  if(this._IS_BUY){
                     this._next_target+=this._stop_diff*this.condition_3;
                     this._move_to_rrr+=this._stop_diff*this.action_3;
                  }
                  else {
                     this._next_target-=this._stop_diff*this.condition_3;
                     this._move_to_rrr-=this._stop_diff*this.action_3;
                  }
                  return;
               }
            }
         }
      }
   }
   
   bool MoveStop(double price, double cls){
      int safe_stopper=5;
      bool result=OrderModify((int)this.ticket, OrderOpenPrice(), price, OrderTakeProfit(), 0);
      while(!result && safe_stopper>0){
         result=OrderModify((int)this.ticket, OrderOpenPrice(), price, OrderTakeProfit(), 0);
         safe_stopper--;
      }
      this.SelectTrade();
      if(this._notify){
         if(this.valid_3){
            if(result) {
               if(this._move_stop_counter==1)SendNotification("تم نقـل السـتوب للصفـقة "+OrderSymbol()+" / #"+(string)this.ticket+" - تم تحريك الستوب إلى الدخول");
               else SendNotification("تم نقـل السـتوب للصفـقة "+OrderSymbol()+" / #"+(string)this.ticket+" - تم بلوغ النقطة رقم "+(string)((this._move_stop_counter-1)*this.action_3)+"R");
            }
            else SendNotification("لم نتمكن من نقل الستوب للصـفقة "+OrderSymbol()+"-"+EnumToString((ENUM_TIMEFRAMES)Period())+" / #"+(string)this.ticket+" - يرجى مراجعة الشارت فورا.");      
         }
         else {
            if(result) SendNotification("تم نقـل السـتوب للصفـقة "+OrderSymbol()+" / #"+(string)this.ticket+" - تم بلوغ النقطة رقم "+(string)(this._CURRENT+1));
            else SendNotification("لم نتمكن من نقل الستوب للصـفقة "+OrderSymbol()+"-"+EnumToString((ENUM_TIMEFRAMES)Period())+" / #"+(string)this.ticket+" - يرجى مراجعة الشارت فورا.");
         }
      }
      if(!(this.valid_3&&this._not_first&&_move_stop_counter==1)) this.ClosePart(cls);
      
      if(!this._reversed_deleted&&this._remove_reversed){
         if(OrderDelete((int)this._reversed_ticket)) {
            this._reversed_deleted=true;
            if(this._notify) SendNotification("تم إلغاء الأمر العكسي  رقم #"+(string)this._reversed_ticket+" / "+Symbol()+" بنجاح!");
         }
         else {
            if(this._notify) SendNotification("لم نتمكن من إلغاء الأمر العكسي برقم #"+(string)this._reversed_ticket+" / "+Symbol());
         }
      }
      
      return(result);
   }
   
   void ClosePart(double percentage){
      if(percentage==0) return;
      double price = this._IS_BUY?Bid:Ask;
      int safe_stopper=5;
      double minlot=MarketInfo(Symbol(), MODE_MINLOT);
      if(OrderLots()==minlot) return;
      double lotsetp=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
      int digits=(lotsetp/0.01)==1?2:(lotsetp/0.1)==1?1:(lotsetp/0.001)==1?3:2;
      double closable=NormalizeDouble(OrderLots()*percentage/100,digits);
      if(OrderLots()-closable<minlot) return;
      bool result=OrderClose((int)this.ticket, closable, price,3);
      while(!result && safe_stopper>0){
         result=OrderClose((int)this.ticket, closable, price,3);
         safe_stopper--;
      }
      this.SelectTrade();
      if(this._notify){
         if(result) SendNotification("تم إغلاق ("+(string)closable+") من "+OrderSymbol()+" / #"+(string)this.ticket+" - ما يوازي ("+(string)percentage+"%)");
         else SendNotification("لم نتمكن من إغلاق جزء من الصفقة "+"("+(string)closable+")"+OrderSymbol()+"-"+EnumToString((ENUM_TIMEFRAMES)Period())+" / #"+(string)this.ticket+" - يرجى مراجعة الشارت فورا.");
      }
      if(percentage==100) this._DESTROY=true;
   }
   
   bool PriceCrossed(double pr){
      double price = Bid;
      if(this._IS_BUY){
         if(Bid>=pr || iHigh(NULL, PERIOD_M1, 0)>=pr) return(true);
         return(false);
      }
      else {
         if(Bid<=pr || iLow(NULL, PERIOD_M1, 0)<=pr) return(true);
         return(false);
      }
   }
}