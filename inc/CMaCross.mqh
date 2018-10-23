//+------------------------------------------------------------------+
//|                                                   |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.yjx.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018."
#property link      "http://www.yjx.com"

#include "structs.mqh";
#include "CMaOne.mqh";
#include "CTrade.mqh";
class CMaCross
{  
   private:
      
      CTrade* oCTrade;
      CMaOne* oCMaOne;
      
      bool    m_isUse;
      double  m_lots;
      int     m_tp;
      int     m_sl;
      
      int     m_ticket_fast;
      int     m_ticket_slow;
      double  m_fast_profit_pips;
      
      double m_Ma10[30];
      double m_Ma30[30];
      double m_Stoch100[30];
      
      datetime CheckTimeM5;
      int OrderOpenPass;
      
      void FillData();
      
      
   public:
   
      CMaCross(int Magic){
         oCTrade = new CTrade(Magic);
         oCMaOne = new CMaOne();
         m_ticket_fast = 0;
         m_ticket_slow = 0;
         m_fast_profit_pips = 0;
         OrderOpenPass  = 0;
      };
      
      void Init(double _lots, int _tp, int _sl);
      void Stop();
      void Tick();
      bool Entry();
      bool Exit();
      void Protect();
      int EntrySignal();
      string ExitSignal();
      
};

void CMaCross::FillData()
{
   for(int i=0;i<30;i++){ 
      m_Ma10[i] = iMA(NULL,PERIOD_M5,10,0,MODE_SMA,PRICE_CLOSE,i);
      m_Ma30[i] = iMA(NULL,PERIOD_M5,30,0,MODE_SMA,PRICE_CLOSE,i);
      m_Stoch100[i] = iStochastic(NULL, PERIOD_M5, 100, 3, 3, MODE_SMA, 0, MODE_MAIN, i);
   }
   OrderOpenPass += 1;
   oCMaOne.AddCol();
   if(m_ticket_fast != 0 && oCTrade.isOrderClosed(m_ticket_fast)){
      m_ticket_fast = 0;
      m_fast_profit_pips = oCTrade.GetProfitPips(m_ticket_fast);
   }
   if(m_ticket_slow != 0 && oCTrade.isOrderClosed(m_ticket_slow)){
      m_ticket_slow = 0;
   }
   if(m_ticket_fast == 0 && m_ticket_slow == 0){
      OrderOpenPass  = 0;
   }
}

void CMaCross::Init(double _lots, int _tp, int _sl)
{
   m_lots = _lots;
   m_tp   = _tp;
   m_sl   = _sl;
   m_isUse = true;
}

void CMaCross::Stop()
{
   m_isUse = false;
}

void CMaCross::Tick()
{
    if(CheckTimeM5 == iTime(NULL,PERIOD_M5,0)){
      
    }else{
         CheckTimeM5 = iTime(NULL,PERIOD_M5,0);
         this.FillData();
         
         this.Exit();
         this.Entry();
    }
}

bool CMaCross::Entry()
{
   if(m_ticket_fast != 0 || m_ticket_slow != 0){
      return false;
   }
   int sig = this.EntrySignal();
   int t = 0;
   if(sig == OP_BUY){
      t = oCTrade.Buy(m_lots, 0, 0, "CMaM5_fast");
      if(t > 0){
         m_ticket_fast = t;
      }
      t = oCTrade.Buy(m_lots, 0, 0, "CMaM5_slow");
      if(t > 0){
         m_ticket_slow = t;
      }
      
   }
   if(sig == OP_SELL){
      t = oCTrade.Sell(m_lots, 0, 0, "CMaM5_fast");
      if(t > 0){
         m_ticket_fast = t;
      }
      t = oCTrade.Sell(m_lots, 0, 0, "CMaM5_slow");
      if(t > 0){
         m_ticket_slow = t;
      }
   }
   return true;
}

bool CMaCross::Exit()
{
   if(m_ticket_fast == 0 && m_ticket_slow == 0){
      return false;
   }
   string sig = this.ExitSignal();
   //TODO
   
}

int CMaCross::EntrySignal()
{
   
   if(m_Ma10[1] > m_Ma30[1] && m_Ma10[2] < m_Ma30[2]){
      oCMaOne.SetCross("up", m_Ma30[1]);
   }
   if(m_Ma10[1] < m_Ma30[1] && m_Ma10[2] > m_Ma30[2]){
      oCMaOne.SetCross("down", m_Ma30[1]);
   }
   if(!oCMaOne.isStochCrossOk && oCMaOne.crossPass <30){
      double hPrice=0,lPrice=100;
      for(int i=1;i<=20;i++){
         if(m_Stoch100[i]>hPrice){
            hPrice = m_Stoch100[i];
         }
         if(m_Stoch100[i]<lPrice){
            lPrice = m_Stoch100[i];
         }
      }
      if(oCMaOne.crossType == "up"){
         if(hPrice > 49 && lPrice<26){
            oCMaOne.isStochCrossOk = true;
         }
      }
      if(oCMaOne.crossType == "down"){
         if(hPrice > 74 && lPrice<51){
            oCMaOne.isStochCrossOk = true;
         }
      }
   }
   
   bool isOk;
   if(oCMaOne.IsCanOpenBuy() && m_Stoch100[1]>50){
      isOk = false;
      if(oCMaOne.crossPass <8 && Ask - oCMaOne.crossPrice<5*oCTrade.GetPip()){
         isOk = true;
      }
      if(oCMaOne.crossPass >=8 && Ask - oCMaOne.crossPrice<25*oCTrade.GetPip() && Ask-m_Ma30[1]<4*oCTrade.GetPip()){
         isOk = true;
      }
      if(oCMaOne.crossPass >=15 && Ask - oCMaOne.crossPrice<25*oCTrade.GetPip() && Ask-m_Ma10[1]<3*oCTrade.GetPip()){
         isOk = true;
      }
      if(isOk){
         //oCMaOne.Reset();
         return OP_BUY;
      }
   }
   
   if(oCMaOne.IsCanOpenSell() && m_Stoch100[1]<50){
      isOk = false;
      if(oCMaOne.crossPass <8 && oCMaOne.crossPrice -Bid<7*oCTrade.GetPip()){
         isOk = true;
      }
      if(oCMaOne.crossPass >=8 && oCMaOne.crossPrice - Bid<25*oCTrade.GetPip() && m_Ma30[1] - Bid<4*oCTrade.GetPip()){
         isOk = true;
      }
      if(oCMaOne.crossPass >=15 && oCMaOne.crossPrice - Bid<25*oCTrade.GetPip() && m_Ma10[1] - Bid<3*oCTrade.GetPip()){
         isOk = true;
      }
      if(isOk){
         //oCMaOne.Reset();
         return OP_SELL;
      }
   }
   return -1;
}

string CMaCross::ExitSignal()
{
   if( (m_Stoch100[1] < m_Stoch100[2] && m_Stoch100[2]<50) || (m_Stoch100[1]>93 && Ask - m_Ma30[1]>24*oCTrade.GetPip())){
      return "exit_buy_all";
   }
   
   if((m_Stoch100[1] > m_Stoch100[2] && m_Stoch100[2]>50) || (m_Stoch100[1]<7 && m_Ma30[1] -Bid>24*oCTrade.GetPip())){
      return "exit_sell_all";
   }
   
   //TODO
   if( m_Stoch100[2]>93 && m_Stoch100[2]>m_Stoch100[1] && oCTrade.GetOrderType(m_ticket_fast) == OP_BUY && oCTrade.GetProfitPips(m_ticket_fast) >8){
      return "exit_buy_fast";
   }
   
   if( m_Stoch100[2]<7 && m_Stoch100[2]<m_Stoch100[1] && oCTrade.GetOrderType(m_ticket_fast) == OP_SELL && oCTrade.GetProfitPips(m_ticket_fast) >8){
      return "exit_sell_fast";
   }
   return "none";
}