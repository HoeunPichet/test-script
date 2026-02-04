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
input int    MaxOpenPositions       = 10;      // REDUCED for better win rate focus
input int    MaxTradesPerDay        = 100;     // REDUCED for quality over quantity
input int    MinBarsBetweenEntries  = 2;      // Minimum bars between entries (prevents overtrading)
input bool   RequirePositiveWinRate = true;   // Only trade when win rate > loss rate
input int    MinTradesForWinRate    = 10;     // Minimum trades before checking win rate

// Strategy (FAST for M1)
input int    EMAPeriod              = 50;
input int    RSIPeriod              = 7;
input double RSI_BuyLevel           = 45;
input double RSI_SellLevel          = 55;
input bool   UseMomentumFilter      = true;   // Require momentum confirmation
input int    MomentumBars          = 3;      // Bars to check for momentum

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
input bool UseFastLossClose         = true;   // Close losing trades faster
input int  MaxLossHoldMinutes       = 5;      // Max minutes to hold losing trade
input double MaxLossPercent         = -0.5;   // Close if loss exceeds this % of trade risk

// ---------------- GLOBALS ----------------
int hATR, hEMA, hRSI;
datetime lastBarTime = 0;
int tradesToday = 0;
double dayStartBalance = 0;
int dayOfYear = -1;

// Win/Loss tracking
int totalWins = 0;
int totalLosses = 0;
datetime lastEntryTime = 0;  // Track last entry time for MinBarsBetweenEntries

// ---------------- UTILS ----------------
void Status(string s)
{
   if(ShowStatusOnChart)
   {
      double winRate = (totalWins + totalLosses > 0) ? ((double)totalWins / (double)(totalWins + totalLosses)) * 100.0 : 0.0;
      Comment("LowRiskEA M1 FAST CLOSE\n",
              _Symbol,"  ", EnumToString(_Period), "\n",
              "Status: ", s, "\n",
              "TradesToday: ", tradesToday, " | Positions: ", CountMyPositions(), "/", MaxOpenPositions, "\n",
              "Win Rate: ", DoubleToString(winRate, 1), "% (W:", totalWins, " L:", totalLosses, ")\n",
              "Spread(points): ", (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
   }
}

// Load win/loss stats from history (on initialization)
void LoadWinLossStats()
{
   totalWins = 0;
   totalLosses = 0;
   
   datetime startTime = TimeCurrent() - PeriodSeconds(PERIOD_D1) * 30; // Last 30 days
   HistorySelect(startTime, TimeCurrent());
   
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      
      string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
      long dealMagic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      
      if(dealSymbol != _Symbol || dealMagic != (long)MagicNumber) continue;
      
      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(dealEntry != DEAL_ENTRY_OUT) continue; // Only closing deals
      
      double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      double dealSwap = HistoryDealGetDouble(ticket, DEAL_SWAP);
      double dealCommission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      double totalProfit = dealProfit + dealSwap + dealCommission;
      
      if(totalProfit > 0)
         totalWins++;
      else if(totalProfit < 0)
         totalLosses++;
   }
   
   DPrint("Loaded stats: Wins=" + IntegerToString(totalWins) + " Losses=" + IntegerToString(totalLosses));
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
      DPrint("Lifetime stats: Wins=" + IntegerToString(totalWins) + " Losses=" + IntegerToString(totalLosses));
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

// Check if we have too many positions in same direction
int CountPositionsByType(long posType)
{
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(!PositionSelectByTicket(t)) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if((long)PositionGetInteger(POSITION_TYPE) == posType) c++;
   }
   return c;
}

// Check win rate requirement
bool IsWinRatePositive()
{
   if(!RequirePositiveWinRate) return true;
   
   int totalTrades = totalWins + totalLosses;
   if(totalTrades < MinTradesForWinRate) return true; // Allow trading until we have enough data
   
   return (totalWins > totalLosses);
}

// Check momentum (price moving in direction)
bool HasMomentum(bool isBuy)
{
   if(!UseMomentumFilter) return true;
   
   double close0 = iClose(_Symbol, _Period, 0);
   double close1 = iClose(_Symbol, _Period, 1);
   double close2 = iClose(_Symbol, _Period, MathMin(2, MomentumBars));
   
   if(isBuy)
   {
      // For buy: check if price is rising
      return (close0 > close1) && (close1 > close2);
   }
   else
   {
      // For sell: check if price is falling
      return (close0 < close1) && (close1 < close2);
   }
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

      // Fast loss close - exit losing trades quickly
      if(UseFastLossClose && profitMoney < 0.0)
      {
         int minutesOpen = (int)((TimeCurrent() - openTime) / 60);
         if(minutesOpen >= MaxLossHoldMinutes)
         {
            if(!trade.PositionClose(ticket))
               DPrint("FastLossClose failed: " + IntegerToString(trade.ResultRetcode()));
            else
            {
               DPrint("FastLossClose: Ticket=" + (string)ticket + " Loss=" + DoubleToString(profitMoney, 2));
               totalLosses++;
            }
            continue;
         }
         
         // Close if loss exceeds max loss percentage
         double slPrice = (sl > 0) ? sl : openPrice;
         double tradeRisk = MathAbs(openPrice - slPrice) / point;
         double riskAmount = dayStartBalance * (RiskPerTradePct / 100.0);
         double maxLossAmount = riskAmount * (MathAbs(MaxLossPercent) / 100.0);
         
         if(profitMoney <= -maxLossAmount)
         {
            if(!trade.PositionClose(ticket))
               DPrint("MaxLossClose failed: " + IntegerToString(trade.ResultRetcode()));
            else
            {
               DPrint("MaxLossClose: Ticket=" + (string)ticket + " Loss=" + DoubleToString(profitMoney, 2));
               totalLosses++;
            }
            continue;
         }
      }
      
      // Profit-only time close
      if(UseProfitTimeClose)
      {
         int minutesOpen = (int)((TimeCurrent() - openTime) / 60);
         if(minutesOpen >= MaxHoldMinutes && profitMoney > 0.0)
         {
            if(!trade.PositionClose(ticket))
               DPrint("TimeClose failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
            else
            {
               DPrint("TimeClose OK (profit-only). Ticket=" + (string)ticket);
               totalWins++;
            }
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
   LoadWinLossStats(); // Load historical win/loss stats
   
   DPrint("EA Initialized - MaxPositions: " + IntegerToString(MaxOpenPositions));
   DPrint("RequirePositiveWinRate: " + (RequirePositiveWinRate ? "YES" : "NO"));
   DPrint("UseMomentumFilter: " + (UseMomentumFilter ? "YES" : "NO"));
   DPrint("UseFastLossClose: " + (UseFastLossClose ? "YES" : "NO"));
   
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
   
   // Check win rate requirement
   if(!IsWinRatePositive())
   {
      double winRate = (totalWins + totalLosses > 0) ? ((double)totalWins / (double)(totalWins + totalLosses)) * 100.0 : 0.0;
      Status("STOP: Win rate negative (" + DoubleToString(winRate, 1) + "%)");
      return;
   }
   
   // Check minimum bars between entries
   if(MinBarsBetweenEntries > 0 && lastEntryTime > 0)
   {
      int barsSinceEntry = (int)((TimeCurrent() - lastEntryTime) / PeriodSeconds(_Period));
      if(barsSinceEntry < MinBarsBetweenEntries)
      {
         Status("WAIT: Min bars between entries (" + IntegerToString(barsSinceEntry) + "/" + IntegerToString(MinBarsBetweenEntries) + ")");
         return;
      }
   }

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

   // Enhanced entry signals with momentum filter
   bool buySignal  = (close0 > ema) && (rsi < RSI_BuyLevel);
   bool sellSignal = (close0 < ema) && (rsi > RSI_SellLevel);
   
   // Check momentum if enabled
   bool buy  = buySignal && HasMomentum(true);
   bool sell = sellSignal && HasMomentum(false);
   
   // Limit positions in same direction (diversification)
   int buyPositions = CountPositionsByType(POSITION_TYPE_BUY);
   int sellPositions = CountPositionsByType(POSITION_TYPE_SELL);
   int maxSameDirection = (int)(MaxOpenPositions * 0.6); // Max 60% in same direction
   
   if(buy && buyPositions >= maxSameDirection)
   {
      Status("WAIT: Too many BUY positions (" + IntegerToString(buyPositions) + ")");
      buy = false;
   }
   
   if(sell && sellPositions >= maxSameDirection)
   {
      Status("WAIT: Too many SELL positions (" + IntegerToString(sellPositions) + ")");
      sell = false;
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(buy)
   {
      bool ok = trade.Buy(lot, _Symbol, 0.0, ask - sl_dist, ask + sl_dist * TP_R_Mult, "M1 BUY");
      if(!ok) DPrint("BUY failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
      if(ok)
      {
         tradesToday++;
         lastEntryTime = TimeCurrent();
         Status("BUY opened (W:" + IntegerToString(totalWins) + " L:" + IntegerToString(totalLosses) + ")");
      }
      else Status("BUY failed (see Experts)");
   }
   else if(sell)
   {
      bool ok = trade.Sell(lot, _Symbol, 0.0, bid + sl_dist, bid - sl_dist * TP_R_Mult, "M1 SELL");
      if(!ok) DPrint("SELL failed: " + IntegerToString(trade.ResultRetcode()) + " | " + trade.ResultRetcodeDescription());
      if(ok)
      {
         tradesToday++;
         lastEntryTime = TimeCurrent();
         Status("SELL opened (W:" + IntegerToString(totalWins) + " L:" + IntegerToString(totalLosses) + ")");
      }
      else Status("SELL failed (see Experts)");
   }
   else
   {
      double winRate = (totalWins + totalLosses > 0) ? ((double)totalWins / (double)(totalWins + totalLosses)) * 100.0 : 0.0;
      Status("ACTIVE: No signal | WR:" + DoubleToString(winRate, 1) + "%");
   }
}

//+------------------------------------------------------------------+
//| Trade transaction handler to track wins/losses                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   
   if(!HistoryDealSelect(trans.deal)) return;
   
   string dealSymbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
   long dealMagic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   
   if(dealSymbol != _Symbol || dealMagic != (long)MagicNumber) return;
   
   ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(dealEntry != DEAL_ENTRY_OUT) return; // Only process closing deals
   
   double dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
   double dealSwap = HistoryDealGetDouble(trans.deal, DEAL_SWAP);
   double dealCommission = HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   double totalProfit = dealProfit + dealSwap + dealCommission;
   
   // Track wins/losses (only if not already tracked in ManageMyPositions)
   // This is a backup tracking mechanism
   if(totalProfit > 0 && totalWins == 0 && totalLosses == 0)
   {
      // Initialize from history if first run
      LoadWinLossStats();
   }
}
