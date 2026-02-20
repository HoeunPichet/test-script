//+------------------------------------------------------------------+
//|                                                     SuperEA.mq5  |
//|                     PROFESSIONAL MULTI-TIMEFRAME SMART TRADER     |
//|                        Institutional-Grade Scalping System        |
//+------------------------------------------------------------------+
#property copyright "SuperEA Pro v2.0"
#property link      ""
#property version   "2.00"

#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== RISK MANAGEMENT ==="
input double   LotSize = 0.01;                    // Fixed Lot Size (if auto OFF)
input bool     UseAutoLotSizing = true;           // Auto Lot Based on Balance
input double   RiskPercent = 1.5;                 // Risk % Per Trade (1-2% recommended)
input int      MagicNumber = 123456;              // Magic Number
input int      MaxPositions = 3;                  // Max Simultaneous Trades
input double   MinBalance = 10;                   // Minimum Balance to Trade
input double   MaxDailyLossPct = 4.0;             // Max Daily Loss % (stop trading)
input double   MaxDrawdownPct = 8.0;              // Max Drawdown % from Peak Equity
input int      MaxConsecLosses = 3;               // Consecutive Losses Before Cooldown
input int      CooldownMinutes = 30;              // Cooldown After Consecutive Losses (min)
input bool     ReduceLotAfterLoss = true;         // Reduce Lot Size After Loss Streak
input double   LotReductionFactor = 0.5;          // Lot Reduction Factor (0.5 = half size)

input group "=== TREND ANALYSIS ==="
input int      FastMA_Period = 8;                 // Fast EMA Period
input int      SlowMA_Period = 21;                // Slow EMA Period
input int      RSI_Period = 14;                   // RSI Period
input int      RSI_Overbought = 70;               // RSI Overbought Level
input int      RSI_Oversold = 30;                 // RSI Oversold Level
input int      MACD_Fast = 12;                    // MACD Fast
input int      MACD_Slow = 26;                    // MACD Slow
input int      MACD_Signal = 9;                   // MACD Signal
input int      Stoch_K = 14;                      // Stochastic K
input int      Stoch_D = 3;                       // Stochastic D
input int      Stoch_Slow = 3;                    // Stochastic Slowing
input int      ADX_Period = 14;                   // ADX Period
input int      ADX_MinStrength = 20;              // ADX Min Trend Strength
input int      BB_Period = 20;                    // Bollinger Bands Period
input double   BB_Deviation = 2.0;                // BB Deviation
input int      CandleBars = 3;                    // Candle Pattern Bars
input int      MinSignalScore = 5;                // Min Score to Trade (out of 22)

input group "=== MULTI-TIMEFRAME ==="
input bool     UseMTF = true;                     // Enable Multi-Timeframe Analysis
input bool     RequireHTFAlignment = true;         // Require Higher TF Trend Alignment
input ENUM_TIMEFRAMES  EntryTF = PERIOD_M1;       // Entry Timeframe
input ENUM_TIMEFRAMES  MidTF = PERIOD_M5;         // Mid Timeframe (structure)
input ENUM_TIMEFRAMES  HighTF = PERIOD_M15;       // High Timeframe (trend)
input ENUM_TIMEFRAMES  BiassTF = PERIOD_H1;       // Bias Timeframe (direction)

input group "=== SESSION FILTER ==="
input bool     UseSessionFilter = true;           // Enable Session Filter
input int      LondonOpenHour = 8;                // London Open (Server Hour)
input int      LondonCloseHour = 17;              // London Close (Server Hour)
input int      NYOpenHour = 13;                   // New York Open (Server Hour)
input int      NYCloseHour = 22;                  // New York Close (Server Hour)
input bool     TradeAsianSession = false;          // Trade Asian Session (low vol)
input int      AsianOpenHour = 0;                 // Asian Open (Server Hour)
input int      AsianCloseHour = 8;                // Asian Close (Server Hour)
input bool     AvoidFirstMinutes = true;          // Avoid First 5 Min of Session
input bool     AvoidFriday = false;               // Avoid Trading on Friday
input int      FridayCloseHour = 20;              // Stop Trading Friday After (Hour)

input group "=== SL/TP MANAGEMENT ==="
input int      StopLoss_Pips = 15;                // Stop Loss (pips) - Fallback
input int      TakeProfit_Pips = 30;              // Take Profit (pips) - Fallback
input bool     UseATR_SL = true;                  // Use ATR for SL
input bool     UseATR_TP = true;                  // Use ATR for TP
input double   ATR_SL_Multiplier = 1.5;           // ATR SL Multiplier
input double   ATR_TP_Multiplier = 2.5;           // ATR TP Multiplier
input double   MinRiskReward = 1.5;               // Minimum Risk:Reward Ratio

input group "=== PROFIT PROTECTION ==="
input bool     UseBreakEven = true;               // Auto Break Even
input int      BreakEven_Pips = 8;                // Break Even at (pips)
input bool     UseTrailingStop = true;            // Trailing Stop
input int      Trailing_Start = 12;               // Trailing Start (pips)
input int      Trailing_Step = 4;                 // Trailing Step (pips)
input bool     UseProgressiveSL = true;           // Progressive SL to TP
input bool     UsePartialClose = true;            // Partial Close at TP Levels
input double   PartialClosePercent = 50.0;        // % of Position to Close at TP1
input double   TP1_Ratio = 0.5;                  // TP1 at X * Full TP Distance
input bool     LockProfitAtTP25 = true;           // Lock at 25% TP
input bool     LockProfitAtTP50 = true;           // Lock Profit at 50% TP
input bool     LockProfitAtTP75 = true;           // Lock Profit at 75% TP
input bool     LockProfitAtTP90 = true;           // Lock at 90% TP

input group "=== SMART ENTRY ==="
input bool     WaitForPullback = true;            // Wait for Pullback Entry
input double   PullbackATR_Pct = 0.3;            // Pullback Depth (% of ATR)
input bool     AvoidChasing = true;               // Avoid Chasing Extended Moves
input double   MaxChaseATR = 1.5;                 // Max Distance from EMA (ATR units)
input bool     UseSRZones = true;                 // Use Support/Resistance Zones
input int      SR_Lookback = 50;                  // S/R Lookback Bars
input double   SR_TouchZone_ATR = 0.5;            // S/R Zone Width (ATR units)

input group "=== FILTERS ==="
input int      MaxSpread_Pips = 15;               // Max Spread (pips)
input bool     TradeOnNewBarOnly = true;          // Trade Only on New Bar
input int      SecondsBetweenTrades = 120;        // Seconds Between Each Trade
input bool     EnableLogs = true;                 // Enable Logging

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

// Entry TF indicator handles
int handleMA_Fast, handleMA_Slow, handleATR;
int handleRSI, handleMACD, handleStoch, handleADX, handleBB;

// Multi-timeframe persistent handles (created once in OnInit)
int hMidEmaFast, hMidEmaSlow, hMidRSI, hMidADX, hMidATR;
int hHighEmaFast, hHighEmaSlow, hHighRSI, hHighADX, hHighATR;
int hBiasEmaFast, hBiasEmaSlow, hBiasATR;

// Signal scoring
struct SignalResult {
    int     direction;      // 1=BUY, -1=SELL, 0=NONE
    int     score;          // 0-22 total score
    double  strength;       // 0.0-1.0 strength
    string  reasons;        // Why the signal was generated
};

datetime lastBarTime = 0;
datetime lastTradeTime = 0;
int totalBuyTrades = 0;
int totalSellTrades = 0;
int totalWins = 0;
int totalLosses = 0;

// Drawdown & risk tracking
double peakEquity = 0;
double dailyStartBalance = 0;
datetime dailyResetTime = 0;
int consecLosses = 0;
datetime cooldownUntil = 0;

struct PositionData {
    ulong ticket;
    bool beApplied;
    bool sl10Applied;
    bool sl25Applied;
    bool sl40Applied;
    bool sl50Applied;
    bool sl60Applied;
    bool sl75Applied;
    bool sl90Applied;
    bool partialClosed;
};
PositionData positions[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Entry TF indicators
    handleMA_Fast = iMA(_Symbol, EntryTF, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    handleMA_Slow = iMA(_Symbol, EntryTF, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    handleATR     = iATR(_Symbol, EntryTF, 14);
    handleRSI     = iRSI(_Symbol, EntryTF, RSI_Period, PRICE_CLOSE);
    handleMACD    = iMACD(_Symbol, EntryTF, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    handleStoch   = iStochastic(_Symbol, EntryTF, Stoch_K, Stoch_D, Stoch_Slow, MODE_SMA, STO_LOWHIGH);
    handleADX     = iADX(_Symbol, EntryTF, ADX_Period);
    handleBB      = iBands(_Symbol, EntryTF, BB_Period, 0, BB_Deviation, PRICE_CLOSE);

    if(handleMA_Fast == INVALID_HANDLE || handleMA_Slow == INVALID_HANDLE || handleATR == INVALID_HANDLE ||
       handleRSI == INVALID_HANDLE || handleMACD == INVALID_HANDLE || handleStoch == INVALID_HANDLE ||
       handleADX == INVALID_HANDLE || handleBB == INVALID_HANDLE)
    {
        Print("FATAL: Failed to initialize entry TF indicators!");
        return INIT_FAILED;
    }

    // Mid TF indicators (persistent — no leak)
    hMidEmaFast = iMA(_Symbol, MidTF, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    hMidEmaSlow = iMA(_Symbol, MidTF, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    hMidRSI     = iRSI(_Symbol, MidTF, RSI_Period, PRICE_CLOSE);
    hMidADX     = iADX(_Symbol, MidTF, ADX_Period);
    hMidATR     = iATR(_Symbol, MidTF, 14);

    // High TF indicators (persistent)
    hHighEmaFast = iMA(_Symbol, HighTF, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    hHighEmaSlow = iMA(_Symbol, HighTF, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    hHighRSI     = iRSI(_Symbol, HighTF, RSI_Period, PRICE_CLOSE);
    hHighADX     = iADX(_Symbol, HighTF, ADX_Period);
    hHighATR     = iATR(_Symbol, HighTF, 14);

    // Bias TF indicators (persistent)
    hBiasEmaFast = iMA(_Symbol, BiassTF, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    hBiasEmaSlow = iMA(_Symbol, BiassTF, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE);
    hBiasATR     = iATR(_Symbol, BiassTF, 14);

    if(hMidEmaFast == INVALID_HANDLE || hHighEmaFast == INVALID_HANDLE || hBiasEmaFast == INVALID_HANDLE)
        Print("WARNING: Some MTF indicators failed — MTF analysis will be limited");

    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);

    ArrayResize(positions, 0);

    // Initialize risk tracking
    peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    dailyResetTime = GetDayStart(TimeCurrent());
    consecLosses = 0;
    cooldownUntil = 0;

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    Print("==============================================");
    Print("  SUPER EA PRO v2.0 — INSTITUTIONAL SCALPER  ");
    Print("==============================================");
    Print("  Entry TF: ", EnumToString(EntryTF), " | Mid: ", EnumToString(MidTF));
    Print("  High TF: ", EnumToString(HighTF), " | Bias: ", EnumToString(BiassTF));
    Print("  Min Score: ", MinSignalScore, "/22 | Max Positions: ", MaxPositions);
    Print("  Risk: ", RiskPercent, "% | Max Daily Loss: ", MaxDailyLossPct, "%");
    Print("  Max Drawdown: ", MaxDrawdownPct, "% | Cooldown: ", CooldownMinutes, "min");
    Print("  Session Filter: ", UseSessionFilter ? "ON" : "OFF");
    Print("  Smart Entry: ", WaitForPullback ? "Pullback" : "Immediate");
    Print("  S/R Zones: ", UseSRZones ? "ON" : "OFF");
    Print("  Partial Close: ", UsePartialClose ? "ON" : "OFF");
    Print("  Balance: $", DoubleToString(balance, 2));
    Print("  SL: ATR x", ATR_SL_Multiplier, " | TP: ATR x", ATR_TP_Multiplier);
    Print("  Min R:R = ", MinRiskReward);
    Print("  STATUS: ACTIVE");
    Print("==============================================");

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release entry TF handles
    IndicatorRelease(handleMA_Fast);
    IndicatorRelease(handleMA_Slow);
    IndicatorRelease(handleATR);
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleMACD);
    IndicatorRelease(handleStoch);
    IndicatorRelease(handleADX);
    IndicatorRelease(handleBB);

    // Release MTF handles
    IndicatorRelease(hMidEmaFast);
    IndicatorRelease(hMidEmaSlow);
    IndicatorRelease(hMidRSI);
    IndicatorRelease(hMidADX);
    IndicatorRelease(hMidATR);
    IndicatorRelease(hHighEmaFast);
    IndicatorRelease(hHighEmaSlow);
    IndicatorRelease(hHighRSI);
    IndicatorRelease(hHighADX);
    IndicatorRelease(hHighATR);
    IndicatorRelease(hBiasEmaFast);
    IndicatorRelease(hBiasEmaSlow);
    IndicatorRelease(hBiasATR);

    Comment("");
    double winRate = (totalWins + totalLosses > 0) ?
                     (double)totalWins / (totalWins + totalLosses) * 100.0 : 0;
    Print("==============================================");
    Print("  SUPER EA PRO v2.0 — SESSION REPORT         ");
    Print("==============================================");
    Print("  Buy Trades: ", totalBuyTrades);
    Print("  Sell Trades: ", totalSellTrades);
    Print("  Wins: ", totalWins, " | Losses: ", totalLosses);
    Print("  Win Rate: ", DoubleToString(winRate, 1), "%");
    Print("==============================================");
}

//+------------------------------------------------------------------+
//| OnTradeTransaction — Track wins/losses for tilt protection       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal))
        {
            long dealMagic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

            if(dealMagic == MagicNumber && dealEntry == DEAL_ENTRY_OUT)
            {
                double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
                double commission = HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
                double swap = HistoryDealGetDouble(trans.deal, DEAL_SWAP);
                double netProfit = profit + commission + swap;

                if(netProfit >= 0)
                {
                    totalWins++;
                    consecLosses = 0;
                    if(EnableLogs) Print("WIN #", totalWins, " | Net: $", DoubleToString(netProfit, 2),
                                         " | Streak reset");
                }
                else
                {
                    totalLosses++;
                    consecLosses++;
                    if(EnableLogs) Print("LOSS #", totalLosses, " | Net: $", DoubleToString(netProfit, 2),
                                         " | Consec: ", consecLosses);

                    if(consecLosses >= MaxConsecLosses)
                    {
                        cooldownUntil = TimeCurrent() + CooldownMinutes * 60;
                        Print("COOLDOWN ACTIVATED: ", consecLosses, " consecutive losses. ",
                              "No new trades until ", TimeToString(cooldownUntil, TIME_SECONDS));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Expert tick function — Professional Flow Control                  |
//+------------------------------------------------------------------+
void OnTick()
{
    // Always manage existing positions regardless of filters
    ManagePositions();

    // New bar filter — only evaluate signals on new bars (reduces noise)
    if(TradeOnNewBarOnly)
    {
        datetime currentBarTime = iTime(_Symbol, EntryTF, 0);
        if(currentBarTime == lastBarTime) return;
        lastBarTime = currentBarTime;
    }

    // Quick pre-checks (balance, spread)
    if(!PassQuickChecks()) return;

    // Daily reset check
    CheckDailyReset();

    // Drawdown protection — hard stop
    if(!CheckDrawdownLimits()) return;

    // Cooldown after consecutive losses (tilt protection)
    if(TimeCurrent() < cooldownUntil)
    {
        static datetime lastCooldownLog = 0;
        if(EnableLogs && TimeCurrent() - lastCooldownLog >= 30)
        {
            int remaining = (int)(cooldownUntil - TimeCurrent());
            Print("COOLDOWN: ", remaining, "s remaining (", consecLosses, " consecutive losses)");
            lastCooldownLog = TimeCurrent();
        }
        return;
    }

    // Session filter — only trade during high-liquidity sessions
    if(UseSessionFilter && !IsGoodSession())
    {
        static datetime lastSessionLog = 0;
        if(EnableLogs && TimeCurrent() - lastSessionLog >= 300)
        {
            Print("SESSION FILTER: Outside trading hours");
            lastSessionLog = TimeCurrent();
        }
        return;
    }

    // Time between trades cooldown
    if(SecondsBetweenTrades > 0 && lastTradeTime > 0)
    {
        int elapsed = (int)(TimeCurrent() - lastTradeTime);
        if(elapsed < SecondsBetweenTrades) return;
    }

    // Run multi-layer analysis
    SignalResult signal = SmartAnalyze();

    // Only trade if score meets threshold
    if(signal.score >= MinSignalScore && signal.direction != 0)
    {
        int currentPositions = CountMyPositions();
        if(currentPositions < MaxPositions)
        {
            if(EnableLogs)
                Print("SIGNAL | Dir:", signal.direction > 0 ? "BUY" : "SELL",
                      " | Score:", signal.score,
                      " | Strength:", DoubleToString(signal.strength * 100, 1), "%",
                      " | ", signal.reasons);
            OpenTrade(signal.direction > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, signal);
        }
    }
}

//+------------------------------------------------------------------+
//| SMART ANALYZER — Professional Multi-Layer Signal Engine           |
//+------------------------------------------------------------------+
SignalResult SmartAnalyze()
{
    SignalResult result;
    result.direction = 0;
    result.score     = 0;
    result.strength  = 0;
    result.reasons   = "";

    int buyScore  = 0;
    int sellScore = 0;
    string buyReasons  = "";
    string sellReasons = "";

    // Fetch all entry TF buffers
    double maFast[], maSlow[], rsi[], macdMain[], macdSig[];
    double stochK[], stochD[], adx[], adxPlus[], adxMinus[];
    double bbUpper[], bbLower[], bbMid[], atr[];
    double close[], open[], high[], low[];

    ArraySetAsSeries(maFast, true); ArraySetAsSeries(maSlow, true);
    ArraySetAsSeries(rsi, true); ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSig, true); ArraySetAsSeries(stochK, true);
    ArraySetAsSeries(stochD, true); ArraySetAsSeries(adx, true);
    ArraySetAsSeries(adxPlus, true); ArraySetAsSeries(adxMinus, true);
    ArraySetAsSeries(bbUpper, true); ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMid, true); ArraySetAsSeries(atr, true);
    ArraySetAsSeries(close, true); ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);

    int bars = MathMax(SR_Lookback + 5, 60);
    if(CopyBuffer(handleMA_Fast, 0, 0, bars, maFast)   <= 0) return result;
    if(CopyBuffer(handleMA_Slow, 0, 0, bars, maSlow)   <= 0) return result;
    if(CopyBuffer(handleRSI,     0, 0, bars, rsi)      <= 0) return result;
    if(CopyBuffer(handleMACD,    0, 0, bars, macdMain) <= 0) return result;
    if(CopyBuffer(handleMACD,    1, 0, bars, macdSig)  <= 0) return result;
    if(CopyBuffer(handleStoch,   0, 0, bars, stochK)   <= 0) return result;
    if(CopyBuffer(handleStoch,   1, 0, bars, stochD)   <= 0) return result;
    if(CopyBuffer(handleADX,     0, 0, bars, adx)      <= 0) return result;
    if(CopyBuffer(handleADX,     1, 0, bars, adxPlus)  <= 0) return result;
    if(CopyBuffer(handleADX,     2, 0, bars, adxMinus) <= 0) return result;
    if(CopyBuffer(handleBB,      1, 0, bars, bbUpper)  <= 0) return result;
    if(CopyBuffer(handleBB,      2, 0, bars, bbLower)  <= 0) return result;
    if(CopyBuffer(handleBB,      0, 0, bars, bbMid)    <= 0) return result;
    if(CopyBuffer(handleATR,     0, 0, bars, atr)      <= 0) return result;
    if(CopyClose (_Symbol, EntryTF, 0, bars, close)    <= 0) return result;
    if(CopyOpen  (_Symbol, EntryTF, 0, bars, open)     <= 0) return result;
    if(CopyHigh  (_Symbol, EntryTF, 0, bars, high)     <= 0) return result;
    if(CopyLow   (_Symbol, EntryTF, 0, bars, low)      <= 0) return result;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    // Pre-computed values
    double bodySize0 = MathAbs(close[0] - open[0]);
    double bodySize1 = MathAbs(close[1] - open[1]);
    double bodySize2 = MathAbs(close[2] - open[2]);
    double wickUp0   = high[0] - MathMax(close[0], open[0]);
    double wickDn0   = MathMin(close[0], open[0]) - low[0];
    double avgBody   = (bodySize0 + bodySize1 + bodySize2) / 3.0;
    double atrNow    = atr[0];

    // GUARD: Skip doji / indecision candles
    if(bodySize0 < atrNow * 0.08)
        return result;

    // GUARD: Skip if ATR too low (dead/flat market)
    double atrAvg = 0;
    for(int i = 0; i < 6; i++) atrAvg += atr[i];
    atrAvg /= 6.0;
    if(atrNow < atrAvg * 0.4)
        return result;

    // GUARD: Extreme zone blocks
    bool rsiBlockBuy  = (rsi[0] > RSI_Overbought + 5);
    bool rsiBlockSell = (rsi[0] < RSI_Oversold - 5);
    bool stochBlockBuy  = (stochK[0] > 85);
    bool stochBlockSell = (stochK[0] < 15);

    // ================================================================
    // LAYER 1 — EMA STRUCTURE (max 3 pts)
    // ================================================================
    bool emaUp         = (maFast[0] > maSlow[0]);
    bool emaDown       = (maFast[0] < maSlow[0]);
    bool emaCrossUp    = (maFast[0] > maSlow[0] && maFast[1] <= maSlow[1]);
    bool emaCrossDown  = (maFast[0] < maSlow[0] && maFast[1] >= maSlow[1]);
    bool emaRisingFast = (maFast[0] > maFast[1] && maFast[1] > maFast[2]);
    bool emaFallingFast= (maFast[0] < maFast[1] && maFast[1] < maFast[2]);
    bool priceAboveBoth= (bid > maFast[0] && bid > maSlow[0]);
    bool priceBelowBoth= (bid < maFast[0] && bid < maSlow[0]);

    if(emaCrossUp)
        { buyScore += 3; buyReasons += "[EMA_CrossUp+3] "; }
    else if(emaUp && emaRisingFast && priceAboveBoth)
        { buyScore += 2; buyReasons += "[EMA_TrendUp+2] "; }
    else if(emaUp)
        { buyScore += 1; buyReasons += "[EMA_Up+1] "; }

    if(emaCrossDown)
        { sellScore += 3; sellReasons += "[EMA_CrossDn+3] "; }
    else if(emaDown && emaFallingFast && priceBelowBoth)
        { sellScore += 2; sellReasons += "[EMA_TrendDn+2] "; }
    else if(emaDown)
        { sellScore += 1; sellReasons += "[EMA_Dn+1] "; }

    // ================================================================
    // LAYER 2 — RSI MOMENTUM (max 2 pts)
    // ================================================================
    bool rsiLeavingOversold  = (rsi[0] > rsi[1] && rsi[1] < RSI_Oversold);
    bool rsiLeavingOverbought= (rsi[0] < rsi[1] && rsi[1] > RSI_Overbought);
    bool rsiBullishRange     = (rsi[0] > 50 && rsi[0] < 70 && rsi[0] > rsi[1]);
    bool rsiBearishRange     = (rsi[0] < 50 && rsi[0] > 30 && rsi[0] < rsi[1]);
    double rsiSlope = rsi[0] - rsi[2];

    if(!rsiBlockBuy)
    {
        if(rsiLeavingOversold)
            { buyScore += 2; buyReasons += "[RSI_BounceUp+2] "; }
        else if(rsiBullishRange && rsiSlope > 2)
            { buyScore += 1; buyReasons += "[RSI_Bull+1] "; }
    }
    if(!rsiBlockSell)
    {
        if(rsiLeavingOverbought)
            { sellScore += 2; sellReasons += "[RSI_RollDn+2] "; }
        else if(rsiBearishRange && rsiSlope < -2)
            { sellScore += 1; sellReasons += "[RSI_Bear+1] "; }
    }

    // ================================================================
    // LAYER 3 — MACD CONFIRMATION (max 2 pts)
    // ================================================================
    bool macdCrossUp    = (macdMain[0] > macdSig[0] && macdMain[1] <= macdSig[1]);
    bool macdCrossDown  = (macdMain[0] < macdSig[0] && macdMain[1] >= macdSig[1]);
    double histNow      = macdMain[0] - macdSig[0];
    double histPrev     = macdMain[1] - macdSig[1];
    bool histGrowing    = (histNow > histPrev && histNow > 0);
    bool histShrinking  = (histNow < histPrev && histNow < 0);

    if(macdCrossUp)
        { buyScore += 2; buyReasons += "[MACD_CrossUp+2] "; }
    else if(histGrowing && macdMain[0] > 0)
        { buyScore += 1; buyReasons += "[MACD_HistUp+1] "; }
    else if(macdMain[0] > macdSig[0] && emaUp)
        { buyScore += 1; buyReasons += "[MACD_Above+1] "; }

    if(macdCrossDown)
        { sellScore += 2; sellReasons += "[MACD_CrossDn+2] "; }
    else if(histShrinking && macdMain[0] < 0)
        { sellScore += 1; sellReasons += "[MACD_HistDn+1] "; }
    else if(macdMain[0] < macdSig[0] && emaDown)
        { sellScore += 1; sellReasons += "[MACD_Below+1] "; }

    // ================================================================
    // LAYER 4 — ADX + DIRECTIONAL MOVEMENT (max 2 pts)
    // ================================================================
    bool adxStrong  = (adx[0] > ADX_MinStrength);
    bool adxRising  = (adx[0] > adx[1]);
    bool diPlusDom  = (adxPlus[0] > adxMinus[0]);
    bool diMinusDom = (adxMinus[0] > adxPlus[0]);
    bool diCrossUp  = (adxPlus[0] > adxMinus[0] && adxPlus[1] <= adxMinus[1]);
    bool diCrossDown= (adxMinus[0] > adxPlus[0] && adxMinus[1] <= adxPlus[1]);

    if(diCrossUp)
        { buyScore += 2; buyReasons += "[DI_CrossUp+2] "; }
    else if(adxStrong && adxRising && diPlusDom)
        { buyScore += 2; buyReasons += "[ADX_Bull+2] "; }
    else if(adxStrong && diPlusDom)
        { buyScore += 1; buyReasons += "[ADX_DI+1] "; }

    if(diCrossDown)
        { sellScore += 2; sellReasons += "[DI_CrossDn+2] "; }
    else if(adxStrong && adxRising && diMinusDom)
        { sellScore += 2; sellReasons += "[ADX_Bear+2] "; }
    else if(adxStrong && diMinusDom)
        { sellScore += 1; sellReasons += "[ADX_DIMinus+1] "; }

    // ================================================================
    // LAYER 5 — STOCHASTIC TIMING (max 1 pt)
    // ================================================================
    bool stochCrossUp   = (stochK[0] > stochD[0] && stochK[1] <= stochD[1]);
    bool stochCrossDown = (stochK[0] < stochD[0] && stochK[1] >= stochD[1]);

    if(!stochBlockBuy && (stochCrossUp || (stochK[0] > stochK[1] && stochK[0] < 60)))
        { buyScore += 1; buyReasons += "[StochUp+1] "; }
    if(!stochBlockSell && (stochCrossDown || (stochK[0] < stochK[1] && stochK[0] > 40)))
        { sellScore += 1; sellReasons += "[StochDn+1] "; }

    // ================================================================
    // LAYER 6 — BOLLINGER BANDS CONTEXT (max 1 pt)
    // ================================================================
    double bbWidth     = bbUpper[0] - bbLower[0];
    double bbWidthPrev = bbUpper[1] - bbLower[1];
    bool bbExpanding   = (bbWidth > bbWidthPrev * 1.1);
    bool priceCrossedMid     = (close[0] > bbMid[0] && close[1] <= bbMid[1]);
    bool priceCrossedMidDown = (close[0] < bbMid[0] && close[1] >= bbMid[1]);
    bool nearLower = (bid < bbLower[0] + bbWidth * 0.15);
    bool nearUpper = (bid > bbUpper[0] - bbWidth * 0.15);

    if(emaUp && (priceCrossedMid || (nearLower && bbExpanding)))
        { buyScore += 1; buyReasons += "[BB_Buy+1] "; }
    if(emaDown && (priceCrossedMidDown || (nearUpper && bbExpanding)))
        { sellScore += 1; sellReasons += "[BB_Sell+1] "; }

    // ================================================================
    // LAYER 7 — CANDLESTICK PATTERNS (max 2 pts)
    // ================================================================
    bool greenCandle = (close[0] > open[0]);
    bool redCandle   = (close[0] < open[0]);
    bool strongBull  = (greenCandle && bodySize0 > atrNow * 0.5);
    bool strongBear  = (redCandle   && bodySize0 > atrNow * 0.5);

    bool hammer = (wickDn0 > bodySize0 * 2.5 && wickUp0 < bodySize0 * 0.5
                   && bodySize0 > atrNow * 0.05 && emaDown);
    bool shootingStar = (wickUp0 > bodySize0 * 2.5 && wickDn0 < bodySize0 * 0.5
                         && bodySize0 > atrNow * 0.05 && emaUp);
    bool bullEngulf = (greenCandle && open[0] < close[1] && close[0] > open[1]
                       && bodySize0 > bodySize1 * 1.2);
    bool bearEngulf = (redCandle && open[0] > close[1] && close[0] < open[1]
                       && bodySize0 > bodySize1 * 1.2);
    bool insideBarBullBreak = (high[0] > high[1] && low[0] > low[1]
                               && bodySize1 < atrNow * 0.4 && greenCandle);
    bool insideBarBearBreak = (low[0] < low[1] && high[0] < high[1]
                               && bodySize1 < atrNow * 0.4 && redCandle);

    if(bullEngulf)
        { buyScore += 2; buyReasons += "[EngulfUp+2] "; }
    else if(hammer || insideBarBullBreak)
        { buyScore += 2; buyReasons += "[PatternBull+2] "; }
    else if(strongBull && emaUp)
        { buyScore += 1; buyReasons += "[BigBull+1] "; }

    if(bearEngulf)
        { sellScore += 2; sellReasons += "[EngulfDn+2] "; }
    else if(shootingStar || insideBarBearBreak)
        { sellScore += 2; sellReasons += "[PatternBear+2] "; }
    else if(strongBear && emaDown)
        { sellScore += 1; sellReasons += "[BigBear+1] "; }

    // ================================================================
    // LAYER 8 — PRICE ACTION MOMENTUM (max 1 pt)
    // ================================================================
    int upBars = 0, downBars = 0;
    for(int i = 0; i < CandleBars; i++)
    {
        if(close[i] > close[i+1]) upBars++;
        else if(close[i] < close[i+1]) downBars++;
    }
    if((double)upBars / CandleBars >= 0.66)
        { buyScore += 1; buyReasons += "[MomUp+1] "; }
    if((double)downBars / CandleBars >= 0.66)
        { sellScore += 1; sellReasons += "[MomDn+1] "; }

    // ================================================================
    // LAYER 9 — MULTI-TIMEFRAME CONFLUENCE (max 5 pts)
    // Uses persistent handles — no handle leaks
    // ================================================================
    if(UseMTF)
    {
        // Mid TF — Structure confirmation (max 2 pts)
        double midFast[], midSlow[], midRsi[];
        ArraySetAsSeries(midFast, true); ArraySetAsSeries(midSlow, true); ArraySetAsSeries(midRsi, true);
        if(CopyBuffer(hMidEmaFast, 0, 0, 3, midFast) > 0 &&
           CopyBuffer(hMidEmaSlow, 0, 0, 3, midSlow) > 0 &&
           CopyBuffer(hMidRSI,     0, 0, 3, midRsi)  > 0)
        {
            bool midUp = (midFast[0] > midSlow[0] && midFast[0] > midFast[1]);
            bool midDn = (midFast[0] < midSlow[0] && midFast[0] < midFast[1]);

            if(midUp && emaUp)
                { buyScore += 2; buyReasons += "[MidTF_Align+2] "; }
            else if(midUp)
                { buyScore += 1; buyReasons += "[MidTF_Bias+1] "; }
            if(midDn && emaDown)
                { sellScore += 2; sellReasons += "[MidTF_Align+2] "; }
            else if(midDn)
                { sellScore += 1; sellReasons += "[MidTF_Bias+1] "; }
        }

        // High TF — Trend direction (max 2 pts)
        double highFast[], highSlow[], highRsi[];
        ArraySetAsSeries(highFast, true); ArraySetAsSeries(highSlow, true); ArraySetAsSeries(highRsi, true);
        if(CopyBuffer(hHighEmaFast, 0, 0, 3, highFast) > 0 &&
           CopyBuffer(hHighEmaSlow, 0, 0, 3, highSlow) > 0 &&
           CopyBuffer(hHighRSI,     0, 0, 3, highRsi)  > 0)
        {
            bool highUp = (highFast[0] > highSlow[0]);
            bool highDn = (highFast[0] < highSlow[0]);

            if(highUp && emaUp)
                { buyScore += 2; buyReasons += "[HighTF_Align+2] "; }
            if(highDn && emaDown)
                { sellScore += 2; sellReasons += "[HighTF_Align+2] "; }

            // HTF VETO: kill signals against higher TF trend
            if(RequireHTFAlignment)
            {
                if(highDn && buyScore > 0)
                    { buyScore = (int)(buyScore * 0.3); buyReasons += "[HTF_VETO-70%] "; }
                if(highUp && sellScore > 0)
                    { sellScore = (int)(sellScore * 0.3); sellReasons += "[HTF_VETO-70%] "; }
            }
        }

        // Bias TF (H1) — Directional bias (max 1 pt)
        double biasFast[], biasSlow[];
        ArraySetAsSeries(biasFast, true); ArraySetAsSeries(biasSlow, true);
        if(CopyBuffer(hBiasEmaFast, 0, 0, 3, biasFast) > 0 &&
           CopyBuffer(hBiasEmaSlow, 0, 0, 3, biasSlow) > 0)
        {
            if(biasFast[0] > biasSlow[0] && emaUp)
                { buyScore += 1; buyReasons += "[H1_Bias+1] "; }
            if(biasFast[0] < biasSlow[0] && emaDown)
                { sellScore += 1; sellReasons += "[H1_Bias+1] "; }
        }
    }

    // ================================================================
    // LAYER 10 — SUPPORT/RESISTANCE ZONE AWARENESS
    // ================================================================
    if(UseSRZones)
    {
        double nearestSupport = 0, nearestResistance = 99999999;
        FindSRZones(high, low, close, MathMin(bars, SR_Lookback), atrNow, nearestSupport, nearestResistance);

        double distToSupport    = bid - nearestSupport;
        double distToResistance = nearestResistance - bid;
        double srZoneWidth      = atrNow * SR_TouchZone_ATR;

        if(distToSupport < srZoneWidth && distToSupport > 0)
            { buyScore += 1; buyReasons += "[NearSupport+1] "; }
        if(distToResistance < srZoneWidth && distToResistance > 0)
            { sellScore += 1; sellReasons += "[NearResist+1] "; }

        // VETO: Don't trade into S/R
        if(distToResistance < srZoneWidth * 0.5 && buyScore > 0)
            { buyScore = (int)(buyScore * 0.4); buyReasons += "[IntoResist-60%] "; }
        if(distToSupport < srZoneWidth * 0.5 && sellScore > 0)
            { sellScore = (int)(sellScore * 0.4); sellReasons += "[IntoSupport-60%] "; }
    }

    // ================================================================
    // LAYER 11 — SMART ENTRY FILTERS (pullback + anti-chase)
    // ================================================================
    if(AvoidChasing && atrNow > 0)
    {
        double distFromEma = MathAbs(bid - maFast[0]);
        if(distFromEma > atrNow * MaxChaseATR)
        {
            buyScore  = (int)(buyScore  * 0.3);
            sellScore = (int)(sellScore * 0.3);
            buyReasons  += "[Chasing-70%] ";
            sellReasons += "[Chasing-70%] ";
        }
    }

    if(WaitForPullback && atrNow > 0)
    {
        double pullbackDepth = atrNow * PullbackATR_Pct;
        if(emaUp && bid > maFast[0] + pullbackDepth * 2)
            { buyScore = (int)(buyScore * 0.5); buyReasons += "[NoPullback-50%] "; }
        if(emaDown && bid < maFast[0] - pullbackDepth * 2)
            { sellScore = (int)(sellScore * 0.5); sellReasons += "[NoPullback-50%] "; }
    }

    // ================================================================
    // LAYER 12 — ANTI-TRAP VETO SYSTEM
    // ================================================================
    if(rsiBlockBuy || stochBlockBuy)
        { buyScore = 0; buyReasons = "VETOED(Overbought)"; }
    if(rsiBlockSell || stochBlockSell)
        { sellScore = 0; sellReasons = "VETOED(Oversold)"; }

    if(emaUp && macdMain[0] < macdSig[0] && !macdCrossUp && buyScore > 0)
        { buyScore = (int)(buyScore * 0.5); buyReasons += "[MACD_Conflict-50%] "; }
    if(emaDown && macdMain[0] > macdSig[0] && !macdCrossDown && sellScore > 0)
        { sellScore = (int)(sellScore * 0.5); sellReasons += "[MACD_Conflict-50%] "; }

    if(adx[0] < 15)
    {
        buyScore  = (int)(buyScore  * 0.5);
        sellScore = (int)(sellScore * 0.5);
        buyReasons  += "[ADX_Weak-50%] ";
        sellReasons += "[ADX_Weak-50%] ";
    }

    // ================================================================
    // FINAL DECISION
    // ================================================================
    int maxScore = 22;
    int margin   = 2;

    if(buyScore > sellScore && buyScore >= MinSignalScore && (buyScore - sellScore) >= margin)
    {
        result.direction = 1;
        result.score     = buyScore;
        result.strength  = MathMin((double)buyScore / maxScore, 1.0);
        result.reasons   = buyReasons;
    }
    else if(sellScore > buyScore && sellScore >= MinSignalScore && (sellScore - buyScore) >= margin)
    {
        result.direction = -1;
        result.score     = sellScore;
        result.strength  = MathMin((double)sellScore / maxScore, 1.0);
        result.reasons   = sellReasons;
    }

    // Log on each new bar
    static datetime lastBar = 0;
    datetime curBar = iTime(_Symbol, EntryTF, 0);
    if(EnableLogs && curBar != lastBar)
    {
        Print("--- ANALYSIS | ", TimeToString(TimeCurrent(), TIME_SECONDS), " ---");
        Print("  BUY  ", buyScore, "/", maxScore, " | ", buyReasons);
        Print("  SELL ", sellScore, "/", maxScore, " | ", sellReasons);
        Print("  RSI:", DoubleToString(rsi[0],1),
              " MACD:", DoubleToString(histNow,5),
              " ADX:", DoubleToString(adx[0],1),
              " +DI:", DoubleToString(adxPlus[0],1),
              " -DI:", DoubleToString(adxMinus[0],1));
        if(result.direction == 1)
            Print("  >>> BUY SIGNAL | Score:", result.score,
                  " | Conf:", DoubleToString(result.strength*100,1), "%");
        else if(result.direction == -1)
            Print("  >>> SELL SIGNAL | Score:", result.score,
                  " | Conf:", DoubleToString(result.strength*100,1), "%");
        else
            Print("  WAITING | Need score>=", MinSignalScore, " margin>=", margin);
        lastBar = curBar;
    }

    return result;
}

//+------------------------------------------------------------------+
//| Open Trade — with R:R enforcement, spread-adjusted SL/TP,        |
//|              loss-streak lot reduction                             |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, SignalResult &signal)
{
    double lotSize = LotSize;
    if(UseAutoLotSizing)
        lotSize = CalculateLotSize();

    // Reduce lot after consecutive losses
    if(ReduceLotAfterLoss && consecLosses >= 2)
    {
        lotSize = lotSize * LotReductionFactor;
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        lotSize = MathMax(minLot, MathFloor(lotSize / lotStep) * lotStep);
        if(EnableLogs) Print("LOT REDUCED: ", consecLosses, " losses -> Lot=", DoubleToString(lotSize, 2));
    }

    double price = (orderType == ORDER_TYPE_BUY) ?
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * point;

    double sl = 0, tp = 0;
    double slDistance = 0, tpDistance = 0;

    // Calculate SL/TP
    if(UseATR_SL || UseATR_TP)
    {
        double atrBuf[];
        ArraySetAsSeries(atrBuf, true);
        if(CopyBuffer(handleATR, 0, 0, 1, atrBuf) > 0)
        {
            double atrValue = atrBuf[0];

            if(UseATR_SL)
                slDistance = atrValue * ATR_SL_Multiplier;
            else
                slDistance = StopLoss_Pips * point * 10;

            if(UseATR_TP)
                tpDistance = atrValue * ATR_TP_Multiplier;
            else
                tpDistance = TakeProfit_Pips * point * 10;
        }
    }
    else
    {
        slDistance = StopLoss_Pips * point * 10;
        tpDistance = TakeProfit_Pips * point * 10;
    }

    // Enforce minimum Risk:Reward ratio
    if(slDistance > 0 && tpDistance / slDistance < MinRiskReward)
    {
        tpDistance = slDistance * MinRiskReward;
        if(EnableLogs) Print("R:R adjusted to minimum ", MinRiskReward, ":1");
    }

    // Add spread buffer to SL for safety
    slDistance += spread;

    if(orderType == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(price - slDistance, digits);
        tp = NormalizeDouble(price + tpDistance, digits);
    }
    else
    {
        sl = NormalizeDouble(price + slDistance, digits);
        tp = NormalizeDouble(price - tpDistance, digits);
    }

    string comment = StringFormat("SuperEA_%s_S%d",
                     orderType == ORDER_TYPE_BUY ? "BUY" : "SELL",
                     signal.score);

    bool tradeResult = false;
    if(orderType == ORDER_TYPE_BUY)
    {
        tradeResult = trade.Buy(lotSize, _Symbol, price, sl, tp, comment);
        if(tradeResult) totalBuyTrades++;
    }
    else
    {
        tradeResult = trade.Sell(lotSize, _Symbol, price, sl, tp, comment);
        if(tradeResult) totalSellTrades++;
    }

    if(tradeResult)
    {
        lastTradeTime = TimeCurrent();
        double rr = (slDistance > 0) ? tpDistance / slDistance : 0;
        Print("EXECUTED ", orderType == ORDER_TYPE_BUY ? "BUY" : "SELL",
              " | Lot:", DoubleToString(lotSize, 2),
              " | Price:", DoubleToString(price, digits),
              " | SL:", DoubleToString(sl, digits),
              " | TP:", DoubleToString(tp, digits),
              " | R:R=", DoubleToString(rr, 2));
    }
    else
    {
        Print("TRADE FAILED: ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size — Risk-based with safety caps                  |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!UseAutoLotSizing)
        return LotSize;

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    // Use the LOWER of balance/equity for conservative sizing
    double accountSize = MathMin(balance, equity);

    double riskAmount = accountSize * (RiskPercent / 100.0);

    double atrBuf[];
    ArraySetAsSeries(atrBuf, true);
    double stopPips = StopLoss_Pips;

    if(UseATR_SL && CopyBuffer(handleATR, 0, 0, 1, atrBuf) > 0)
    {
        double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        stopPips = (atrBuf[0] * ATR_SL_Multiplier) / (pt * 10);
        stopPips = MathMax(stopPips, 5);
        stopPips = MathMin(stopPips, 100);
    }

    double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if(stopPips <= 0 || tickValue <= 0 || tickSize <= 0 || pt <= 0)
    {
        Print("WARNING: Invalid lot calc values, using base lot");
        return LotSize;
    }

    double stopLossValue = stopPips * pt * 10;
    double calcLot = (riskAmount / (stopLossValue / pt)) * (tickSize / tickValue);

    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    calcLot = MathMax(minLot, MathMin(maxLot, calcLot));
    calcLot = MathFloor(calcLot / lotStep) * lotStep;

    // Hard safety cap: never risk more than 5% on one trade
    double maxRiskAmount = accountSize * 0.05;
    double maxSafeLot = (maxRiskAmount / (stopLossValue / pt)) * (tickSize / tickValue);
    maxSafeLot = MathFloor(maxSafeLot / lotStep) * lotStep;
    if(calcLot > maxSafeLot)
    {
        calcLot = MathMax(minLot, maxSafeLot);
        if(EnableLogs) Print("LOT CAPPED at safe max: ", DoubleToString(calcLot, 2));
    }

    if(calcLot < minLot) calcLot = minLot;

    if(EnableLogs)
        Print("AUTO LOT: Acct=$", DoubleToString(accountSize, 2),
              " Risk=", RiskPercent, "% SL=", DoubleToString(stopPips, 1),
              "pip Lot=", DoubleToString(calcLot, 2));

    return calcLot;
}

//+------------------------------------------------------------------+
//| Manage Open Positions — Progressive SL, BE, Trail, Partial Close |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0) continue;

        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

        // Partial close at TP1
        if(UsePartialClose)
            ApplyPartialClose(ticket);

        // Progressive SL (most aggressive)
        if(UseProgressiveSL)
            ApplyProgressiveSL(ticket);

        // Break even
        if(UseBreakEven)
            ApplyBreakEven(ticket);

        // Trailing stop
        if(UseTrailingStop)
            ApplyTrailingStop(ticket);
    }
}

//+------------------------------------------------------------------+
//| Apply Partial Close — Close portion at TP1 level                  |
//+------------------------------------------------------------------+
void ApplyPartialClose(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;

    int posIndex = FindOrCreatePositionData(ticket);
    if(posIndex < 0 || positions[posIndex].partialClosed) return;

    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentTP = PositionGetDouble(POSITION_TP);
    double volume    = PositionGetDouble(POSITION_VOLUME);
    if(currentTP == 0 || volume <= 0) return;

    bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double totalDistance = MathAbs(currentTP - openPrice);
    double tp1Distance   = totalDistance * TP1_Ratio;
    double currentDist   = isBuy ? (currentPrice - openPrice) : (openPrice - currentPrice);

    if(currentDist >= tp1Distance)
    {
        double closeVolume = volume * (PartialClosePercent / 100.0);
        double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        closeVolume = MathFloor(closeVolume / lotStep) * lotStep;

        if(closeVolume >= minLot && (volume - closeVolume) >= minLot)
        {
            if(trade.PositionClosePartial(ticket, closeVolume))
            {
                positions[posIndex].partialClosed = true;
                Print("PARTIAL CLOSE: #", ticket, " closed ", DoubleToString(closeVolume, 2),
                      " lots at TP1 (", DoubleToString(TP1_Ratio * 100, 0), "% of TP)");
            }
        }
        else
        {
            positions[posIndex].partialClosed = true;
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Progressive SL — Moves SL as trade progresses toward TP    |
//+------------------------------------------------------------------+
void ApplyProgressiveSL(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;

    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    if(currentTP == 0) return;

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double totalDistance = MathAbs(currentTP - openPrice);
    double currentDistance = isBuy ? (currentPrice - openPrice) : (openPrice - currentPrice);
    double progressPercent = (currentDistance / totalDistance) * 100.0;

    if(progressPercent < 0) return;

    double newSL = 0;
    bool shouldModify = false;
    string level = "";

    int posIndex = FindOrCreatePositionData(ticket);
    if(posIndex < 0) return;

    // Progressive SL Levels
    if(progressPercent >= 90 && !positions[posIndex].sl90Applied && LockProfitAtTP90)
    {
        double lockDist = totalDistance * 0.80;
        newSL = isBuy ? NormalizeDouble(openPrice + lockDist, digits) :
                         NormalizeDouble(openPrice - lockDist, digits);
        shouldModify = true; level = "90%->Lock80%";
        positions[posIndex].sl90Applied = true;
    }
    else if(progressPercent >= 75 && !positions[posIndex].sl75Applied && LockProfitAtTP75)
    {
        double lockDist = totalDistance * 0.60;
        newSL = isBuy ? NormalizeDouble(openPrice + lockDist, digits) :
                         NormalizeDouble(openPrice - lockDist, digits);
        shouldModify = true; level = "75%->Lock60%";
        positions[posIndex].sl75Applied = true;
    }
    else if(progressPercent >= 60 && !positions[posIndex].sl60Applied)
    {
        double lockDist = totalDistance * 0.45;
        newSL = isBuy ? NormalizeDouble(openPrice + lockDist, digits) :
                         NormalizeDouble(openPrice - lockDist, digits);
        shouldModify = true; level = "60%->Lock45%";
        positions[posIndex].sl60Applied = true;
    }
    else if(progressPercent >= 50 && !positions[posIndex].sl50Applied && LockProfitAtTP50)
    {
        double lockDist = totalDistance * 0.35;
        newSL = isBuy ? NormalizeDouble(openPrice + lockDist, digits) :
                         NormalizeDouble(openPrice - lockDist, digits);
        shouldModify = true; level = "50%->Lock35%";
        positions[posIndex].sl50Applied = true;
    }
    else if(progressPercent >= 40 && !positions[posIndex].sl40Applied)
    {
        double lockDist = totalDistance * 0.20;
        newSL = isBuy ? NormalizeDouble(openPrice + lockDist, digits) :
                         NormalizeDouble(openPrice - lockDist, digits);
        shouldModify = true; level = "40%->Lock20%";
        positions[posIndex].sl40Applied = true;
    }
    else if(progressPercent >= 25 && !positions[posIndex].sl25Applied && LockProfitAtTP25)
    {
        double lockDist = totalDistance * 0.10;
        newSL = isBuy ? NormalizeDouble(openPrice + lockDist, digits) :
                         NormalizeDouble(openPrice - lockDist, digits);
        shouldModify = true; level = "25%->Lock10%";
        positions[posIndex].sl25Applied = true;
    }
    else if(progressPercent >= 10 && !positions[posIndex].sl10Applied)
    {
        newSL = NormalizeDouble(openPrice + (isBuy ? 1*point : -1*point), digits);
        shouldModify = true; level = "10%->BE";
        positions[posIndex].sl10Applied = true;
    }

    if(shouldModify)
    {
        bool isBetter = isBuy ? (newSL > currentSL || currentSL == 0) :
                                (newSL < currentSL || currentSL == 0);
        if(isBetter)
        {
            if(trade.PositionModify(ticket, newSL, currentTP))
                Print("SL UPDATE: #", ticket, " | ", level,
                      " | SL:", DoubleToString(newSL, digits),
                      " | Progress:", DoubleToString(progressPercent, 1), "%");
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Break Even                                                  |
//+------------------------------------------------------------------+
void ApplyBreakEven(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;

    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double pips = isBuy ? (currentPrice - openPrice) / (point * 10) :
                          (openPrice - currentPrice) / (point * 10);

    if(pips >= BreakEven_Pips)
    {
        double newSL = isBuy ? NormalizeDouble(openPrice + 1 * point, digits) :
                               NormalizeDouble(openPrice - 1 * point, digits);

        bool isBetter = isBuy ? (newSL > currentSL) :
                                (newSL < currentSL || currentSL == 0);
        if(isBetter)
        {
            if(trade.PositionModify(ticket, newSL, currentTP))
                Print("BE: #", ticket, " at ", DoubleToString(pips, 1), " pips");
        }
    }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                               |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;

    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                  SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    double pips = isBuy ? (currentPrice - openPrice) / (point * 10) :
                          (openPrice - currentPrice) / (point * 10);

    if(pips < Trailing_Start) return;

    double trailDistance = Trailing_Step * point * 10;
    double newSL = isBuy ? NormalizeDouble(currentPrice - trailDistance, digits) :
                           NormalizeDouble(currentPrice + trailDistance, digits);

    bool isBetter = isBuy ? (newSL > currentSL + point * 10) :
                            (newSL < currentSL - point * 10 || currentSL == 0);
    if(isBetter)
    {
        if(trade.PositionModify(ticket, newSL, currentTP))
            Print("TRAIL: #", ticket, " SL->", DoubleToString(newSL, digits));
    }
}

//+------------------------------------------------------------------+
//| Find or Create Position Data entry                                |
//+------------------------------------------------------------------+
int FindOrCreatePositionData(ulong ticket)
{
    for(int j = 0; j < ArraySize(positions); j++)
    {
        if(positions[j].ticket == ticket)
            return j;
    }

    int idx = ArraySize(positions);
    ArrayResize(positions, idx + 1);
    positions[idx].ticket = ticket;
    positions[idx].beApplied = false;
    positions[idx].sl10Applied = false;
    positions[idx].sl25Applied = false;
    positions[idx].sl40Applied = false;
    positions[idx].sl50Applied = false;
    positions[idx].sl60Applied = false;
    positions[idx].sl75Applied = false;
    positions[idx].sl90Applied = false;
    positions[idx].partialClosed = false;
    return idx;
}

//+------------------------------------------------------------------+
//| Find Support/Resistance Zones from price action                   |
//+------------------------------------------------------------------+
void FindSRZones(const double &highArr[], const double &lowArr[], const double &closeArr[],
                 int lookback, double atrVal,
                 double &support, double &resistance)
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    support = 0;
    resistance = 99999999;
    double zoneWidth = atrVal * 0.3;

    // Find swing highs and lows
    for(int i = 2; i < lookback - 1; i++)
    {
        // Swing high: high[i] > high[i-1] && high[i] > high[i+1]
        if(highArr[i] > highArr[i-1] && highArr[i] > highArr[i+1])
        {
            if(highArr[i] > bid && highArr[i] < resistance)
                resistance = highArr[i];
        }

        // Swing low: low[i] < low[i-1] && low[i] < low[i+1]
        if(lowArr[i] < lowArr[i-1] && lowArr[i] < lowArr[i+1])
        {
            if(lowArr[i] < bid && lowArr[i] > support)
                support = lowArr[i];
        }
    }

    // Also check for price clusters (areas where price reversed multiple times)
    double levels[];
    int levelCount = 0;
    ArrayResize(levels, 0);

    for(int i = 3; i < lookback - 1; i++)
    {
        // Check if this level was tested multiple times
        double testLevel = (highArr[i] + lowArr[i]) / 2.0;
        int touches = 0;
        for(int j = 0; j < lookback; j++)
        {
            if(j == i) continue;
            if(MathAbs(highArr[j] - testLevel) < zoneWidth ||
               MathAbs(lowArr[j] - testLevel) < zoneWidth)
                touches++;
        }

        if(touches >= 3)
        {
            if(testLevel > bid && testLevel < resistance)
                resistance = testLevel;
            if(testLevel < bid && testLevel > support)
                support = testLevel;
        }
    }
}

//+------------------------------------------------------------------+
//| Session Filter — Only trade during high-liquidity hours           |
//+------------------------------------------------------------------+
bool IsGoodSession()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    int hour = dt.hour;
    int minute = dt.min;
    int dayOfWeek = dt.day_of_week;

    // Skip weekends
    if(dayOfWeek == 0 || dayOfWeek == 6) return false;

    // Friday close filter
    if(AvoidFriday && dayOfWeek == 5 && hour >= FridayCloseHour) return false;

    // Avoid first 5 minutes of session opens
    if(AvoidFirstMinutes)
    {
        if((hour == LondonOpenHour || hour == NYOpenHour) && minute < 5)
            return false;
    }

    // Check London session
    bool inLondon = (hour >= LondonOpenHour && hour < LondonCloseHour);

    // Check NY session
    bool inNY = (hour >= NYOpenHour && hour < NYCloseHour);

    // Check Asian session
    bool inAsian = false;
    if(TradeAsianSession)
    {
        if(AsianOpenHour < AsianCloseHour)
            inAsian = (hour >= AsianOpenHour && hour < AsianCloseHour);
        else
            inAsian = (hour >= AsianOpenHour || hour < AsianCloseHour);
    }

    return (inLondon || inNY || inAsian);
}

//+------------------------------------------------------------------+
//| Check Drawdown Limits — Daily loss + peak equity drawdown         |
//+------------------------------------------------------------------+
bool CheckDrawdownLimits()
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);

    // Update peak equity
    if(equity > peakEquity)
        peakEquity = equity;

    // Check max drawdown from peak
    double drawdownPct = ((peakEquity - equity) / peakEquity) * 100.0;
    if(drawdownPct >= MaxDrawdownPct)
    {
        static datetime lastDDLog = 0;
        if(TimeCurrent() - lastDDLog >= 60)
        {
            Print("DRAWDOWN LIMIT: ", DoubleToString(drawdownPct, 1),
                  "% >= ", MaxDrawdownPct, "% — TRADING HALTED");
            lastDDLog = TimeCurrent();
        }
        return false;
    }

    // Check daily loss limit
    double dailyPnL = balance - dailyStartBalance;
    double dailyLossPct = 0;
    if(dailyStartBalance > 0)
        dailyLossPct = (-dailyPnL / dailyStartBalance) * 100.0;

    if(dailyPnL < 0 && dailyLossPct >= MaxDailyLossPct)
    {
        static datetime lastDailyLog = 0;
        if(TimeCurrent() - lastDailyLog >= 60)
        {
            Print("DAILY LOSS LIMIT: -", DoubleToString(dailyLossPct, 1),
                  "% >= ", MaxDailyLossPct, "% — NO NEW TRADES TODAY");
            lastDailyLog = TimeCurrent();
        }
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Check Daily Reset — Reset daily tracking at midnight              |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
    datetime dayStart = GetDayStart(TimeCurrent());
    if(dayStart > dailyResetTime)
    {
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        dailyResetTime = dayStart;
        if(EnableLogs) Print("DAILY RESET: New day started. Balance: $",
                             DoubleToString(dailyStartBalance, 2));
    }
}

//+------------------------------------------------------------------+
//| Get start of day (midnight) for a given time                      |
//+------------------------------------------------------------------+
datetime GetDayStart(datetime t)
{
    MqlDateTime dt;
    TimeToStruct(t, dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Pass Quick Checks — Balance + Spread                              |
//+------------------------------------------------------------------+
bool PassQuickChecks()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance < MinBalance)
    {
        static datetime lastWarning = 0;
        if(TimeCurrent() - lastWarning > 60)
        {
            Print("WARNING: Balance too low: $", DoubleToString(balance, 2), " < $", DoubleToString(MinBalance, 2));
            lastWarning = TimeCurrent();
        }
        return false;
    }

    int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread > MaxSpread_Pips * 10)
    {
        static datetime lastWarning2 = 0;
        if(TimeCurrent() - lastWarning2 > 60)
        {
            Print("WARNING: Spread too high: ", spread / 10, " pips > ", MaxSpread_Pips);
            lastWarning2 = TimeCurrent();
        }
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Count My Positions                                                |
//+------------------------------------------------------------------+
int CountMyPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetTicket(i) > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
                count++;
        }
    }
    return count;
}
//+------------------------------------------------------------------+
