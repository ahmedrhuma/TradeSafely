#include "Classes\Dialog.mqh";
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include "Classes\List.mqh";
#include <Controls\WndClient.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Picture.mqh>
#include "Classes\ComboBox.mqh";
#include "Classes\CheckBox.mqh";
#resource "separator.bmp";
#resource "footer.bmp";

class TSPanel : public CAppDialog {
   public:
   double				m_DPIScale;
   CButton button_apply;
   CButton toggle_button;
   CButton hide_reversed;
   CLabel  intro_label;
   CListView trades_list;
   CComboBox combo_box;
   CWndClient controls_tab;
   CWndClient reverse_tab;
   CButton return_to_tab;
   CButton show_all;
   CButton show_controlled;
   CButton show_uncontrolled;
   CLabel entry_when;
   CLabel entry_move_to;
   CEdit action_1, move1;
   CPicture sparator_1;
   CLabel entry_when2;
   CLabel sparator_3_text;
   CLabel entry_move_to2;
   CEdit action_2, move2;
   CPicture sparator_2;
   CLabel entry_when3;
   CLabel entry_move_to3;
   CLabel entry_close_to;
   CLabel entry_close_to2;
   CLabel entry_close_to3;
   CEdit close_percentage1;
   CEdit close_percentage2;
   CEdit close_percentage3;
   CEdit action_3, move3;
   CPicture sparator_3;
   CCheckBox notify_me;
   CCheckBox remove_reversed;
   CPicture footer;
   CCheckBox visual_1;
   CCheckBox visual_2;
   CCheckBox dont_close_first;
   int _show_mode;
   string old_mname;
   public:
      bool              Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
      //--- chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
      void              ChangeColors();
      bool              CreateButton(CButton &btn, string name, string txt, int x1, int y1, bool toggle = true);
      bool              CreateLabel(CLabel &lbl, string name, string txt, int x1, int y1);
      bool CreateButtonClose(void){ return(true); };
      bool              CreateToggleButton(void);
      bool              CreateEdit(CEdit &edt, string name, int x1, int y1, string defaultValue);
      bool              CreateListView(void);
      bool OnResize(void){
         controls_tab.Visible(false);
         reverse_tab.Visible(false);
         RemoveLines();
         return(CAppDialog::OnResize());
      };
      bool              Chain(void);
      string GetOrderType(int o);
      void Destroy(const int reason);
      
      void LoadTrades(void);
      double PointToPips(double d);
      bool CreateControlTab(void);
      void ToggleButtonColor(CButton &btn, bool toggle = true);
      bool CreateTab(CWndClient &wnd, string name, bool visible);
      void SetReadOnly(CEdit &edt, bool flag);
      
      // events
      void RemoveLines(void);
      void MakeLines(void);
      void OnClickToggle(void);
      void OnChangeListView(void);
      void OnClickBack(void);
      void OnClickApply(void);
      void OnClickShowControlled(void);
      void OnClickShowUncontrolled(void);
      void OnClickShowAll(void);
      void DoMoves(string sparam);
      void VisibleMove1(void);
      void VisibleMove2(void);
      void ChangeRemoveReversed(void);
      void HideReversed(){ reverse_tab.Visible(false); }
};

EVENT_MAP_BEGIN(TSPanel)
ON_EVENT(ON_CLICK, hide_reversed, HideReversed)
ON_EVENT(ON_CHANGE, remove_reversed, ChangeRemoveReversed)
ON_EVENT(ON_CHANGE, visual_1, VisibleMove1)
ON_EVENT(ON_CHANGE, visual_2, VisibleMove2)
ON_EVENT(ON_CLICK, show_controlled, OnClickShowControlled)
ON_EVENT(ON_CLICK, show_uncontrolled, OnClickShowUncontrolled)
ON_EVENT(ON_CLICK, show_all, OnClickShowAll)
ON_EVENT(ON_CLICK, button_apply, OnClickApply)
ON_EVENT(ON_CLICK, return_to_tab, OnClickBack)
ON_EVENT(ON_CLICK, toggle_button, OnClickToggle)
ON_EVENT(ON_CHANGE,trades_list,OnChangeListView)
EVENT_MAP_END(CAppDialog)

void TSPanel::Destroy(const int reason){
   int total=controls_tab.ControlsTotal();
   for(int i=0;i<total;i++){
      CWnd *control=controls_tab.Control(0);
      if(control==NULL) continue;
      control.Destroy();
      controls_tab.Delete(control);
   }
   
   total=reverse_tab.ControlsTotal();
   for(int i=0;i<total;i++){
      CWnd *control=reverse_tab.Control(0);
      if(control==NULL) continue;
      control.Destroy();
      reverse_tab.Delete(control);
   }
   reverse_tab.Destroy();
   controls_tab.Destroy();
   //delete controls_tab
   CAppDialog::Destroy(reason);
   ObjectsDeleteAll(0, EXPERT_NAME, 0);
   ObjectsDeleteAll(0, old_mname, 0);
}

bool TSPanel::CreateTab(CWndClient &wnd, string name, bool visible){
   int off=(m_panel_flag) ? 0:2*CONTROLS_BORDER_WIDTH;
//--- coordinates
   int x1=off+CONTROLS_DIALOG_CLIENT_OFF;
   int y1=off+CONTROLS_DIALOG_CAPTION_HEIGHT;
   int x2=Width()-(off+CONTROLS_DIALOG_CLIENT_OFF);
   int y2=Height()-(off+CONTROLS_DIALOG_CLIENT_OFF);
   if(!wnd.Create(m_chart_id,m_name+name,m_subwin,x1,y1,x2,y2))
      return(false);
   if(!wnd.ColorBackground(C'52,52,52'))
      return(false);
   if(!wnd.ColorBorder(C'45,45,45'))
      return(false);
   wnd.Visible(visible);

   if(!CWndContainer::Add(wnd)) return(false);
   return(true);
}

bool TSPanel::Create(const long chart,const string name,const int subwin,const int x1,const int y1,int x2,int y2)
   {
      ObjectDelete(0, "AHMEDR_VIS_ST");
      ObjectDelete(0, "AHMEDR_VIS_AC");
      double screen_dpi = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
	   m_DPIScale = screen_dpi / 96.0;
	   x2 = (int)MathRound(x2 * m_DPIScale);
	   y2 = (int)MathRound(y2 * m_DPIScale);
	   
	   BUTTON_WIDTH=(int)MathRound(BUTTON_WIDTH*m_DPIScale);
      BUTTON_HEIGHT=(int)MathRound(BUTTON_HEIGHT*m_DPIScale);
      INDENT_LEFT=(int)MathRound(INDENT_LEFT*m_DPIScale);
      INDENT_TOP=(int)MathRound(INDENT_TOP*m_DPIScale);
      BUTTON_FONT_SIZE=(int)MathRound(BUTTON_FONT_SIZE*m_DPIScale);
      TEXT_WIDTH=(int)MathRound(TEXT_WIDTH*m_DPIScale);
      CONTROLS_GAP_X=(int)MathRound(CONTROLS_GAP_X*m_DPIScale);
      CONTROLS_GAP_Y=(int)MathRound(CONTROLS_GAP_Y*m_DPIScale);
      EDIT_WIDTH=(int)MathRound(EDIT_WIDTH*m_DPIScale);
      
      CreateLines();
      	   
      bool result = CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2);
      old_mname=m_name;
      m_name=EXPERT_NAME;
      
      ChangeColors();
      this.RemoveLines();
      if(!Chain()) return(false);
      return(result);
   }

void TSPanel::ChangeColors(){
   m_background.ColorBackground(C'45,45,45');
   m_background.ColorBorder(C'45,45,45');
   m_background.Color(clrWhite);
   
   m_white_border.ColorBackground(clrBlack);
   m_white_border.ColorBorder(C'200,200,200');
   m_white_border.Color(clrYellow);
   
   m_client_area.ColorBackground(C'45,45,45');
   m_client_area.ColorBorder(C'45,45,45');
   
   m_caption.ColorBackground(C'24,24,24');
   m_caption.ColorBorder(C'24,24,24');
   m_caption.Color(C'200,200,200');
}

//--- button color changer
void TSPanel::ToggleButtonColor(CButton &btn, bool toggle = true){
   btn.ColorBackground(toggle ? C'26,85,192' : C'25,25,25');
   btn.Color(clrWhite);
   btn.ColorBorder(toggle ? C'21,76,174' : C'15,15,15');
}

bool TSPanel::CreateLabel(CLabel &lbl, string name, string txt, int x1, int y1){
   int x2=x1+TEXT_WIDTH;
   int y2=y1+BUTTON_HEIGHT;

   if(!lbl.Create(m_chart_id,m_name+"_CLABEL_"+name,m_subwin,x1,y1,x2,y2))
      return(false);
   if(!lbl.Text(txt))
      return(false);
   lbl.Color(C'197,197,197');
   lbl.FontSize(BUTTON_FONT_SIZE);
   return(true);
 }
 
void TSPanel::SetReadOnly(CEdit &edt, bool flag){
   edt.ReadOnly(flag);
   if(flag){
      edt.ColorBackground(C'45,45,45');
      edt.ColorBorder(C'30,30,30');
      edt.Color(C'255,255,255');
   }
   else {
      edt.ColorBackground(C'55,55,55');
      edt.ColorBorder(C'40,40,40');
      edt.Color(C'250,250,250');
   }
}

//--- edit 
bool TSPanel::CreateEdit(CEdit &edt, string name, int x1, int y1, string defaultValue){
   int x2=x1+EDIT_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   if(!edt.Create(m_chart_id,m_name+"_CEDIT_"+name,m_subwin,x1,y1,x2,y2))
      return(false);
   edt.Text(defaultValue);
   edt.ColorBackground(C'55,55,55');
   edt.ColorBorder(C'40,40,40');
   edt.Color(C'250,250,250');
   return(true);
}


bool TSPanel::CreateButton(CButton &btn, string name, string txt, int x1, int y1, bool toggle = true)  {
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   if(!btn.Create(m_chart_id,m_name+"_CBUTTON_"+name,m_subwin,x1,y1,x2,y2))
      return(false);
   if(!btn.Text(txt))
      return(false);
   if (!btn.ColorBackground(toggle ? C'26,85,192' : C'25,25,25'))
      return(false);
   if (!btn.Color(clrWhite))
      return(false);
   if (!btn.ColorBorder(toggle ? C'21,76,174' : C'15,15,15'))
      return(false);
   btn.FontSize(BUTTON_FONT_SIZE);
   return(true);
}

bool TSPanel::CreateToggleButton(void){
   if(!CreateButton(toggle_button, "_TOGGLE", "Disable", INDENT_LEFT, INDENT_TOP)) return(false);
   if(!toggle_button.Width(m_client_area.Width()-(INDENT_LEFT*2))) return(false);
   if(!Add(toggle_button)) return(false);
   
   
   int y=INDENT_TOP+BUTTON_HEIGHT+CONTROLS_GAP_Y;
   if(!CreateLabel(intro_label, "INTRO", "Select a position to secure:", INDENT_LEFT, y)) return(false);
   if(!intro_label.Width(m_client_area.Width()-INDENT_LEFT)) return(false);
   if(!Add(intro_label)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   _show_mode=3;
   
   int x=INDENT_LEFT;
   int btn_width=m_client_area.Width()-INDENT_LEFT-INDENT_LEFT-CONTROLS_GAP_X;
   btn_width/=2;
   if(!CreateButton(show_controlled, "_SHOW_CONTROLLED", "Controlled", x, y, false)) return(false);
   show_controlled.Width(btn_width);   
   if(!Add(show_controlled)) return(false);
   
   x+=CONTROLS_GAP_X+btn_width;
   if(!CreateButton(show_uncontrolled, "_SHOW_UNCONTROLLED", "Uncontrolled", x, y, true)) return(false);
   show_uncontrolled.Width(btn_width);   
   if(!Add(show_uncontrolled)) return(false);
   
   y+= BUTTON_HEIGHT+CONTROLS_GAP_Y;
   x=m_client_area.Width()-INDENT_LEFT-INDENT_LEFT-BUTTON_WIDTH;
   x/=2;
   if(!CreateButton(show_all, "_SHOW_ALL", "All", x, y, false)) return(false);
   if(!Add(show_all)) return(false);
   
   return(true);
}

bool TSPanel::CreateListView(void){
   int y=(BUTTON_HEIGHT*4)+(CONTROLS_GAP_Y*4)+INDENT_TOP;
   int y2=m_client_area.Height()-INDENT_TOP;
   if(!trades_list.Create(m_chart_id, m_name+"_TRADE_LIST", m_subwin, INDENT_LEFT, y, m_client_area.Width()-INDENT_LEFT, y2)) {
      return(false);
   }
   Add(trades_list);
   LoadTrades();
   return(true);
}

bool TSPanel::Chain(void){
   if(!CreateToggleButton()) return(false);
   if(!CreateListView()) return(false);
   if(!CreateControlTab()) return(false);
   return(true);
}

bool TSPanel::CreateControlTab(void){
   if(!CreateTab(controls_tab, "CONTROLS_TAB", false)) return(false);
   if(!CreateTab(reverse_tab, "REVERSE_TAB", false)) return(false);
   
   int ROW1=INDENT_TOP+BUTTON_HEIGHT+CONTROLS_GAP_Y;
   combo_box.Create(m_chart_id, m_name+"FOOTER", 0, INDENT_LEFT, ROW1, m_client_area.Width()-INDENT_LEFT-INDENT_LEFT, ROW1+40);
   combo_box.EditColor(clrWhite);
   combo_box.EditColorBackground(C'53,28,52');
   combo_box.EditColorBorder(clrLightCoral);
   reverse_tab.Add(combo_box);
   
   if(!CreateButton(hide_reversed, "HIDE REVERSED", "BACK", INDENT_LEFT, m_client_area.Height()-BUTTON_HEIGHT-BUTTON_HEIGHT)) return(false);
   hide_reversed.Width(m_client_area.Width()-INDENT_LEFT-INDENT_LEFT);
   reverse_tab.Add(hide_reversed);
   hide_reversed.ColorBackground(C'53,28,52');
   hide_reversed.ColorBorder(clrLightCoral);
   hide_reversed.Color(clrLightCoral);
   
   
   
   if(!CreateButton(return_to_tab, "BACK", "BACK", INDENT_LEFT, INDENT_TOP)) return(false);
   return_to_tab.Width(m_client_area.Width()-INDENT_LEFT-INDENT_LEFT);
   controls_tab.Add(return_to_tab);
   return_to_tab.ColorBackground(C'53,28,52');
   return_to_tab.ColorBorder(clrLightCoral);
   return_to_tab.Color(clrLightCoral);
   
   int x=INDENT_LEFT;
   int y=INDENT_TOP+BUTTON_HEIGHT+CONTROLS_GAP_Y;
   ROW1=y;
   int PANEL_SIZE = m_client_area.Width()-INDENT_LEFT;
   
   PANEL_SIZE-=CONTROLS_GAP_X;
   int HALF_GAP=(int)(CONTROLS_GAP_X/2);
   int COLUMN1=INDENT_LEFT;
   int COLUMN2=(int)(PANEL_SIZE/3)+HALF_GAP;
   int COLUMN3=COLUMN2+COLUMN2-HALF_GAP;
   
   //+------------------------------------------------------------------+
   //|                            COLUMN 1                              |
   //+------------------------------------------------------------------+
   
   int COL_WIDTH=COLUMN2-CONTROLS_GAP_X;
   if(!CreateLabel(entry_when, "WHEN_PRICE1", "When Price:", COLUMN1, y)) return(false);
   if(!entry_when.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_when)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(action_1, "Action1", INDENT_LEFT, y, "")) return(false);
   if(!action_1.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(action_1)) return(false);
   
   int diff=m_client_area.Width()-150;
   if(diff<0) diff=0;
   else diff/=2;
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!sparator_1.Create(m_chart_id, m_name+"SEPARATOR_1", m_subwin, diff, y, m_client_area.Width()-INDENT_LEFT, 25)) return(false);
   sparator_1.BmpName("::separator.bmp");
   if(!controls_tab.Add(sparator_1)) return(false);
   
   y+=CONTROLS_GAP_Y+25;
   int ROW2=y;
   if(!CreateLabel(entry_when2, "WHEN_PRICE2", "When Price:", x, y)) return(false);
   if(!entry_when2.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_when2)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(action_2, "Action2", INDENT_LEFT, y, "")) return(false);
   if(!action_2.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(action_2)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT+5;
   /*if(!sparator_3.Create(m_chart_id, m_name+"SEPARATOR_3", m_subwin, diff, y, m_client_area.Width()-INDENT_LEFT, 25)) return(false);
   sparator_3.BmpName("::separator.bmp");
   if(!controls_tab.Add(sparator_3)) return(false);*/
   
   if(!CreateLabel(sparator_3_text, m_name+"SEPARATOR_3", "Move By Risk to Reward Ratio", INDENT_LEFT, y)) return(false);
   if(!controls_tab.Add(sparator_3_text)) return(false);
   sparator_3_text.Width(m_client_area.Width()-INDENT_LEFT);
   sparator_3_text.Color(clrWhite);
   
   y+=CONTROLS_GAP_Y+25;
   int ROW3=y;
   if(!CreateLabel(entry_when3, "WHEN_PRICE3", "When RRR", x, y)) return(false);
   if(!entry_when3.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_when3)) return(false);
   entry_when3.Color(clrWhite);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(action_3, "Action3", INDENT_LEFT, y, "")) return(false);
   if(!action_3.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(action_3)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!sparator_2.Create(m_chart_id, m_name+"SEPARATOR_2", m_subwin, diff, y, m_client_area.Width()-INDENT_LEFT, 25)) return(false);
   sparator_2.BmpName("::separator.bmp");
   if(!controls_tab.Add(sparator_2)) return(false);

   //+------------------------------------------------------------------+
   //|                            COLUMN 2                              |
   //+------------------------------------------------------------------+
   
   x=COLUMN2;
   y=ROW1;
   if(!CreateLabel(entry_move_to, "MOVE_TO1", "Move To:", x, y)) return(false);
   if(!entry_move_to.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_move_to)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(move1, "Move1", x, y, "")) return(false);
   if(!move1.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(move1)) return(false);
   
   y=ROW2;
   if(!CreateLabel(entry_move_to2, "MOVE_TO2", "Move To:", x, y)) return(false);
   if(!entry_move_to2.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_move_to2)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(move2, "Move2", x, y, "")) return(false);
   if(!move2.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(move2)) return(false);
   
   y=ROW3;
   if(!CreateLabel(entry_move_to3, "MOVE_TO3", "Move R:", x, y)) return(false);
   if(!entry_move_to3.Width(COL_WIDTH)) return(false);
   entry_move_to3.Color(clrWhite);
   if(!controls_tab.Add(entry_move_to3)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(move3, "Move3", x, y, "")) return(false);
   if(!move3.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(move3)) return(false);
   
   //+------------------------------------------------------------------+
   //|                            COLUMN 3                              |
   //+------------------------------------------------------------------+
   
   x=COLUMN3;
   y=ROW1;
   if(!CreateLabel(entry_close_to, "close_percentage1_label", "Close %:", x, y)) return(false);
   if(!entry_close_to.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_close_to)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(close_percentage1, "close_percentage1", x, y, "")) return(false);
   if(!close_percentage1.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(close_percentage1)) return(false);
   
   y=ROW2;
   if(!CreateLabel(entry_close_to2, "close_percentage2_label", "Close %:", x, y)) return(false);
   if(!entry_close_to2.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(entry_close_to2)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(close_percentage2, "close_percentage2", x, y, "")) return(false);
   if(!close_percentage2.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(close_percentage2)) return(false);
   
   y=ROW3;
   if(!CreateLabel(entry_close_to3, "close_percentage3_label", "Close %:", x, y)) return(false);
   if(!entry_close_to3.Width(COL_WIDTH)) return(false);
   entry_close_to3.Color(clrWhite);
   if(!controls_tab.Add(entry_close_to3)) return(false);
   
   y+=CONTROLS_GAP_Y+BUTTON_HEIGHT;
   if(!CreateEdit(close_percentage3, "close_percentage3", x, y, "")) return(false);
   if(!close_percentage3.Width(COL_WIDTH)) return(false);
   if(!controls_tab.Add(close_percentage3)) return(false);
   
   //+------------------------------------------------------------------+
   //|                            COLUMN 4                              |
   //+------------------------------------------------------------------+
   y=ROW1;
   if(!visual_1.Create(m_chart_id, m_name+"VISUAL_1", 0, m_client_area.Width()-25, y, m_client_area.Width(), y+20)) return(false);
   visual_1.ColorBackgrund(C'45,45,45');
   visual_1.ColorBorder(C'45,45,45');
   if(!controls_tab.Add(visual_1)) return(false);
   
   y=ROW2;
   if(!visual_2.Create(m_chart_id, m_name+"VISUAL_2", 0, m_client_area.Width()-25, y, m_client_area.Width(), y+20)) return(false);
   visual_2.ColorBackgrund(C'45,45,45');
   visual_2.ColorBorder(C'45,45,45');
   if(!controls_tab.Add(visual_2)) return(false);
   
   y=ROW3;
   if(!dont_close_first.Create(m_chart_id, m_name+"dont_close_first", 0, m_client_area.Width()-25, y, m_client_area.Width(), y+20)) return(false);
   dont_close_first.ColorBackgrund(C'45,45,45');
   dont_close_first.ColorBorder(C'45,45,45');
   dont_close_first.Text("After First");
   dont_close_first.Color(clrWhite);
   if(!controls_tab.Add(dont_close_first)) return(false);
   
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   
   y+=CONTROLS_GAP_Y+25+BUTTON_HEIGHT+BUTTON_HEIGHT;
   if(!notify_me.Create(m_chart_id, m_name+"_NOTIFY_ME", m_subwin, INDENT_LEFT, y, m_client_area.Width()-INDENT_LEFT-INDENT_LEFT, y+20)) return(false);
   notify_me.Text("Notify me");
   notify_me.ColorBackgrund(C'52,52,52');
   notify_me.ColorBorder(C'52,52,52');
   notify_me.Color(C'197,197,197');
   notify_me.FontSize(BUTTON_FONT_SIZE);
   if(!controls_tab.Add(notify_me)) return(false);
   
   if(!remove_reversed.Create(m_chart_id, m_name+"_REMOVE_REVERSED", m_subwin, m_client_area.Width()-INDENT_LEFT-INDENT_LEFT-BUTTON_WIDTH-BUTTON_WIDTH-BUTTON_WIDTH, y, m_client_area.Width()-INDENT_LEFT-INDENT_LEFT, y+20)) return(false);
   remove_reversed.Text("Remove Reversed");
   remove_reversed.ColorBackgrund(C'52,52,52');
   remove_reversed.ColorBorder(C'52,52,52');
   remove_reversed.Color(C'197,197,197');
   remove_reversed.FontSize(BUTTON_FONT_SIZE);
   if(!controls_tab.Add(remove_reversed)) return(false);
   y+=20+CONTROLS_GAP_Y;
   
   if(!CreateButton(button_apply, "APPLY", "APPLY", INDENT_LEFT, y)) return(false);
   button_apply.Width(m_client_area.Width()-INDENT_LEFT-INDENT_LEFT);
   controls_tab.Add(button_apply);
   button_apply.ColorBackground(C'53,28,52');
   button_apply.ColorBorder(clrLightCoral);
   button_apply.Color(clrLightCoral);
   
   if(!footer.Create(m_chart_id, m_name+"FOOTER", m_subwin, 0, m_client_area.Height()-54, m_client_area.Width(), m_client_area.Height())) return(false);
   footer.BmpName("::footer.bmp");
   if(!controls_tab.Add(footer)) return(false);
   return(true);
}

void TSPanel::OnClickToggle(void){
   _ENABLED=!_ENABLED;
   ToggleButtonColor(toggle_button, _ENABLED);
   if(_ENABLED) toggle_button.Text("Disable");
   else toggle_button.Text("Enable");
   
   if(_ENABLED){
      trades_list.Visible(true);
      intro_label.Visible(true);
      show_all.Visible(true);
      show_controlled.Visible(true);
      show_uncontrolled.Visible(true);
      m_rect.Height(WINDOW_HEIGHT);
      Size(m_rect.Size());
      LoadTrades();
   }
   else {
      trades_list.Visible(false);
      intro_label.Visible(false);
      show_all.Visible(false);
      show_controlled.Visible(false);
      show_uncontrolled.Visible(false);
      int off=(m_panel_flag) ? 0:2*CONTROLS_BORDER_WIDTH;
      
      m_rect.Height(INDENT_TOP+INDENT_TOP+BUTTON_HEIGHT+off+CONTROLS_DIALOG_CAPTION_HEIGHT);
      Size(m_rect.Size());
   }
}

void TSPanel::LoadTrades(void){
   if(ObjectFind(0, "AHMEDR_VIS_AC")==-1||ObjectFind(0, "AHMEDR_VIS_ST")==-1){
      ReloadPanel();
      return;
   }
   if(CheckPointer(Controlled)==POINTER_INVALID) return;
   trades_list.ItemsClear();
   int deletable[];
   int cntr=0;
   for(int i=0; i<Trades.Total(); i++){
      if(((TradeManager*)Trades.At(i))._DESTROY){
         ArrayResize(deletable, cntr+1);
         deletable[cntr]=i;
      }
   }
   for(int i=0; i<ArraySize(deletable); i++) Trades.Delete(deletable[i]);
   //trades_list.Select(-1);
   for(int i=0; i<OrdersTotal(); i++){
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(_show_mode==2 && Controlled.SearchFirst(OrderTicket())<0) continue;
      if(_show_mode==3 && Controlled.SearchFirst(OrderTicket())>=0) continue;
      string type=GetOrderType(OrderType());
      if(type=="") continue;
      string name = "#"+(string)OrderTicket();
      name += " / ";
      name+=OrderSymbol();
      name +=" - ";
      name += type;
      if(OrderType()==OP_BUY||OrderType()==OP_SELL){
         if(OrderType()==OP_BUY){
            name+=" ("+DoubleToString(PointToPips(Bid-OrderOpenPrice()),1)+")Pips";
         }
         else name+=" ("+DoubleToString(PointToPips(OrderOpenPrice()-Ask), 1)+")Pips";
      }
      trades_list.AddItem(name, OrderTicket());
   }
}

string TSPanel::GetOrderType(int o){
   switch(o){
      case OP_BUY: return("Buy");
      case OP_SELL: return("Sell");
      case OP_BUYLIMIT: return("B-Limit");
      case OP_BUYSTOP: return("B-Stop");
      case OP_SELLLIMIT: return("S-Limit");
      case OP_SELLSTOP: return("S-Stop");
      default: return"";
   }
}

void TSPanel::OnChangeListView(void){
   if(trades_list.Select()=="") return;
   visual_1.Checked(false);
   visual_2.Checked(false);
   dont_close_first.Checked(false);
   
   SetReadOnly(action_1, false);
   SetReadOnly(action_2, false);
   SetReadOnly(action_3, false);
   SetReadOnly(move1, false);
   SetReadOnly(move2, false);
   SetReadOnly(move3, false);
   action_1.Text("");
   action_2.Text("");
   action_3.Text("");
   move1.Text("");
   move2.Text("");
   move3.Text("");
   close_percentage1.Text("");
   close_percentage2.Text("");
   close_percentage3.Text("");
   
   if(OrderSelect((int)trades_list.Value(), SELECT_BY_TICKET)) {
      if(OrderStopLoss()>0) {
         sparator_3_text.Color(clrWhite);
         sparator_3_text.Text("Move By Risk to Reward Ratio ("+DoubleToString(PointToPips(MathAbs(OrderOpenPrice()-OrderStopLoss())),1)+") Pips");
         action_3.ReadOnly(false);
         move3.ReadOnly(false);
         close_percentage3.ReadOnly(false);
         entry_close_to3.Color(clrWhite);
         entry_move_to3.Color(clrWhite);
         entry_when3.Color(clrWhite);
      }else {
         sparator_3_text.Color(clrRosyBrown);
         sparator_3_text.Text("You have to set stoploss to use this.");
         action_3.ReadOnly(true);
         move3.ReadOnly(true);
         close_percentage3.ReadOnly(true);
         entry_close_to3.Color(clrRosyBrown);
         entry_move_to3.Color(clrRosyBrown);
         entry_when3.Color(clrRosyBrown);
      }
   }
   
   for(int i=0; i<Trades.Total(); i++){
      TradeManager* tr = Trades.At(i);
      if(tr.IsTicketFound(trades_list.Value())) {
         tr.FillEntries();
      }
   }
   return_to_tab.Text("#"+(string)trades_list.Value()+"-Back");
   controls_tab.Visible(true);
}

double TSPanel::PointToPips(double d){
   double pips2dbl;
   int pips2points, pips;
   
   if (Digits == 5 || Digits == 3) {
      pips2dbl = Point*10;
      pips2points = 10;
      pips = 1;
    }
    else {
      pips2dbl = Point;
      pips2points = 1;
      pips = 0;
    }
   return(d / pips2dbl);         
}

void TSPanel::OnClickBack(void){
   RemoveLines();
   controls_tab.Visible(false);
}

void TSPanel::OnClickApply(void){
   double condition_1=(double)action_1.Text();   
   double condition_2=(double)action_2.Text();
   double condition_3=(double)action_3.Text();
   
   double a1=(double)move1.Text();
   double a2=(double)move2.Text();
   double a3=(double)move3.Text();
   if(condition_1>0&&a1==0){
      MessageBox("الشرط الأول صحيح ولكن الفعل غير صحيح يرجى التعديل.", "خطــأ!",0);
      return;
   }
   if(condition_2>0&&a2==0){
      MessageBox("الشرط الثاني صحيح ولكن الفعل غير صحيح يرجى التعديل.", "خطــأ!",0);
      return;
   }
   if(condition_3>0&&a3==0){
      MessageBox("الشرط الثالث صحيح ولكن الفعل غير صحيح يرجى التعديل.", "خطــأ!",0);
      return;
   }
   if(a3>condition_3){
      MessageBox("لا يمكن أن يكون الفعل أكبر من عدد الشرط الثالث.", "خطــأ!",0);
      return;    
   }
   int deleteable[];
   int counter=0;
   bool found=false;
   TradeManager* tr=NULL;
   for(int i=0; i<Trades.Total(); i++){
      tr = Trades.At(i);
      if(!found) found=tr.IsTicketFound(trades_list.Value());
      if(tr._DESTROY){
         ArrayResize(deleteable, counter+1);
         deleteable[counter++]=i;
         continue;
      }
      if(found) tr.ReloadRates();
   }
   if(!found) {
      if(condition_1==0&&condition_2==0&&condition_3==0){
         MessageBox("يجب إدخال شرط واحد على الأقل.", "خطــأ!",0);
         return;
      }
      if(a1==0&&a2==0&&a3==0){
         MessageBox("يجب إدخال فعل واحد على الأقل.", "خطــأ!",0);
         return;
   }
      Trades.Add(new TradeManager(trades_list.Value()));
      tr=Trades.At(Trades.Total()-1);
      Controlled.Resize(Controlled.Total()+1);
      Controlled.Add(trades_list.Value());
      Controlled.Sort();
   }
   for(int i=0; i<counter;i++) Trades.Delete(deleteable[i]);
   if(CheckPointer(tr)!=POINTER_INVALID&&tr.HasError()) return;
   controls_tab.Visible(false);
   RemoveLines();
   LoadTrades();
}

void  TSPanel::OnClickShowControlled(void){
   ToggleButtonColor(show_controlled, true);
   ToggleButtonColor(show_uncontrolled, false);
   ToggleButtonColor(show_all, false);
   _show_mode=2;
   LoadTrades();
}
void  TSPanel::OnClickShowUncontrolled(void){
   ToggleButtonColor(show_controlled, false);
   ToggleButtonColor(show_uncontrolled, true);
   ToggleButtonColor(show_all, false);
   _show_mode=3;
   LoadTrades();
}
void  TSPanel::OnClickShowAll(void){
   ToggleButtonColor(show_controlled, false);
   ToggleButtonColor(show_uncontrolled, false);
   ToggleButtonColor(show_all, true);
   _show_mode=1;
   LoadTrades();
}

void TSPanel::VisibleMove1(void){
   visual_2.Checked(false);
   if(action_1.ReadOnly() || move1.ReadOnly()) {
      visual_1.Checked(false);
      return;
   }
   if(visual_1.Checked()) MakeLines();
   else RemoveLines();
}
void TSPanel::VisibleMove2(void){
   visual_1.Checked(false);
   if(action_2.ReadOnly() || move2.ReadOnly()) {
      visual_2.Checked(false);
      return;
   }
   if(visual_2.Checked()) MakeLines();
   else RemoveLines();
}

void TSPanel::RemoveLines(void){
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
}

void TSPanel::MakeLines(void){
   RemoveLines();
   double price1=iHigh(NULL, 0, 0), price2=iHigh(NULL, 0, 10);
   if(visual_1.Checked()){
      double d = (double)action_1.Text();
      if(d>0) price1=d;
      d = (double)move1.Text();
      if(d>0) price2=d;
   }
   else if(visual_2.Checked()){
      double d = (double)action_2.Text();
      if(d>0) price1=d;
      d = (double)move2.Text();
      if(d>0) price2=d;
   }
   ObjectSetDouble(ChartID(), "AHMEDR_VIS_ST", OBJPROP_PRICE, price2);
   ObjectSetDouble(ChartID(), "AHMEDR_VIS_AC", OBJPROP_PRICE, price1);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_ST", OBJPROP_SELECTED, true);
   ObjectSetInteger(ChartID(), "AHMEDR_VIS_AC", OBJPROP_SELECTED, true);
   
   m_white_border.Visible(false);
   m_caption.Visible(false);
   m_background.Visible(false);
   m_button_close.Visible(false);
   m_client_area.Visible(false);
   controls_tab.Visible(false);
   m_button_minmax.Visible(false);
   
   m_white_border.Visible(true);
   m_background.Visible(true);
   m_caption.Visible(true);
   m_button_close.Visible(true);
   m_button_minmax.Visible(true);
   m_client_area.Visible(true);
   controls_tab.Visible(true);
}

void TSPanel::DoMoves(string sparam){
   if(sparam=="AHMEDR_VIS_AC"||sparam=="AHMEDR_VIS_ST"){
      if(visual_1.Checked()){
         if(sparam=="AHMEDR_VIS_AC") action_1.Text(DoubleToString(ObjectGetDouble(ChartID(), "AHMEDR_VIS_AC", OBJPROP_PRICE), Digits));
         if(sparam=="AHMEDR_VIS_ST") move1.Text(DoubleToString(ObjectGetDouble(ChartID(), "AHMEDR_VIS_ST", OBJPROP_PRICE), Digits));
      }
      else if(visual_2.Checked()){
         if(sparam=="AHMEDR_VIS_AC") action_2.Text(DoubleToString(ObjectGetDouble(ChartID(), "AHMEDR_VIS_AC", OBJPROP_PRICE), Digits));
         if(sparam=="AHMEDR_VIS_ST") move2.Text(DoubleToString(ObjectGetDouble(ChartID(), "AHMEDR_VIS_ST", OBJPROP_PRICE), Digits));
      }
   }
}

void TSPanel::ChangeRemoveReversed(void){
   if(remove_reversed.Checked()){
      combo_box.ItemsClear();
      for(int i=0; i<OrdersTotal(); i++){
         if(OrderSelect(i, SELECT_BY_POS)){
            if(OrderTicket()==trades_list.Value()) continue;
            if(OrderType() == OP_BUY || OrderType() == OP_SELL) continue;
            combo_box.ItemAdd(OrderSymbol()+" / "+DoubleToString(OrderLots(), 2)+" / "+GetOrderType(OrderType()), OrderTicket());
         }
      }
      reverse_tab.Visible(true);
   }
   else {
      reverse_tab.Visible(false);
   }
}