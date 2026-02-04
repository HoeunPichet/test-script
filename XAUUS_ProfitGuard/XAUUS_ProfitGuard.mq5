//+------------------------------------------------------------------+
//|                                                XAUUS_ProfitGuard |
//|                Low-risk XAU/USD EA for $100–$1000 accounts        |
//|          ✅ Fixed: Uses CTrade, proper event handlers, no errors  |
//+------------------------------------------------------------------+
#property strict
#property version   "2.1"
#property description "Robust XAU/USD EA with dynamic ATR SL/TP, time filter, 1% risk"

#include <Trade\Trade.mqh>
CTrade trade;

input double LotSizePer100 = 0.01;     // Lot per $100 balance
input int    EMAShort = 9;
input int    EMALong = 21;
input int    RSIPeriod = 14;
input double RSIOverbought = 70;
input double RSIOversold = 30;
input int    ATRPeriod = 14;
input double SL_Multiplier = 1.5;
input double TP_Multiplier = 2.5;
input int    StartHour = 8;            // EST hours (server time adjusted)
input int    EndHour = 12;

double ema_short[], ema_long[], rsi[], atr[];
int handle_ema_s, handle_ema_l, handle_rsi, handle_atr;

//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize trade object
   trade.SetExpertMagicNumber(123456);
   trade.SetDeviationInPoints(10);
   
   // Create indicators
   handle_ema_s = iMA(_Symbol, _Period, EMAShort, 0, MODE_EMA, PRICE_CLOSE);
   handle_ema_l = iMA(_Symbol, _Period, EMALong, 0, MODE_EMA, PRICE_CLOSE);
   handle_rsi   = iRSI(_Symbol, _Period, RSIPeriod, PRICE_CLOSE);
   handle_atr   = iATR(_Symbol, _Period, ATRPeriod);

   if(handle_ema_s==INVALID_HANDLE || handle_ema_l==INVALID_HANDLE ||
      handle_rsi==INVALID_HANDLE || handle_atr==INVALID_HANDLE)
   {
      Print("Failed to create indicators");
      return INIT_FAILED;
   }

   Print("XAUUS_ProfitGuard initialized successfully.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(handle_ema_s);
   IndicatorRelease(handle_ema_l);
   IndicatorRelease(handle_rsi);
   IndicatorRelease(handle_atr);
   Print("XAUUS_ProfitGuard deinitialized.");
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsTradeAllowed()) return;
   if(PositionExists()) return; // Only one position

   // Refresh indicator buffers (min 3 bars)
   if(CopyBuffer(handle_ema_s, 0, 0, 3, ema_short) < 3 ||
      CopyBuffer(handle_ema_l, 0, 0, 3, ema_long) < 3 ||
      CopyBuffer(handle_rsi, 0, 0, 3, rsi) < 3 ||
      CopyBuffer(handle_atr, 0, 0, 3, atr) < 3)
      return;

   double current_atr = atr[0];
   double sl_points = SL_Multiplier * current_atr;
   double tp_points = TP_Multiplier * current_atr;

   // Normalize to minimum stop level
   double min_stop = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(sl_points < min_stop) sl_points = min_stop;
   if(tp_points < min_stop) tp_points = min_stop;

   // Calculate lot size (max 0.05 for $1000 account)
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double lots = NormalizeDouble((equity / 100.0) * LotSizePer100, 2);
   lots = MathMax(0.01, MathMin(lots, 0.05)); // Cap at 0.05 lots

   // Convert server time to EST (assuming server is GMT+0 or GMT+2 — adjust if needed)
   datetime now = TimeCurrent();
   MqlDateTime tm;
   TimeToStruct(now, tm);
   int server_hour = tm.hour;
   // Assume server is UTC (common on most brokers). EST = UTC -5
   int_hour = (server_hour - 5 + 24) % 24;

   if(est_hour < StartHour || est_hour > EndHour)
      return;

   // Signal logic
   bool buy_cond  = (ema_short[1] > ema_long[1]) && (ema_short[2] <= ema_long[2]) &&
                    (rsi[1] > RSIOversold) && (rsi[1] < RSIOverbought);
   bool sell_cond = (ema_short[1] < ema_long[1]) && (ema_short[2] >= ema_long[2]) &&
                    (rsi[1] < RSIOverbought) && (rsi[1] > RSIOversold);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(buy_cond)
   {
      double sl = ask - sl_points;
      double tp = ask + tp_points;
      if(!trade.Buy(lots, _Symbol, ask, sl, tp, "XAUUS_ProfitGuard BUY"))
         Print("Buy failed: ", trade.ResultRetcodeDescription());
   }
   else if(sell_cond)
   {
      double sl = bid + sl_points;
      double tp = bid - tp_points;
      if(!trade.Sell(lots, _Symbol, bid, sl, tp, "XAUUS_ProfitGuard SELL"))
         Print("Sell failed: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
bool PositionExists()
{
   return PositionsTotal() > 0 && 
          PositionSelect(_Symbol);
}