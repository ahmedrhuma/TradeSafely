#include <Object.mqh>
class TradeManager : public CObject{
   public:
   long ticket;
   double condition_1, action_1, condition_2, action_2, condition_3, action_3;
   bool is_1, is_2, is_3;
   bool valid_1, valid_2, valid_3;
   bool _DESTROY;
   bool _notify;
   bool _IS_BUY;
   bool _HAS_ERROR;
   int _counter, _CURRENT;
   
   TradeManager(long t){
      this.ticket=t;
      this.is_1=false;
      this.is_2=false;
      this.is_3=false;
      this.valid_1=false;
      this.valid_2=false;
      this.valid_3=false;
      this._DESTROY=false;
      this._notify=false;
      this._HAS_ERROR=false;
      this._counter=0;
      this._CURRENT=0;
      this.ReloadRates();
      if(OrderSelect((int)t, SELECT_BY_TICKET)){
         this._IS_BUY=OrderType()==OP_BUY||OrderType()==OP_BUYLIMIT||OrderType()==OP_BUYSTOP;
      }
   }
   ~TradeManager(){
      int ix=Controlled.SearchLinear(this.ticket);
      if(ix>=0) Controlled.Delete(ix);
   }
   
   void FillEntries(){
      if(this.valid_1) Panel.action_1.Text(DoubleToString(this.condition_1, Digits));
      else Panel.action_1.Text("");
      if(this.valid_2) Panel.action_2.Text(DoubleToString(this.condition_2, Digits));
      else Panel.action_2.Text("");
      if(this.valid_3) Panel.action_3.Text(DoubleToString(this.condition_3, Digits));
      else Panel.action_3.Text("");
      
      if(this.valid_1) Panel.move1.Text(DoubleToString(this.action_1, Digits));
      else Panel.move1.Text("");
      
      if(this.valid_2) Panel.move2.Text(DoubleToString(this.action_2, Digits));
      else Panel.move2.Text("");
      if(this.valid_3) Panel.move3.Text(DoubleToString(this.action_3, Digits));
      else Panel.move3.Text("");
      
      if(this.is_1){
         Panel.SetReadOnly(Panel.action_1, true);
         Panel.SetReadOnly(Panel.move1, true);
      }
      else if(this.is_2){
         Panel.SetReadOnly(Panel.action_2, true);
         Panel.SetReadOnly(Panel.move2, true);
      }
      else if(this.is_3){
         Panel.SetReadOnly(Panel.action_3, true);
         Panel.SetReadOnly(Panel.move3, true);
      }
      Panel.notify_me.Checked(this._notify);
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
               if(ix>=0) Controlled.Update(ix, this.ticket);
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
      if(!this.is_1) {
         this.condition_1=(double)Panel.action_1.Text();
         this.action_1=(double)Panel.move1.Text();
      }
      if(!this.is_2) {
         this.condition_2=(double)Panel.action_2.Text();
         this.action_2=(double)Panel.move2.Text();
      }
      if(!this.is_3) {
         this.condition_3=(double)Panel.action_3.Text();
         this.action_3=(double)Panel.move3.Text();
      }
      
      this.SelectTrade();
      this._IS_BUY=OrderType()==OP_BUY||OrderType()==OP_BUYLIMIT||OrderType()==OP_BUYSTOP;

      this._notify = Panel.notify_me.Checked();
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
      }
      if(this.condition_3>0 && this.action_3>0) {
         if(this._IS_BUY){
            if(this.condition_3<this.action_3){
               MessageBox("يجب أن يكون الشرط أعلى من الوقف، في الشرط الثالث.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
            }
            else {
               this.valid_3=true;
               this._counter++;  
            }
         }
         else {
            if(this.condition_3>this.action_3){
               MessageBox("يجب أن يكون الشرط أدنى من الوقف، في الشرط الثالث.", "خطـأ في الإعداد");
               this._HAS_ERROR=true;
            }
            else {
               this.valid_3=true;
               this._counter++;
            }
         }
      }
      
      if(!this.valid_1&&!this.valid_2&&!this.valid_3) this._DESTROY=true;
   }
   
   bool HasError(){
      return(this._HAS_ERROR);
   }
   
   void Handle(){
      if(this._DESTROY) return;
      if(!this.SelectTrade()) return;
      if(OrderType()==OP_BUY||OrderType()==OP_SELL){
         if(this.valid_1 && !this.is_1){
            if(this.PriceCrossed(this.condition_1)) {
               if(this.MoveStop(this.action_1)){
                  this._CURRENT++;
                  this.is_1=true;
                  if(this._CURRENT==this._counter) this._DESTROY=true; 
               }
               return;
            }
         }
         else if(this.valid_2 && !this.is_2){
            if(this.PriceCrossed(this.condition_2)) {
               if(this.MoveStop(this.action_2)){
                  this._CURRENT++;
                  this.is_2=true;
                  if(this._CURRENT==this._counter) this._DESTROY=true;
               }
               return;
            }
         }
         else if(this.valid_3 && !this.is_3){
            if(this.PriceCrossed(this.condition_3)) {
               if(this.MoveStop(this.action_3)){
                   this._CURRENT++;
                    this.is_3=true;
                  if(this._CURRENT==this._counter) this._DESTROY=true;
               }
               return;
            }
         }
      }
   }
   
   bool MoveStop(double price){
      int safe_stopper=5;
      bool result=OrderModify((int)this.ticket, OrderOpenPrice(), price, OrderTakeProfit(), 0);
      while(!result && safe_stopper>0){ result=OrderModify((int)this.ticket, OrderOpenPrice(), price, OrderTakeProfit(), 0); }
      this.SelectTrade();
      if(this._notify){
         if(result) SendNotification("تم نقـل السـتوب للصفـقة "+OrderSymbol()+" / #"+(string)this.ticket+" - تم بلوغ النقطة رقم "+(string)(this._CURRENT+1));
         else SendNotification("لم نتمكن من نقل الستوب للصـفقة "+OrderSymbol()+" / #"+(string)this.ticket+" - يرجى مراجعة الشارت فورا.");
      }
      return(result);
   }
   
   bool PriceCrossed(double pr){
      double price = this._IS_BUY?Bid:Ask;
      if(this._IS_BUY){
         if(Bid>=pr || iHigh(NULL, PERIOD_M1, 0)>=pr) return(true);
         return(false);
      }
      else {
         if(Ask<=pr || iLow(NULL, PERIOD_M1, 0)<=pr) return(true);
         return(false);
      }
   }
}