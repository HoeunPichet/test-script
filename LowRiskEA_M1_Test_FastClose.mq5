//+------------------------------------------------------------------+
//| LowRiskEA_M1_Test_FastClose.mq5                                  |
//| MT5 EA for M1 testing: ACTIVE display, multi-position capable    |
//| + Faster Closing (BE + Trailing + Profit-only time close)        |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

// ---------------- INPUTS ----------------
input ulong  MagicNumber            = 111001;

input bool   AllowTrading           = true;
input bool   ShowStatusOnChart      = true;
input bool   DebugPrints            = true;

// FORCE TEST (to prove broker allows trades)
input bool   ForceTestTrade         = false;
input int    ForceDirection         = 1;      // 1=BUY, -1=SELL
input int    ForceSL_Points         = 20000;  // increase if "invalid stops"
input int    ForceTP_Points         = 20000;

// Risk & money management
input double RiskPerTradePct        = 0.05;   // VERY SMALL for M1
input int    MaxOpenPositions       = 10;
input int    MaxTradesPerDay        = 100;
input int    MinBarsBetweenEntries  = 0;      // kept for compatibility (not used in entry below)

// Strategy (FAST for M1)
input int    EMAPeriod              = 50;
input int    RSIPeriod              = 7;
input double RSI_BuyLevel           = 45;
input double RSI_SellLevel          = 55;

// Stops (base SL/TP)
input int    ATRPeriod              = 14;
input double SL_ATR_Mult            = 1.5;
input double TP_R_Mult              = 1.0;

// Filters
input int    MaxSpreadPoints        = 800;
input double MaxDailyLossPct        = 3.0;

// ---- Faster closing / profit lock ----
input bool UseBreakEven             = true;
input int  BE_TriggerPoints         = 300;    // when profit >= this, move SL to BE+lock
input int  BE_LockPoints            = 50;     // lock this many points after BE

input bool UseTrailing              = true;
input int  TrailStartPoints         = 400;    // start trailing after this profit
input int  TrailDistancePoints      = 250;    // SL distance behind price
input int  TrailStepPoints          = 50;     // only update if SL improves by this

input bool UseProfitTimeClose       = true;
input int  MaxHoldMinutes           = 10;     // close faster if open too long (profit only)

// ---------------- GLOBALS ----------------
int hATR, hEMA, hRSI;
datetime lastBarTime = 0;
int tradesToday = 0;
double dayStartBalance = 0;
int dayOfYear = -1;

// ---------------- UTILS ----------------
void Status(string s)
{
   if(ShowStatusOnChart)
      Comment("LowRiskEA M1 FAST CLOSE\n",
              _Symbol,"  ", EnumToString(_Period), "\n",
              "Status: ", s, "\n",
              "TradesToday: ", tradesToday, "\n",
              "MyPositions: ", CountMyPositions(), "\n",
              "Spread(points): ", (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
}

void DPrint(string s){ if(DebugPrints) Print(s); }

bool IsNewBar()
{
   datetime t = iTime(_Symbol, _Period, 0);
   if(t != lastBarTime){ lastBarTime = t; return true; }
   return false;
}

void ResetDay()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != dayOfYear)
   {
      dayOfYear = dt.day_of_year;
      tradesToday = 0;
      dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      DPrint("Daily reset. StartBalance=" + DoubleToString(dayStartBalance, 2));
   }
}

bool DailyLossHit()
{
   double loss = dayStartBalance - AccountInfoDouble(ACCOUNT_BALANCE);
   return loss >= dayStartBalance * (MaxDailyLossPct/100.0);
}

int CountMyPositions()
{
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(!PositionSelectByTicket(t)) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      c++;
   }
   return c;
}

double GetBuf(int h)
{
   double b[];
   if(CopyBuffer(h, 0, 0, 1, b) < 1) return 0.0;
   return b[0];
}

double CalcLot(double sl_points)
{
   if(sl_points <= 0) return 0.0;

   double bal  = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk = bal * (RiskPerTradePct/100.0);

   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double moneyPerLot = sl_points * (tv * (pt/ts));
   if(moneyPerLot <= 0) return 0.0;

   double lot = risk / moneyPerLot;

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   lot = MathFloor(lot/step) * step;
   return NormalizeDouble(lot, 2);
}

// --- Manage open positions: BreakEven + Trailing + Profit-only Time Close ---
void ManageMyPositions()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

      long   type      = (long)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl        = PositionGetDouble(POSITION_SL);
      double tp        = PositionGetDouble(POSITION_TP);

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      double profitMoney = PositionGetDouble(POSITION_PROFIT);

      double priceNow = (type == POSITION_TYPE_BUY) ? bid : ask;
      double profitPts = (type == POSITION_TYPE_BUY)
                         ? (priceNow - openPrice) / point
                         : (openPrice - priceNow) / point;

      // Profit-only time close
      if(UseProfitTimeClose)
      {
         int minutesOpen = (int)((TimeCurrent() - openTime) / 60);
         if(minutesOpen >= MaxHoldMinutes && profitMoney > 0.0)
         {
            if(!trade.PositionClose(ticket))
               DPrint("TimeClose failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
            else
               DPrint("TimeClose OK (profit-only). Ticket=" + (string)ticket);
            continue;
         }
      }

      // Break-even
      if(UseBreakEven && profitPts >= (double)BE_TriggerPoints)
      {
         double newSL = sl;

         if(type == POSITION_TYPE_BUY)
         {
            double beSL = openPrice + (double)BE_LockPoints * point;
            if(sl == 0.0 || beSL > sl) newSL = beSL;
         }
         else // SELL
         {
            double beSL = openPrice - (double)BE_LockPoints * point;
            if(sl == 0.0 || beSL < sl) newSL = beSL;
         }

         if(newSL != sl)
         {
            if(!trade.PositionModify(ticket, newSL, tp))
               DPrint("BE modify failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
         }
      }

      // Trailing stop
      if(UseTrailing && profitPts >= (double)TrailStartPoints)
      {
         double newSL = sl;

         if(type == POSITION_TYPE_BUY)
         {
            double trailSL = bid - (double)TrailDistancePoints * point;
            if(sl == 0.0 || trailSL > sl + (double)TrailStepPoints * point) newSL = trailSL;
         }
         else // SELL
         {
            double trailSL = ask + (double)TrailDistancePoints * point;
            if(sl == 0.0 || trailSL < sl - (double)TrailStepPoints * point) newSL = trailSL;
         }

         if(newSL != sl)
         {
            if(!trade.PositionModify(ticket, newSL, tp))
               DPrint("Trail modify failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
         }
      }
   }
}

// ---------------- INIT ----------------
int OnInit()
{
   trade.SetExpertMagicNumber((long)MagicNumber);

   hATR = iATR(_Symbol, _Period, ATRPeriod);
   hEMA = iMA(_Symbol, _Period, EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hRSI = iRSI(_Symbol, _Period, RSIPeriod, PRICE_CLOSE);

   ResetDay();
   Status("ACTIVE (initialized)");
   return INIT_SUCCEEDED;
}

// ---------------- DEINIT ----------------
void OnDeinit(const int reason)
{
   if(ShowStatusOnChart) Comment("");
}

// ---------------- TICK ----------------
void OnTick()
{
   if(!AllowTrading){ Status("Trading disabled"); return; }

   ResetDay();
   if(DailyLossHit()){ Status("STOP: Daily loss hit"); return; }

   // Manage open positions every tick (fast close / profit lock)
   ManageMyPositions();

   // FORCE TEST
   if(ForceTestTrade)
   {
      double pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      bool ok;
      if(ForceDirection > 0)
         ok = trade.Buy(lot, _Symbol, 0.0, ask - (double)ForceSL_Points * pt, ask + (double)ForceTP_Points * pt, "FORCE BUY");
      else
         ok = trade.Sell(lot, _Symbol, 0.0, bid + (double)ForceSL_Points * pt, bid - (double)ForceTP_Points * pt, "FORCE SELL");

      if(!ok) DPrint("FORCE failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
      Status(ok ? "FORCE TRADE OPENED" : "FORCE TRADE FAILED (see Experts)");
      return;
   }

   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPoints)
   { Status("WAIT: Spread too high"); return; }

   // Enter on new bar
   if(!IsNewBar()){ Status("WAIT: No new bar"); return; }

   if(tradesToday >= MaxTradesPerDay)
   { Status("STOP: Max trades/day"); return; }

   if(CountMyPositions() >= MaxOpenPositions)
   { Status("STOP: Max positions"); return; }

   double atr = GetBuf(hATR);
   double ema = GetBuf(hEMA);
   double rsi = GetBuf(hRSI);
   if(atr <= 0 || ema <= 0){ Status("WAIT: Indicators not ready"); return; }

   double close0 = iClose(_Symbol, _Period, 0);
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double sl_dist   = atr * SL_ATR_Mult;
   double sl_points = sl_dist / pt;

   double lot = CalcLot(sl_points);
   if(lot <= 0){ Status("STOP: Lot calc failed"); return; }

   bool buy  = (close0 > ema) && (rsi < RSI_BuyLevel);
   bool sell = (close0 < ema) && (rsi > RSI_SellLevel);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(buy)
   {
      bool ok = trade.Buy(lot, _Symbol, 0.0, ask - sl_dist, ask + sl_dist * TP_R_Mult, "M1 BUY");
      if(!ok) DPrint("BUY failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
      if(ok){ tradesToday++; Status("BUY opened"); }
      else  Status("BUY failed (see Experts)");
   }
   else if(sell)
   {
      bool ok = trade.Sell(lot, _Symbol, 0.0, bid + sl_dist, bid - sl_dist * TP_R_Mult, "M1 SELL");
      if(!ok) DPrint("SELL failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
      if(ok){ tradesToday++; Status("SELL opened"); }
      else  Status("SELL failed (see Experts)");
   }
   else
   {
      Status("ACTIVE: No signal");
   }
}
