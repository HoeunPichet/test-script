//+------------------------------------------------------------------+
//|                                          SmartTrendPro_EA.mq5    |
//|              AI-Powered Mixed Trading EA (BUY+SELL per bar)      |
//|              Super Smart Auto SL/TP Modification System          |
//|                                    Production-Ready v2.0          |
//+------------------------------------------------------------------+
#property copyright "SmartTrendPro EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "═══════════════════════════════════════════════════════"
input string   InpComment = "SmartTrendPro";              // Trade Comment
input int      InpMagic = 123456;                         // Magic Number

input group "═══════════════════════════════════════════════════════"
input double   InpMaxRiskPerTrade = 1.0;                  // Max Risk Per Trade (%)
input int      InpMaxPositions = 10;                      // Max Simultaneous Positions
input double   InpMaxDailyDrawdown = 15.0;                // Max Daily Drawdown (%)
input double   InpMaxSpreadPips = 3.0;                    // Max Spread (pips)
input int      InpMinBarsBetweenTrades = 2;               // Min Bars Between Trades

input group "═══════════════════════════════════════════════════════"
input int      InpEMA_Fast = 12;                          // EMA Fast Period
input int      InpEMA_Slow = 26;                          // EMA Slow Period
input int      InpADX_Period = 14;                        // ADX Period
input double   InpADX_MinLevel = 20.0;                    // ADX Minimum Level
input int      InpATR_Period = 14;                        // ATR Period
input double   InpATR_SL_Multiplier = 1.5;                // ATR SL Multiplier
input double   InpATR_TP_Multiplier = 2.5;                // ATR TP Multiplier
input int      InpRSI_Period = 14;                        // RSI Period

input group "═══════════════════════════════════════════════════════"
input bool     InpEnableTrailing = true;                  // Enable Trailing Stop
input double   InpTrailingStartPips = 10.0;              // Trailing Start (pips) - Fast Trading
input double   InpTrailingStepPips = 3.0;                 // Trailing Step (pips) - Aggressive
input bool     InpEnableBreakEven = true;                 // Enable Break-Even SL
input double   InpBreakEvenTriggerPips = 8.0;            // Break-Even Trigger (pips)
input double   InpBreakEvenOffsetPips = 2.0;             // Break-Even Offset (pips)
input bool     InpEnableTPFollowing = true;               // Enable TP Following (Move TP up)
input double   InpTPFollowingStartPips = 15.0;           // TP Following Start (pips)
input double   InpTPFollowingStepPips = 5.0;             // TP Following Step (pips)
input bool     InpEnablePartialProfit = false;            // Enable Partial Profit
input double   InpPartialProfitPercent = 50.0;           // Partial Profit (%)
input double   InpPartialProfitPips = 20.0;               // Partial Profit at (pips) - Fast
input bool     InpFastExitOnProfit = true;                // Fast Exit on Quick Profit
input double   InpFastExitProfitPips = 25.0;             // Fast Exit Profit Target (pips)

input group "═══════════════════════════════════════════════════════"
input bool     InpEnableNewsFilter = true;                // Enable News Analysis
input double   InpNewsVolatilitySpike = 2.5;              // News Volatility Spike (x normal)
input double   InpNewsSpreadSpike = 3.0;                  // News Spread Spike (x normal)
input bool     InpCloseOnNews = false;                    // Close Positions on News
input bool     InpTightenStopsOnNews = true;              // Tighten Stops on News
input int      InpNewsAvoidanceMinutes = 30;              // Avoid Trading (minutes after news)

input group "═══════════════════════════════════════════════════════"
input bool     InpAutoDetectCentAccount = true;           // Auto-Detect Cent Account
input bool     InpEnableLogging = true;                   // Enable Detailed Logging

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  position;
CAccountInfo   account;
CSymbolInfo    g_symbol;  // Renamed to avoid conflict with Trade.mqh

// Indicator Handles
int            h_EMA_Fast;
int            h_EMA_Slow;
int            h_ADX;
int            h_ATR;
int            h_RSI;

// Trend Analysis
struct TrendData {
    int direction;           // -1 = DOWN, 0 = NEUTRAL, 1 = UP
    double strength;         // 0-100
    double confidence;        // 0-100
    bool isValid;             // true if trend is strong enough
    double atrValue;          // Current ATR value
    double volatility;        // Volatility index
    bool isTrending;          // true if market is trending (not ranging)
    double momentum;          // Momentum score (-100 to +100)
    int marketRegime;         // 0=ranging, 1=trending, 2=high volatility
    double supportLevel;      // Key support level
    double resistanceLevel;   // Key resistance level
};

// Multi-Timeframe Analysis
struct TimeframeTrendData {
    int direction;           // -1 = DOWN, 0 = NEUTRAL, 1 = UP
    double strength;         // 0-100
    double confidence;       // 0-100
    double adxValue;         // ADX value
    double atrValue;         // ATR value
    double volatility;       // Volatility index
    bool isValid;            // true if trend is valid
    int bullishCandles;      // Count of bullish candles in last 50
    int bearishCandles;      // Count of bearish candles in last 50
    double avgBodySize;      // Average candle body size
    double higherHighs;      // Count of higher highs
    double lowerLows;        // Count of lower lows
};

TrendData      currentTrend;
TimeframeTrendData m1_Trend;   // 1-minute timeframe
TimeframeTrendData m5_Trend;   // 5-minute timeframe
TimeframeTrendData m15_Trend;  // 15-minute timeframe

// Account Management
bool           g_isCentAccount = false;
double         g_pipValue = 0.0001;
double         g_initialEquity = 0;
double         g_peakEquity = 0;
double         g_dailyStartEquity = 0;
datetime       g_lastDayCheck = 0;
datetime       g_lastTradeTime = 0;
int            g_barsSinceLastTrade = 0;
datetime       g_lastBarTime = 0;
datetime       g_lastBuyBarTime = 0;  // Track last BUY trade per bar
datetime       g_lastSellBarTime = 0; // Track last SELL trade per bar

// Position Tracking
int            g_buyPositions = 0;
int            g_sellPositions = 0;
double         g_totalExposure = 0;

// Performance Tracking (for Auto-Recovery & Dynamic Lot Size)
int            g_totalWins = 0;
int            g_totalLosses = 0;
int            g_consecutiveWins = 0;
int            g_consecutiveLosses = 0;
double         g_totalProfit = 0;
double         g_totalLoss = 0;
double         g_recentProfit = 0;        // Profit from last 10 trades
int            g_recentTradesCount = 0;   // Count of recent trades
double         g_winRate = 0;              // Win rate percentage
datetime       g_lastTradeCloseTime = 0;
double         g_recoveryMultiplier = 1.0; // Dynamic recovery multiplier
double         g_performanceMultiplier = 1.0; // Performance-based lot multiplier

// News Analysis
struct NewsData {
    bool isNewsDetected;           // True if news is detected
    double volatilitySpike;        // Current volatility vs normal
    double spreadSpike;            // Current spread vs normal
    bool isVolatilitySpike;        // Volatility spike detected
    bool isSpreadSpike;            // Spread spike detected
    bool isPriceGap;               // Price gap detected
    datetime newsStartTime;        // When news was detected
    string newsType;               // Type of news detected
    double normalATR;             // Normal ATR baseline
    double normalSpread;          // Normal spread baseline
};

NewsData       currentNews;
datetime       g_lastNewsCheck = 0;
double         g_normalATR = 0;
double         g_normalSpread = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trade objects
    trade.SetExpertMagicNumber(InpMagic);
    trade.SetDeviationInPoints(50);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    trade.SetAsyncMode(false);
    
    g_symbol.Name(_Symbol);
    g_symbol.Refresh();
    
    // Detect account type
    DetectAccountType();
    
    // Initialize equity tracking
    g_initialEquity = account.Equity();
    g_peakEquity = g_initialEquity;
    g_dailyStartEquity = g_initialEquity;
    g_lastDayCheck = TimeCurrent();
    
    // Initialize performance tracking
    g_totalWins = 0;
    g_totalLosses = 0;
    g_consecutiveWins = 0;
    g_consecutiveLosses = 0;
    g_totalProfit = 0;
    g_totalLoss = 0;
    g_recentProfit = 0;
    g_recentTradesCount = 0;
    g_winRate = 0;
    g_recoveryMultiplier = 1.0;
    g_performanceMultiplier = 1.0;
    
    // Create indicators
    h_EMA_Fast = iMA(_Symbol, PERIOD_CURRENT, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    h_EMA_Slow = iMA(_Symbol, PERIOD_CURRENT, InpEMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    h_ADX = iADX(_Symbol, PERIOD_CURRENT, InpADX_Period);
    h_ATR = iATR(_Symbol, PERIOD_CURRENT, InpATR_Period);
    h_RSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSI_Period, PRICE_CLOSE);
    
    // Verify indicators
    if(h_EMA_Fast == INVALID_HANDLE || h_EMA_Slow == INVALID_HANDLE ||
       h_ADX == INVALID_HANDLE || h_ATR == INVALID_HANDLE ||
       h_RSI == INVALID_HANDLE) {
        Print("❌ Failed to create indicators!");
        return INIT_FAILED;
    }
    
    // Wait for indicators to calculate
    Sleep(1000);
    
    // Initialize trend
    currentTrend.direction = 0;
    currentTrend.strength = 0;
    currentTrend.confidence = 0;
    currentTrend.isValid = false;
    currentTrend.isTrending = false;
    currentTrend.momentum = 0;
    currentTrend.marketRegime = 0;
    currentTrend.supportLevel = 0;
    currentTrend.resistanceLevel = 0;
    
    // Initialize news detection
    currentNews.isNewsDetected = false;
    currentNews.volatilitySpike = 1.0;
    currentNews.spreadSpike = 1.0;
    currentNews.isVolatilitySpike = false;
    currentNews.isSpreadSpike = false;
    currentNews.isPriceGap = false;
    currentNews.newsStartTime = 0;
    currentNews.newsType = "";
    currentNews.normalATR = 0;
    currentNews.normalSpread = 0;
    
    // Initialize baseline
    UpdateNewsBaseline();
    
    // Initialize bar tracking for mixed mode
    g_lastBuyBarTime = 0;
    g_lastSellBarTime = 0;
    
    Print("═══════════════════════════════════════════════════════════");
    Print("✅ SmartTrendPro EA Initialized Successfully");
    Print("🤖 MIXED MODE: BUY+SELL per bar enabled");
    Print("🤖 AI-POWERED: Super smart SL/TP auto-modification");
    Print("═══════════════════════════════════════════════════════════");
    Print("Account Type: ", g_isCentAccount ? "CENT (USC)" : "STANDARD (USD)");
    Print("Symbol: ", _Symbol);
    Print("Max Risk Per Trade: ", InpMaxRiskPerTrade, "%");
    Print("Max Positions: ", InpMaxPositions);
    Print("Max Spread: ", InpMaxSpreadPips, " pips");
    Print("Pip Value: ", g_pipValue);
    Print("═══════════════════════════════════════════════════════════");
    Print("News Filter: ", InpEnableNewsFilter ? "ENABLED" : "DISABLED");
    if(InpEnableNewsFilter) {
        Print("   Volatility Spike Threshold: ", InpNewsVolatilitySpike, "x");
        Print("   Spread Spike Threshold: ", InpNewsSpreadSpike, "x");
        Print("   Close on News: ", InpCloseOnNews ? "YES" : "NO");
        Print("   Tighten Stops on News: ", InpTightenStopsOnNews ? "YES" : "NO");
        Print("   Avoid Trading: ", InpNewsAvoidanceMinutes, " minutes after news");
    }
    Print("═══════════════════════════════════════════════════════════");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicators
    if(h_EMA_Fast != INVALID_HANDLE) IndicatorRelease(h_EMA_Fast);
    if(h_EMA_Slow != INVALID_HANDLE) IndicatorRelease(h_EMA_Slow);
    if(h_ADX != INVALID_HANDLE) IndicatorRelease(h_ADX);
    if(h_ATR != INVALID_HANDLE) IndicatorRelease(h_ATR);
    if(h_RSI != INVALID_HANDLE) IndicatorRelease(h_RSI);
    
    Print("SmartTrendPro EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    // Refresh symbol data
    g_symbol.Refresh();
    g_symbol.RefreshRates();
    
    // Periodic logging (every 10 seconds)
    static datetime lastLogTime = 0;
    static int tickCounter = 0;
    tickCounter++;
    bool shouldLog = (TimeCurrent() - lastLogTime >= 10) || (tickCounter % 100 == 0);
    
    if(shouldLog)
    {
        Print("═══════════════════════════════════════════════════════════");
        Print("📊 ONTICK STATUS CHECK - ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
        Print("═══════════════════════════════════════════════════════════");
        
        // News status summary
        if(InpEnableNewsFilter) {
            if(currentNews.isNewsDetected) {
                double minutesSinceNews = (TimeCurrent() - currentNews.newsStartTime) / 60.0;
                Print("🚨 NEWS STATUS: ACTIVE");
                Print("   Type: ", currentNews.newsType);
                Print("   Duration: ", DoubleToString(minutesSinceNews, 1), " minutes");
                Print("   Volatility: ", DoubleToString(currentNews.volatilitySpike, 2), "x normal");
                Print("   Spread: ", DoubleToString(currentNews.spreadSpike, 2), "x normal");
            }
            else {
                Print("✅ News Status: CLEAR (No unexpected news)");
            }
        }
        
        lastLogTime = TimeCurrent();
    }
    
    // Check for new bar
    datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBar != g_lastBarTime);
    if(isNewBar) {
        g_lastBarTime = currentBar;
        g_barsSinceLastTrade++;
    }
    
    // Daily reset check
    CheckDailyReset();
    
    // Analyze unexpected news events
    if(InpEnableNewsFilter) {
        AnalyzeNewsEvents(shouldLog);
    }
    
    // Emergency equity protection
    if(CheckEmergencyStop()) {
        CloseAllPositions("Emergency Stop - Max Drawdown Exceeded");
        return;
    }
    
    // Block trading during news events
    if(InpEnableNewsFilter && currentNews.isNewsDetected) {
        if(shouldLog) {
            Print("⚠️ NEWS DETECTED - Trading Blocked");
            Print("   News Type: ", currentNews.newsType);
            Print("   Volatility Spike: ", DoubleToString(currentNews.volatilitySpike, 2), "x");
            Print("   Spread Spike: ", DoubleToString(currentNews.spreadSpike, 2), "x");
        }
        
        // Close positions if enabled
        if(InpCloseOnNews) {
            CloseAllPositions("News Event Detected");
        }
        // Or tighten stops
        else if(InpTightenStopsOnNews) {
            TightenStopsOnNews();
        }
        
        // Block new trades during news
        if(TimeCurrent() - currentNews.newsStartTime < InpNewsAvoidanceMinutes * 60) {
            if(shouldLog) Print("⏸️  Waiting for news to settle (", InpNewsAvoidanceMinutes, " minutes)");
            if(shouldLog) Print("═══════════════════════════════════════════════════════════");
            return;
        }
    }
    
    // Update position counts
    UpdatePositionCounts();
    
    if(shouldLog)
    {
        Print("📊 Position Status:");
        Print("   BUY Positions: ", g_buyPositions, " | SELL Positions: ", g_sellPositions);
        Print("   Total Positions: ", (g_buyPositions + g_sellPositions), "/", InpMaxPositions);
        Print("   Total Exposure: ", DoubleToString(g_totalExposure, 2), " lots");
    }
    
    // Calculate multi-timeframe trend analysis (50+ candles per timeframe)
    AnalyzeMultiTimeframe(shouldLog, isNewBar);
    
    // Calculate current trend (combined multi-timeframe analysis)
    CalculateTrend(shouldLog, isNewBar);
    
    // Manage open positions (trailing stop, partial profit)
    ManageOpenPositions();
    
    // Check if we can open new trades
    if(!CanOpenNewTrade(shouldLog)) {
        if(shouldLog) Print("═══════════════════════════════════════════════════════════");
        return;
    }
    
    // Execute trades based on trend
    ExecuteTradeLogic(shouldLog);
    
    if(shouldLog) Print("═══════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Detect Account Type                                               |
//+------------------------------------------------------------------+
void DetectAccountType()
{
    string accountCurrency = account.Currency();
    double accountBalance = account.Balance();
    
    if(InpAutoDetectCentAccount) {
        if(StringFind(accountCurrency, "USC") >= 0 || StringFind(accountCurrency, "C") >= 0) {
            g_isCentAccount = true;
        }
        else if(StringFind(accountCurrency, "USD") >= 0 && accountBalance < 100.0) {
            g_isCentAccount = true;
        }
    }
    
    // Calculate pip value
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(g_isCentAccount || digits == 3 || digits == 5) {
        g_pipValue = point * 10;
    }
    else {
        g_pipValue = point;
    }
}

//+------------------------------------------------------------------+
//| Get Pip Value                                                     |
//+------------------------------------------------------------------+
double GetPipValue()
{
    return g_pipValue;
}

//+------------------------------------------------------------------+
//| Convert Pips to Points                                            |
//+------------------------------------------------------------------+
double PipsToPoints(double pips)
{
    return pips * (g_pipValue / g_symbol.Point());
}

//+------------------------------------------------------------------+
//| Convert Points to Pips                                            |
//+------------------------------------------------------------------+
double PointsToPips(double points)
{
    if(g_pipValue > 0)
        return points / (g_pipValue / g_symbol.Point());
    return 0;
}

//+------------------------------------------------------------------+
//| Analyze Multi-Timeframe (50+ candles per timeframe)              |
//+------------------------------------------------------------------+
void AnalyzeMultiTimeframe(bool logDetails = false, bool isNewBar = false)
{
    // Analyze 1-minute timeframe
    AnalyzeTimeframe(PERIOD_M1, m1_Trend, logDetails);
    
    // Analyze 5-minute timeframe
    AnalyzeTimeframe(PERIOD_M5, m5_Trend, logDetails);
    
    // Analyze 15-minute timeframe
    AnalyzeTimeframe(PERIOD_M15, m15_Trend, logDetails);
    
    if(logDetails && isNewBar)
    {
        Print("═══════════════════════════════════════════════════════════");
        Print("📊 MULTI-TIMEFRAME ANALYSIS (50+ candles each)");
        Print("═══════════════════════════════════════════════════════════");
        Print("1-MINUTE (M1):");
        Print("   Direction: ", m1_Trend.direction == 1 ? "UP" : (m1_Trend.direction == -1 ? "DOWN" : "NEUTRAL"));
        Print("   Strength: ", DoubleToString(m1_Trend.strength, 1), "/100");
        Print("   Confidence: ", DoubleToString(m1_Trend.confidence, 1), "%");
        Print("   ADX: ", DoubleToString(m1_Trend.adxValue, 1));
        Print("   Bullish Candles: ", m1_Trend.bullishCandles, "/50");
        Print("   Bearish Candles: ", m1_Trend.bearishCandles, "/50");
        Print("   Higher Highs: ", DoubleToString(m1_Trend.higherHighs, 0));
        Print("   Lower Lows: ", DoubleToString(m1_Trend.lowerLows, 0));
        Print("5-MINUTE (M5):");
        Print("   Direction: ", m5_Trend.direction == 1 ? "UP" : (m5_Trend.direction == -1 ? "DOWN" : "NEUTRAL"));
        Print("   Strength: ", DoubleToString(m5_Trend.strength, 1), "/100");
        Print("   Confidence: ", DoubleToString(m5_Trend.confidence, 1), "%");
        Print("   ADX: ", DoubleToString(m5_Trend.adxValue, 1));
        Print("   Bullish Candles: ", m5_Trend.bullishCandles, "/50");
        Print("   Bearish Candles: ", m5_Trend.bearishCandles, "/50");
        Print("   Higher Highs: ", DoubleToString(m5_Trend.higherHighs, 0));
        Print("   Lower Lows: ", DoubleToString(m5_Trend.lowerLows, 0));
        Print("15-MINUTE (M15):");
        Print("   Direction: ", m15_Trend.direction == 1 ? "UP" : (m15_Trend.direction == -1 ? "DOWN" : "NEUTRAL"));
        Print("   Strength: ", DoubleToString(m15_Trend.strength, 1), "/100");
        Print("   Confidence: ", DoubleToString(m15_Trend.confidence, 1), "%");
        Print("   ADX: ", DoubleToString(m15_Trend.adxValue, 1));
        Print("   Bullish Candles: ", m15_Trend.bullishCandles, "/50");
        Print("   Bearish Candles: ", m15_Trend.bearishCandles, "/50");
        Print("   Higher Highs: ", DoubleToString(m15_Trend.higherHighs, 0));
        Print("   Lower Lows: ", DoubleToString(m15_Trend.lowerLows, 0));
        Print("═══════════════════════════════════════════════════════════");
    }
}

//+------------------------------------------------------------------+
//| Analyze Single Timeframe (50+ candles)                           |
//+------------------------------------------------------------------+
void AnalyzeTimeframe(ENUM_TIMEFRAMES timeframe, TimeframeTrendData &tfData, bool logDetails = false)
{
    // Create indicator handles for this timeframe
    int h_EMA_Fast_TF = iMA(_Symbol, timeframe, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
    int h_EMA_Slow_TF = iMA(_Symbol, timeframe, InpEMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
    int h_ADX_TF = iADX(_Symbol, timeframe, InpADX_Period);
    int h_ATR_TF = iATR(_Symbol, timeframe, InpATR_Period);
    int h_RSI_TF = iRSI(_Symbol, timeframe, InpRSI_Period, PRICE_CLOSE);
    
    if(h_EMA_Fast_TF == INVALID_HANDLE || h_EMA_Slow_TF == INVALID_HANDLE ||
       h_ADX_TF == INVALID_HANDLE || h_ATR_TF == INVALID_HANDLE ||
       h_RSI_TF == INVALID_HANDLE) {
        tfData.isValid = false;
        return;
    }
    
    // Prepare arrays for 50+ candles
    double ema_fast[], ema_slow[], adx[], plusDI[], minusDI[], atr[], rsi[];
    double close[], high[], low[], open[];
    
    ArraySetAsSeries(ema_fast, true);
    ArraySetAsSeries(ema_slow, true);
    ArraySetAsSeries(adx, true);
    ArraySetAsSeries(plusDI, true);
    ArraySetAsSeries(minusDI, true);
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);
    
    // Copy 50+ candles of data
    int candlesToAnalyze = 50;
    if(CopyBuffer(h_EMA_Fast_TF, 0, 0, candlesToAnalyze, ema_fast) < candlesToAnalyze) {
        IndicatorRelease(h_EMA_Fast_TF);
        IndicatorRelease(h_EMA_Slow_TF);
        IndicatorRelease(h_ADX_TF);
        IndicatorRelease(h_ATR_TF);
        IndicatorRelease(h_RSI_TF);
        tfData.isValid = false;
        return;
    }
    
    if(CopyBuffer(h_EMA_Slow_TF, 0, 0, candlesToAnalyze, ema_slow) < candlesToAnalyze) return;
    if(CopyBuffer(h_ADX_TF, 0, 0, candlesToAnalyze, adx) < candlesToAnalyze) return;
    if(CopyBuffer(h_ADX_TF, 1, 0, candlesToAnalyze, plusDI) < candlesToAnalyze) return;
    if(CopyBuffer(h_ADX_TF, 2, 0, candlesToAnalyze, minusDI) < candlesToAnalyze) return;
    if(CopyBuffer(h_ATR_TF, 0, 0, candlesToAnalyze, atr) < candlesToAnalyze) return;
    if(CopyBuffer(h_RSI_TF, 0, 0, candlesToAnalyze, rsi) < candlesToAnalyze) return;
    if(CopyClose(_Symbol, timeframe, 0, candlesToAnalyze, close) < candlesToAnalyze) return;
    if(CopyHigh(_Symbol, timeframe, 0, candlesToAnalyze, high) < candlesToAnalyze) return;
    if(CopyLow(_Symbol, timeframe, 0, candlesToAnalyze, low) < candlesToAnalyze) return;
    if(CopyOpen(_Symbol, timeframe, 0, candlesToAnalyze, open) < candlesToAnalyze) return;
    
    // Store ATR value
    tfData.atrValue = atr[0];
    tfData.adxValue = adx[0];
    
    // Calculate volatility
    double avgATR = 0;
    for(int i = 0; i < candlesToAnalyze; i++) {
        avgATR += atr[i];
    }
    avgATR /= candlesToAnalyze;
    tfData.volatility = (atr[0] / avgATR) * 100.0;
    
    // ───────────────────────────────────────────────────────
    // ANALYZE 50 CANDLES: Candle Pattern Analysis
    // ───────────────────────────────────────────────────────
    tfData.bullishCandles = 0;
    tfData.bearishCandles = 0;
    double totalBodySize = 0;
    tfData.higherHighs = 0;
    tfData.lowerLows = 0;
    
    for(int i = 0; i < candlesToAnalyze; i++) {
        // Count bullish/bearish candles
        if(close[i] > open[i]) {
            tfData.bullishCandles++;
        }
        else if(close[i] < open[i]) {
            tfData.bearishCandles++;
        }
        
        // Calculate body size
        double bodySize = MathAbs(close[i] - open[i]);
        totalBodySize += bodySize;
        
        // Detect higher highs and lower lows
        if(i > 0) {
            if(high[i] > high[i-1]) {
                tfData.higherHighs++;
            }
            if(low[i] < low[i-1]) {
                tfData.lowerLows++;
            }
        }
    }
    
    tfData.avgBodySize = totalBodySize / candlesToAnalyze;
    
    // ───────────────────────────────────────────────────────
    // TREND DIRECTION ANALYSIS
    // ───────────────────────────────────────────────────────
    double trendScore = 0;
    double confidenceScore = 0;
    
    // EMA Analysis
    bool emaBullish = ema_fast[0] > ema_slow[0];
    bool emaBearish = ema_fast[0] < ema_slow[0];
    
    if(emaBullish) {
        trendScore += 25;
        confidenceScore += 15;
        
        // EMA alignment over 50 candles
        int emaBullishCount = 0;
        for(int i = 0; i < 20; i++) {
            if(ema_fast[i] > ema_slow[i]) emaBullishCount++;
        }
        if(emaBullishCount >= 15) {
            trendScore += 15;
            confidenceScore += 10;
        }
    }
    else if(emaBearish) {
        trendScore -= 25;
        confidenceScore += 15;
        
        // EMA alignment over 50 candles
        int emaBearishCount = 0;
        for(int i = 0; i < 20; i++) {
            if(ema_fast[i] < ema_slow[i]) emaBearishCount++;
        }
        if(emaBearishCount >= 15) {
            trendScore -= 15;
            confidenceScore += 10;
        }
    }
    
    // ADX Trend Strength
    if(adx[0] >= InpADX_MinLevel) {
        confidenceScore += 20;
        
        if(plusDI[0] > minusDI[0] && emaBullish) {
            trendScore += 20;
            confidenceScore += 15;
        }
        else if(minusDI[0] > plusDI[0] && emaBearish) {
            trendScore -= 20;
            confidenceScore += 15;
        }
        
        // ADX strength multiplier
        double adxMultiplier = MathMin(adx[0] / 30.0, 1.5);
        trendScore *= adxMultiplier;
    }
    
    // Candle Pattern Weight (from 50 candles analysis)
    double bullishRatio = (double)tfData.bullishCandles / candlesToAnalyze;
    double bearishRatio = (double)tfData.bearishCandles / candlesToAnalyze;
    
    if(bullishRatio > 0.6) {
        trendScore += 15;
        confidenceScore += 10;
    }
    else if(bearishRatio > 0.6) {
        trendScore -= 15;
        confidenceScore += 10;
    }
    
    // Market Structure (Higher Highs / Lower Lows)
    double hhRatio = tfData.higherHighs / candlesToAnalyze;
    double llRatio = tfData.lowerLows / candlesToAnalyze;
    
    if(hhRatio > 0.4 && emaBullish) {
        trendScore += 10;
        confidenceScore += 5;
    }
    else if(llRatio > 0.4 && emaBearish) {
        trendScore -= 10;
        confidenceScore += 5;
    }
    
    // RSI Confirmation
    if(rsi[0] > 50 && rsi[0] < 70 && emaBullish) {
        trendScore += 10;
    }
    else if(rsi[0] < 50 && rsi[0] > 30 && emaBearish) {
        trendScore -= 10;
    }
    
    // Finalize trend data
    tfData.strength = MathAbs(trendScore);
    tfData.confidence = MathMin(confidenceScore, 100);
    
    // Determine direction
    if(trendScore > 30 && adx[0] >= InpADX_MinLevel) {
        tfData.direction = 1;  // UPTREND
        tfData.isValid = true;
    }
    else if(trendScore < -30 && adx[0] >= InpADX_MinLevel) {
        tfData.direction = -1; // DOWNTREND
        tfData.isValid = true;
    }
    else {
        tfData.direction = 0;  // NEUTRAL
        tfData.isValid = (adx[0] >= InpADX_MinLevel && tfData.strength > 20);
    }
    
    // Release indicator handles
    IndicatorRelease(h_EMA_Fast_TF);
    IndicatorRelease(h_EMA_Slow_TF);
    IndicatorRelease(h_ADX_TF);
    IndicatorRelease(h_ATR_TF);
    IndicatorRelease(h_RSI_TF);
}

//+------------------------------------------------------------------+
//| Detect Market Regime (Trending vs Ranging)                        |
//+------------------------------------------------------------------+
void DetectMarketRegime()
{
    // Analyze price action over last 50 bars to determine market regime
    double close[], high[], low[];
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 50, close) < 50) return;
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 50, high) < 50) return;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 50, low) < 50) return;
    
    // Calculate price range
    double maxPrice = high[ArrayMaximum(high, 0, 50)];
    double minPrice = low[ArrayMinimum(low, 0, 50)];
    double priceRange = maxPrice - minPrice;
    double avgPrice = (maxPrice + minPrice) / 2.0;
    double rangePercent = (priceRange / avgPrice) * 100.0;
    
    // Calculate ADX to determine trend strength
    double adx[];
    ArraySetAsSeries(adx, true);
    if(CopyBuffer(h_ADX, 0, 0, 20, adx) < 20) return;
    
    double avgADX = 0;
    for(int i = 0; i < 20; i++) {
        avgADX += adx[i];
    }
    avgADX /= 20.0;
    
    // Determine market regime
    if(avgADX > 25 && rangePercent > 0.5) {
        currentTrend.marketRegime = 1; // Trending
        currentTrend.isTrending = true;
    }
    else if(currentTrend.volatility > 130) {
        currentTrend.marketRegime = 2; // High volatility
        currentTrend.isTrending = false;
    }
    else {
        currentTrend.marketRegime = 0; // Ranging
        currentTrend.isTrending = false;
    }
    
    // Calculate key support and resistance levels
    currentTrend.supportLevel = minPrice;
    currentTrend.resistanceLevel = maxPrice;
    
    // Find more precise S/R levels (swing points)
    for(int i = 5; i < 45; i++) {
        bool isSwingLow = true;
        bool isSwingHigh = true;
        
        for(int j = i - 3; j <= i + 3; j++) {
            if(j != i) {
                if(low[j] < low[i]) isSwingLow = false;
                if(high[j] > high[i]) isSwingHigh = false;
            }
        }
        
        if(isSwingLow && low[i] < currentTrend.supportLevel && low[i] > close[0] * 0.95) {
            currentTrend.supportLevel = low[i];
        }
        if(isSwingHigh && high[i] > currentTrend.resistanceLevel && high[i] < close[0] * 1.05) {
            currentTrend.resistanceLevel = high[i];
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate Momentum Score                                         |
//+------------------------------------------------------------------+
void CalculateMomentum()
{
    double close[], rsi[], ema_fast[], ema_slow[];
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(ema_fast, true);
    ArraySetAsSeries(ema_slow, true);
    
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 20, close) < 20) return;
    if(CopyBuffer(h_RSI, 0, 0, 5, rsi) < 5) return;
    if(CopyBuffer(h_EMA_Fast, 0, 0, 5, ema_fast) < 5) return;
    if(CopyBuffer(h_EMA_Slow, 0, 0, 5, ema_slow) < 5) return;
    
    double momentumScore = 0;
    
    // Price momentum (rate of change)
    double priceChange = (close[0] - close[4]) / close[4] * 100.0;
    momentumScore += priceChange * 2.0;
    
    // EMA momentum
    if(ema_fast[0] > ema_slow[0] && ema_fast[0] > ema_fast[1]) {
        momentumScore += 20; // Strong bullish momentum
    }
    else if(ema_fast[0] < ema_slow[0] && ema_fast[0] < ema_fast[1]) {
        momentumScore -= 20; // Strong bearish momentum
    }
    
    // RSI momentum
    if(rsi[0] > 60 && rsi[0] < 80) {
        momentumScore += 15; // Bullish but not overbought
    }
    else if(rsi[0] < 40 && rsi[0] > 20) {
        momentumScore -= 15; // Bearish but not oversold
    }
    else if(rsi[0] > 80) {
        momentumScore -= 10; // Overbought
    }
    else if(rsi[0] < 20) {
        momentumScore += 10; // Oversold (potential reversal)
    }
    
    // Volume/price action momentum (using ATR as proxy)
    double atrPips = PointsToPips(currentTrend.atrValue);
    if(atrPips > 20) {
        momentumScore *= 1.2; // High volatility = stronger momentum
    }
    
    currentTrend.momentum = MathMax(-100, MathMin(100, momentumScore));
}

//+------------------------------------------------------------------+
//| Calculate Trend (Combined Multi-Timeframe Analysis)              |
//+------------------------------------------------------------------+
void CalculateTrend(bool logDetails = false, bool isNewBar = false)
{
    // ───────────────────────────────────────────────────────
    // COMBINE MULTI-TIMEFRAME ANALYSIS
    // ───────────────────────────────────────────────────────
    // Weight: M15 (40%), M5 (35%), M1 (25%)
    
    double combinedTrendScore = 0;
    double combinedConfidence = 0;
    double combinedStrength = 0;
    int directionVotes = 0; // +1 for UP, -1 for DOWN
    
    // 15-minute timeframe (highest weight - 40%)
    if(m15_Trend.isValid) {
        double weight = 0.40;
        combinedTrendScore += m15_Trend.direction * m15_Trend.strength * weight;
        combinedConfidence += m15_Trend.confidence * weight;
        combinedStrength += m15_Trend.strength * weight;
        directionVotes += m15_Trend.direction;
    }
    
    // 5-minute timeframe (medium weight - 35%)
    if(m5_Trend.isValid) {
        double weight = 0.35;
        combinedTrendScore += m5_Trend.direction * m5_Trend.strength * weight;
        combinedConfidence += m5_Trend.confidence * weight;
        combinedStrength += m5_Trend.strength * weight;
        directionVotes += m5_Trend.direction;
    }
    
    // 1-minute timeframe (lower weight - 25%)
    if(m1_Trend.isValid) {
        double weight = 0.25;
        combinedTrendScore += m1_Trend.direction * m1_Trend.strength * weight;
        combinedConfidence += m1_Trend.confidence * weight;
        combinedStrength += m1_Trend.strength * weight;
        directionVotes += m1_Trend.direction;
    }
    
    // Get current timeframe data for ATR
    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(h_ATR, 0, 0, 3, atr) < 3) return;
    currentTrend.atrValue = atr[0];
    
    // Calculate volatility from current timeframe
    double avgATR = 0;
    for(int i = 0; i < 20; i++) {
        double atrTemp[];
        ArraySetAsSeries(atrTemp, true);
        if(CopyBuffer(h_ATR, 0, i, 1, atrTemp) > 0) {
            avgATR += atrTemp[0];
        }
    }
    avgATR /= 20.0;
    currentTrend.volatility = (atr[0] / avgATR) * 100.0;
    
    // ───────────────────────────────────────────────────────
    // FINALIZE COMBINED TREND
    // ───────────────────────────────────────────────────────
    currentTrend.strength = combinedStrength;
    currentTrend.confidence = combinedConfidence;
    
    // AGGRESSIVE MODE: Lower thresholds for more trades
    // Determine direction based on analysis (no strict consensus required)
    // Use weighted analysis - lower timeframes can drive decision if strong enough
    if(directionVotes >= 1) {
        // At least 1 timeframe shows UP (prefer M5+M1 if M15 is neutral)
        currentTrend.direction = 1;
        
        // AGGRESSIVE: Lower validation thresholds
        if(m15_Trend.direction == 0 && m5_Trend.isValid && m1_Trend.isValid) {
            // M15 neutral, but M5 and M1 agree - allow trade (AGGRESSIVE: lower thresholds)
            if(m5_Trend.direction == 1 && m1_Trend.direction == 1) {
                currentTrend.isValid = (m5_Trend.strength > 20 && m1_Trend.strength > 20); // Lowered from 30
                currentTrend.confidence = (m5_Trend.confidence + m1_Trend.confidence) / 2.0;
            }
            else {
                currentTrend.isValid = (combinedStrength > 25 && combinedConfidence > 35); // Lowered thresholds
            }
        }
        else {
            // M15 has direction or standard validation (AGGRESSIVE: lower thresholds)
            currentTrend.isValid = (combinedStrength > 25 && combinedConfidence > 35); // Lowered from 35/45
        }
    }
    else if(directionVotes <= -1) {
        // At least 1 timeframe shows DOWN (prefer M5+M1 if M15 is neutral)
        currentTrend.direction = -1;
        
        // AGGRESSIVE: Lower validation thresholds
        if(m15_Trend.direction == 0 && m5_Trend.isValid && m1_Trend.isValid) {
            // M15 neutral, but M5 and M1 agree - allow trade (AGGRESSIVE: lower thresholds)
            if(m5_Trend.direction == -1 && m1_Trend.direction == -1) {
                currentTrend.isValid = (m5_Trend.strength > 20 && m1_Trend.strength > 20); // Lowered from 30
                currentTrend.confidence = (m5_Trend.confidence + m1_Trend.confidence) / 2.0;
            }
            else {
                currentTrend.isValid = (combinedStrength > 25 && combinedConfidence > 35); // Lowered thresholds
            }
        }
        else {
            // M15 has direction or standard validation (AGGRESSIVE: lower thresholds)
            currentTrend.isValid = (combinedStrength > 25 && combinedConfidence > 35); // Lowered from 35/45
        }
    }
    else {
        // Truly mixed signals
        currentTrend.direction = 0;
        currentTrend.isValid = false;
    }
    
    // Boost confidence if M15 agrees, but don't require it
    if(currentTrend.direction != 0 && m15_Trend.isValid && m15_Trend.direction == currentTrend.direction) {
        currentTrend.confidence += 15;
    }
    
    // Detect market regime and calculate momentum
    DetectMarketRegime();
    CalculateMomentum();
    
    // Adjust confidence based on market regime
    if(currentTrend.isTrending && currentTrend.direction != 0) {
        currentTrend.confidence += 10; // Higher confidence in trending markets
    }
    else if(currentTrend.marketRegime == 0 && currentTrend.direction != 0) {
        currentTrend.confidence -= 10; // Lower confidence in ranging markets
    }
    
    // Adjust confidence based on momentum
    if(currentTrend.direction == 1 && currentTrend.momentum > 30) {
        currentTrend.confidence += 5;
    }
    else if(currentTrend.direction == -1 && currentTrend.momentum < -30) {
        currentTrend.confidence += 5;
    }
    else if((currentTrend.direction == 1 && currentTrend.momentum < -20) ||
            (currentTrend.direction == -1 && currentTrend.momentum > 20)) {
        currentTrend.confidence -= 15; // Momentum divergence
    }
    
    currentTrend.confidence = MathMax(0, MathMin(100, currentTrend.confidence));
    
    // Log combined trend if enabled
    if((InpEnableLogging || logDetails) && isNewBar) {
        Print("═══════════════════════════════════════════════════════════");
        Print("📊 COMBINED MULTI-TIMEFRAME TREND");
        Print("═══════════════════════════════════════════════════════════");
        Print("Final Direction: ", currentTrend.direction == 1 ? "UP" : (currentTrend.direction == -1 ? "DOWN" : "NEUTRAL"));
        Print("Combined Strength: ", DoubleToString(currentTrend.strength, 1), "/100");
        Print("Combined Confidence: ", DoubleToString(currentTrend.confidence, 1), "%");
        Print("Direction Votes: ", directionVotes, " (M15:", m15_Trend.direction, " M5:", m5_Trend.direction, " M1:", m1_Trend.direction, ")");
        Print("ATR: ", DoubleToString(PointsToPips(currentTrend.atrValue), 2), " pips");
        Print("Volatility: ", DoubleToString(currentTrend.volatility, 1), "%");
        Print("Market Regime: ", currentTrend.marketRegime == 1 ? "TRENDING" : (currentTrend.marketRegime == 2 ? "HIGH VOLATILITY" : "RANGING"));
        Print("Momentum: ", DoubleToString(currentTrend.momentum, 1));
        Print("Support Level: ", DoubleToString(currentTrend.supportLevel, _Digits));
        Print("Resistance Level: ", DoubleToString(currentTrend.resistanceLevel, _Digits));
        Print("Trend Valid: ", currentTrend.isValid ? "YES" : "NO");
        Print("═══════════════════════════════════════════════════════════");
    }
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size (Optimized for Small Cent Accounts)    |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPips)
{
    if(stopLossPips <= 0) return 0.01;
    
    // Get account data
    double balance = account.Balance();
    double equity = account.Equity();
    double freeMargin = account.FreeMargin();
    
    // ═══════════════════════════════════════════════════════
    // SMALL ACCOUNT PROTECTION (100 cents = $1.00)
    // ═══════════════════════════════════════════════════════
    
    // For very small cent accounts, use conservative lot sizing
    bool isVerySmallAccount = false;
    double accountSizeUSD = balance;
    
    if(g_isCentAccount) {
        // Cent account: balance is in USC (cents), convert to USD
        accountSizeUSD = balance / 100.0;
        if(accountSizeUSD < 5.0) { // Less than $5 USD
            isVerySmallAccount = true;
        }
    }
    else {
        if(accountSizeUSD < 5.0) {
            isVerySmallAccount = true;
        }
    }
    
    // Calculate risk amount
    double riskAmount = balance * (InpMaxRiskPerTrade / 100.0);
    
    // For very small accounts, reduce risk further
    if(isVerySmallAccount) {
        // Cap risk at 0.5% for accounts under $5
        double maxRiskPercent = MathMin(InpMaxRiskPerTrade, 0.5);
        riskAmount = balance * (maxRiskPercent / 100.0);
    }
    
    // Adjust for drawdown
    double drawdownPercent = 0;
    if(g_peakEquity > 0) {
        drawdownPercent = ((g_peakEquity - equity) / g_peakEquity) * 100.0;
    }
    
    // Reduce lot size during drawdown
    double drawdownMultiplier = 1.0;
    if(drawdownPercent > 5.0) {
        drawdownMultiplier = 1.0 - (drawdownPercent / 100.0);
        drawdownMultiplier = MathMax(drawdownMultiplier, 0.3); // Minimum 30% for small accounts
    }
    
    // Calculate point value
    double tickValue = g_symbol.TickValue();
    double tickSize = g_symbol.TickSize();
    double pointValue = (tickValue / tickSize) * GetPipValue();
    
    // Calculate lot size
    double lotSize = 0.01;
    if(pointValue > 0 && stopLossPips > 0) {
        lotSize = riskAmount / (stopLossPips * pointValue);
    }
    
    // Apply drawdown multiplier
    lotSize *= drawdownMultiplier;
    
    // ═══════════════════════════════════════════════════════
    // AUTO-RECOVERY & DYNAMIC LOT SIZE ADJUSTMENT
    // ═══════════════════════════════════════════════════════
    
    // Calculate win rate
    int totalTrades = g_totalWins + g_totalLosses;
    if(totalTrades > 0) {
        g_winRate = (double)g_totalWins / (double)totalTrades * 100.0;
    }
    
    // Update recovery multiplier based on consecutive losses
    if(g_consecutiveLosses >= 2) {
        // After 2+ losses, start recovery mode (gradual increase)
        // Safe recovery: 1.1x, 1.2x, 1.3x, 1.4x, 1.5x max
        g_recoveryMultiplier = 1.0 + (g_consecutiveLosses - 1) * 0.1;
        g_recoveryMultiplier = MathMin(g_recoveryMultiplier, 1.5); // Max 1.5x for safety
    }
    else if(g_consecutiveWins >= 3) {
        // After 3+ wins, reduce recovery multiplier (we're back on track)
        g_recoveryMultiplier = MathMax(1.0, g_recoveryMultiplier - 0.1);
    }
    else if(g_consecutiveWins == 0 && g_consecutiveLosses == 0) {
        // Reset to normal after break-even
        g_recoveryMultiplier = 1.0;
    }
    
    // Update performance multiplier based on recent performance
    if(g_recentTradesCount >= 5) {
        // Calculate recent win rate (last 10 trades)
        double recentWinRate = 0;
        if(g_recentTradesCount > 0) {
            // Estimate from recent profit
            if(g_recentProfit > 0) {
                recentWinRate = 60.0; // Assume positive = good performance
            }
            else {
                recentWinRate = 40.0; // Negative = poor performance
            }
        }
        
        // Adjust lot size based on recent performance
        if(recentWinRate >= 60.0 && g_winRate >= 55.0) {
            // Good performance: increase lot size slightly
            g_performanceMultiplier = 1.0 + ((recentWinRate - 50.0) / 100.0) * 0.3;
            g_performanceMultiplier = MathMin(g_performanceMultiplier, 1.3); // Max 1.3x
        }
        else if(recentWinRate < 40.0 || g_winRate < 45.0) {
            // Poor performance: reduce lot size
            g_performanceMultiplier = 1.0 - ((50.0 - recentWinRate) / 100.0) * 0.2;
            g_performanceMultiplier = MathMax(g_performanceMultiplier, 0.7); // Min 0.7x
        }
        else {
            // Average performance: normal lot size
            g_performanceMultiplier = 1.0;
        }
    }
    
    // Apply recovery and performance multipliers
    lotSize *= g_recoveryMultiplier;
    lotSize *= g_performanceMultiplier;
    
    // ═══════════════════════════════════════════════════════
    // ACCOUNT SIZE-BASED MAXIMUM LOT SIZE
    // ═══════════════════════════════════════════════════════
    
    // Calculate maximum lot size based on account balance
    double maxLotByBalance = 0.01;
    if(g_isCentAccount) {
        // For cent accounts: balance in USC
        // Conservative: max 10% of account per trade
        if(balance >= 1000) { // $10 USD
            maxLotByBalance = 0.10;
        }
        else if(balance >= 500) { // $5 USD
            maxLotByBalance = 0.05;
        }
        else if(balance >= 200) { // $2 USD
            maxLotByBalance = 0.02;
        }
        else { // $1 USD (100 cents)
            maxLotByBalance = 0.01; // Maximum 0.01 lot for 100 cent account
        }
    }
    else {
        // Standard account
        if(balance >= 100) {
            maxLotByBalance = 1.0;
        }
        else if(balance >= 50) {
            maxLotByBalance = 0.5;
        }
        else if(balance >= 10) {
            maxLotByBalance = 0.1;
        }
        else {
            maxLotByBalance = 0.01;
        }
    }
    
    // AGGRESSIVE: Scale based on trend strength (pyramiding) - more aggressive
    int totalPositions = g_buyPositions + g_sellPositions;
    if(totalPositions > 0 && currentTrend.strength > 50 && !isVerySmallAccount) { // Lowered from 60
        // AGGRESSIVE: Increase lot size more aggressively for additional positions
        double strengthMultiplier = 1.0 + ((currentTrend.strength - 50) / 100.0) * 0.4; // Increased from 0.2 to 0.4
        lotSize *= strengthMultiplier;
    }
    
    // AGGRESSIVE: Boost lot size based on momentum
    if(MathAbs(currentTrend.momentum) > 40) {
        lotSize *= 1.15; // 15% boost for strong momentum
    }
    
    // AGGRESSIVE: Boost lot size in trending markets
    if(currentTrend.isTrending && currentTrend.direction != 0) {
        lotSize *= 1.1; // 10% boost in trending markets
    }
    
    // Normalize lot size
    double minLot = g_symbol.LotsMin();
    double maxLot = g_symbol.LotsMax();
    double lotStep = g_symbol.LotsStep();
    
    lotSize = MathMax(lotSize, minLot);
    
    // Apply maximum lot size based on account balance
    lotSize = MathMin(lotSize, maxLotByBalance);
    
    // Also respect broker's maximum
    lotSize = MathMin(lotSize, maxLot);
    
    // Round to lot step
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    // Final safety: ensure minimum lot size
    if(lotSize < minLot) {
        lotSize = minLot;
    }
    
    // ═══════════════════════════════════════════════════════
    // LOGGING
    // ═══════════════════════════════════════════════════════
    if(InpEnableLogging) {
        Print("═══════════════════════════════════════════════════════════");
        Print("💰 LOT SIZE CALCULATION");
        Print("═══════════════════════════════════════════════════════════");
        Print("Account Type: ", g_isCentAccount ? "CENT" : "STANDARD");
        Print("Account Balance: ", DoubleToString(balance, 2), " ", (g_isCentAccount ? "USC" : "USD"));
        if(g_isCentAccount) {
            Print("Account Balance (USD): $", DoubleToString(accountSizeUSD, 2));
        }
        Print("Risk Amount: ", DoubleToString(riskAmount, 4), " ", (g_isCentAccount ? "USC" : "USD"));
        Print("Stop Loss: ", DoubleToString(stopLossPips, 2), " pips");
        Print("Max Lot by Balance: ", DoubleToString(maxLotByBalance, 2));
        Print("Calculated Lot Size: ", DoubleToString(lotSize, 2));
        Print("Drawdown: ", DoubleToString(drawdownPercent, 2), "%");
        Print("Recovery Multiplier: ", DoubleToString(g_recoveryMultiplier, 2), "x");
        Print("Performance Multiplier: ", DoubleToString(g_performanceMultiplier, 2), "x");
        Print("Win Rate: ", DoubleToString(g_winRate, 1), "% (", g_totalWins, "W/", g_totalLosses, "L)");
        if(g_consecutiveWins > 0) {
            Print("Consecutive Wins: +", g_consecutiveWins);
        }
        else if(g_consecutiveLosses > 0) {
            Print("Consecutive Losses: -", g_consecutiveLosses);
        }
        Print("═══════════════════════════════════════════════════════════");
    }
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| OnTradeTransaction - Track Wins/Losses for Auto-Recovery         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    // Only process position close events
    if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
    
    // Get deal information
    if(!HistoryDealSelect(trans.deal)) return;
    
    long dealTicket = HistoryDealGetInteger(trans.deal, DEAL_TICKET);
    long dealMagic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
    long dealType = HistoryDealGetInteger(trans.deal, DEAL_TYPE);
    string dealSymbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
    
    // Only process our deals
    if(dealMagic != InpMagic || dealSymbol != _Symbol) return;
    
    // Only process position close deals
    if(dealType != DEAL_TYPE_SELL && dealType != DEAL_TYPE_BUY) return;
    
    // Check if this is a position close
    ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
    if(dealEntry != DEAL_ENTRY_OUT) return;
    
    // Get profit
    double dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
    double dealVolume = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
    
    // Update performance tracking
    if(dealProfit > 0) {
        // WIN
        g_totalWins++;
        g_consecutiveWins++;
        g_consecutiveLosses = 0;
        g_totalProfit += dealProfit;
        g_recentProfit += dealProfit;
        g_recentTradesCount++;
        
        // Update recovery multiplier (reduce after win)
        if(g_consecutiveWins >= 2) {
            g_recoveryMultiplier = MathMax(1.0, g_recoveryMultiplier - 0.05);
        }
        
        if(InpEnableLogging) {
            Print("✅ WIN #", dealTicket, " | Profit: +", DoubleToString(dealProfit, 2), 
                  " | Consecutive Wins: ", g_consecutiveWins, " | Win Rate: ", DoubleToString(g_winRate, 1), "%");
        }
    }
    else if(dealProfit < 0) {
        // LOSS
        g_totalLosses++;
        g_consecutiveLosses++;
        g_consecutiveWins = 0;
        g_totalLoss += MathAbs(dealProfit);
        g_recentProfit += dealProfit; // Negative
        g_recentTradesCount++;
        
        // Update recovery multiplier (increase after loss)
        if(g_consecutiveLosses >= 2) {
            g_recoveryMultiplier = 1.0 + (g_consecutiveLosses - 1) * 0.1;
            g_recoveryMultiplier = MathMin(g_recoveryMultiplier, 1.5); // Max 1.5x
        }
        
        if(InpEnableLogging) {
            Print("❌ LOSS #", dealTicket, " | Loss: ", DoubleToString(dealProfit, 2), 
                  " | Consecutive Losses: ", g_consecutiveLosses, " | Win Rate: ", DoubleToString(g_winRate, 1), "%");
        }
    }
    
    // Update win rate
    int totalTrades = g_totalWins + g_totalLosses;
    if(totalTrades > 0) {
        g_winRate = (double)g_totalWins / (double)totalTrades * 100.0;
    }
    
    // Keep recent trades count manageable (last 20 trades)
    if(g_recentTradesCount > 20) {
        // Reset recent profit tracking periodically
        g_recentProfit = 0;
        g_recentTradesCount = 0;
    }
    
    // Update peak equity
    double currentEquity = account.Equity();
    if(currentEquity > g_peakEquity) {
        g_peakEquity = currentEquity;
    }
    
    g_lastTradeCloseTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Find Support/Resistance Level (Multi-Timeframe)                  |
//+------------------------------------------------------------------+
double FindSupportResistanceLevel(int direction, int lookback = 50)
{
    double level = 0;
    int touchCount = 0;
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return 0;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return 0;
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, lookback, close) < lookback) return 0;
    
    if(direction == 1) {
        // For BUY: Find support level (swing low)
        double minLow = low[0];
        int minIndex = 0;
        for(int i = 1; i < lookback - 5; i++) {
            if(low[i] < minLow) {
                minLow = low[i];
                minIndex = i;
            }
        }
        
        // Count touches near this level
        double tolerance = PointsToPips(currentTrend.atrValue) * 0.5;
        for(int i = 0; i < lookback; i++) {
            if(MathAbs(PointsToPips(low[i] - minLow)) < tolerance) {
                touchCount++;
            }
        }
        
        if(touchCount >= 2) {
            level = minLow;
        }
    }
    else {
        // For SELL: Find resistance level (swing high)
        double maxHigh = high[0];
        int maxIndex = 0;
        for(int i = 1; i < lookback - 5; i++) {
            if(high[i] > maxHigh) {
                maxHigh = high[i];
                maxIndex = i;
            }
        }
        
        // Count touches near this level
        double tolerance = PointsToPips(currentTrend.atrValue) * 0.5;
        for(int i = 0; i < lookback; i++) {
            if(MathAbs(PointsToPips(high[i] - maxHigh)) < tolerance) {
                touchCount++;
            }
        }
        
        if(touchCount >= 2) {
            level = maxHigh;
        }
    }
    
    return level;
}

//+------------------------------------------------------------------+
//| Find Swing High/Low                                              |
//+------------------------------------------------------------------+
double FindSwingPoint(int direction, int period = 5, int lookback = 50)
{
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return 0;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return 0;
    
    if(direction == 1) {
        // Find swing low for BUY
        for(int i = period; i < lookback - period; i++) {
            bool isSwingLow = true;
            for(int j = i - period; j <= i + period; j++) {
                if(j != i && low[j] <= low[i]) {
                    isSwingLow = false;
                    break;
                }
            }
            if(isSwingLow) {
                return low[i];
            }
        }
    }
    else {
        // Find swing high for SELL
        for(int i = period; i < lookback - period; i++) {
            bool isSwingHigh = true;
            for(int j = i - period; j <= i + period; j++) {
                if(j != i && high[j] >= high[i]) {
                    isSwingHigh = false;
                    break;
                }
            }
            if(isSwingHigh) {
                return high[i];
            }
        }
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci Levels for TP                                |
//+------------------------------------------------------------------+
double CalculateFibonacciTP(int direction, double entryPrice, double slPrice)
{
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, 50, high) < 50) return 0;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, 50, low) < 50) return 0;
    
    // Find recent swing high and low
    int maxIndex = ArrayMaximum(high, 0, 50);
    int minIndex = ArrayMinimum(low, 0, 50);
    double swingHigh = (maxIndex >= 0) ? high[maxIndex] : 0;
    double swingLow = (minIndex >= 0) ? low[minIndex] : 0;
    double range = swingHigh - swingLow;
    
    if(range <= 0) return 0;
    
    // Fibonacci levels: 1.272, 1.618, 2.0, 2.618
    double fibLevels[];
    ArrayResize(fibLevels, 4);
    fibLevels[0] = 1.272;
    fibLevels[1] = 1.618;
    fibLevels[2] = 2.0;
    fibLevels[3] = 2.618;
    
    if(direction == 1) {
        // BUY: Use 1.618 or 2.0 Fibonacci extension
        double slDistance = entryPrice - slPrice;
        double targetFib = slDistance * (currentTrend.strength > 70 ? 2.0 : 1.618);
        return entryPrice + targetFib;
    }
    else {
        // SELL: Use 1.618 or 2.0 Fibonacci extension
        double slDistance = slPrice - entryPrice;
        double targetFib = slDistance * (currentTrend.strength > 70 ? 2.0 : 1.618);
        return entryPrice - targetFib;
    }
}

//+------------------------------------------------------------------+
//| Find Recent Swing High/Low (Closer to Entry)                     |
//+------------------------------------------------------------------+
double FindRecentSwingPoint(int direction, int lookback = 20)
{
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return 0;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return 0;
    
    if(direction == 1) {
        // BUY: Find recent swing low (closest support)
        double minLow = low[0];
        for(int i = 1; i < MathMin(lookback, 15); i++) {
            if(low[i] < minLow) {
                minLow = low[i];
            }
        }
        return minLow;
    }
    else {
        // SELL: Find recent swing high (closest resistance)
        double maxHigh = high[0];
        for(int i = 1; i < MathMin(lookback, 15); i++) {
            if(high[i] > maxHigh) {
                maxHigh = high[i];
            }
        }
        return maxHigh;
    }
}

//+------------------------------------------------------------------+
//| Find Nearest Support/Resistance (Recent Price Action)            |
//+------------------------------------------------------------------+
double FindNearestSRLevel(int direction, int lookback = 30)
{
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, lookback, high) < lookback) return 0;
    if(CopyLow(_Symbol, PERIOD_CURRENT, 0, lookback, low) < lookback) return 0;
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, lookback, close) < lookback) return 0;
    
    double currentPrice = close[0];
    double nearestLevel = 0;
    double minDistance = 999999;
    
    if(direction == 1) {
        // BUY: Find nearest support below entry
        for(int i = 1; i < MathMin(lookback, 20); i++) {
            if(low[i] < currentPrice) {
                double distance = currentPrice - low[i];
                if(distance < minDistance && distance > 0) {
                    minDistance = distance;
                    nearestLevel = low[i];
                }
            }
        }
    }
    else {
        // SELL: Find nearest resistance above entry
        for(int i = 1; i < MathMin(lookback, 20); i++) {
            if(high[i] > currentPrice) {
                double distance = high[i] - currentPrice;
                if(distance < minDistance && distance > 0) {
                    minDistance = distance;
                    nearestLevel = high[i];
                }
            }
        }
    }
    
    return nearestLevel;
}

//+------------------------------------------------------------------+
//| SUPER SMART Stop Loss and Take Profit Calculation (Balance & Lot Based)|
//+------------------------------------------------------------------+
void CalculateSLTP(int direction, double lotSize, double &sl, double &tp)
{
    double entryPrice = (direction == 1) ? g_symbol.Ask() : g_symbol.Bid();
    double atrPips = PointsToPips(currentTrend.atrValue);
    double spreadPips = PointsToPips(g_symbol.Spread() * g_symbol.Point());
    
    // ═══════════════════════════════════════════════════════
    // STEP 0: CALCULATE RISK-BASED SL DISTANCE (Balance & Lot Size)
    // ═══════════════════════════════════════════════════════
    
    // Get account balance
    double balance = account.Balance();
    double riskAmount = balance * (InpMaxRiskPerTrade / 100.0);
    
    // Calculate point value for this symbol
    double tickValue = g_symbol.TickValue();
    double tickSize = g_symbol.TickSize();
    double pointValue = (tickValue / tickSize) * g_symbol.Point();
    
    // Calculate SL distance in price units based on risk amount and lot size
    // Formula: Risk Amount = Lot Size × SL_Distance × Point_Value
    // Therefore: SL_Distance = Risk Amount / (Lot Size × Point_Value)
    double slDistancePrice = 0;
    if(lotSize > 0 && pointValue > 0) {
        slDistancePrice = riskAmount / (lotSize * pointValue);
    }
    
    // Convert to pips for reference
    double slDistancePips = PointsToPips(slDistancePrice);
    
    // ═══════════════════════════════════════════════════════
    // STEP 1: AI-POWERED ULTRA SMART STOP LOSS (Balance-Based)
    // ═══════════════════════════════════════════════════════
    
    // Base SL from ATR (adaptive multiplier based on market regime)
    double atrMultiplier = InpATR_SL_Multiplier;
    
    // Adjust multiplier based on market regime
    if(currentTrend.marketRegime == 1) { // Trending
        atrMultiplier *= 0.9; // Tighter SL in trending markets
    }
    else if(currentTrend.marketRegime == 2) { // High volatility
        atrMultiplier *= 1.3; // Wider SL in high volatility
    }
    else { // Ranging
        atrMultiplier *= 1.1; // Slightly wider in ranging markets
    }
    
    // Use detected support/resistance levels if available
    double smartSLPips = 0;
    if(direction == 1 && currentTrend.supportLevel > 0 && currentTrend.supportLevel < entryPrice) {
        double srDistance = PointsToPips(entryPrice - currentTrend.supportLevel);
        if(srDistance > 3.0 && srDistance < atrPips * 3.0) {
            smartSLPips = srDistance + (atrPips * 0.2); // 20% buffer below support
        }
    }
    else if(direction == -1 && currentTrend.resistanceLevel > 0 && currentTrend.resistanceLevel > entryPrice) {
        double srDistance = PointsToPips(currentTrend.resistanceLevel - entryPrice);
        if(srDistance > 3.0 && srDistance < atrPips * 3.0) {
            smartSLPips = srDistance + (atrPips * 0.2); // 20% buffer above resistance
        }
    }
    
    // Base SL from ATR (use smaller multiplier for closer SL)
    double baseSLPips = atrPips * MathMin(atrMultiplier, 1.5);
    
    // Use smart SL if available and better
    if(smartSLPips > 0 && smartSLPips < baseSLPips * 1.2) {
        baseSLPips = smartSLPips;
    }
    
    // ═══════════════════════════════════════════════════════
    // BALANCE-BASED SL: Use risk-based distance as primary reference
    // ═══════════════════════════════════════════════════════
    // The SL distance calculated from balance and lot size is the target
    // We'll use it as the base and adjust based on market conditions
    if(slDistancePips > 0) {
        // Use balance-based SL as primary, but allow ATR/SR adjustments within 30%
        double minSLPips = slDistancePips * 0.7;  // Allow 30% tighter
        double maxSLPips = slDistancePips * 1.3;  // Allow 30% wider
        
        // If ATR-based SL is within range, use it (with market adjustments)
        if(baseSLPips >= minSLPips && baseSLPips <= maxSLPips) {
            // Use ATR-based but keep it close to balance-based target
            baseSLPips = (baseSLPips * 0.6) + (slDistancePips * 0.4); // Blend 60% ATR, 40% balance-based
        }
        else if(baseSLPips < minSLPips) {
            // ATR too tight - use minimum (balance-based)
            baseSLPips = minSLPips;
        }
        else {
            // ATR too wide - use maximum (balance-based)
            baseSLPips = maxSLPips;
        }
    }
    
    // Find RECENT support/resistance (closer to entry)
    double recentSwing = FindRecentSwingPoint(direction, 20);
    double nearestSR = FindNearestSRLevel(direction, 30);
    
    // Use the CLOSEST significant level (prioritize proximity)
    double closestLevel = 0;
    double closestDistance = 999999;
    
    if(direction == 1) {
        // BUY: Find closest support below entry
        if(recentSwing > 0 && recentSwing < entryPrice) {
            double dist = PointsToPips(entryPrice - recentSwing);
            if(dist < closestDistance && dist > 0) {
                closestDistance = dist;
                closestLevel = recentSwing;
            }
        }
        if(nearestSR > 0 && nearestSR < entryPrice) {
            double dist = PointsToPips(entryPrice - nearestSR);
            if(dist < closestDistance && dist > 0) {
                closestDistance = dist;
                closestLevel = nearestSR;
            }
        }
    }
    else {
        // SELL: Find closest resistance above entry
        if(recentSwing > 0 && recentSwing > entryPrice) {
            double dist = PointsToPips(recentSwing - entryPrice);
            if(dist < closestDistance && dist > 0) {
                closestDistance = dist;
                closestLevel = recentSwing;
            }
        }
        if(nearestSR > 0 && nearestSR > entryPrice) {
            double dist = PointsToPips(nearestSR - entryPrice);
            if(dist < closestDistance && dist > 0) {
                closestDistance = dist;
                closestLevel = nearestSR;
            }
        }
    }
    
    // Use closest level if it's reasonable (not too close, not too far)
    double slPips = baseSLPips;
    if(closestLevel > 0 && closestDistance > 0) {
        // Prefer level-based SL if it's closer than 2x ATR
        if(closestDistance <= atrPips * 2.5) {
            double levelBasedSL = closestDistance + (atrPips * 0.15); // Small buffer (15% of ATR)
            
            // Check if level-based SL is within balance-based range
            if(slDistancePips > 0) {
                double minSL = slDistancePips * 0.7;
                double maxSL = slDistancePips * 1.3;
                if(levelBasedSL >= minSL && levelBasedSL <= maxSL) {
                    slPips = levelBasedSL;
                }
                else if(levelBasedSL < minSL) {
                    slPips = minSL; // Use minimum balance-based SL
                }
                else {
                    slPips = maxSL; // Use maximum balance-based SL
                }
            }
            else {
                slPips = levelBasedSL;
            }
        }
        // But ensure minimum distance
        else if(closestDistance < baseSLPips) {
            double levelBasedSL = closestDistance + (atrPips * 0.1);
            if(slDistancePips > 0) {
                double minSL = slDistancePips * 0.7;
                slPips = MathMax(levelBasedSL, minSL);
            }
            else {
                slPips = levelBasedSL;
            }
        }
    }
    
    // Adjust SL based on volatility (more precise)
    if(currentTrend.volatility > 120) {
        slPips *= 1.1; // Slightly wider in high volatility
    }
    else if(currentTrend.volatility < 80) {
        slPips *= 0.9; // Tighter in low volatility
    }
    
    // Adjust SL based on trend strength and confidence (tighter for strong trends)
    if(currentTrend.strength > 75 && currentTrend.confidence > 75) {
        slPips *= 0.85; // Tighter SL in very strong trend
    }
    else if(currentTrend.strength > 60) {
        slPips *= 0.90; // Slightly tighter in strong trend
    }
    
    // Adjust SL based on momentum (tighter if momentum is strong)
    if(MathAbs(currentTrend.momentum) > 50) {
        slPips *= 0.92; // Tighter SL when momentum is very strong
    }
    
    // Adjust SL based on market regime
    if(currentTrend.isTrending && currentTrend.direction != 0) {
        slPips *= 0.95; // Slightly tighter in confirmed trending market
    }
    
    // Add spread buffer (reduced multiplier)
    slPips += spreadPips * 1.2;
    
    // Minimum and maximum SL (account-aware) - Optimized for closer placement
    double minSL = g_isCentAccount ? 3.0 : 6.0;  // Tighter minimum
    double maxSL = g_isCentAccount ? 40.0 : 60.0; // Tighter maximum (closer to entry)
    slPips = MathMax(slPips, minSL);
    slPips = MathMin(slPips, maxSL);
    
    // ═══════════════════════════════════════════════════════
    // STEP 2: AI-POWERED ULTRA SMART TAKE PROFIT
    // ═══════════════════════════════════════════════════════
    
    // Base RR ratio (adaptive based on market conditions)
    double baseRR = InpATR_TP_Multiplier;
    
    // Use detected resistance/support levels for TP
    double smartTPPips = 0;
    if(direction == 1 && currentTrend.resistanceLevel > 0 && currentTrend.resistanceLevel > entryPrice) {
        double srDistance = PointsToPips(currentTrend.resistanceLevel - entryPrice);
        if(srDistance > slPips * 1.3 && srDistance < slPips * 4.0) {
            smartTPPips = srDistance;
        }
    }
    else if(direction == -1 && currentTrend.supportLevel > 0 && currentTrend.supportLevel < entryPrice) {
        double srDistance = PointsToPips(entryPrice - currentTrend.supportLevel);
        if(srDistance > slPips * 1.3 && srDistance < slPips * 4.0) {
            smartTPPips = srDistance;
        }
    }
    
    // Calculate Fibonacci-based TP if strong trend
    double fibTPPips = 0;
    if(currentTrend.strength > 70 && currentTrend.isTrending) {
        // Calculate preliminary SL for Fibonacci calculation
        double preliminarySL = (direction == 1) ? entryPrice - slDistancePrice : entryPrice + slDistancePrice;
        double fibLevel = CalculateFibonacciTP(direction, entryPrice, preliminarySL);
        if(fibLevel > 0) {
            fibTPPips = PointsToPips(MathAbs(fibLevel - entryPrice));
            if(fibTPPips > slPips * 1.5 && fibTPPips < slPips * 5.0) {
                // Valid Fibonacci target
            }
            else {
                fibTPPips = 0;
            }
        }
    }
    
    // Base RR ratio (optimized for closer TP)
    baseRR = MathMin(baseRR, 2.5); // Cap at 2.5x
    
    // Adjust RR based on trend strength (moderate adjustments)
    if(currentTrend.strength > 75 && currentTrend.confidence > 75) {
        baseRR *= 1.4; // Higher RR in very strong trends
    }
    else if(currentTrend.strength > 70 && currentTrend.confidence > 70) {
        baseRR *= 1.3;
    }
    else if(currentTrend.strength > 60) {
        baseRR *= 1.15;
    }
    else if(currentTrend.strength < 40) {
        baseRR *= 0.90; // Lower RR in weak trends
    }
    
    // Adjust RR based on momentum
    if(MathAbs(currentTrend.momentum) > 50) {
        baseRR *= 1.2; // Higher RR with strong momentum
    }
    
    // Adjust RR based on market regime
    if(currentTrend.isTrending) {
        baseRR *= 1.15; // Higher RR in trending markets
    }
    else if(currentTrend.marketRegime == 0) {
        baseRR *= 0.90; // Lower RR in ranging markets
    }
    
    // Adjust RR based on volatility (moderate)
    if(currentTrend.volatility > 120) {
        baseRR *= 1.05; // Slightly higher RR in high volatility
    }
    else if(currentTrend.volatility < 80) {
        baseRR *= 0.98; // Slightly lower RR in low volatility
    }
    
    // ═══════════════════════════════════════════════════════
    // BALANCE-BASED TP: Calculate TP based on SL and RR ratio
    // ═══════════════════════════════════════════════════════
    // TP distance in price units = SL distance × RR ratio
    double tpDistancePrice = slDistancePrice * baseRR;
    double tpDistancePips = PointsToPips(tpDistancePrice);
    
    // Calculate TP from SL (use balance-based as reference)
    double tpPips = slPips * baseRR;
    
    // Ensure TP is at least the balance-based target
    if(tpDistancePips > 0 && tpPips < tpDistancePips * 0.9) {
        tpPips = tpDistancePips * 0.9; // Use 90% of balance-based TP as minimum
    }
    
    // Prioritize smart TP levels (S/R, Fibonacci)
    if(smartTPPips > 0) {
        // Use S/R level if it's reasonable
        if(smartTPPips >= slPips * 1.3 && smartTPPips <= slPips * 4.0) {
            if(smartTPPips > tpPips * 0.9) { // Prefer if it's better or similar
                tpPips = smartTPPips;
            }
        }
    }
    
    if(fibTPPips > 0 && currentTrend.strength > 70) {
        // Use Fibonacci target if strong trend
        if(fibTPPips >= slPips * 1.5 && fibTPPips <= slPips * 5.0) {
            if(fibTPPips > tpPips) {
                tpPips = fibTPPips;
            }
        }
    }
    
    // Find NEAREST resistance/support for TP (closer target)
    double nextLevel = FindNearestSRLevel((direction == 1) ? -1 : 1, 25);
    if(nextLevel > 0) {
        double levelTPDistance = PointsToPips(MathAbs(nextLevel - entryPrice));
        // Use level if it's reasonable and better than current TP
        if(levelTPDistance >= slPips * 1.3 && levelTPDistance <= slPips * 4.0) {
            // Prefer level-based TP if it's better
            if(levelTPDistance > tpPips * 0.95 && levelTPDistance < tpPips * 1.2) {
                tpPips = levelTPDistance;
            }
        }
    }
    
    // Try recent swing high/low for TP (even closer)
    double recentTPLevel = FindRecentSwingPoint((direction == 1) ? -1 : 1, 15);
    if(recentTPLevel > 0) {
        double recentTPDistance = PointsToPips(MathAbs(recentTPLevel - entryPrice));
        // Use if it's reasonable and better
        if(recentTPDistance >= slPips * 1.3 && recentTPDistance <= slPips * 3.5) {
            if(recentTPDistance > tpPips * 0.9 && recentTPDistance < tpPips * 1.1) {
                tpPips = recentTPDistance;
            }
        }
    }
    
    // Minimum and maximum TP (account-aware) - Optimized for closer placement
    double minTP = g_isCentAccount ? 5.0 : 10.0;  // Tighter minimum (closer)
    double maxTP = g_isCentAccount ? 80.0 : 120.0; // Tighter maximum (closer to entry)
    tpPips = MathMax(tpPips, minTP);
    tpPips = MathMin(tpPips, maxTP);
    
    // Ensure minimum RR of 1.3:1 (slightly higher for safety)
    if(tpPips < slPips * 1.3) {
        tpPips = slPips * 1.3;
    }
    
    // Cap maximum TP distance (don't go too far)
    double maxTPDistance = g_isCentAccount ? 80.0 : 120.0;
    if(tpPips > maxTPDistance) {
        tpPips = maxTPDistance;
    }
    
    // ═══════════════════════════════════════════════════════
    // STEP 3: CALCULATE ACTUAL PRICES (Balance & Lot Based)
    // ═══════════════════════════════════════════════════════
    
    // Use price units directly from balance/lot calculation
    if(slDistancePrice > 0) {
        // Primary: Use balance-based SL distance in price units
        if(direction == 1) {
            sl = entryPrice - slDistancePrice;
            tp = entryPrice + (slDistancePrice * baseRR);
        }
        else {
            sl = entryPrice + slDistancePrice;
            tp = entryPrice - (slDistancePrice * baseRR);
        }
        
        // Adjust if market-based SL/TP suggests different levels (within tolerance)
        double marketSL = (direction == 1) ? entryPrice - PipsToPoints(slPips) : entryPrice + PipsToPoints(slPips);
        double marketTP = (direction == 1) ? entryPrice + PipsToPoints(tpPips) : entryPrice - PipsToPoints(tpPips);
        
        // Allow market-based adjustments if they're within 20% of balance-based
        double slTolerance = slDistancePrice * 0.2;
        double tpTolerance = tpDistancePrice * 0.2;
        
        if(MathAbs(marketSL - sl) <= slTolerance) {
            // Use market-based SL if it's better (tighter) and within tolerance
            if((direction == 1 && marketSL > sl) || (direction == -1 && marketSL < sl)) {
                sl = marketSL;
            }
        }
        
        if(MathAbs(marketTP - tp) <= tpTolerance) {
            // Use market-based TP if it's better (further) and within tolerance
            if((direction == 1 && marketTP > tp) || (direction == -1 && marketTP < tp)) {
                tp = marketTP;
            }
        }
    }
    else {
        // Fallback: Use pip-based calculation if balance-based failed
        if(direction == 1) {
            sl = entryPrice - PipsToPoints(slPips);
            tp = entryPrice + PipsToPoints(tpPips);
        }
        else {
            sl = entryPrice + PipsToPoints(slPips);
            tp = entryPrice - PipsToPoints(tpPips);
        }
    }
    
    // ═══════════════════════════════════════════════════════
    // STEP 4: VALIDATE BROKER REQUIREMENTS
    // ═══════════════════════════════════════════════════════
    
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * g_symbol.Point();
    double minStopDistancePips = PointsToPips(minStopDistance);
    
    if(slPips < minStopDistancePips) {
        slPips = minStopDistancePips + 2.0;
        // Recalculate TP to maintain RR
        tpPips = slPips * baseRR;
        
        if(direction == 1) {
            sl = entryPrice - PipsToPoints(slPips);
            tp = entryPrice + PipsToPoints(tpPips);
        }
        else {
            sl = entryPrice + PipsToPoints(slPips);
            tp = entryPrice - PipsToPoints(tpPips);
        }
    }
    
    // Final validation: Ensure SL/TP are not too close to entry
    double actualSLDistance = PointsToPips(MathAbs(entryPrice - sl));
    double actualTPDistance = PointsToPips(MathAbs(tp - entryPrice));
    
    if(actualSLDistance < minStopDistancePips) {
        slPips = minStopDistancePips + 1.0;
        if(direction == 1) {
            sl = entryPrice - PipsToPoints(slPips);
        }
        else {
            sl = entryPrice + PipsToPoints(slPips);
        }
    }
    
    // Normalize
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    // ═══════════════════════════════════════════════════════
    // LOGGING (if enabled)
    // ═══════════════════════════════════════════════════════
    if(InpEnableLogging) {
        Print("═══════════════════════════════════════════════════════════");
        Print("🧠 SUPER SMART SL/TP CALCULATION");
        Print("═══════════════════════════════════════════════════════════");
        Print("Direction: ", direction == 1 ? "BUY" : "SELL");
        Print("Entry Price: ", DoubleToString(entryPrice, _Digits));
        Print("Lot Size: ", DoubleToString(lotSize, 2));
        Print("Balance: ", DoubleToString(balance, 2));
        Print("Risk Amount: ", DoubleToString(riskAmount, 4), " ", (g_isCentAccount ? "USC" : "USD"));
        Print("SL Distance (Price Units): ", DoubleToString(slDistancePrice, _Digits));
        Print("SL Distance (Pips): ", DoubleToString(slDistancePips, 2), " pips");
        Print("TP Distance (Price Units): ", DoubleToString(tpDistancePrice, _Digits));
        Print("TP Distance (Pips): ", DoubleToString(tpDistancePips, 2), " pips");
        Print("ATR: ", DoubleToString(atrPips, 2), " pips");
        Print("Spread: ", DoubleToString(spreadPips, 2), " pips");
        if(closestLevel > 0) {
            Print("Closest Support/Resistance: ", DoubleToString(closestLevel, _Digits), " (", DoubleToString(closestDistance, 2), " pips away)");
        }
        if(recentSwing > 0) {
            Print("Recent Swing Point: ", DoubleToString(recentSwing, _Digits));
        }
        if(nearestSR > 0) {
            Print("Nearest SR Level: ", DoubleToString(nearestSR, _Digits));
        }
        Print("───────────────────────────────────────────────────────────");
        Print("Stop Loss: ", DoubleToString(sl, _Digits), " (", DoubleToString(actualSLDistance, 2), " pips from entry)");
        Print("Take Profit: ", DoubleToString(tp, _Digits), " (", DoubleToString(actualTPDistance, 2), " pips from entry)");
        Print("Risk:Reward Ratio: 1:", DoubleToString(actualTPDistance / actualSLDistance, 2));
        Print("Distance Ratio (TP/SL): ", DoubleToString(actualTPDistance / actualSLDistance, 2), "x");
        Print("Balance-Based SL: ", DoubleToString(slDistancePips, 2), " pips");
        Print("Balance-Based TP: ", DoubleToString(tpDistancePips, 2), " pips");
        Print("Actual Risk: ", DoubleToString((actualSLDistance * lotSize * pointValue / balance) * 100, 2), "%");
        Print("Trend Strength: ", DoubleToString(currentTrend.strength, 1));
        Print("Trend Confidence: ", DoubleToString(currentTrend.confidence, 1), "%");
        Print("═══════════════════════════════════════════════════════════");
    }
}

//+------------------------------------------------------------------+
//| Manage Open Positions (Multi-Timeframe Exit Logic)                |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!position.SelectByIndex(i)) continue;
        if(position.Symbol() != _Symbol) continue;
        if(position.Magic() != InpMagic) continue;
        
        ulong ticket = position.Ticket();
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)position.Type();
        double openPrice = position.PriceOpen();
        double currentSL = position.StopLoss();
        double currentTP = position.TakeProfit();
        
        double currentPrice = (posType == POSITION_TYPE_BUY) ? g_symbol.Bid() : g_symbol.Ask();
        double profitPips = 0;
        
        if(posType == POSITION_TYPE_BUY) {
            profitPips = PointsToPips(currentPrice - openPrice);
        }
        else {
            profitPips = PointsToPips(openPrice - currentPrice);
        }
        
        // ───────────────────────────────────────────────────────
        // AI-POWERED MULTI-TIMEFRAME EXIT SIGNAL CHECK (50+ bars analyzed)
        // ───────────────────────────────────────────────────────
        // Check if trend has reversed on lower timeframes (M5+M1)
        bool shouldExit = false;
        int reversalCount = 0;
        double exitConfidence = 0;
        
        // Check M5 reversal (50 bars analyzed)
        if(m5_Trend.isValid && m5_Trend.direction != 0) {
            if((posType == POSITION_TYPE_BUY && m5_Trend.direction == -1) ||
               (posType == POSITION_TYPE_SELL && m5_Trend.direction == 1)) {
                reversalCount++;
                exitConfidence += m5_Trend.strength * 0.4; // Weight M5 reversal
            }
        }
        
        // Check M1 reversal (50 bars analyzed)
        if(m1_Trend.isValid && m1_Trend.direction != 0) {
            if((posType == POSITION_TYPE_BUY && m1_Trend.direction == -1) ||
               (posType == POSITION_TYPE_SELL && m1_Trend.direction == 1)) {
                reversalCount++;
                exitConfidence += m1_Trend.strength * 0.3; // Weight M1 reversal
            }
        }
        
        // Check M15 reversal (higher weight)
        if(m15_Trend.isValid && m15_Trend.direction != 0) {
            if((posType == POSITION_TYPE_BUY && m15_Trend.direction == -1) ||
               (posType == POSITION_TYPE_SELL && m15_Trend.direction == 1)) {
                reversalCount++;
                exitConfidence += m15_Trend.strength * 0.5; // Higher weight for M15
            }
        }
        
        // Check momentum reversal
        if((posType == POSITION_TYPE_BUY && currentTrend.momentum < -30) ||
           (posType == POSITION_TYPE_SELL && currentTrend.momentum > 30)) {
            exitConfidence += 20; // Momentum divergence
        }
        
        // Check if price broke key support/resistance
        if((posType == POSITION_TYPE_BUY && currentPrice < currentTrend.supportLevel && currentTrend.supportLevel > 0) ||
           (posType == POSITION_TYPE_SELL && currentPrice > currentTrend.resistanceLevel && currentTrend.resistanceLevel > 0)) {
            exitConfidence += 30; // Price broke key level
        }
        
        // If M5 and M1 both show reversal (analyzed 50+ bars each), consider exit
        if(reversalCount >= 2 && profitPips > 5.0) {
            shouldExit = true;
            if(InpEnableLogging) {
                Print("⚠️ AI Multi-Timeframe Reversal Detected (50+ bars analyzed): #", ticket);
                Print("   M15 Reversal: ", (posType == POSITION_TYPE_BUY && m15_Trend.direction == -1) || (posType == POSITION_TYPE_SELL && m15_Trend.direction == 1) ? "YES" : "NO");
                Print("   M5 Reversal: ", (posType == POSITION_TYPE_BUY && m5_Trend.direction == -1) || (posType == POSITION_TYPE_SELL && m5_Trend.direction == 1) ? "YES" : "NO");
                Print("   M1 Reversal: ", (posType == POSITION_TYPE_BUY && m1_Trend.direction == -1) || (posType == POSITION_TYPE_SELL && m1_Trend.direction == 1) ? "YES" : "NO");
                Print("   Reversal Count: ", reversalCount, "/3 (M15+M5+M1)");
                Print("   Exit Confidence: ", DoubleToString(exitConfidence, 1));
            }
        }
        
        // AGGRESSIVE: Exit if strong reversal signal (higher thresholds - hold longer)
        double exitThreshold = exitConfidence > 70 ? 8.0 : (exitConfidence > 50 ? 12.0 : 18.0); // Increased thresholds
        if(shouldExit && profitPips > exitThreshold) {
            if(trade.PositionClose(ticket)) {
                Print("🔄 AGGRESSIVE: Position Closed (Multi-TF Reversal): #", ticket, " | Profit: +", DoubleToString(profitPips, 2), " pips | Confidence: ", DoubleToString(exitConfidence, 1));
            }
            continue;
        }
        
        // ───────────────────────────────────────────────────────
        // FAST EXIT ON QUICK PROFIT (Fast Money Strategy)
        // ───────────────────────────────────────────────────────
        if(InpFastExitOnProfit && profitPips >= InpFastExitProfitPips) {
            // Close position immediately for quick profit
            if(trade.PositionClose(ticket)) {
                Print("⚡ FAST EXIT: #", ticket, " | Quick Profit: +", DoubleToString(profitPips, 2), " pips | Target: ", InpFastExitProfitPips, " pips");
            }
            continue;
        }
        
        // ───────────────────────────────────────────────────────
        // AGGRESSIVE BREAK-EVEN STOP LOSS (Protect Early Profits - Faster)
        // ───────────────────────────────────────────────────────
        // AGGRESSIVE: Trigger break-even earlier (at 70% of normal trigger)
        double aggressiveBETrigger = InpBreakEvenTriggerPips * 0.7;
        if(InpEnableBreakEven && profitPips >= aggressiveBETrigger) {
            double breakEvenSL = 0;
            bool shouldMoveToBE = false;
            
            if(posType == POSITION_TYPE_BUY) {
                breakEvenSL = openPrice + PipsToPoints(InpBreakEvenOffsetPips);
                // Only move to break-even if current SL is below break-even
                if(currentSL == 0 || currentSL < breakEvenSL) {
                    shouldMoveToBE = true;
                }
            }
            else {
                breakEvenSL = openPrice - PipsToPoints(InpBreakEvenOffsetPips);
                // Only move to break-even if current SL is above break-even
                if(currentSL == 0 || currentSL > breakEvenSL) {
                    shouldMoveToBE = true;
                }
            }
            
            if(shouldMoveToBE) {
                breakEvenSL = NormalizeDouble(breakEvenSL, _Digits);
                if(trade.PositionModify(ticket, breakEvenSL, currentTP)) {
                    if(InpEnableLogging) {
                        Print("🛡️ Break-Even: #", ticket, " | SL moved to: ", breakEvenSL, " | Profit: +", DoubleToString(profitPips, 2), " pips");
                    }
                }
            }
        }
        
        // ───────────────────────────────────────────────────────
        // AGGRESSIVE AI-POWERED ADAPTIVE TRAILING STOP (Tighter, Starts Earlier)
        // ───────────────────────────────────────────────────────
        // AGGRESSIVE: Start trailing earlier (at 70% of normal start)
        double aggressiveTrailingStart = InpTrailingStartPips * 0.7;
        if(InpEnableTrailing && profitPips > aggressiveTrailingStart) {
            double trailDistance = InpTrailingStepPips;
            
            // AGGRESSIVE: Tighter trailing distance
            trailDistance *= 0.85; // Start 15% tighter
            
            // Adjust trailing distance based on ATR and profit
            double atrPips = PointsToPips(currentTrend.atrValue);
            if(atrPips > 20) {
                trailDistance *= 1.1; // Slightly wider in high volatility (reduced from 1.15)
            }
            else {
                // AGGRESSIVE: Even tighter trailing for fast trading
                trailDistance *= 0.85; // Tighter in normal volatility
            }
            
            // Adaptive trailing based on market regime
            if(currentTrend.isTrending && currentTrend.direction != 0) {
                // In trending markets, still use tight trailing (AGGRESSIVE)
                if(profitPips < 30) {
                    trailDistance *= 0.95; // Tighter even in early profit
                }
            }
            else if(currentTrend.marketRegime == 0) {
                // AGGRESSIVE: Even tighter in ranging markets
                trailDistance *= 0.75; // Very tight in ranging markets
            }
            
            // Adjust based on momentum (AGGRESSIVE: tighter if momentum is weakening)
            if(MathAbs(currentTrend.momentum) < 20) {
                trailDistance *= 0.85; // Tighter if momentum is weak
            }
            
            // AGGRESSIVE: Make trailing much more aggressive as profit increases
            if(profitPips > 20) { // Lowered from 30
                trailDistance *= 0.8; // Tighter trailing for larger profits
            }
            if(profitPips > 35) { // Lowered from 50
                trailDistance *= 0.7; // Even tighter for very large profits
            }
            if(profitPips > 50) { // Lowered from 70
                trailDistance *= 0.6; // Very tight for exceptional profits
            }
            
            // AGGRESSIVE: Dynamic trailing - tighter when near TP
            if(currentTP > 0) {
                double tpDistance = PointsToPips(MathAbs(currentTP - currentPrice));
                double originalTPDistance = PointsToPips(MathAbs(currentTP - openPrice));
                
                // AGGRESSIVE: Tighter thresholds
                if(tpDistance < originalTPDistance * 0.4) { // Changed from 0.3
                    trailDistance *= 0.6; // Very tight when near TP
                }
                else if(tpDistance < originalTPDistance * 0.6) { // Changed from 0.5
                    trailDistance *= 0.75; // Tighter when approaching TP
                }
            }
            
            double newSL = 0;
            bool shouldModify = false;
            
            if(posType == POSITION_TYPE_BUY) {
                newSL = currentPrice - PipsToPoints(trailDistance);
                // Always move SL up if price moved up
                if(newSL > currentSL && newSL < currentPrice) {
                    shouldModify = true;
                }
            }
            else {
                newSL = currentPrice + PipsToPoints(trailDistance);
                // Always move SL down if price moved down
                if((currentSL == 0 || newSL < currentSL) && newSL > currentPrice) {
                    shouldModify = true;
                }
            }
            
            if(shouldModify) {
                newSL = NormalizeDouble(newSL, _Digits);
                
                // AI: Smart TP adjustment when moving SL
                double newTP = currentTP;
                bool shouldAdjustTP = false;
                
                // If price is moving favorably, adjust TP to maintain RR ratio
                if(currentTP > 0 && profitPips > 15) {
                    double currentRR = PointsToPips(MathAbs(currentTP - openPrice)) / PointsToPips(MathAbs(openPrice - newSL));
                    double targetRR = 2.0; // Target RR ratio
                    
                    if(currentRR < targetRR * 0.8) {
                        // TP is too close relative to new SL - move it further
                        double newTPDistance = PointsToPips(MathAbs(openPrice - newSL)) * targetRR;
                        if(posType == POSITION_TYPE_BUY) {
                            newTP = currentPrice + PipsToPoints(newTPDistance * 0.5); // Move TP 50% of way to target
                            if(newTP > currentTP) shouldAdjustTP = true;
                        }
                        else {
                            newTP = currentPrice - PipsToPoints(newTPDistance * 0.5);
                            if(newTP < currentTP || currentTP == 0) shouldAdjustTP = true;
                        }
                    }
                }
                
                if(trade.PositionModify(ticket, newSL, shouldAdjustTP ? newTP : currentTP)) {
                    if(InpEnableLogging) {
                        Print("🤖 AI Trailing Stop: #", ticket, " | New SL: ", newSL, " | Distance: ", DoubleToString(trailDistance, 2), " pips | Profit: +", DoubleToString(profitPips, 2), " pips");
                        if(shouldAdjustTP) {
                            Print("   🎯 AI TP Adjusted: ", DoubleToString(newTP, _Digits), " (Maintaining RR ratio)");
                        }
                    }
                }
            }
        }
        
        // ───────────────────────────────────────────────────────
        // AGGRESSIVE AI-POWERED DYNAMIC TP FOLLOWING (Faster, Larger Steps)
        // ───────────────────────────────────────────────────────
        // AGGRESSIVE: Start TP following earlier (at 70% of normal start)
        double aggressiveTPStart = InpTPFollowingStartPips * 0.7;
        if(InpEnableTPFollowing && profitPips >= aggressiveTPStart && currentTP > 0) {
            double tpDistance = PointsToPips(MathAbs(currentTP - openPrice));
            double currentTPDistance = PointsToPips(MathAbs(currentTP - currentPrice));
            
            // AGGRESSIVE: Calculate dynamic step (larger steps)
            double dynamicStep = InpTPFollowingStepPips;
            dynamicStep *= 1.2; // 20% larger steps by default
            
            // Adjust step based on trend strength (AGGRESSIVE)
            if(currentTrend.strength > 70 && currentTrend.isTrending) { // Lowered from 75
                dynamicStep *= 1.5; // Larger steps in strong trends (increased from 1.3)
            }
            else if(currentTrend.marketRegime == 0) {
                dynamicStep *= 0.9; // Still decent steps in ranging markets (increased from 0.7)
            }
            
            // AGGRESSIVE: Adjust step based on momentum (lower threshold)
            if(MathAbs(currentTrend.momentum) > 35) { // Lowered from 50
                dynamicStep *= 1.3; // Larger steps with strong momentum (increased from 1.2)
            }
            
            // AGGRESSIVE: Adjust step based on profit level (lower threshold)
            if(profitPips > 30) { // Lowered from 50
                dynamicStep *= 1.2; // Larger steps for larger profits (increased from 1.1)
            }
            
            // AGGRESSIVE: Check if we should move TP (more lenient conditions)
            bool shouldMoveTP = false;
            double newTP = 0;
            
            // AGGRESSIVE: Condition 1 - Price is close to TP (within 40% - more lenient)
            if(currentTPDistance < tpDistance * 0.4) { // Changed from 0.3
                shouldMoveTP = true;
            }
            // AGGRESSIVE: Condition 2 - Strong momentum (lower threshold)
            else if((posType == POSITION_TYPE_BUY && currentTrend.momentum > 30) || // Lowered from 40
                    (posType == POSITION_TYPE_SELL && currentTrend.momentum < -30)) { // Lowered from -40
                if(currentTPDistance < tpDistance * 0.6) { // Changed from 0.5
                    shouldMoveTP = true;
                }
            }
            // AGGRESSIVE: Condition 3 - Price broke through key resistance/support
            else if((posType == POSITION_TYPE_BUY && currentPrice > currentTrend.resistanceLevel && currentTrend.resistanceLevel > 0) ||
                    (posType == POSITION_TYPE_SELL && currentPrice < currentTrend.supportLevel && currentTrend.supportLevel > 0)) {
                shouldMoveTP = true;
                dynamicStep *= 1.8; // Larger step after breaking S/R (increased from 1.5)
            }
            // AGGRESSIVE: Condition 4 - Any profit above threshold
            else if(profitPips > aggressiveTPStart * 1.5) {
                if(currentTPDistance < tpDistance * 0.7) { // More lenient
                    shouldMoveTP = true;
                }
            }
            
                if(shouldMoveTP) {
                    // AI: Calculate optimal TP based on multiple factors
                    double optimalTP = 0;
                    double baseTPDistance = 0;
                    
                    if(posType == POSITION_TYPE_BUY) {
                        baseTPDistance = PointsToPips(currentPrice - openPrice);
                        // AI: Use Fibonacci extension if strong trend
                        if(currentTrend.strength > 70 && currentTrend.isTrending) {
                            double fibTP = CalculateFibonacciTP(1, openPrice, currentSL);
                            if(fibTP > currentPrice && fibTP > currentTP) {
                                optimalTP = fibTP;
                            }
                        }
                        // AI: Use resistance level if available
                        if(optimalTP == 0 && currentTrend.resistanceLevel > currentPrice) {
                            double resistanceDistance = PointsToPips(currentTrend.resistanceLevel - currentPrice);
                            if(resistanceDistance > dynamicStep && resistanceDistance < dynamicStep * 3) {
                                optimalTP = currentTrend.resistanceLevel - PipsToPoints(2.0); // 2 pip buffer
                            }
                        }
                        // Default: Move TP up by dynamic step
                        if(optimalTP == 0) {
                            optimalTP = currentPrice + PipsToPoints(dynamicStep);
                        }
                        
                        // Don't move TP down, only up
                        if(optimalTP > currentTP) {
                            optimalTP = NormalizeDouble(optimalTP, _Digits);
                            
                            // AI: Also adjust SL to maintain optimal RR ratio
                            double newSL = currentSL;
                            double optimalRR = 2.5; // Target RR
                            double slDistance = PointsToPips(MathAbs(openPrice - currentSL));
                            double tpDistance = PointsToPips(MathAbs(optimalTP - openPrice));
                            double currentRR = tpDistance / slDistance;
                            
                            // If RR is too high, tighten SL slightly
                            if(currentRR > optimalRR * 1.2 && profitPips > 20) {
                                double targetSLDistance = tpDistance / optimalRR;
                                if(posType == POSITION_TYPE_BUY) {
                                    newSL = openPrice - PipsToPoints(targetSLDistance);
                                    if(newSL > currentSL && newSL < currentPrice) {
                                        newSL = NormalizeDouble(newSL, _Digits);
                                    }
                                    else {
                                        newSL = currentSL;
                                    }
                                }
                            }
                            
                            if(trade.PositionModify(ticket, newSL, optimalTP)) {
                                if(InpEnableLogging) {
                                    Print("🤖 AI TP Following: #", ticket, " | New TP: ", optimalTP, " | Profit: +", DoubleToString(profitPips, 2), " pips");
                                    Print("   🎯 AI SL Adjusted: ", DoubleToString(newSL, _Digits), " | RR: ", DoubleToString(tpDistance / PointsToPips(MathAbs(openPrice - newSL)), 2));
                                    if(optimalTP != (currentPrice + PipsToPoints(dynamicStep))) {
                                        Print("   📊 AI Used: ", (currentTrend.strength > 70 ? "Fibonacci" : "Resistance Level"));
                                    }
                                }
                            }
                        }
                    }
                    else {
                        baseTPDistance = PointsToPips(openPrice - currentPrice);
                        // AI: Use Fibonacci extension if strong trend
                        if(currentTrend.strength > 70 && currentTrend.isTrending) {
                            double fibTP = CalculateFibonacciTP(-1, openPrice, currentSL);
                            if(fibTP < currentPrice && (fibTP < currentTP || currentTP == 0)) {
                                optimalTP = fibTP;
                            }
                        }
                        // AI: Use support level if available
                        if(optimalTP == 0 && currentTrend.supportLevel < currentPrice) {
                            double supportDistance = PointsToPips(currentPrice - currentTrend.supportLevel);
                            if(supportDistance > dynamicStep && supportDistance < dynamicStep * 3) {
                                optimalTP = currentTrend.supportLevel + PipsToPoints(2.0); // 2 pip buffer
                            }
                        }
                        // Default: Move TP down by dynamic step
                        if(optimalTP == 0) {
                            optimalTP = currentPrice - PipsToPoints(dynamicStep);
                        }
                        
                        // Don't move TP up, only down
                        if(optimalTP < currentTP || currentTP == 0) {
                            optimalTP = NormalizeDouble(optimalTP, _Digits);
                            
                            // AI: Also adjust SL to maintain optimal RR ratio
                            double newSL = currentSL;
                            double optimalRR = 2.5; // Target RR
                            double slDistance = PointsToPips(MathAbs(currentSL - openPrice));
                            double tpDistance = PointsToPips(MathAbs(openPrice - optimalTP));
                            double currentRR = tpDistance / slDistance;
                            
                            // If RR is too high, tighten SL slightly
                            if(currentRR > optimalRR * 1.2 && profitPips > 20) {
                                double targetSLDistance = tpDistance / optimalRR;
                                if(posType == POSITION_TYPE_SELL) {
                                    newSL = openPrice + PipsToPoints(targetSLDistance);
                                    if((currentSL == 0 || newSL < currentSL) && newSL > currentPrice) {
                                        newSL = NormalizeDouble(newSL, _Digits);
                                    }
                                    else {
                                        newSL = currentSL;
                                    }
                                }
                            }
                            
                            if(trade.PositionModify(ticket, newSL, optimalTP)) {
                                if(InpEnableLogging) {
                                    Print("🤖 AI TP Following: #", ticket, " | New TP: ", optimalTP, " | Profit: +", DoubleToString(profitPips, 2), " pips");
                                    Print("   🎯 AI SL Adjusted: ", DoubleToString(newSL, _Digits), " | RR: ", DoubleToString(tpDistance / PointsToPips(MathAbs(newSL - openPrice)), 2));
                                    if(optimalTP != (currentPrice - PipsToPoints(dynamicStep))) {
                                        Print("   📊 AI Used: ", (currentTrend.strength > 70 ? "Fibonacci" : "Support Level"));
                                    }
                                }
                            }
                        }
                    }
                }
        }
        
        // ───────────────────────────────────────────────────────
        // PARTIAL PROFIT TAKING
        // ───────────────────────────────────────────────────────
        if(InpEnablePartialProfit && profitPips >= InpPartialProfitPips) {
            double positionVolume = position.Volume();
            double partialVolume = positionVolume * (InpPartialProfitPercent / 100.0);
            
            // Normalize partial volume
            double lotStep = g_symbol.LotsStep();
            partialVolume = MathFloor(partialVolume / lotStep) * lotStep;
            partialVolume = MathMax(partialVolume, g_symbol.LotsMin());
            
            if(partialVolume < positionVolume) {
                if(trade.PositionClosePartial(ticket, partialVolume)) {
                    if(InpEnableLogging) {
                        Print("💰 Partial Profit: #", ticket, " | Closed: ", DoubleToString(partialVolume, 2), " lots | Profit: +", DoubleToString(profitPips, 2), " pips");
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update Position Counts                                           |
//+------------------------------------------------------------------+
void UpdatePositionCounts()
{
    g_buyPositions = 0;
    g_sellPositions = 0;
    g_totalExposure = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!position.SelectByIndex(i)) continue;
        if(position.Symbol() != _Symbol) continue;
        if(position.Magic() != InpMagic) continue;
        
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)position.Type();
        if(posType == POSITION_TYPE_BUY) {
            g_buyPositions++;
        }
        else if(posType == POSITION_TYPE_SELL) {
            g_sellPositions++;
        }
        
        g_totalExposure += position.Volume();
    }
}

//+------------------------------------------------------------------+
//| Check if Can Open New Trade                                      |
//+------------------------------------------------------------------+
bool CanOpenNewTrade(bool logDetails = false)
{
    // Check max positions
    int totalPositions = g_buyPositions + g_sellPositions;
    if(totalPositions >= InpMaxPositions) {
        if(logDetails) Print("❌ BLOCKED: Max positions reached (", totalPositions, " >= ", InpMaxPositions, ")");
        return false;
    }
    if(logDetails) Print("✅ Position limit: OK");
    
    // Check news events
    if(InpEnableNewsFilter && currentNews.isNewsDetected) {
        double minutesSinceNews = (TimeCurrent() - currentNews.newsStartTime) / 60.0;
        if(minutesSinceNews < InpNewsAvoidanceMinutes) {
            if(logDetails) {
                Print("❌ BLOCKED: News event detected (", currentNews.newsType, ")");
                Print("   Time since news: ", DoubleToString(minutesSinceNews, 1), " minutes");
                Print("   Avoidance period: ", InpNewsAvoidanceMinutes, " minutes");
            }
            return false;
        }
    }
    if(logDetails && InpEnableNewsFilter) {
        if(currentNews.isNewsDetected) {
            double minutesSinceNews = (TimeCurrent() - currentNews.newsStartTime) / 60.0;
            Print("⚠️ News Active: ", currentNews.newsType, " (", DoubleToString(minutesSinceNews, 1), " min ago)");
        }
        else {
            Print("✅ News check: OK (No news detected)");
        }
    }
    
    // Check spread
    long spread = g_symbol.Spread();
    double spreadPips = PointsToPips((double)spread * g_symbol.Point());
    
    if(logDetails)
    {
        Print("📊 Spread Check:");
        Print("   Current Spread: ", DoubleToString(spreadPips, 2), " pips");
        if(g_normalSpread > 0) {
            Print("   Normal Spread: ", DoubleToString(g_normalSpread, 2), " pips");
            Print("   Spread Spike: ", DoubleToString(currentNews.spreadSpike, 2), "x");
        }
        Print("   Max Allowed: ", DoubleToString(InpMaxSpreadPips, 2), " pips");
    }
    
    // AGGRESSIVE: Allow slightly higher spread (10% more lenient)
    double aggressiveMaxSpread = InpMaxSpreadPips * 1.1;
    if(spreadPips > aggressiveMaxSpread) {
        if(logDetails) Print("❌ BLOCKED: Spread too high (", DoubleToString(spreadPips, 2), " > ", DoubleToString(aggressiveMaxSpread, 2), " pips)");
        return false;
    }
    if(logDetails) Print("✅ Spread check: OK");
    
    // Check minimum bars between trades
    if(logDetails)
    {
        Print("📊 Trade Timing:");
        Print("   Bars since last trade: ", g_barsSinceLastTrade);
        Print("   Min required: ", InpMinBarsBetweenTrades);
    }
    
    if(g_barsSinceLastTrade < InpMinBarsBetweenTrades) {
        if(logDetails) Print("❌ BLOCKED: Too soon since last trade (", g_barsSinceLastTrade, " < ", InpMinBarsBetweenTrades, " bars)");
        return false;
    }
    if(logDetails) Print("✅ Timing check: OK");
    
    // Check multi-timeframe analysis (50+ bars analyzed on each)
    int validTimeframes = 0;
    int upVotes = 0;
    int downVotes = 0;
    
    if(m15_Trend.isValid) {
        validTimeframes++;
        if(m15_Trend.direction == 1) upVotes++;
        else if(m15_Trend.direction == -1) downVotes++;
    }
    if(m5_Trend.isValid) {
        validTimeframes++;
        if(m5_Trend.direction == 1) upVotes++;
        else if(m5_Trend.direction == -1) downVotes++;
    }
    if(m1_Trend.isValid) {
        validTimeframes++;
        if(m1_Trend.direction == 1) upVotes++;
        else if(m1_Trend.direction == -1) downVotes++;
    }
    
    if(logDetails)
    {
        Print("📊 Multi-Timeframe Analysis (50+ bars each):");
        Print("   M15: ", m15_Trend.direction == 1 ? "UP" : (m15_Trend.direction == -1 ? "DOWN" : "NEUTRAL"), 
              " | Strength: ", DoubleToString(m15_Trend.strength, 1), " | Valid: ", m15_Trend.isValid ? "YES" : "NO");
        Print("   M5: ", m5_Trend.direction == 1 ? "UP" : (m5_Trend.direction == -1 ? "DOWN" : "NEUTRAL"), 
              " | Strength: ", DoubleToString(m5_Trend.strength, 1), " | Valid: ", m5_Trend.isValid ? "YES" : "NO");
        Print("   M1: ", m1_Trend.direction == 1 ? "UP" : (m1_Trend.direction == -1 ? "DOWN" : "NEUTRAL"), 
              " | Strength: ", DoubleToString(m1_Trend.strength, 1), " | Valid: ", m1_Trend.isValid ? "YES" : "NO");
        Print("   Analysis: ", validTimeframes, " valid timeframes | UP votes: ", upVotes, " | DOWN votes: ", downVotes);
    }
    
    // Require at least 2 valid timeframes with analysis
    if(validTimeframes < 2) {
        if(logDetails) Print("❌ BLOCKED: Need at least 2 valid timeframes (have ", validTimeframes, ")");
        return false;
    }
    
    // AGGRESSIVE MODE: More relaxed trend validation
    if(!currentTrend.isValid) {
        // AGGRESSIVE: Allow if M5 and M1 agree, even with lower strength
        if(m5_Trend.isValid && m1_Trend.isValid && 
           m5_Trend.direction != 0 && m1_Trend.direction != 0 &&
           m5_Trend.direction == m1_Trend.direction) {
            // M5 and M1 agree - allow trade (AGGRESSIVE: lower thresholds)
            currentTrend.direction = m5_Trend.direction;
            currentTrend.isValid = (m5_Trend.strength > 15 && m1_Trend.strength > 15); // Lowered from 25
            currentTrend.strength = (m5_Trend.strength + m1_Trend.strength) / 2.0;
            currentTrend.confidence = (m5_Trend.confidence + m1_Trend.confidence) / 2.0;
            
            if(logDetails) {
                Print("✅ AGGRESSIVE: Lower timeframe agreement detected (M5+M1) - Allowing trade");
                Print("   Direction: ", currentTrend.direction == 1 ? "UP" : "DOWN");
                Print("   Strength: ", DoubleToString(currentTrend.strength, 1));
                Print("   Confidence: ", DoubleToString(currentTrend.confidence, 1), "%");
            }
        }
        // AGGRESSIVE: Allow even if only one timeframe is strong
        else if((m5_Trend.isValid && m5_Trend.strength > 40 && m5_Trend.direction != 0) ||
                (m1_Trend.isValid && m1_Trend.strength > 40 && m1_Trend.direction != 0)) {
            if(m5_Trend.strength > m1_Trend.strength) {
                currentTrend.direction = m5_Trend.direction;
                currentTrend.isValid = true;
                currentTrend.strength = m5_Trend.strength;
                currentTrend.confidence = m5_Trend.confidence;
            }
            else {
                currentTrend.direction = m1_Trend.direction;
                currentTrend.isValid = true;
                currentTrend.strength = m1_Trend.strength;
                currentTrend.confidence = m1_Trend.confidence;
            }
            
            if(logDetails) {
                Print("✅ AGGRESSIVE: Single strong timeframe detected - Allowing trade");
                Print("   Direction: ", currentTrend.direction == 1 ? "UP" : "DOWN");
            }
        }
        else {
            if(logDetails) Print("❌ BLOCKED: Trend not valid (strength: ", DoubleToString(currentTrend.strength, 1), ", confidence: ", DoubleToString(currentTrend.confidence, 1), "%)");
            return false;
        }
    }
    if(logDetails) Print("✅ Trend analysis: OK");
    
    // MIXED MODE: Allow both BUY and SELL positions simultaneously
    // Removed restriction - now allows hedging/mixed positions
    if(logDetails) Print("✅ Direction check: OK (Mixed mode enabled - BUY+SELL allowed)");
    
    // Check margin
    double freeMargin = account.FreeMargin();
    double balance = account.Balance();
    double requiredMargin = balance * 0.1; // 10% of balance
    double freeMarginPercent = (freeMargin / balance) * 100.0;
    
    if(logDetails)
    {
        Print("📊 Margin Check:");
        Print("   Free Margin: ", DoubleToString(freeMargin, 2));
        Print("   Required (10%): ", DoubleToString(requiredMargin, 2));
        Print("   Free Margin %: ", DoubleToString(freeMarginPercent, 2), "%");
    }
    
    if(freeMargin < requiredMargin) {
        if(logDetails) Print("❌ BLOCKED: Insufficient margin (", DoubleToString(freeMarginPercent, 2), "% < 10%)");
        return false;
    }
    if(logDetails) Print("✅ Margin check: OK");
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze Trend for Specific Direction (BUY or SELL)              |
//+------------------------------------------------------------------+
bool AnalyzeDirectionTrend(int direction, double &strength, double &confidence, string &reason)
{
    strength = 0;
    confidence = 0;
    reason = "";
    
    // Analyze multi-timeframe for this direction
    int directionVotes = 0;
    double combinedStrength = 0;
    double combinedConfidence = 0;
    
    if(m15_Trend.isValid && m15_Trend.direction == direction) {
        directionVotes++;
        combinedStrength += m15_Trend.strength * 0.4;
        combinedConfidence += m15_Trend.confidence * 0.4;
    }
    if(m5_Trend.isValid && m5_Trend.direction == direction) {
        directionVotes++;
        combinedStrength += m5_Trend.strength * 0.35;
        combinedConfidence += m5_Trend.confidence * 0.35;
    }
    if(m1_Trend.isValid && m1_Trend.direction == direction) {
        directionVotes++;
        combinedStrength += m1_Trend.strength * 0.25;
        combinedConfidence += m1_Trend.confidence * 0.25;
    }
    
    strength = combinedStrength;
    confidence = combinedConfidence;
    
    // AGGRESSIVE: Lower thresholds for mixed trading
    if(directionVotes >= 1 && strength > 20 && confidence > 30) {
        reason = (direction == 1 ? "BUY" : "SELL") + " signal from " + IntegerToString(directionVotes) + " timeframe(s)";
        return true;
    }
    
    // Also check if momentum supports this direction
    if(direction == 1 && currentTrend.momentum > 15) {
        strength += 10;
        confidence += 5;
        reason = "BUY momentum detected";
        return (strength > 20 && confidence > 30);
    }
    else if(direction == -1 && currentTrend.momentum < -15) {
        strength += 10;
        confidence += 5;
        reason = "SELL momentum detected";
        return (strength > 20 && confidence > 30);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Execute Trade Logic - MIXED MODE (BUY+SELL per bar)             |
//+------------------------------------------------------------------+
void ExecuteTradeLogic(bool logDetails = false)
{
    if(logDetails)
    {
        Print("═══════════════════════════════════════════════════════════");
        Print("📊 MIXED MODE Trade Execution Logic:");
        Print("   Current Trend: ", currentTrend.direction == 1 ? "UP" : (currentTrend.direction == -1 ? "DOWN" : "NEUTRAL"));
        Print("   Current BUY Positions: ", g_buyPositions, "/", InpMaxPositions);
        Print("   Current SELL Positions: ", g_sellPositions, "/", InpMaxPositions);
    }
    
    // Get current bar time
    datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool canTradeBuy = (currentBar != g_lastBuyBarTime);
    bool canTradeSell = (currentBar != g_lastSellBarTime);
    
    // ───────────────────────────────────────────────────────
    // ANALYZE BUY OPPORTUNITY (Independent Analysis)
    // ───────────────────────────────────────────────────────
    if(canTradeBuy && g_buyPositions < InpMaxPositions) {
        double buyStrength = 0, buyConfidence = 0;
        string buyReason = "";
        bool shouldBuy = AnalyzeDirectionTrend(1, buyStrength, buyConfidence, buyReason);
        
        // Additional BUY confirmations
        if(shouldBuy) {
            // Check momentum
            if(currentTrend.momentum < -25) {
                shouldBuy = false;
                buyReason = "Very weak BUY momentum";
            }
            // Check S/R levels
            else if(currentTrend.resistanceLevel > 0 && g_symbol.Ask() > currentTrend.resistanceLevel * 0.997) {
                shouldBuy = false;
                buyReason = "Too close to resistance";
            }
            // Check market regime
            else if(currentTrend.marketRegime == 0 && buyConfidence < 35) {
                shouldBuy = false;
                buyReason = "Ranging market - low BUY confidence";
            }
        }
        
        if(shouldBuy) {
            if(logDetails) {
                Print("🚀 MIXED MODE: BUY Signal Detected");
                Print("   Reason: ", buyReason);
                Print("   Strength: ", DoubleToString(buyStrength, 1));
                Print("   Confidence: ", DoubleToString(buyConfidence, 1), "%");
            }
            OpenTrade(ORDER_TYPE_BUY, logDetails);
            g_lastBuyBarTime = currentBar;
        }
        else if(logDetails) {
            Print("⏸️  BUY Blocked: ", buyReason, " | Positions: ", g_buyPositions, "/", InpMaxPositions);
        }
    }
    
    // ───────────────────────────────────────────────────────
    // ANALYZE SELL OPPORTUNITY (Independent Analysis)
    // ───────────────────────────────────────────────────────
    if(canTradeSell && g_sellPositions < InpMaxPositions) {
        double sellStrength = 0, sellConfidence = 0;
        string sellReason = "";
        bool shouldSell = AnalyzeDirectionTrend(-1, sellStrength, sellConfidence, sellReason);
        
        // Additional SELL confirmations
        if(shouldSell) {
            // Check momentum
            if(currentTrend.momentum > 25) {
                shouldSell = false;
                sellReason = "Very weak SELL momentum";
            }
            // Check S/R levels
            else if(currentTrend.supportLevel > 0 && g_symbol.Bid() < currentTrend.supportLevel * 1.003) {
                shouldSell = false;
                sellReason = "Too close to support";
            }
            // Check market regime
            else if(currentTrend.marketRegime == 0 && sellConfidence < 35) {
                shouldSell = false;
                sellReason = "Ranging market - low SELL confidence";
            }
        }
        
        if(shouldSell) {
            if(logDetails) {
                Print("🚀 MIXED MODE: SELL Signal Detected");
                Print("   Reason: ", sellReason);
                Print("   Strength: ", DoubleToString(sellStrength, 1));
                Print("   Confidence: ", DoubleToString(sellConfidence, 1), "%");
            }
            OpenTrade(ORDER_TYPE_SELL, logDetails);
            g_lastSellBarTime = currentBar;
        }
        else if(logDetails) {
            Print("⏸️  SELL Blocked: ", sellReason, " | Positions: ", g_sellPositions, "/", InpMaxPositions);
        }
    }
    
    if(logDetails) {
        Print("═══════════════════════════════════════════════════════════");
    }
}

//+------------------------------------------------------------------+
//| Open Trade                                                        |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE orderType, bool logDetails = false)
{
    int direction = (orderType == ORDER_TYPE_BUY) ? 1 : -1;
    double entryPrice = (orderType == ORDER_TYPE_BUY) ? g_symbol.Ask() : g_symbol.Bid();
    
    // ═══════════════════════════════════════════════════════
    // STEP 1: Calculate preliminary lot size based on ATR
    // ═══════════════════════════════════════════════════════
    double atrPips = PointsToPips(currentTrend.atrValue);
    double preliminarySLPips = atrPips * InpATR_SL_Multiplier;
    double lotSize = CalculateLotSize(preliminarySLPips);
    
    // ═══════════════════════════════════════════════════════
    // STEP 2: Calculate SL/TP based on balance and lot size
    // ═══════════════════════════════════════════════════════
    double sl = 0, tp = 0;
    CalculateSLTP(direction, lotSize, sl, tp);
    
    // ═══════════════════════════════════════════════════════
    // STEP 3: Verify and adjust if needed
    // ═══════════════════════════════════════════════════════
    double finalSLDistance = PointsToPips(MathAbs(entryPrice - sl));
    double finalTPDistance = PointsToPips(MathAbs(tp - entryPrice));
    
    if(logDetails)
    {
        Print("📊 Trade Details:");
        Print("   Order Type: ", EnumToString(orderType));
        Print("   Entry Price: ", DoubleToString(entryPrice, _Digits));
        Print("   Stop Loss: ", DoubleToString(sl, _Digits), " (", DoubleToString(finalSLDistance, 2), " pips)");
        Print("   Take Profit: ", DoubleToString(tp, _Digits), " (", DoubleToString(finalTPDistance, 2), " pips)");
        Print("   Lot Size: ", DoubleToString(lotSize, 2));
        Print("   Risk: ", DoubleToString(InpMaxRiskPerTrade, 2), "%");
    }
    
    // Execute trade
    bool result = false;
    if(orderType == ORDER_TYPE_BUY) {
        result = trade.Buy(lotSize, _Symbol, entryPrice, sl, tp, InpComment);
    }
    else {
        result = trade.Sell(lotSize, _Symbol, entryPrice, sl, tp, InpComment);
    }
    
    if(result) {
        g_lastTradeTime = TimeCurrent();
        g_barsSinceLastTrade = 0;
        
        // ═══════════════════════════════════════════════════════
        // POST-TRADE VERIFICATION: Ensure SL/TP were set correctly
        // ═══════════════════════════════════════════════════════
        Sleep(300); // Small delay to ensure position is registered
        
        ulong ticket = trade.ResultOrder();
        bool sltpVerified = false;
        bool sltpCorrected = false;
        
        if(ticket > 0) {
            // Try to select position by ticket
            if(PositionSelectByTicket(ticket) || PositionSelect(_Symbol)) {
                double actualSL = PositionGetDouble(POSITION_SL);
                double actualTP = PositionGetDouble(POSITION_TP);
                double actualEntry = PositionGetDouble(POSITION_PRICE_OPEN);
                
                // Check if SL/TP are missing or significantly different
                double slTolerance = g_symbol.Point() * 20; // 20 points tolerance
                double tpTolerance = g_symbol.Point() * 20;
                
                bool needModify = false;
                string modifyReason = "";
                
                if(actualSL == 0 || MathAbs(actualSL - sl) > slTolerance) {
                    needModify = true;
                    modifyReason += "SL ";
                }
                
                if(actualTP == 0 || MathAbs(actualTP - tp) > tpTolerance) {
                    needModify = true;
                    modifyReason += "TP ";
                }
                
                // Auto-correct if needed
                if(needModify) {
                    if(InpEnableLogging) {
                        Print("⚠️ SL/TP Verification Failed for Ticket #", ticket);
                        Print("   Expected SL: ", DoubleToString(sl, _Digits), " | Actual: ", DoubleToString(actualSL, _Digits));
                        Print("   Expected TP: ", DoubleToString(tp, _Digits), " | Actual: ", DoubleToString(actualTP, _Digits));
                        Print("   Attempting auto-correction...");
                    }
                    
                    // Retry with modified SL/TP
                    if(trade.PositionModify(ticket, sl, tp)) {
                        sltpCorrected = true;
                        Print("✅ SL/TP Auto-Corrected Successfully: #", ticket);
                        
                        // Verify again after correction
                        Sleep(200);
                        if(PositionSelectByTicket(ticket)) {
                            double correctedSL = PositionGetDouble(POSITION_SL);
                            double correctedTP = PositionGetDouble(POSITION_TP);
                            
                            if((correctedSL == 0 || MathAbs(correctedSL - sl) > slTolerance) ||
                               (correctedTP == 0 || MathAbs(correctedTP - tp) > tpTolerance)) {
                                Print("❌ WARNING: SL/TP correction may have failed. Please verify manually.");
                                Print("   Corrected SL: ", DoubleToString(correctedSL, _Digits));
                                Print("   Corrected TP: ", DoubleToString(correctedTP, _Digits));
                            }
                            else {
                                sltpVerified = true;
                            }
                        }
                    }
                    else {
                        uint errorCode = GetLastError();
                        Print("❌ Failed to correct SL/TP: #", ticket);
                        Print("   Error Code: ", errorCode);
                        Print("   Error: ", trade.ResultRetcodeDescription());
                        Print("   Please set SL/TP manually!");
                    }
                }
                else {
                    sltpVerified = true;
                }
            }
        }
        
        Print("✅✅✅ TRADE OPENED SUCCESSFULLY! ✅✅✅");
        Print("   Type: ", EnumToString(orderType));
        Print("   Ticket: ", ticket);
        Print("   Lots: ", DoubleToString(lotSize, 2));
        Print("   Entry: ", DoubleToString(entryPrice, _Digits));
        Print("   SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(finalSLDistance, 2), " pips)");
        Print("   TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(finalTPDistance, 2), " pips)");
        Print("   Risk:Reward: 1:", DoubleToString(finalTPDistance / finalSLDistance, 2));
        Print("   Trend Strength: ", DoubleToString(currentTrend.strength, 1));
        Print("   Trend Confidence: ", DoubleToString(currentTrend.confidence, 1), "%");
        if(sltpVerified) {
            Print("   ✅ SL/TP Verified: Correctly Set");
        }
        else if(sltpCorrected) {
            Print("   ⚠️ SL/TP Corrected: Please Verify");
        }
        else {
            Print("   ⚠️ SL/TP Status: Unknown (Please Verify)");
        }
    }
    else {
        uint errorCode = GetLastError();
        Print("❌ TRADE FAILED!");
        Print("   Type: ", EnumToString(orderType));
        Print("   Error Code: ", errorCode);
        Print("   Error Description: ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Check Daily Reset                                                 |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime currentStruct, lastStruct;
    TimeToStruct(currentTime, currentStruct);
    TimeToStruct(g_lastDayCheck, lastStruct);
    
    if(currentStruct.day != lastStruct.day) {
        // New day - reset daily equity
        g_dailyStartEquity = account.Equity();
        g_lastDayCheck = currentTime;
        
        if(InpEnableLogging) {
            Print("📅 New Day - Daily Equity Reset: ", DoubleToString(g_dailyStartEquity, 2));
        }
    }
}

//+------------------------------------------------------------------+
//| Check Emergency Stop                                              |
//+------------------------------------------------------------------+
bool CheckEmergencyStop()
{
    double currentEquity = account.Equity();
    
    // Update peak equity
    if(currentEquity > g_peakEquity) {
        g_peakEquity = currentEquity;
    }
    
    // Calculate daily drawdown
    double dailyDrawdown = 0;
    if(g_dailyStartEquity > 0) {
        dailyDrawdown = ((g_dailyStartEquity - currentEquity) / g_dailyStartEquity) * 100.0;
    }
    
    if(dailyDrawdown >= InpMaxDailyDrawdown) {
        if(InpEnableLogging) {
            Print("🚨 EMERGENCY STOP: Daily Drawdown Exceeded! ", DoubleToString(dailyDrawdown, 2), "% >= ", InpMaxDailyDrawdown, "%");
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Analyze News Events (Unexpected News Detection)                  |
//+------------------------------------------------------------------+
void AnalyzeNewsEvents(bool logDetails = false)
{
    // Update baseline every 5 minutes
    static datetime lastBaselineUpdate = 0;
    if(TimeCurrent() - lastBaselineUpdate > 300) {
        UpdateNewsBaseline();
        lastBaselineUpdate = TimeCurrent();
    }
    
    // Get current market conditions
    double currentATR = currentTrend.atrValue;
    long currentSpread = g_symbol.Spread();
    double currentSpreadPips = PointsToPips((double)currentSpread * g_symbol.Point());
    
    // Calculate volatility spike
    currentNews.volatilitySpike = 1.0;
    if(g_normalATR > 0) {
        currentNews.volatilitySpike = currentATR / g_normalATR;
    }
    currentNews.isVolatilitySpike = (currentNews.volatilitySpike >= InpNewsVolatilitySpike);
    
    // Calculate spread spike
    currentNews.spreadSpike = 1.0;
    if(g_normalSpread > 0) {
        currentNews.spreadSpike = currentSpreadPips / g_normalSpread;
    }
    currentNews.isSpreadSpike = (currentNews.spreadSpike >= InpNewsSpreadSpike);
    
    // Detect price gaps
    currentNews.isPriceGap = DetectPriceGap();
    
    // Determine if news is detected
    bool newsDetected = false;
    string newsType = "";
    
    if(currentNews.isVolatilitySpike && currentNews.isSpreadSpike) {
        newsDetected = true;
        newsType = "HIGH-IMPACT NEWS (Volatility + Spread Spike)";
    }
    else if(currentNews.isVolatilitySpike) {
        newsDetected = true;
        newsType = "VOLATILITY SPIKE";
    }
    else if(currentNews.isSpreadSpike) {
        newsDetected = true;
        newsType = "SPREAD WIDENING";
    }
    else if(currentNews.isPriceGap) {
        newsDetected = true;
        newsType = "PRICE GAP";
    }
    
    // Update news status
    if(newsDetected && !currentNews.isNewsDetected) {
        // News just detected
        currentNews.isNewsDetected = true;
        currentNews.newsStartTime = TimeCurrent();
        currentNews.newsType = newsType;
        
        Print("🚨🚨🚨 UNEXPECTED NEWS DETECTED! 🚨🚨🚨");
        Print("═══════════════════════════════════════════════════════════");
        Print("News Type: ", newsType);
        Print("Volatility Spike: ", DoubleToString(currentNews.volatilitySpike, 2), "x normal");
        Print("Spread Spike: ", DoubleToString(currentNews.spreadSpike, 2), "x normal");
        Print("Current ATR: ", DoubleToString(PointsToPips(currentATR), 2), " pips");
        Print("Normal ATR: ", DoubleToString(PointsToPips(g_normalATR), 2), " pips");
        Print("Current Spread: ", DoubleToString(currentSpreadPips, 2), " pips");
        Print("Normal Spread: ", DoubleToString(g_normalSpread, 2), " pips");
        Print("Price Gap: ", currentNews.isPriceGap ? "YES" : "NO");
        Print("═══════════════════════════════════════════════════════════");
    }
    else if(!newsDetected && currentNews.isNewsDetected) {
        // News has settled
        double minutesSinceNews = (TimeCurrent() - currentNews.newsStartTime) / 60.0;
        Print("✅ News Event Settled (", DoubleToString(minutesSinceNews, 1), " minutes since detection)");
        currentNews.isNewsDetected = false;
        currentNews.newsType = "";
    }
    
    if(logDetails && currentNews.isNewsDetected) {
        double minutesSinceNews = (TimeCurrent() - currentNews.newsStartTime) / 60.0;
        Print("📰 News Status: ACTIVE | Type: ", currentNews.newsType, " | Duration: ", DoubleToString(minutesSinceNews, 1), " minutes");
    }
}

//+------------------------------------------------------------------+
//| Update News Baseline (Normal Market Conditions)                  |
//+------------------------------------------------------------------+
void UpdateNewsBaseline()
{
    // Calculate normal ATR over last 100 bars
    double atrArray[];
    ArraySetAsSeries(atrArray, true);
    if(CopyBuffer(h_ATR, 0, 0, 100, atrArray) >= 100) {
        double sumATR = 0;
        int count = 0;
        
        // Use median to avoid outliers
        double atrSorted[];
        ArrayResize(atrSorted, 100);
        ArrayCopy(atrSorted, atrArray);
        ArraySort(atrSorted);
        
        // Use middle 50% (25th to 75th percentile)
        int startIdx = 25;
        int endIdx = 75;
        for(int i = startIdx; i < endIdx; i++) {
            sumATR += atrSorted[i];
            count++;
        }
        
        if(count > 0) {
            g_normalATR = sumATR / count;
            currentNews.normalATR = g_normalATR;
        }
    }
    
    // Calculate normal spread over last 50 checks
    static double spreadHistory[];
    static int spreadHistorySize = 0;
    
    long currentSpread = g_symbol.Spread();
    double currentSpreadPips = PointsToPips((double)currentSpread * g_symbol.Point());
    
    if(ArraySize(spreadHistory) < 50) {
        ArrayResize(spreadHistory, ArraySize(spreadHistory) + 1);
        spreadHistory[ArraySize(spreadHistory) - 1] = currentSpreadPips;
        spreadHistorySize = ArraySize(spreadHistory);
    }
    else {
        // Shift array and add new value
        for(int i = 0; i < 49; i++) {
            spreadHistory[i] = spreadHistory[i + 1];
        }
        spreadHistory[49] = currentSpreadPips;
    }
    
    // Calculate median spread
    if(spreadHistorySize > 0) {
        double spreadSorted[];
        ArrayResize(spreadSorted, spreadHistorySize);
        ArrayCopy(spreadSorted, spreadHistory);
        ArraySort(spreadSorted);
        
        int medianIdx = spreadHistorySize / 2;
        g_normalSpread = spreadSorted[medianIdx];
        currentNews.normalSpread = g_normalSpread;
    }
}

//+------------------------------------------------------------------+
//| Detect Price Gap                                                  |
//+------------------------------------------------------------------+
bool DetectPriceGap()
{
    // Check for gaps between current and previous bar
    double close[], open[];
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 3, close) < 3) return false;
    if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 3, open) < 3) return false;
    
    // Calculate gap size
    double gapSize = MathAbs(close[1] - open[0]);
    double gapPips = PointsToPips(gapSize);
    
    // Consider it a gap if it's larger than 2x normal ATR
    if(g_normalATR > 0) {
        double normalATRPips = PointsToPips(g_normalATR);
        if(gapPips > normalATRPips * 2.0) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Tighten Stops on News                                              |
//+------------------------------------------------------------------+
void TightenStopsOnNews()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!position.SelectByIndex(i)) continue;
        if(position.Symbol() != _Symbol) continue;
        if(position.Magic() != InpMagic) continue;
        
        ulong ticket = position.Ticket();
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)position.Type();
        double openPrice = position.PriceOpen();
        double currentSL = position.StopLoss();
        double currentTP = position.TakeProfit();
        double currentPrice = (posType == POSITION_TYPE_BUY) ? g_symbol.Bid() : g_symbol.Ask();
        
        // Calculate current profit
        double profitPips = 0;
        if(posType == POSITION_TYPE_BUY) {
            profitPips = PointsToPips(currentPrice - openPrice);
        }
        else {
            profitPips = PointsToPips(openPrice - currentPrice);
        }
        
        // Only tighten if in profit
        if(profitPips > 5.0) {
            double newSL = 0;
            bool shouldModify = false;
            
            // Move SL to breakeven + small buffer
            if(posType == POSITION_TYPE_BUY) {
                newSL = openPrice + PipsToPoints(2.0); // 2 pip buffer
                if(newSL > currentSL && newSL < currentPrice) {
                    shouldModify = true;
                }
            }
            else {
                newSL = openPrice - PipsToPoints(2.0); // 2 pip buffer
                if((currentSL == 0 || newSL < currentSL) && newSL > currentPrice) {
                    shouldModify = true;
                }
            }
            
            if(shouldModify) {
                newSL = NormalizeDouble(newSL, _Digits);
                if(trade.PositionModify(ticket, newSL, currentTP)) {
                    if(InpEnableLogging) {
                        Print("🛡️ Stop Tightened (News): #", ticket, " | New SL: ", newSL, " | Profit: +", DoubleToString(profitPips, 2), " pips");
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close All Positions                                               |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(!position.SelectByIndex(i)) continue;
        if(position.Symbol() != _Symbol) continue;
        if(position.Magic() != InpMagic) continue;
        
        ulong ticket = position.Ticket();
        trade.PositionClose(ticket);
    }
    
    if(InpEnableLogging) {
        Print("🛑 All Positions Closed. Reason: ", reason);
    }
}
//+------------------------------------------------------------------+

