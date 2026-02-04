//+------------------------------------------------------------------+
//|                                           SmartMomentumEA.mq5     |
//|                                   High Win Rate Momentum System   |
//|                                                                    |
//| Strategy: Buy when price tries to go up, Sell when tries to down |
//| Entry: Bullish/Bearish momentum with confirmation                 |
//| Risk Management: Fixed risk per trade, proper SL/TP               |
//+------------------------------------------------------------------+
#property copyright "Smart Trading System"
#property version   "1.00"
#property strict

//--- Input Parameters
//=== GENERAL SETTINGS ===
input group "=== GENERAL CONTROL ==="
input bool     MasterEnableTrading = true;           // Master Enable Trading
input string   InpLicenseKey = "";                   // License Key (if needed)

//=== RISK MANAGEMENT ===
input group "=== RISK MANAGEMENT ==="
input double   RiskPercent = 1.0;                    // Risk Per Trade (%)
input double   MaxDailyRisk = 3.0;                   // Max Daily Risk (%)
input double   MaxOpenRisk = 5.0;                    // Max Total Open Risk (%)
input int      MaxConcurrentTrades = 3;              // Max Concurrent Trades
input double   MinRiskRewardRatio = 1.5;             // Min Risk:Reward Ratio

//=== ENTRY STRATEGY ===
input group "=== MOMENTUM ENTRY SETTINGS ==="
input bool     UseMultiConfirmation = true;          // Use Multi-Timeframe Confirmation
input int      MomentumPeriod = 14;                  // Momentum Period (bars)
input double   MinMomentumStrength = 60.0;           // Min Momentum Strength (0-100)
input int      ConfirmationCandles = 2;              // Candles for Confirmation

//=== CANDLESTICK PATTERN DETECTION ===
input group "=== CANDLESTICK PATTERNS ==="
input bool     UseBullishEngulfing = true;           // Detect Bullish Engulfing
input bool     UseBearishEngulfing = true;           // Detect Bearish Engulfing
input bool     UsePinBar = true;                     // Detect Pin Bars
input bool     UseInsideBar = true;                  // Detect Inside Bars (continuation)
input double   PinBarRatio = 2.5;                    // Pin Bar Body:Wick Ratio

//=== TREND FILTER ===
input group "=== TREND FILTER ==="
input bool     UseTrendFilter = true;                // Enable Trend Filter
input int      TrendMA_Fast = 20;                    // Fast MA Period
input int      TrendMA_Slow = 50;                    // Slow MA Period
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;    // Trend Timeframe

//=== ADX FILTER (Trend Strength) ===
input group "=== ADX FILTER ==="
input bool     UseADXFilter = true;                  // Enable ADX Filter
input int      ADXPeriod = 14;                       // ADX Period
input double   MinADX = 20.0;                        // Min ADX Value (trend strength)

//=== RSI FILTER (Overbought/Oversold) ===
input group "=== RSI FILTER ==="
input bool     UseRSIFilter = true;                  // Enable RSI Filter
input int      RSIPeriod = 14;                       // RSI Period
input double   RSI_Overbought = 70.0;                // RSI Overbought Level
input double   RSI_Oversold = 30.0;                  // RSI Oversold Level
input bool     RSI_AllowExtreme = false;             // Allow entries in extreme zones

//--- Enums (must be declared before input parameters that use them)
enum ENUM_SL_MODE
{
   SL_FIXED,      // Fixed Pips
   SL_ATR,        // ATR Based
   SL_SWING       // Swing High/Low
};

//=== STOP LOSS & TAKE PROFIT ===
input group "=== SL & TP SETTINGS ==="
input ENUM_SL_MODE StopLossMode = SL_ATR;           // Stop Loss Mode
input double   FixedSL_Pips = 50.0;                  // Fixed SL (pips)
input int      ATR_Period = 14;                      // ATR Period for SL/TP
input double   ATR_SL_Multiplier = 2.0;              // ATR Multiplier for SL
input double   ATR_TP_Multiplier = 3.0;              // ATR Multiplier for TP
input int      SwingLookback = 20;                   // Swing High/Low Lookback

//=== TRAILING STOP ===
input group "=== TRAILING STOP ==="
input bool     UseTrailingStop = true;               // Enable Trailing Stop
input double   TrailingStart_Pips = 20.0;            // Start Trailing at (pips profit)
input double   TrailingStop_Pips = 15.0;             // Trailing Stop Distance (pips)
input double   TrailingStep_Pips = 5.0;              // Trailing Step (pips)

//=== BREAK EVEN ===
input group "=== BREAK EVEN ==="
input bool     UseBreakEven = true;                  // Move to Break Even
input double   BreakEven_Pips = 15.0;                // Activate at profit (pips)
input double   BreakEven_Plus = 2.0;                 // Lock profit (pips)

//=== TIME FILTER ===
input group "=== SESSION FILTER ==="
input bool     EnableSessionFilter = true;           // Enable Session Filter
input bool     TradeAsianSession = true;             // Trade Asian Session
input string   AsianSession = "00:00-08:00";         // Asian Session (Broker Time)
input bool     TradeLondonSession = true;            // Trade London Session
input string   LondonSession = "08:00-16:00";        // London Session (Broker Time)
input bool     TradeNYSession = true;                // Trade NY Session
input string   NYSession = "13:00-22:00";            // NY Session (Broker Time)

//=== TRADING DIRECTION ===
input group "=== TRADING DIRECTION ==="
input bool     EnableBuy = true;                     // Enable Buy Orders
input bool     EnableSell = true;                    // Enable Sell Orders
input int      BuyMagicNumber = 10001;               // Buy Magic Number
input int      SellMagicNumber = 10002;              // Sell Magic Number

//=== SPREAD FILTER ===
input group "=== SPREAD FILTER ==="
input bool     EnableSpreadFilter = true;            // Enable Spread Filter
input double   MaxSpreadPips = 3.0;                  // Max Spread (pips)

//=== NEWS FILTER ===
input group "=== VOLATILITY/NEWS FILTER ==="
input bool     PauseOnHighVolatility = true;         // Pause on High Volatility
input double   VolatilityThreshold = 1.5;            // Volatility Multiplier Threshold

//--- Global Variables
int handleMA_Fast, handleMA_Slow, handleADX, handleRSI, handleATR;
double dailyProfit = 0.0;
datetime lastDayCheck = 0;
double accountBalance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Initialize indicators
   handleMA_Fast = iMA(_Symbol, TrendTimeframe, TrendMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_Slow = iMA(_Symbol, TrendTimeframe, TrendMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   handleADX = iADX(_Symbol, PERIOD_CURRENT, ADXPeriod);
   handleRSI = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE);
   handleATR = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   
   if(handleMA_Fast == INVALID_HANDLE || handleMA_Slow == INVALID_HANDLE ||
      handleADX == INVALID_HANDLE || handleRSI == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Error creating indicators");
      return(INIT_FAILED);
   }
   
   accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   Print("Smart Momentum EA Initialized Successfully");
   Print("Risk Per Trade: ", RiskPercent, "%");
   Print("Min Risk:Reward: 1:", MinRiskRewardRatio);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handles
   IndicatorRelease(handleMA_Fast);
   IndicatorRelease(handleMA_Slow);
   IndicatorRelease(handleADX);
   IndicatorRelease(handleRSI);
   IndicatorRelease(handleATR);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check if trading is enabled
   if(!MasterEnableTrading) return;
   
   //--- Check new bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(currentBarTime == lastBarTime) return; // Wait for new bar
   lastBarTime = currentBarTime;
   
   //--- Update daily profit tracking
   CheckDailyReset();
   
   //--- Risk management checks
   if(!PassesRiskManagement()) return;
   
   //--- Session filter
   if(EnableSessionFilter && !IsTradingSession()) return;
   
   //--- Spread filter
   if(EnableSpreadFilter && !PassesSpreadFilter()) return;
   
   //--- Volatility filter
   if(PauseOnHighVolatility && IsExtremeVolatility()) return;
   
   //--- Manage open positions
   ManageOpenPositions();
   
   //--- Check for entry signals
   int signal = GetEntrySignal();
   
   if(signal == 1 && EnableBuy)
   {
      OpenBuyOrder();
   }
   else if(signal == -1 && EnableSell)
   {
      OpenSellOrder();
   }
}

//+------------------------------------------------------------------+
//| Get Entry Signal                                                  |
//| Returns: 1 = Buy, -1 = Sell, 0 = No Signal                       |
//+------------------------------------------------------------------+
int GetEntrySignal()
{
   //--- 1. Check candlestick momentum
   int momentumSignal = CheckMomentum();
   if(momentumSignal == 0) return 0;
   
   //--- 2. Check candlestick patterns
   int patternSignal = CheckCandlestickPatterns();
   if(patternSignal != momentumSignal && patternSignal != 0) return 0;
   
   //--- 3. Trend filter
   if(UseTrendFilter)
   {
      int trendSignal = CheckTrendDirection();
      if(trendSignal != momentumSignal && trendSignal != 0) return 0;
   }
   
   //--- 4. ADX filter (trend strength)
   if(UseADXFilter)
   {
      if(!CheckADX()) return 0;
   }
   
   //--- 5. RSI filter
   if(UseRSIFilter)
   {
      int rsiSignal = CheckRSI();
      if(rsiSignal == -momentumSignal) return 0; // Opposite signal
   }
   
   //--- All filters passed
   return momentumSignal;
}

//+------------------------------------------------------------------+
//| Check Momentum (Price trying to go up or down)                   |
//+------------------------------------------------------------------+
int CheckMomentum()
{
   double closes[];
   ArraySetAsSeries(closes, true);
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, MomentumPeriod + 1, closes) <= 0) return 0;
   
   //--- Calculate momentum strength
   double priceChange = closes[0] - closes[MomentumPeriod];
   double volatility = 0;
   
   for(int i = 0; i < MomentumPeriod; i++)
   {
      volatility += MathAbs(closes[i] - closes[i+1]);
   }
   volatility /= MomentumPeriod;
   
   if(volatility == 0) return 0;
   
   double momentumStrength = (MathAbs(priceChange) / volatility) * 100.0;
   
   //--- Check momentum strength threshold
   if(momentumStrength < MinMomentumStrength) return 0;
   
   //--- Check recent candle confirmation
   int bullishCandles = 0;
   int bearishCandles = 0;
   
   for(int i = 1; i <= ConfirmationCandles; i++)
   {
      if(closes[i] > closes[i+1]) bullishCandles++;
      else bearishCandles++;
   }
   
   //--- Determine signal
   double requiredConfirmation = (double)ConfirmationCandles * 0.6;
   if(priceChange > 0 && bullishCandles >= (int)requiredConfirmation) return 1;  // Buy
   if(priceChange < 0 && bearishCandles >= (int)requiredConfirmation) return -1; // Sell
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check Candlestick Patterns                                        |
//+------------------------------------------------------------------+
int CheckCandlestickPatterns()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, 5, rates) <= 0) return 0;
   
   //--- Bullish Engulfing
   if(UseBullishEngulfing)
   {
      if(IsBullishEngulfing(rates))
         return 1;
   }
   
   //--- Bearish Engulfing
   if(UseBearishEngulfing)
   {
      if(IsBearishEngulfing(rates))
         return -1;
   }
   
   //--- Pin Bar
   if(UsePinBar)
   {
      int pinSignal = IsPinBar(rates);
      if(pinSignal != 0) return pinSignal;
   }
   
   //--- Inside Bar (continuation pattern)
   if(UseInsideBar)
   {
      int insideSignal = IsInsideBar(rates);
      if(insideSignal != 0) return insideSignal;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Bullish Engulfing Pattern                                         |
//+------------------------------------------------------------------+
bool IsBullishEngulfing(const MqlRates &rates[])
{
   double body1 = MathAbs(rates[2].close - rates[2].open);
   double body2 = MathAbs(rates[1].close - rates[1].open);
   
   if(rates[2].close < rates[2].open &&  // Previous bearish
      rates[1].close > rates[1].open &&  // Current bullish
      rates[1].open < rates[2].close &&  // Opens below previous close
      rates[1].close > rates[2].open &&  // Closes above previous open
      body2 > body1 * 1.2)               // Current body bigger
   {
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Bearish Engulfing Pattern                                         |
//+------------------------------------------------------------------+
bool IsBearishEngulfing(const MqlRates &rates[])
{
   double body1 = MathAbs(rates[2].close - rates[2].open);
   double body2 = MathAbs(rates[1].close - rates[1].open);
   
   if(rates[2].close > rates[2].open &&  // Previous bullish
      rates[1].close < rates[1].open &&  // Current bearish
      rates[1].open > rates[2].close &&  // Opens above previous close
      rates[1].close < rates[2].open &&  // Closes below previous open
      body2 > body1 * 1.2)               // Current body bigger
   {
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Pin Bar Pattern                                                   |
//+------------------------------------------------------------------+
int IsPinBar(const MqlRates &rates[])
{
   double body = MathAbs(rates[1].close - rates[1].open);
   double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
   double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
   double totalRange = rates[1].high - rates[1].low;
   
   if(totalRange == 0) return 0;
   
   //--- Bullish Pin Bar (long lower wick)
   if(lowerWick > body * PinBarRatio && 
      lowerWick > totalRange * 0.6 &&
      rates[1].close > rates[1].open)
   {
      return 1;
   }
   
   //--- Bearish Pin Bar (long upper wick)
   if(upperWick > body * PinBarRatio && 
      upperWick > totalRange * 0.6 &&
      rates[1].close < rates[1].open)
   {
      return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Inside Bar Pattern (continuation)                                 |
//+------------------------------------------------------------------+
int IsInsideBar(const MqlRates &rates[])
{
   //--- Current bar completely inside previous bar
   if(rates[1].high < rates[2].high && rates[1].low > rates[2].low)
   {
      //--- Bullish continuation
      if(rates[2].close > rates[2].open && rates[1].close > rates[1].open)
         return 1;
      
      //--- Bearish continuation
      if(rates[2].close < rates[2].open && rates[1].close < rates[1].open)
         return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check Trend Direction                                             |
//+------------------------------------------------------------------+
int CheckTrendDirection()
{
   double maFast[], maSlow[];
   ArraySetAsSeries(maFast, true);
   ArraySetAsSeries(maSlow, true);
   
   if(CopyBuffer(handleMA_Fast, 0, 0, 3, maFast) <= 0) return 0;
   if(CopyBuffer(handleMA_Slow, 0, 0, 3, maSlow) <= 0) return 0;
   
   //--- Uptrend
   if(maFast[0] > maSlow[0] && maFast[1] > maSlow[1])
      return 1;
   
   //--- Downtrend
   if(maFast[0] < maSlow[0] && maFast[1] < maSlow[1])
      return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check ADX (Trend Strength)                                        |
//+------------------------------------------------------------------+
bool CheckADX()
{
   double adxValue[];
   ArraySetAsSeries(adxValue, true);
   
   if(CopyBuffer(handleADX, 0, 0, 2, adxValue) <= 0) return false;
   
   return (adxValue[0] >= MinADX);
}

//+------------------------------------------------------------------+
//| Check RSI                                                         |
//+------------------------------------------------------------------+
int CheckRSI()
{
   double rsiValue[];
   ArraySetAsSeries(rsiValue, true);
   
   if(CopyBuffer(handleRSI, 0, 0, 2, rsiValue) <= 0) return 0;
   
   //--- Don't buy in overbought
   if(!RSI_AllowExtreme && rsiValue[0] > RSI_Overbought)
      return -1;
   
   //--- Don't sell in oversold
   if(!RSI_AllowExtreme && rsiValue[0] < RSI_Oversold)
      return 1;
   
   //--- RSI confirms buy
   if(rsiValue[0] < RSI_Overbought && rsiValue[0] > 50)
      return 1;
   
   //--- RSI confirms sell
   if(rsiValue[0] > RSI_Oversold && rsiValue[0] < 50)
      return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                    |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
   //--- Check if we already have a buy position
   if(CountPositions(BuyMagicNumber) > 0) return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = CalculateStopLoss(ORDER_TYPE_BUY, ask);
   double tp = CalculateTakeProfit(ORDER_TYPE_BUY, ask, sl);
   
   //--- Check Risk:Reward Ratio
   double slDistance = ask - sl;
   double tpDistance = tp - ask;
   
   if(slDistance == 0) return;
   
   double rrRatio = tpDistance / slDistance;
   if(rrRatio < MinRiskRewardRatio)
   {
      Print("Buy signal rejected: R:R ratio ", DoubleToString(rrRatio, 2), " < ", MinRiskRewardRatio);
      return;
   }
   
   //--- Calculate lot size based on risk
   double lotSize = CalculateLotSize(sl, ask);
   
   //--- Prepare trade request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = ask;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = BuyMagicNumber;
   request.comment = "Momentum Buy R:R=" + DoubleToString(rrRatio, 2);
   
   //--- Send order
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
      {
         Print("BUY order opened successfully. Ticket: ", result.order, 
               " | Lot: ", lotSize, " | SL: ", sl, " | TP: ", tp, " | R:R: ", rrRatio);
      }
      else
      {
         Print("BUY order failed. Error: ", result.retcode);
      }
   }
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                   |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
   //--- Check if we already have a sell position
   if(CountPositions(SellMagicNumber) > 0) return;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = CalculateStopLoss(ORDER_TYPE_SELL, bid);
   double tp = CalculateTakeProfit(ORDER_TYPE_SELL, bid, sl);
   
   //--- Check Risk:Reward Ratio
   double slDistance = sl - bid;
   double tpDistance = bid - tp;
   
   if(slDistance == 0) return;
   
   double rrRatio = tpDistance / slDistance;
   if(rrRatio < MinRiskRewardRatio)
   {
      Print("Sell signal rejected: R:R ratio ", DoubleToString(rrRatio, 2), " < ", MinRiskRewardRatio);
      return;
   }
   
   //--- Calculate lot size based on risk
   double lotSize = CalculateLotSize(sl, bid);
   
   //--- Prepare trade request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = bid;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = SellMagicNumber;
   request.comment = "Momentum Sell R:R=" + DoubleToString(rrRatio, 2);
   
   //--- Send order
   if(OrderSend(request, result))
   {
      if(result.retcode == TRADE_RETCODE_DONE)
      {
         Print("SELL order opened successfully. Ticket: ", result.order, 
               " | Lot: ", lotSize, " | SL: ", sl, " | TP: ", tp, " | R:R: ", rrRatio);
      }
      else
      {
         Print("SELL order failed. Error: ", result.retcode);
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                              |
//+------------------------------------------------------------------+
double CalculateStopLoss(ENUM_ORDER_TYPE orderType, double entryPrice)
{
   double sl = 0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   if(StopLossMode == SL_FIXED)
   {
      //--- Fixed pips
      if(orderType == ORDER_TYPE_BUY)
         sl = entryPrice - FixedSL_Pips * point * 10;
      else
         sl = entryPrice + FixedSL_Pips * point * 10;
   }
   else if(StopLossMode == SL_ATR)
   {
      //--- ATR based
      double atrValue[];
      ArraySetAsSeries(atrValue, true);
      if(CopyBuffer(handleATR, 0, 0, 1, atrValue) > 0)
      {
         double atr = atrValue[0] * ATR_SL_Multiplier;
         if(orderType == ORDER_TYPE_BUY)
            sl = entryPrice - atr;
         else
            sl = entryPrice + atr;
      }
   }
   else if(StopLossMode == SL_SWING)
   {
      //--- Swing high/low
      if(orderType == ORDER_TYPE_BUY)
      {
         double low = iLow(_Symbol, PERIOD_CURRENT, iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, SwingLookback, 1));
         sl = low - 5 * point;
      }
      else
      {
         double high = iHigh(_Symbol, PERIOD_CURRENT, iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, SwingLookback, 1));
         sl = high + 5 * point;
      }
   }
   
   return NormalizeDouble(sl, digits);
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_ORDER_TYPE orderType, double entryPrice, double stopLoss)
{
   double tp = 0;
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   if(StopLossMode == SL_ATR)
   {
      //--- ATR based TP
      double atrValue[];
      ArraySetAsSeries(atrValue, true);
      if(CopyBuffer(handleATR, 0, 0, 1, atrValue) > 0)
      {
         double atr = atrValue[0] * ATR_TP_Multiplier;
         if(orderType == ORDER_TYPE_BUY)
            tp = entryPrice + atr;
         else
            tp = entryPrice - atr;
      }
   }
   else
   {
      //--- Risk:Reward based TP
      double slDistance = MathAbs(entryPrice - stopLoss);
      double tpDistance = slDistance * MinRiskRewardRatio;
      
      if(orderType == ORDER_TYPE_BUY)
         tp = entryPrice + tpDistance;
      else
         tp = entryPrice - tpDistance;
   }
   
   return NormalizeDouble(tp, digits);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLoss, double entryPrice)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (RiskPercent / 100.0);
   
   double slDistance = MathAbs(entryPrice - stopLoss);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(slDistance == 0 || tickSize == 0) return 0;
   
   double lots = (riskMoney / (slDistance / tickSize * tickValue));
   
   //--- Normalize lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   
   return lots;
}

//+------------------------------------------------------------------+
//| Manage Open Positions (Trailing Stop, Break Even)                |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      int magic = (int)PositionGetInteger(POSITION_MAGIC);
      if(magic != BuyMagicNumber && magic != SellMagicNumber) continue;
      
      //--- Get position info
      double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSL = PositionGetDouble(POSITION_SL);
      double posTP = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                            SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                            SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      
      //--- Calculate profit in pips
      double profitPips = 0;
      if(posType == POSITION_TYPE_BUY)
         profitPips = (currentPrice - posOpenPrice) / (point * 10);
      else
         profitPips = (posOpenPrice - currentPrice) / (point * 10);
      
      //--- Break Even
      if(UseBreakEven && profitPips >= BreakEven_Pips)
      {
         double newSL = posOpenPrice + (BreakEven_Plus * point * 10) * ((posType == POSITION_TYPE_BUY) ? 1 : -1);
         
         if((posType == POSITION_TYPE_BUY && newSL > posSL) ||
            (posType == POSITION_TYPE_SELL && newSL < posSL))
         {
            ModifyPosition(ticket, newSL, posTP);
            Print("Break Even activated for ticket: ", ticket);
         }
      }
      
      //--- Trailing Stop
      if(UseTrailingStop && profitPips >= TrailingStart_Pips)
      {
         double newSL = 0;
         
         if(posType == POSITION_TYPE_BUY)
         {
            newSL = currentPrice - TrailingStop_Pips * point * 10;
            if(newSL > posSL + TrailingStep_Pips * point * 10)
            {
               ModifyPosition(ticket, NormalizeDouble(newSL, digits), posTP);
               Print("Trailing Stop updated for BUY ticket: ", ticket);
            }
         }
         else
         {
            newSL = currentPrice + TrailingStop_Pips * point * 10;
            if(newSL < posSL - TrailingStep_Pips * point * 10 || posSL == 0)
            {
               ModifyPosition(ticket, NormalizeDouble(newSL, digits), posTP);
               Print("Trailing Stop updated for SELL ticket: ", ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Modify Position                                                   |
//+------------------------------------------------------------------+
bool ModifyPosition(ulong ticket, double sl, double tp)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.sl = sl;
   request.tp = tp;
   
   return OrderSend(request, result);
}

//+------------------------------------------------------------------+
//| Count Positions by Magic Number                                  |
//+------------------------------------------------------------------+
int CountPositions(int magic)
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == magic)
      {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Risk Management Checks                                            |
//+------------------------------------------------------------------+
bool PassesRiskManagement()
{
   //--- Check max concurrent trades
   int totalPositions = CountPositions(BuyMagicNumber) + CountPositions(SellMagicNumber);
   if(totalPositions >= MaxConcurrentTrades)
   {
      return false;
   }
   
   //--- Check daily risk limit
   if(dailyProfit <= -MaxDailyRisk)
   {
      Print("Daily risk limit reached: ", dailyProfit, "%");
      return false;
   }
   
   //--- Check total open risk
   double totalRisk = totalPositions * RiskPercent;
   if(totalRisk >= MaxOpenRisk)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check Daily Reset                                                 |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime currentTime = TimeCurrent();
   MqlDateTime timeStruct;
   TimeToStruct(currentTime, timeStruct);
   
   MqlDateTime lastTimeStruct;
   TimeToStruct(lastDayCheck, lastTimeStruct);
   
   if(timeStruct.day != lastTimeStruct.day)
   {
      dailyProfit = 0;
      lastDayCheck = currentTime;
   }
   
   //--- Update daily profit
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   dailyProfit = ((currentBalance - accountBalance) / accountBalance) * 100.0;
}

//+------------------------------------------------------------------+
//| Session Filter                                                    |
//+------------------------------------------------------------------+
bool IsTradingSession()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   
   //--- Parse session times
   if(TradeAsianSession && IsInSession(AsianSession, currentMinutes)) return true;
   if(TradeLondonSession && IsInSession(LondonSession, currentMinutes)) return true;
   if(TradeNYSession && IsInSession(NYSession, currentMinutes)) return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if in session                                              |
//+------------------------------------------------------------------+
bool IsInSession(string session, int currentMinutes)
{
   string parts[];
   StringSplit(session, '-', parts);
   
   if(ArraySize(parts) != 2) return false;
   
   string startParts[], endParts[];
   StringSplit(parts[0], ':', startParts);
   StringSplit(parts[1], ':', endParts);
   
   int startMinutes = StringToInteger(startParts[0]) * 60 + StringToInteger(startParts[1]);
   int endMinutes = StringToInteger(endParts[0]) * 60 + StringToInteger(endParts[1]);
   
   if(startMinutes < endMinutes)
   {
      return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
   }
   else // Overnight session
   {
      return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
   }
}

//+------------------------------------------------------------------+
//| Spread Filter                                                     |
//+------------------------------------------------------------------+
bool PassesSpreadFilter()
{
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double spreadPips = spread / 10.0;
   
   return (spreadPips <= MaxSpreadPips);
}

//+------------------------------------------------------------------+
//| Check Extreme Volatility                                          |
//+------------------------------------------------------------------+
bool IsExtremeVolatility()
{
   double atrCurrent[];
   ArraySetAsSeries(atrCurrent, true);
   
   if(CopyBuffer(handleATR, 0, 0, 50, atrCurrent) <= 0) return false;
   
   double avgATR = 0;
   for(int i = 1; i < 50; i++)
   {
      avgATR += atrCurrent[i];
   }
   avgATR /= 49;
   
   if(avgATR == 0) return false;
   
   return (atrCurrent[0] > avgATR * VolatilityThreshold);
}

//+------------------------------------------------------------------+
