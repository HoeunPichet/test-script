//+------------------------------------------------------------------+
//|                                          EMA_Crossover_EA.mq5    |
//|                        Production-Ready MT5 Expert Advisor      |
//|                        With Comprehensive Risk Management        |
//+------------------------------------------------------------------+
#property copyright "MT5 EA"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>

//--- Input Parameters
input group "=== Risk Management ==="
input double   RiskPercent = 2.0;           // Risk per trade (% of balance)
input double   StopLossPips = 50.0;         // Stop Loss (pips)
input double   TakeProfitPips = 100.0;      // Take Profit (pips)
input int      MaxOpenTrades = 3;           // Maximum open trades
input double   MaxDailyLoss = 500.0;        // Maximum daily loss (account currency)
input double   MaxDailyLossPercent = 5.0;   // Maximum daily loss (% of equity)
input int      MaxDailyTrades = 10;         // Maximum trades per day
input int      MaxConsecutiveLosses = 3;    // Max consecutive losses per day
input bool     EnableKillSwitch = true;     // Enable global kill-switch

input group "=== Trading Strategy ==="
input int      FastEMA = 12;                // Fast EMA period
input int      SlowEMA = 26;                // Slow EMA period
input ENUM_APPLIED_PRICE PriceType = PRICE_CLOSE; // Applied price

input group "=== Trade Management ==="
input bool     EnableTrailingStop = true;   // Enable Trailing Stop
input bool     UseATRTrailing = false;      // Use ATR-based trailing stop
input int      ATRPeriod = 14;              // ATR period for trailing stop
input double   ATRMultiplier = 2.0;         // ATR multiplier for trailing distance
input double   TrailingStopPips = 30.0;     // Trailing Stop distance (pips)
input double   TrailingStepPips = 10.0;     // Trailing Stop step (pips)
input bool     EnableBreakEven = true;      // Enable Break-Even
input double   BreakEvenPips = 20.0;        // Break-Even trigger (pips profit)
input double   BreakEvenOffsetPips = 5.0;   // Break-Even offset from entry

input group "=== Trading Hours ==="
input int      TradingStartHour = 0;        // Trading start hour (0-23)
input int      TradingEndHour = 23;         // Trading end hour (0-23)
input bool     TradeOnFriday = true;        // Allow trading on Friday

input group "=== Safety Settings ==="
input double   MaxSpreadPips = 5.0;         // Maximum spread (pips)
input int      SlippagePoints = 10;         // Maximum slippage (points)

//--- Global Variables
CTrade         trade;
CPositionInfo  position;
CAccountInfo   account;
CDealInfo      deal;

int            fastEMAHandle;
int            slowEMAHandle;
double         fastEMABuffer[];
double         slowEMABuffer[];

int            atrHandle = INVALID_HANDLE;
double         atrBuffer[];

datetime       lastBarTime = 0;
double         initialBalance = 0;
double         initialEquity = 0;
double         dailyProfit = 0;
int            dailyTrades = 0;
int            consecutiveLosses = 0;
datetime       lastTradeDate = 0;
bool           tradingDisabled = false;     // Global kill-switch flag
string         globalVarPrefix = "EA_Stats_"; // Prefix for GlobalVariables

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set trade parameters
   trade.SetExpertMagicNumber(123456);
   trade.SetDeviationInPoints(SlippagePoints);
   
   //--- Auto-detect broker's filling mode
   int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      trade.SetTypeFilling(ORDER_FILLING_RETURN);
   
   trade.SetAsyncMode(false);
   
   //--- Initialize indicators
   fastEMAHandle = iMA(_Symbol, PERIOD_CURRENT, FastEMA, 0, MODE_EMA, PriceType);
   slowEMAHandle = iMA(_Symbol, PERIOD_CURRENT, SlowEMA, 0, MODE_EMA, PriceType);
   
   if(fastEMAHandle == INVALID_HANDLE || slowEMAHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles");
      return(INIT_FAILED);
   }
   
   //--- Initialize ATR if ATR-based trailing is enabled
   if(UseATRTrailing)
   {
      atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
      if(atrHandle == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create ATR indicator handle");
         return(INIT_FAILED);
      }
      ArraySetAsSeries(atrBuffer, true);
   }
   
   //--- Set array as series
   ArraySetAsSeries(fastEMABuffer, true);
   ArraySetAsSeries(slowEMABuffer, true);
   
   //--- Initialize tracking variables
   initialBalance = account.Balance();
   initialEquity = account.Equity();
   dailyProfit = 0;
   dailyTrades = 0;
   consecutiveLosses = 0;
   lastTradeDate = 0;
   tradingDisabled = false;
   
   //--- Load persisted daily statistics from GlobalVariables
   LoadDailyStatistics();
   
   //--- Validate inputs
   if(RiskPercent <= 0 || RiskPercent > 100)
   {
      Print("ERROR: RiskPercent must be between 0 and 100");
      return(INIT_FAILED);
   }
   
   if(StopLossPips <= 0 || TakeProfitPips <= 0)
   {
      Print("ERROR: StopLoss and TakeProfit must be greater than 0");
      return(INIT_FAILED);
   }
   
   if(MaxOpenTrades <= 0)
   {
      Print("ERROR: MaxOpenTrades must be greater than 0");
      return(INIT_FAILED);
   }
   
   Print("EA initialized successfully");
   Print("Risk per trade: ", RiskPercent, "%");
   Print("Stop Loss: ", StopLossPips, " pips");
   Print("Take Profit: ", TakeProfitPips, " pips");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Save daily statistics to GlobalVariables
   SaveDailyStatistics();
   
   //--- Release indicator handles
   if(fastEMAHandle != INVALID_HANDLE)
      IndicatorRelease(fastEMAHandle);
   if(slowEMAHandle != INVALID_HANDLE)
      IndicatorRelease(slowEMAHandle);
   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
   
   Print("EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check if new bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool isNewBar = (currentBarTime != lastBarTime);
   
   if(isNewBar)
   {
      lastBarTime = currentBarTime;
      ResetDailyCounters();
   }
   
   //--- Update daily profit tracking
   UpdateDailyProfit();
   
   //--- Safety checks
   if(!IsTradingAllowed())
      return;
   
   if(IsDailyLossExceeded())
   {
      CloseAllPositions();
      return;
   }
   
   if(IsMaxConsecutiveLossesExceeded())
      return;
   
   //--- Copy indicator data
   if(CopyBuffer(fastEMAHandle, 0, 0, 3, fastEMABuffer) <= 0 ||
      CopyBuffer(slowEMAHandle, 0, 0, 3, slowEMABuffer) <= 0)
   {
      Print("ERROR: Failed to copy indicator buffers");
      return;
   }
   
   //--- Copy ATR data if ATR-based trailing is enabled
   if(UseATRTrailing && atrHandle != INVALID_HANDLE)
   {
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) <= 0)
      {
         Print("WARNING: Failed to copy ATR buffer");
      }
   }
   
   //--- Manage existing positions
   ManageOpenPositions();
   
   //--- Check for new trading signals (only on new bar to prevent duplicates)
   if(isNewBar)
   {
      CheckTradingSignals();
   }
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   //--- Check global kill-switch
   if(EnableKillSwitch && tradingDisabled)
   {
      Print("Trading blocked: Global kill-switch is active");
      return false;
   }
   
   //--- Check symbol trading permissions
   if(!IsSymbolTradable())
   {
      Print("Trading blocked: Symbol trading not allowed");
      return false;
   }
   
   //--- Check trading hours
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(!TradeOnFriday && dt.day_of_week == 5)
      return false;
   
   int currentHour = dt.hour;
   if(TradingStartHour <= TradingEndHour)
   {
      if(currentHour < TradingStartHour || currentHour >= TradingEndHour)
         return false;
   }
   else // Trading session spans midnight
   {
      if(currentHour < TradingStartHour && currentHour >= TradingEndHour)
         return false;
   }
   
   //--- Check spread
   double spread = GetSpreadInPips();
   if(spread > MaxSpreadPips)
   {
      Print("Trading blocked: Spread too high (", spread, " pips)");
      return false;
   }
   
   //--- Check maximum open trades
   if(CountOpenPositions() >= MaxOpenTrades)
      return false;
   
   //--- Check daily trade limit
   if(dailyTrades >= MaxDailyTrades)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check for trading signals                                        |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
   //--- EMA Crossover Strategy
   // Buy signal: Fast EMA crosses above Slow EMA
   // Sell signal: Fast EMA crosses below Slow EMA
   
   double fastEMA0 = fastEMABuffer[0];
   double fastEMA1 = fastEMABuffer[1];
   double slowEMA0 = slowEMABuffer[0];
   double slowEMA1 = slowEMABuffer[1];
   
   //--- Buy signal: Fast EMA crosses above Slow EMA
   if(fastEMA1 <= slowEMA1 && fastEMA0 > slowEMA0)
   {
      OpenBuyOrder();
   }
   
   //--- Sell signal: Fast EMA crosses below Slow EMA
   if(fastEMA1 >= slowEMA1 && fastEMA0 < slowEMA0)
   {
      OpenSellOrder();
   }
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
   //--- Calculate lot size
   double lotSize = CalculateLotSize(StopLossPips);
   if(lotSize <= 0)
   {
      Print("ERROR: Invalid lot size calculated");
      return;
   }
   
   //--- Normalize lot size
   lotSize = NormalizeLotSize(lotSize);
   
   //--- Get current price
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   //--- Calculate SL and TP in price
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double stopLoss = ask - StopLossPips * GetPipValue();
   double takeProfit = ask + TakeProfitPips * GetPipValue();
   
   //--- Normalize prices
   stopLoss = NormalizeDouble(stopLoss, digits);
   takeProfit = NormalizeDouble(takeProfit, digits);
   
   //--- Validate SL and TP
   if(stopLoss >= ask || takeProfit <= ask)
   {
      Print("ERROR: Invalid SL/TP levels");
      return;
   }
   
   //--- Open buy order with retry logic (max 2 retries)
   bool orderOpened = false;
   int retryCount = 0;
   int maxRetries = 2;
   
   while(!orderOpened && retryCount <= maxRetries)
   {
      //--- Refresh prices before retry
      if(retryCount > 0)
      {
         ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         stopLoss = ask - StopLossPips * GetPipValue();
         takeProfit = ask + TakeProfitPips * GetPipValue();
         stopLoss = NormalizeDouble(stopLoss, digits);
         takeProfit = NormalizeDouble(takeProfit, digits);
         Sleep(100); // Small delay before retry
      }
      
      //--- Check slippage before opening
      double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double slippagePoints = MathAbs(currentAsk - ask) / point;
      
      if(slippagePoints > SlippagePoints)
      {
         Print("WARNING: Slippage too high (", slippagePoints, " points). Retrying...");
         retryCount++;
         continue;
      }
      
      orderOpened = trade.Buy(lotSize, _Symbol, ask, stopLoss, takeProfit, "EMA Crossover Buy");
      
      if(orderOpened)
      {
         Print("BUY order opened: Lots=", lotSize, " Price=", ask, " SL=", stopLoss, " TP=", takeProfit);
         dailyTrades++;
         SaveDailyStatistics(); // Persist immediately
      }
      else
      {
         int errorCode = GetLastError();
         Print("ERROR: Failed to open BUY order (attempt ", retryCount + 1, "). Error code: ", errorCode);
         retryCount++;
      }
   }
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
   //--- Calculate lot size
   double lotSize = CalculateLotSize(StopLossPips);
   if(lotSize <= 0)
   {
      Print("ERROR: Invalid lot size calculated");
      return;
   }
   
   //--- Normalize lot size
   lotSize = NormalizeLotSize(lotSize);
   
   //--- Get current price
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   //--- Calculate SL and TP in price
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double stopLoss = bid + StopLossPips * GetPipValue();
   double takeProfit = bid - TakeProfitPips * GetPipValue();
   
   //--- Normalize prices
   stopLoss = NormalizeDouble(stopLoss, digits);
   takeProfit = NormalizeDouble(takeProfit, digits);
   
   //--- Validate SL and TP
   if(stopLoss <= bid || takeProfit >= bid)
   {
      Print("ERROR: Invalid SL/TP levels");
      return;
   }
   
   //--- Open sell order with retry logic (max 2 retries)
   bool orderOpened = false;
   int retryCount = 0;
   int maxRetries = 2;
   
   while(!orderOpened && retryCount <= maxRetries)
   {
      //--- Refresh prices before retry
      if(retryCount > 0)
      {
         ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         stopLoss = bid + StopLossPips * GetPipValue();
         takeProfit = bid - TakeProfitPips * GetPipValue();
         stopLoss = NormalizeDouble(stopLoss, digits);
         takeProfit = NormalizeDouble(takeProfit, digits);
         Sleep(100); // Small delay before retry
      }
      
      //--- Check slippage before opening
      double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double slippagePoints = MathAbs(currentBid - bid) / point;
      
      if(slippagePoints > SlippagePoints)
      {
         Print("WARNING: Slippage too high (", slippagePoints, " points). Retrying...");
         retryCount++;
         continue;
      }
      
      orderOpened = trade.Sell(lotSize, _Symbol, bid, stopLoss, takeProfit, "EMA Crossover Sell");
      
      if(orderOpened)
      {
         Print("SELL order opened: Lots=", lotSize, " Price=", bid, " SL=", stopLoss, " TP=", takeProfit);
         dailyTrades++;
         SaveDailyStatistics(); // Persist immediately
      }
      else
      {
         int errorCode = GetLastError();
         Print("ERROR: Failed to open SELL order (attempt ", retryCount + 1, "). Error code: ", errorCode);
         retryCount++;
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPips)
{
   double accountBalance = account.Balance();
   double riskAmount = accountBalance * RiskPercent / 100.0;
   
   //--- Get symbol properties
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipValue = GetPipValue();
   
   //--- Calculate stop loss in points
   double stopLossPoints = stopLossPips * (pipValue / point);
   
   //--- Calculate risk per lot
   double riskPerLot = (stopLossPoints * tickValue) / tickSize;
   
   if(riskPerLot <= 0)
   {
      Print("ERROR: Invalid risk per lot calculation");
      return 0;
   }
   
   //--- Calculate lot size
   double lotSize = riskAmount / riskPerLot;
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker requirements                       |
//+------------------------------------------------------------------+
double NormalizeLotSize(double lots)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(lots < minLot)
      return 0;
   if(lots > maxLot)
      lots = maxLot;
   
   //--- Round to step
   lots = MathFloor(lots / stepLot) * stepLot;
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Get pip value for current symbol                                |
//+------------------------------------------------------------------+
double GetPipValue()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   //--- For 3 and 5 digit brokers, pip = 10 * point
   if(digits == 3 || digits == 5)
      return point * 10;
   else
      return point;
}

//+------------------------------------------------------------------+
//| Get spread in pips                                              |
//+------------------------------------------------------------------+
double GetSpreadInPips()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = ask - bid;
   double pipValue = GetPipValue();
   
   return spread / pipValue;
}

//+------------------------------------------------------------------+
//| Check if symbol is tradable                                      |
//+------------------------------------------------------------------+
bool IsSymbolTradable()
{
   //--- Check if symbol is visible and selectable
   if(!SymbolInfoInteger(_Symbol, SYMBOL_SELECT))
      return false;
   
   //--- Check trading mode (0 = no trading, 1 = long only, 2 = short only, 4 = both)
   long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED)
      return false;
   
   //--- Check if market is currently open for trading
   long tradeModeEx = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE_EX);
   if(tradeModeEx == SYMBOL_TRADE_MODE_EX_DISABLED)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Load daily statistics from GlobalVariables                      |
//+------------------------------------------------------------------+
void LoadDailyStatistics()
{
   string varName = globalVarPrefix + _Symbol + "_" + IntegerToString(trade.GetExpertMagicNumber());
   string dateStr = TimeToString(TimeCurrent(), TIME_DATE);
   string fullVarName = varName + "_" + dateStr;
   
   //--- Load daily trades count
   if(GlobalVariableCheck(fullVarName + "_Trades"))
   {
      dailyTrades = (int)GlobalVariableGet(fullVarName + "_Trades");
   }
   
   //--- Load consecutive losses
   if(GlobalVariableCheck(fullVarName + "_ConsecutiveLosses"))
   {
      consecutiveLosses = (int)GlobalVariableGet(fullVarName + "_ConsecutiveLosses");
   }
   
   //--- Load trading disabled flag
   if(GlobalVariableCheck(fullVarName + "_Disabled"))
   {
      tradingDisabled = (bool)GlobalVariableGet(fullVarName + "_Disabled");
      if(tradingDisabled)
         Print("WARNING: Trading was disabled from previous session");
   }
}

//+------------------------------------------------------------------+
//| Save daily statistics to GlobalVariables                        |
//+------------------------------------------------------------------+
void SaveDailyStatistics()
{
   string varName = globalVarPrefix + _Symbol + "_" + IntegerToString(trade.GetExpertMagicNumber());
   string dateStr = TimeToString(TimeCurrent(), TIME_DATE);
   string fullVarName = varName + "_" + dateStr;
   
   //--- Save daily statistics
   GlobalVariableSet(fullVarName + "_Trades", dailyTrades);
   GlobalVariableSet(fullVarName + "_ConsecutiveLosses", consecutiveLosses);
   GlobalVariableSet(fullVarName + "_Disabled", tradingDisabled ? 1.0 : 0.0);
   GlobalVariableSet(fullVarName + "_DailyProfit", dailyProfit);
   
   //--- Set expiration to 2 days (cleanup old variables)
   GlobalVariableSetOnCondition(fullVarName + "_Trades", dailyTrades, 0);
   GlobalVariableSetOnCondition(fullVarName + "_ConsecutiveLosses", consecutiveLosses, 0);
   GlobalVariableSetOnCondition(fullVarName + "_Disabled", tradingDisabled ? 1.0 : 0.0, 0);
   GlobalVariableSetOnCondition(fullVarName + "_DailyProfit", dailyProfit, 0);
}

//+------------------------------------------------------------------+
//| Count open positions                                             |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == trade.GetExpertMagicNumber())
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, break-even)               |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!position.SelectByIndex(i))
         continue;
      
      if(position.Symbol() != _Symbol || position.Magic() != trade.GetExpertMagicNumber())
         continue;
      
      double positionOpenPrice = position.PriceOpen();
      double currentSL = position.StopLoss();
      double currentTP = position.TakeProfit();
      ulong ticket = position.Ticket();
      
      double currentPrice = (position.PositionType() == POSITION_TYPE_BUY) ? 
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double pipValue = GetPipValue();
      double profitInPips = 0;
      
      if(position.PositionType() == POSITION_TYPE_BUY)
      {
         profitInPips = (currentPrice - positionOpenPrice) / pipValue;
      }
      else // SELL
      {
         profitInPips = (positionOpenPrice - currentPrice) / pipValue;
      }
      
      //--- Break-Even logic
      if(EnableBreakEven && profitInPips >= BreakEvenPips)
      {
         double newSL = positionOpenPrice;
         if(position.PositionType() == POSITION_TYPE_BUY)
            newSL += BreakEvenOffsetPips * pipValue;
         else
            newSL -= BreakEvenOffsetPips * pipValue;
         
         newSL = NormalizeDouble(newSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
         
         //--- Only modify if new SL is better than current
         bool shouldModify = false;
         if(position.PositionType() == POSITION_TYPE_BUY)
         {
            if(currentSL == 0 || newSL > currentSL)
               shouldModify = true;
         }
         else
         {
            if(currentSL == 0 || newSL < currentSL)
               shouldModify = true;
         }
         
         if(shouldModify)
         {
            trade.PositionModify(ticket, newSL, currentTP);
         }
      }
      
      //--- Trailing Stop logic
      if(EnableTrailingStop)
      {
         double trailingDistance = 0;
         
         //--- Use ATR-based trailing if enabled
         if(UseATRTrailing && atrHandle != INVALID_HANDLE)
         {
            if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0)
            {
               trailingDistance = atrBuffer[0] * ATRMultiplier;
            }
            else
            {
               //--- Fallback to pip-based if ATR fails
               trailingDistance = TrailingStopPips * pipValue;
            }
         }
         else
         {
            //--- Use pip-based trailing
            trailingDistance = TrailingStopPips * pipValue;
         }
         
         //--- Only activate trailing if position is in profit
         double minProfitForTrailing = trailingDistance;
         if(UseATRTrailing)
            minProfitForTrailing = trailingDistance;
         else
            minProfitForTrailing = TrailingStopPips * pipValue;
         
         if(profitInPips * pipValue > minProfitForTrailing)
         {
            double newSL = 0;
            bool shouldModify = false;
            
            if(position.PositionType() == POSITION_TYPE_BUY)
            {
               newSL = currentPrice - trailingDistance;
               newSL = NormalizeDouble(newSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
               
               double stepDistance = UseATRTrailing ? (trailingDistance * 0.3) : (TrailingStepPips * pipValue);
               if(currentSL == 0 || newSL > currentSL + stepDistance)
                  shouldModify = true;
            }
            else // SELL
            {
               newSL = currentPrice + trailingDistance;
               newSL = NormalizeDouble(newSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
               
               double stepDistance = UseATRTrailing ? (trailingDistance * 0.3) : (TrailingStepPips * pipValue);
               if(currentSL == 0 || newSL < currentSL - stepDistance)
                  shouldModify = true;
            }
            
            if(shouldModify)
            {
               trade.PositionModify(ticket, newSL, currentTP);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if daily loss exceeded                                    |
//+------------------------------------------------------------------+
bool IsDailyLossExceeded()
{
   //--- Check absolute daily loss limit
   if(dailyProfit <= -MaxDailyLoss)
   {
      Print("WARNING: Daily loss limit exceeded (", dailyProfit, ")");
      if(EnableKillSwitch)
         tradingDisabled = true;
      return true;
   }
   
   //--- Check equity-based daily loss limit
   double currentEquity = account.Equity();
   double equityLoss = initialEquity - currentEquity;
   double equityLossPercent = (equityLoss / initialEquity) * 100.0;
   
   if(equityLossPercent >= MaxDailyLossPercent)
   {
      Print("WARNING: Daily equity loss limit exceeded (", equityLossPercent, "%)");
      if(EnableKillSwitch)
         tradingDisabled = true;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if max consecutive losses exceeded                        |
//+------------------------------------------------------------------+
bool IsMaxConsecutiveLossesExceeded()
{
   if(consecutiveLosses >= MaxConsecutiveLosses)
   {
      Print("WARNING: Maximum consecutive losses reached (", consecutiveLosses, ")");
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update daily profit tracking                                    |
//+------------------------------------------------------------------+
void UpdateDailyProfit()
{
   //--- Calculate daily profit from balance change
   double currentBalance = account.Balance();
   dailyProfit = currentBalance - initialBalance;
}

//+------------------------------------------------------------------+
//| Reset daily counters                                            |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime currentDate = StringToTime(IntegerToString(dt.year) + "." + 
                                      IntegerToString(dt.mon) + "." + 
                                      IntegerToString(dt.day));
   
   if(currentDate != lastTradeDate)
   {
      //--- Save previous day's statistics before reset
      if(lastTradeDate != 0)
         SaveDailyStatistics();
      
      initialBalance = account.Balance();
      initialEquity = account.Equity();
      dailyProfit = 0;
      dailyTrades = 0;
      consecutiveLosses = 0;
      lastTradeDate = currentDate;
      
      //--- Reset kill-switch at start of new day
      if(EnableKillSwitch)
         tradingDisabled = false;
      
      Print("Daily counters reset. New trading day started.");
   }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == trade.GetExpertMagicNumber())
         {
            trade.PositionClose(position.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                  |
//| Tracks closed positions to update consecutive losses             |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   //--- Only process deal events
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   
   //--- Select deal
   if(!HistoryDealSelect(trans.deal))
      return;
   
   if(!deal.Ticket(trans.deal))
      return;
   
   //--- Check if this is our EA's deal
   if(deal.Symbol() != _Symbol || deal.Magic() != trade.GetExpertMagicNumber())
      return;
   
   //--- Only process position closing deals
   if(deal.Entry() == DEAL_ENTRY_OUT)
   {
      //--- Check if this deal closed today
      MqlDateTime dt;
      TimeToStruct(deal.Time(), dt);
      datetime dealDate = StringToTime(IntegerToString(dt.year) + "." + 
                                      IntegerToString(dt.mon) + "." + 
                                      IntegerToString(dt.day));
      
      if(dealDate == lastTradeDate)
      {
         //--- Update consecutive losses
         double dealProfit = deal.Profit() + deal.Swap() + deal.Commission();
         if(dealProfit < 0)
         {
            consecutiveLosses++;
            Print("Consecutive losses: ", consecutiveLosses);
         }
         else
         {
            consecutiveLosses = 0; // Reset on profit
         }
         
         //--- Persist statistics after each closed trade
         SaveDailyStatistics();
      }
   }
}

//+------------------------------------------------------------------+

