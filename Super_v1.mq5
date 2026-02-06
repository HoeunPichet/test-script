//+------------------------------------------------------------------+
//|                                   SuperSmartGoldEA_Exness_Cent.mq5|
//|                          OPTIMIZED FOR EXNESS CENT ACCOUNTS       |
//|                                   Ultra-Fast Smart Gold Trader    |
//+------------------------------------------------------------------+
#property copyright "SuperTradingEA - Exness Cent Optimized"
#property link      "https://supertradingea.com"
#property version   "2.51"
#property strict

//+------------------------------------------------------------------+
//| INCLUDES                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| EXNESS CENT ACCOUNT SETTINGS                                      |
//+------------------------------------------------------------------+
input group "=== EXNESS CENT ACCOUNT ==="
input bool IsExnessCentAccount = true;                   // Is This Exness Cent Account?
input double CentAccountMultiplier = 100.0;              // Cent Account Multiplier (100x)

//+------------------------------------------------------------------+
//| GENERAL CONTROL                                                   |
//+------------------------------------------------------------------+
input group "=== GENERAL CONTROL ==="
input bool MasterEnableTrading = true;                    // Master Trading Switch

//+------------------------------------------------------------------+
//| LICENSE                                                           |
//+------------------------------------------------------------------+
input group "=== LICENSE ==="
input string InpLicenseKey = "supertradingea-j_M5MaWQ9tzY"; // License Key

//+------------------------------------------------------------------+
//| LOT SETTINGS - EXNESS CENT OPTIMIZED                              |
//+------------------------------------------------------------------+
input group "=== LOT SETTINGS (CENT ACCOUNT) ==="
input double StartingLots = 0.01;                         // Starting Lot Size (0.01 = 1 cent)
input double LayerMultiplier = 1.3;                       // Layer Multiplier
input double MaximumLotSizeCap = 10.0;                    // Maximum Lot Cap (for cent)
input bool UseProgressiveLotScaling = true;               // Use Smart Lot Scaling
input double MinLotSize = 0.01;                           // Minimum Lot Size
input double MaxLotSize = 10.0;                           // Maximum Lot Size

//+------------------------------------------------------------------+
//| GRID SETTINGS - EXNESS OPTIMIZED                                  |
//+------------------------------------------------------------------+
input group "=== GRID SETTINGS ==="
input bool UseOpenCandle = false;                         // Use Tick-Based Entry
input bool RealTimeTrading = true;                          // Real-Time Tick Trading (Recommended)
input double PipStep = 8.0;                               // Base Pip Step (Exness: 8 pips optimal)
input int MaxTrades = 20;                                 // Maximum Total Trades
input int MaxTradesPerDirection = 10;                     // Max Trades Per Direction

//+------------------------------------------------------------------+
//| RAPID ENTRY MODE - EXNESS LATENCY OPTIMIZED                       |
//+------------------------------------------------------------------+
input group "=== RAPID ENTRY MODE ==="
input bool EnableRapidEntryMode = true;                   // Enable Rapid Entry
input int RapidEntryIntervalMS = 2000;                    // Entry Interval (2s for Exness stability)
input int MaxEntriesPerSecond = 1;                        // Max Entries/Sec (1 for Exness)
input bool UseSmartEntrySignals = true;                   // Use Smart Entry Logic
input int EntrySignalMode = 2;                            // Entry Mode (2=Hybrid recommended)

//+------------------------------------------------------------------+
//| SMART ENTRY SIGNALS                                               |
//+------------------------------------------------------------------+
input group "=== SMART ENTRY SIGNALS ==="
input bool UseMomentumFilter = true;                      // Use Momentum Filter
input int RSIPeriod = 14;                                 // RSI Period
input double RSIOverbought = 70.0;                        // RSI Overbought
input double RSIOversold = 30.0;                          // RSI Oversold
input int MACDFast = 12;                                  // MACD Fast Period
input int MACDSlow = 26;                                  // MACD Slow Period
input int MACDSignal = 9;                                 // MACD Signal Period

input bool UseBBEntrySignal = true;                       // Use Bollinger Bands
input int BBPeriod = 20;                                  // BB Period
input double BBDeviation = 2.0;                           // BB Deviation
input int BBEntryMode = 1;                                // BB Mode (1=Bounce for gold)

input bool EnablePricePatterns = true;                    // Detect Price Patterns
input bool DetectPinBars = true;                          // Detect Pin Bars
input bool DetectEngulfing = true;                        // Detect Engulfing
input bool DetectInsideBars = true;                       // Detect Inside Bars
input double PatternMinBodyPips = 5.0;                    // Min Pattern Body (5 pips for gold)

//+------------------------------------------------------------------+
//| ADAPTIVE PIP STEP - EXNESS GOLD OPTIMIZED                         |
//+------------------------------------------------------------------+
input group "=== ADAPTIVE PIP STEP ==="
input int PipStepMode = 3;                                // Step Mode (3=Hybrid best for Exness)
input int ATRPeriod = 14;                                 // ATR Period
input double ATRSimpleMultiplier = 1.0;                   // ATR Multiplier (1.0 for Exness)
input int ATRPercentileLookback = 50;                     // ATR Percentile Lookback
input int BBWidthLookback = 50;                           // BB Width Lookback
input double BBWidthMasterMultiplier = 1.2;               // BB Width Multiplier
input int RangeFastBars = 10;                             // Range Fast Bars
input int RangeSlowBars = 50;                             // Range Slow Bars
input double PriceRangeMasterMultiplier = 1.8;            // Price Range Multiplier
input double MinAdaptiveStepPips = 5.0;                   // Min Adaptive Step (5 pips for Exness)
input double MaxAdaptiveStepPips = 80.0;                  // Max Adaptive Step (80 pips)
input double HybridVolatilityThreshold = 1.1;             // Hybrid Volatility Threshold
input double StepSmoothingAlpha = 0.3;                    // Step Smoothing Factor
input double StepMaxIncreasePctPerUpdate = 40.0;          // Max Step Increase %
input double StepMaxDecreasePctPerUpdate = 30.0;          // Max Step Decrease %
input double SpreadMinStepMultiplier = 2.5;               // Spread Min Step Multiplier

//+------------------------------------------------------------------+
//| SMART STOP LOSS - EXNESS EXECUTION OPTIMIZED                      |
//+------------------------------------------------------------------+
input group "=== SMART STOP LOSS ==="
input bool UseDynamicStopLoss = true;                     // Use Dynamic SL
input int SLMode = 2;                                     // SL Mode (2=S/R best for gold)
input double FixedSLPips = 50.0;                          // Fixed SL (50 pips safe for Exness)
input double ATRSLMultiplier = 2.5;                       // ATR SL Multiplier (2.5 for safety)
input int SLPlacementMode = 1;                            // SL Placement (1=Swing)
input bool UseBreakEvenStop = true;                       // Use Break-Even
input double BreakEvenTriggerPips = 15.0;                 // Break-Even Trigger (15 pips)
input double BreakEvenOffsetPips = 3.0;                   // Break-Even Offset (3 pips buffer)
input bool UseTrailingStop = true;                        // Use Trailing Stop
input double TrailingStartPips = 20.0;                    // Trailing Start (20 pips)
input double TrailingStepPips = 5.0;                      // Trailing Step (5 pips)
input double TrailingDistancePips = 12.0;                 // Trailing Distance (12 pips)

//+------------------------------------------------------------------+
//| SMART TAKE PROFIT - EXNESS GOLD OPTIMIZED                         |
//+------------------------------------------------------------------+
input group "=== SMART TAKE PROFIT ==="
input bool UseDynamicTakeProfit = true;                   // Use Dynamic TP
input int TPMode = 3;                                     // TP Mode (3=Fib best for gold)
input double FixedTPPips = 80.0;                          // Fixed TP (80 pips for gold)
input double ATRTPMultiplier = 3.5;                       // ATR TP Multiplier (3.5 for gold)
input double RiskRewardRatio = 2.0;                       // Risk-Reward Ratio (2:1 minimum)
input bool UseFibonacciLevels = true;                     // Use Fibonacci TP
input double FibTP1 = 0.382;                              // Fib Level 1
input double FibTP2 = 0.618;                              // Fib Level 2
input double FibTP3 = 1.0;                                // Fib Level 3
input double PartialClosePercent = 30.0;                  // Partial Close %

//+------------------------------------------------------------------+
//| BASKET TAKE PROFIT - EXNESS CENT ADJUSTED                         |
//+------------------------------------------------------------------+
input group "=== BASKET TAKE PROFIT ==="
input bool EnableBasketTakeProfit = true;                 // Enable Basket TP
input int BasketTakeProfitMode = 1;                       // Basket Mode (1=Money for cent)
input double BasketTP_FixedPips = 150.0;                  // Basket TP Pips (150 for safety)
input int BasketTP_ATRSmoothPeriod = 14;                  // ATR Smooth Period
input double BasketTP_ATRMultiplierK = 0.2;               // ATR Multiplier (0.2 for cent)
input double BasketTP_MinProfitMoney = 50.0;              // Min Profit (50 cents = $0.50)
input double BasketTP_TargetProfitPercent = 3.0;          // Target Profit % (3% for cent)

//+------------------------------------------------------------------+
//| CORRELATION & HEDGING                                             |
//+------------------------------------------------------------------+
input group "=== CORRELATION & HEDGING ==="
input bool EnableSmartHedging = true;                     // Enable Smart Hedging
input double HedgeRatio = 0.8;                            // Hedge Ratio (0.8 for safety)
input double HedgeTriggerDrawdownPercent = 8.0;           // Hedge Trigger DD% (8% for cent)
input bool AutoBalanceBuySell = true;                     // Auto Balance Buy/Sell
input int MaxBuySellImbalance = 4;                        // Max Buy/Sell Difference

//+------------------------------------------------------------------+
//| STOCHASTIC FILTER                                                 |
//+------------------------------------------------------------------+
input group "=== STOCHASTIC FILTER ==="
input bool EnableStochFilter = true;                      // Enable Stochastic
input ENUM_TIMEFRAMES StochTimeframe = PERIOD_M1;         // Stochastic Timeframe
input int StochKPeriod = 14;                              // K Period
input int StochDPeriod = 3;                               // D Period
input int StochSlowing = 3;                               // Slowing
input double StochOverbought = 80.0;                      // Overbought Level
input double StochOversold = 20.0;                        // Oversold Level
input bool StochFirstEntryOnly = false;                   // First Entry Only
input bool StochCrossMode = true;                         // Use Crossover Signals

//+------------------------------------------------------------------+
//| MARKET REGIME DETECTION                                           |
//+------------------------------------------------------------------+
input group "=== MARKET REGIME ==="
input bool EnableMarketRegimeFilter = true;               // Enable Regime Filter
input int RegimeDetectionPeriod = 100;                    // Detection Period
input double TrendingThreshold = 0.6;                     // Trending Threshold
input double RangingThreshold = 0.4;                      // Ranging Threshold
input int TrendingStrategy = 1;                           // Trending Strategy (1=Breakout)
input int RangingStrategy = 0;                            // Ranging Strategy (0=Mean)

//+------------------------------------------------------------------+
//| VOLUME/LIQUIDITY ANALYSIS                                         |
//+------------------------------------------------------------------+
input group "=== VOLUME FILTER ==="
input bool EnableVolumeFilter = true;                     // Enable Volume Filter
input double MinVolumePercentile = 25.0;                  // Min Volume Percentile (25 for more trades)
input double VolumeSpikesMultiplier = 2.5;                // Volume Spike Multiplier
input bool AvoidLowLiquidityPeriods = true;               // Avoid Low Liquidity
input int LiquidityCheckPeriod = 50;                      // Liquidity Check Period

//+------------------------------------------------------------------+
//| TRADING DIRECTION                                                 |
//+------------------------------------------------------------------+
input group "=== TRADING DIRECTION ==="
input bool EnableBuy = true;                              // Enable Buy
input int BuyMagicNumber = 1001;                          // Buy Magic Number
input bool EnableSell = true;                             // Enable Sell
input int SellMagicNumber = 1002;                         // Sell Magic Number
input bool SimultaneousBuySell = true;                    // Allow Both Directions
input bool BalanceDirections = true;                      // Balance Directions

//+------------------------------------------------------------------+
//| EQUITY PROTECTION - EXNESS CENT OPTIMIZED                         |
//+------------------------------------------------------------------+
input group "=== EQUITY PROTECTION ==="
input bool EnableEquityProtection = true;                 // Enable Protection
input double StopLossDrawdownPercent = 20.0;              // Max Drawdown % (20% for cent safety)
input bool UseTrailingDrawdown = true;                    // Trailing Drawdown
input double TrailingDrawdownPercent = 12.0;              // Trailing DD % (12%)
input double MaxDailyDrawdownPercent = 10.0;              // Max Daily DD % (10%)
input double EmergencyCloseDrawdown = 25.0;               // Emergency Close DD % (25%)

//+------------------------------------------------------------------+
//| SAFETY FILTERS - EXNESS SPECIFIC                                  |
//+------------------------------------------------------------------+
input group "=== SAFETY FILTERS (EXNESS) ==="
input bool CheckMarginBeforeTrade = true;                 // Check Margin
input double MinFreeMarginPercentRequired = 30.0;         // Min Free Margin % (30% for cent)
input bool EnableSpreadFilter = true;                     // Enable Spread Filter
input double MaxSpreadPips = 25.0;                        // Max Spread (25 pips for Exness gold)
input bool DynamicSpreadAdjustment = true;                // Dynamic Spread Adjust
input bool PauseOnExtremeVolatility = true;               // Pause on High Volatility
input double PauseIfATRMulAboveNormal = 2.0;              // ATR Pause Multiplier (2.0 safer)
input int ATRNormalLookbackBars = 200;                    // ATR Normal Lookback
input bool PauseOnNewsEvents = true;                      // Pause on News
input int ExnessReconnectDelaySeconds = 5;                // Exness Reconnect Delay

//+------------------------------------------------------------------+
//| SMART RECOVERY - EXNESS CENT OPTIMIZED                            |
//+------------------------------------------------------------------+
input group "=== SMART RECOVERY ==="
input bool EnableSmartRecovery = true;                    // Enable Smart Recovery
input int RecoveryMode = 2;                               // Recovery Mode (2=Smart best)
input int MaxRecoveryLayers = 6;                          // Max Recovery Layers (6 for cent)
input double RecoveryMultiplier = 1.4;                    // Recovery Multiplier
input bool BreakEvenRecoveryTarget = true;                // Break-Even Target
input bool PartialRecoveryClose = true;                   // Partial Recovery Close
input double RecoveryProfitPercent = 1.5;                 // Recovery Profit % (1.5%)

//+------------------------------------------------------------------+
//| DAILY PROFIT TARGET - EXNESS CENT                                 |
//+------------------------------------------------------------------+
input group "=== DAILY PROFIT TARGET (CENT) ==="
input bool UseDailyProfitLimit = true;                    // Enable Daily Limit
input int DailyProfitMode = 1;                            // Mode (1=Money for cent)
input double DailyGrossProfitLimit = 5.0;                 // Daily % Limit
input double DailyProfitMoneyTarget = 500.0;              // Daily Target (500 cents = $5)
input bool CloseAllWhenLimitReached = true;               // Close All at Limit
input bool LockProfitsMode = true;                        // Lock Profits
input double DailyProfitTrailPercent = 60.0;              // Profit Trail % (60%)

//+------------------------------------------------------------------+
//| SESSION FILTER - CAMBODIA + EXNESS SERVER TIME                    |
//+------------------------------------------------------------------+
input group "=== SESSION FILTER (GMT+7 Cambodia) ==="
input bool EnableSessionFilter = true;                    // Enable Session Filter
input bool CloseAllOutsideSession = false;                // Close All Outside
input bool StopNewTradesOutsideSession = true;            // Stop New Trades Outside

input bool TradeAsiaSession = true;                       // Trade Asia Session
input string AsiaSessionLocal = "07:00-12:00";            // Asia Hours (Peak morning)
input double AsiaVolatilityMultiplier = 1.0;              // Asia Volatility Mult.

input bool TradeLondonSession = true;                     // Trade London Session
input string LondonSessionLocal = "14:00-19:00";          // London Hours (Extended)
input double LondonVolatilityMultiplier = 1.5;            // London Volatility Mult.

input bool TradeNewYorkSession = false;                   // Trade NY Session
input string NewYorkSessionLocal = "20:00-23:00";         // NY Hours (Evening only)
input double NewYorkVolatilityMultiplier = 1.3;           // NY Volatility Mult.

//+------------------------------------------------------------------+
//| TIME-BASED RULES                                                  |
//+------------------------------------------------------------------+
input group "=== TIME-BASED RULES ==="
input bool AvoidMondayMorning = true;                     // Avoid Monday Morning
input int MondayStartHour = 9;                            // Monday Start Hour (9 AM safe)
input bool AvoidFridayEvening = true;                     // Avoid Friday Evening
input int FridayStopHour = 21;                            // Friday Stop Hour (9 PM)
input bool WeekendCloseAll = true;                        // Close All Weekend

//+------------------------------------------------------------------+
//| PERFORMANCE OPTIMIZATION - EXNESS                                 |
//+------------------------------------------------------------------+
input group "=== PERFORMANCE (EXNESS) ==="
input bool UseTickProcessing = true;                      // Tick Processing
input int MaxTicksPerSecond = 5;                          // Max Ticks/Sec (5 for Exness stability)
input int LoggingLevel = 2;                               // Logging (2=Info)
input bool SavePerformanceStats = true;                   // Save Stats
input int ExnessSlippagePoints = 20;                      // Max Slippage (20 points for Exness)
input int ExnessMaxRetries = 3;                           // Max Order Retries

//+------------------------------------------------------------------+
//| EXNESS-SPECIFIC FEATURES                                          |
//+------------------------------------------------------------------+
input group "=== EXNESS SPECIFIC ==="
input bool UseExnessOptimizations = true;                 // Use Exness Optimizations
input bool CompensateForSpreadWidening = true;            // Compensate Spread Widening
input int ExnessSymbolRefreshMS = 100;                    // Symbol Refresh Rate (ms)
input bool UseExnessFillPolicy = true;                    // Use FOK/IOC Fill Policy

//--- Rest of the code remains the same as the original EA ---
//--- (Copy all the global variables, OnInit, OnDeinit, OnTick functions from the original)

// [Previous code continues here - all the functions remain identical]
// I'll add Exness-specific modifications in the trading functions


//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade trade;
CPositionInfo position;
COrderInfo order;
CSymbolInfo symbol;
CAccountInfo account;

// Exness-specific
double realAccountMultiplier = 1.0;
int exnessReconnectAttempts = 0;
datetime lastExnessError = 0;

// Cent account detection
bool g_isCentAccount = false;
double g_pipValue = 0.0001;  // Default pip value
bool g_autoDetectCentAccount = true;  // Auto-detect cent accounts

// Timing variables
datetime lastEntryTime = 0;
int entriesThisSecond = 0;
datetime currentSecond = 0;

// Price tracking
double lastBuyPrice = 0;
double lastSellPrice = 0;

// Equity tracking
double startingEquity = 0;
double peakEquity = 0;
double dailyStartEquity = 0;
double dailyProfit = 0;
datetime lastDayCheck = 0;

// Adaptive pip step
double currentAdaptiveStep = 0;
double smoothedStep = 0;

// Market regime
int currentRegime = 0;

// Real-time trend detection
int currentTrend = 0; // -1 = downtrend, 0 = neutral, 1 = uptrend
double trendStrength = 0.0; // 0-100, strength of current trend

// Performance tracking
int totalTrades = 0;
int winningTrades = 0;
double totalProfit = 0;

// Indicator handles
int handleRSI = INVALID_HANDLE;
int handleMACD = INVALID_HANDLE;
int handleBB = INVALID_HANDLE;
int handleATR = INVALID_HANDLE;
int handleStoch = INVALID_HANDLE;

// Buffers
double rsiBuffer[];
double macdMainBuffer[], macdSignalBuffer[];
double bbUpperBuffer[], bbMiddleBuffer[], bbLowerBuffer[];
double atrBuffer[];
double stochMainBuffer[], stochSignalBuffer[];

//+------------------------------------------------------------------+
//| Helper: convert deinit reason code to text                        |
//+------------------------------------------------------------------+
string GetUninitReasonText(const int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:    return "EA removed from chart";
      case REASON_REMOVE:     return "EA removed";
      case REASON_RECOMPILE:  return "EA recompiled";
      case REASON_CHARTCHANGE:return "Chart period/symbol changed";
      case REASON_CHARTCLOSE: return "Chart closed";
      case REASON_PARAMETERS: return "Input parameters changed";
      case REASON_ACCOUNT:    return "Account changed";
      case REASON_TEMPLATE:   return "Template applied";
      case REASON_INITFAILED: return "Initialization failed";
      case REASON_CLOSE:      return "Terminal closed";
      default:                return "Unknown reason";
   }
}

//+------------------------------------------------------------------+
//| Helper: check terminal connection (MQL4-style IsConnected)        |
//+------------------------------------------------------------------+
bool IsConnected()
{
   // In MQL5, connection state is obtained via TerminalInfoInteger
   return (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
}

//+------------------------------------------------------------------+
//| Detect Account Type (Cent vs Standard)                          |
//+------------------------------------------------------------------+
void DetectAccountType()
{
    string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Auto-detect cent account
    if(g_autoDetectCentAccount)
    {
        // Check if currency is USC (cent account)
        if(StringFind(accountCurrency, "USC") >= 0 || StringFind(accountCurrency, "C") >= 0)
        {
            g_isCentAccount = true;
        }
        // Check if balance suggests cent account (very small balance in USD)
        else if(StringFind(accountCurrency, "USD") >= 0 && accountBalance < 100.0)
        {
            // Could be cent account with USD currency display
            // Check broker name or use manual setting
            g_isCentAccount = IsExnessCentAccount;
        }
        else
        {
            g_isCentAccount = IsExnessCentAccount;
        }
    }
    else
    {
        g_isCentAccount = IsExnessCentAccount;
    }
    
    // Calculate proper pip value
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // For cent accounts or 3/5 digit brokers
    if(g_isCentAccount || digits == 3 || digits == 5)
    {
        g_pipValue = point * 10;  // 1 pip = 10 points
    }
    else
    {
        g_pipValue = point;  // 1 pip = 1 point (2/4 digit)
    }
    
    Print("═══════════════════════════════════════════════════════════");
    Print("📊 ACCOUNT TYPE DETECTION");
    Print("═══════════════════════════════════════════════════════════");
    Print("Account Currency: ", accountCurrency);
    Print("Account Balance: ", DoubleToString(accountBalance, 2));
    Print("Account Type: ", g_isCentAccount ? "CENT ACCOUNT (USC) ⚠️" : "STANDARD ACCOUNT (USD)");
    Print("Symbol Digits: ", digits);
    Print("Point Value: ", point);
    Print("Pip Value: ", g_pipValue, " (1 pip = ", (g_pipValue / point), " points)");
    Print("═══════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Get Pip Value (Account-aware)                                    |
//+------------------------------------------------------------------+
double GetPipValue()
{
    return g_pipValue;
}

//+------------------------------------------------------------------+
//| Convert Pips to Points (Account-aware)                           |
//+------------------------------------------------------------------+
double PipsToPoints(double pips)
{
    return pips * (g_pipValue / symbol.Point());
}

//+------------------------------------------------------------------+
//| Convert Points to Pips (Account-aware)                           |
//+------------------------------------------------------------------+
double PointsToPips(double points)
{
    if(g_pipValue > 0)
        return points / (g_pipValue / symbol.Point());
    return 0;
}

//+------------------------------------------------------------------+
//| Expert initialization function - EXNESS OPTIMIZED                 |
//+------------------------------------------------------------------+
int OnInit()
{
    // Detect account type FIRST (before any calculations)
    DetectAccountType();
    
    // Validate license
    if(!ValidateLicense())
    {
        Print("Invalid license key!");
        return INIT_FAILED;
    }
    
    // Detect Exness cent account
    if(IsExnessCentAccount)
    {
        realAccountMultiplier = CentAccountMultiplier;
        Print("EXNESS CENT ACCOUNT DETECTED - Multiplier: ", realAccountMultiplier);
        Print("Display balance will be actual balance × ", realAccountMultiplier);
    }
    
    // Set symbol
    symbol.Name(_Symbol);
    symbol.Refresh();
    
    // Exness-specific symbol validation
    if(StringFind(_Symbol, "XAUUSD") == -1 && StringFind(_Symbol, "GOLD") == -1)
    {
        Print("WARNING: This EA is optimized for XAUUSD/GOLD only!");
        Print("Current symbol: ", _Symbol);
    }
    
    // Check for Exness broker
    string brokerName = AccountInfoString(ACCOUNT_COMPANY);
    if(StringFind(brokerName, "Exness") == -1)
    {
        Print("WARNING: This EA is optimized for Exness broker.");
        Print("Current broker: ", brokerName);
        Print("Some features may not work optimally.");
    }
    else
    {
        Print("EXNESS BROKER DETECTED: ", brokerName);
    }
    
    // Set Exness-optimized trade settings
    if(UseExnessOptimizations)
    {
        trade.SetDeviationInPoints(ExnessSlippagePoints);
        trade.SetAsyncMode(false); // Synchronous mode for Exness stability
        
        if(UseExnessFillPolicy)
        {
            trade.SetTypeFilling(ORDER_FILLING_FOK); // Fill or Kill for Exness
        }
        
        Print("Exness optimizations enabled:");
        Print("- Max slippage: ", ExnessSlippagePoints, " points");
        Print("- Fill policy: FOK/IOC");
        Print("- Symbol refresh: ", ExnessSymbolRefreshMS, "ms");
    }
    
    // Initialize equity tracking
    startingEquity = account.Equity();
    peakEquity = startingEquity;
    dailyStartEquity = startingEquity;
    lastDayCheck = TimeCurrent();
    
    // Initialize adaptive step
    currentAdaptiveStep = PipStep;
    smoothedStep = PipStep;
    
    // Initialize trend detection
    currentTrend = 0;
    trendStrength = 0.0;
    
    // Initialize indicators
    if(!InitializeIndicators())
    {
        Print("Failed to initialize indicators!");
        return INIT_FAILED;
    }
    
    // Set magic numbers
    trade.SetExpertMagicNumber(BuyMagicNumber);
    
    // Exness account info
    double displayBalance = account.Balance() * realAccountMultiplier;
    double displayEquity = account.Equity() * realAccountMultiplier;
    
    Print("════════════════════════════════════════════════");
    Print("SuperSmartGoldEA v2.51 - EXNESS CENT EDITION");
    Print("════════════════════════════════════════════════");
    Print("Broker: ", brokerName);
    Print("Account: ", IsExnessCentAccount ? "CENT (×100)" : "Standard");
    Print("Symbol: ", _Symbol);
    Print("Actual Balance: $", DoubleToString(account.Balance(), 2));
    Print("Display Balance: $", DoubleToString(displayBalance, 2));
    Print("Starting Equity: $", DoubleToString(displayEquity, 2));
    Print("Leverage: 1:", IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE)));
    double spreadPips = PointsToPips((double)symbol.Spread() * symbol.Point());
    Print("Spread: ", DoubleToString(spreadPips, 2), " pips");
    Print("────────────────────────────────────────────────");
    Print("Settings:");
    Print("- Rapid Entry: ", EnableRapidEntryMode ? "ENABLED" : "DISABLED");
    Print("- Entry Interval: ", RapidEntryIntervalMS, "ms");
    Print("- Starting Lots: ", DoubleToString(StartingLots, 2));
    Print("- Pip Step: ", DoubleToString(PipStep, 1), " pips");
    Print("- Max Trades: ", MaxTrades, " (", MaxTradesPerDirection, " per side)");
    Print("- Daily Target: ", DoubleToString(DailyProfitMoneyTarget * realAccountMultiplier, 2), " cents");
    Print("- Max Drawdown: ", DoubleToString(StopLossDrawdownPercent, 1), "%");
    Print("════════════════════════════════════════════════");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(handleRSI != INVALID_HANDLE) IndicatorRelease(handleRSI);
    if(handleMACD != INVALID_HANDLE) IndicatorRelease(handleMACD);
    if(handleBB != INVALID_HANDLE) IndicatorRelease(handleBB);
    if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
    if(handleStoch != INVALID_HANDLE) IndicatorRelease(handleStoch);
    
    double winRate = totalTrades > 0 ? (double)winningTrades/totalTrades*100 : 0;
    double displayProfit = totalProfit * realAccountMultiplier;
    
    Print("════════════════════════════════════════════════");
    Print("SuperSmartGoldEA - SESSION SUMMARY");
    Print("════════════════════════════════════════════════");
    Print("Total Trades: ", totalTrades);
    Print("Winning Trades: ", winningTrades);
    Print("Win Rate: ", DoubleToString(winRate, 2), "%");
    Print("Total Profit: ", DoubleToString(displayProfit, 2), " cents");
    Print("Reason: ", GetUninitReasonText(reason));
    Print("════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Expert tick function - EXNESS OPTIMIZED                           |
//+------------------------------------------------------------------+
void OnTick()
{
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
        lastLogTime = TimeCurrent();
    }
    
    // Master switch check
    if(!MasterEnableTrading)
    {
        if(shouldLog) Print("❌ BLOCKED: MasterEnableTrading = FALSE");
        return;
    }
    if(shouldLog) Print("✅ MasterEnableTrading = TRUE");
    
    // Exness symbol refresh optimization
    static datetime lastSymbolRefresh = 0;
    if(TimeCurrent() - lastSymbolRefresh > ExnessSymbolRefreshMS / 1000.0)
    {
        symbol.Refresh();
        symbol.RefreshRates();
        lastSymbolRefresh = TimeCurrent();
    }
    
    // Check for Exness connection issues
    if(!IsConnected())
    {
        if(TimeCurrent() - lastExnessError > ExnessReconnectDelaySeconds)
        {
            Print("❌ BLOCKED: Exness connection lost. Waiting for reconnection...");
            lastExnessError = TimeCurrent();
        }
        return;
    }
    if(shouldLog) Print("✅ Connection: OK");
    
    // Check daily profit/loss reset
    CheckDailyReset();
    
    // Check daily profit target
    if(UseDailyProfitLimit && CheckDailyProfitTarget())
    {
        if(CloseAllWhenLimitReached)
        {
            CloseAllPositions();
            double displayTarget = DailyProfitMoneyTarget * realAccountMultiplier;
            Print("❌ BLOCKED: Daily profit target reached! (", DoubleToString(displayTarget, 2), " cents)");
        }
        if(shouldLog) Print("❌ BLOCKED: Daily profit target reached");
        return;
    }
    if(shouldLog) Print("✅ Daily profit check: OK");
    
    // Check equity protection
    if(EnableEquityProtection && CheckEquityProtection())
    {
        CloseAllPositions();
        Print("❌ BLOCKED: Emergency equity protection triggered!");
        return;
    }
    if(shouldLog) Print("✅ Equity protection: OK");
    
    // Check session filter
    if(EnableSessionFilter && !IsWithinTradingSession())
    {
        if(CloseAllOutsideSession)
            CloseAllPositions();
        if(shouldLog) Print("❌ BLOCKED: Outside trading session");
        return;
    }
    if(shouldLog && EnableSessionFilter) Print("✅ Trading session: OK");
    
    // Check time-based rules
    if(!CheckTimeBasedRules())
    {
        if(shouldLog) Print("❌ BLOCKED: Time-based rules check failed");
        return;
    }
    if(shouldLog) Print("✅ Time-based rules: OK");
    
    // Update adaptive pip step
    if(PipStepMode > 0)
        UpdateAdaptivePipStep();
    
    // Update ATR buffer for real-time calculations
    if(handleATR != INVALID_HANDLE)
        CopyBuffer(handleATR, 0, 0, 50, atrBuffer);
    
    // Detect market regime
    if(EnableMarketRegimeFilter)
        DetectMarketRegime();
    
    // Detect real-time trend for mixed buy/sell strategy
    DetectRealTimeTrend();
    
    // REAL-TIME POSITION MANAGEMENT (Open/Close with smart SL/TP)
    ManagePositions();
    
    // Real-time position opening/closing based on market conditions
    CheckRealTimePositionActions();
    
    // Real-time position opening opportunities (immediate signals)
    CheckRealTimeOpenOpportunities();
    
    // Check basket take profit
    if(EnableBasketTakeProfit && CheckBasketTakeProfit())
    {
        CloseAllPositions();
        Print("Basket take profit reached!");
        return;
    }
    
    // Check if we can enter new trades
    if(!CanOpenNewTrade())
    {
        if(shouldLog) Print("❌ BLOCKED: CanOpenNewTrade() = FALSE");
        return;
    }
    if(shouldLog) Print("✅ CanOpenNewTrade: OK");
    
    // Rate limiting for rapid entries
    if(EnableRapidEntryMode && !CheckRateLimiting())
    {
        if(shouldLog) Print("❌ BLOCKED: Rate limiting active");
        return;
    }
    if(shouldLog && EnableRapidEntryMode) Print("✅ Rate limiting: OK");
    
    // Check spread filter (Exness-specific adjustments)
    if(EnableSpreadFilter && !CheckSpreadFilterExness())
    {
        if(shouldLog)
        {
            double currentSpread = PointsToPips((symbol.Ask() - symbol.Bid()));
            Print("❌ BLOCKED: Spread filter failed. Current spread: ", DoubleToString(currentSpread, 2), 
                  " pips | Max: ", DoubleToString(MaxSpreadPips, 2), " pips");
        }
        return;
    }
    if(shouldLog && EnableSpreadFilter)
    {
        double currentSpread = PointsToPips((symbol.Ask() - symbol.Bid()));
        Print("✅ Spread filter: OK (", DoubleToString(currentSpread, 2), " pips)");
    }
    
    // Check volatility filter
    if(PauseOnExtremeVolatility && CheckExtremeVolatility())
    {
        if(shouldLog) Print("❌ BLOCKED: Extreme volatility detected");
        return;
    }
    if(shouldLog && PauseOnExtremeVolatility) Print("✅ Volatility check: OK");
    
    // Check margin
    if(CheckMarginBeforeTrade && !CheckMarginLevel())
    {
        if(shouldLog) Print("❌ BLOCKED: Insufficient margin");
        return;
    }
    if(shouldLog && CheckMarginBeforeTrade) Print("✅ Margin check: OK");
    
    // Get entry signals
    int buySignal = 0, sellSignal = 0;
    
    if(UseSmartEntrySignals)
    {
        AnalyzeEntrySignals(buySignal, sellSignal);
        if(shouldLog) Print("📊 Entry Signals (Smart): BUY=", buySignal, " | SELL=", sellSignal);
    }
    else
    {
        buySignal = ShouldOpenBuy() ? 1 : 0;
        sellSignal = ShouldOpenSell() ? 1 : 0;
        if(shouldLog) Print("📊 Entry Signals (Simple): BUY=", buySignal, " | SELL=", sellSignal);
    }
    
    // Execute trades with trend-aware mixed buy/sell logic
    int buyCount = CountPositions(POSITION_TYPE_BUY);
    int sellCount = CountPositions(POSITION_TYPE_SELL);
    
    if(shouldLog)
    {
        Print("📊 Position Counts: BUY=", buyCount, " | SELL=", sellCount);
        Print("📊 Trend: ", currentTrend == 1 ? "UP" : (currentTrend == -1 ? "DOWN" : "NEUTRAL"), 
              " | Strength: ", DoubleToString(trendStrength, 1));
    }
    
    // Calculate trend-based position limits
    int maxBuyTrades = MaxTradesPerDirection;
    int maxSellTrades = MaxTradesPerDirection;
    
    // Adjust limits based on trend direction and strength
    if(SimultaneousBuySell && trendStrength > 30.0) // Only adjust if trend is significant
    {
        if(currentTrend == 1) // Uptrend - favor buys
        {
            // Allow more buys, fewer sells
            double trendFactor = trendStrength / 100.0; // 0.3 to 1.0
            maxBuyTrades = (int)(MaxTradesPerDirection * (1.0 + trendFactor * 0.5)); // Up to 1.5x
            maxSellTrades = (int)(MaxTradesPerDirection * (1.0 - trendFactor * 0.3)); // Down to 0.7x
        }
        else if(currentTrend == -1) // Downtrend - favor sells
        {
            // Allow more sells, fewer buys
            double trendFactor = trendStrength / 100.0;
            maxSellTrades = (int)(MaxTradesPerDirection * (1.0 + trendFactor * 0.5)); // Up to 1.5x
            maxBuyTrades = (int)(MaxTradesPerDirection * (1.0 - trendFactor * 0.3)); // Down to 0.7x
        }
        // Neutral trend: equal limits (default)
    }
    
    // Ensure minimum positions allowed
    maxBuyTrades = MathMax(maxBuyTrades, 1);
    maxSellTrades = MathMax(maxSellTrades, 1);
    
    if(shouldLog)
    {
        Print("📊 Max Trades: BUY=", maxBuyTrades, " | SELL=", maxSellTrades);
        Print("📊 EnableBuy: ", EnableBuy ? "TRUE" : "FALSE", " | EnableSell: ", EnableSell ? "TRUE" : "FALSE");
    }
    
    // Execute BUY trades with trend consideration
    if(EnableBuy && buySignal > 0)
    {
        // In strong downtrend, require stronger signal for counter-trend buys
        bool allowBuy = true;
        if(currentTrend == -1 && trendStrength > 60.0)
        {
            // Require stronger signal for counter-trend entries
            if(buySignal < 4) // Need stronger signal
            {
                allowBuy = false;
                if(shouldLog) Print("❌ BUY BLOCKED: Counter-trend signal too weak (signal=", buySignal, ", need >=4)");
            }
        }
        
        if(!allowBuy)
        {
            if(shouldLog) Print("❌ BUY BLOCKED: allowBuy = FALSE");
        }
        else if(buyCount >= maxBuyTrades)
        {
            if(shouldLog) Print("❌ BUY BLOCKED: Max BUY positions reached (", buyCount, " >= ", maxBuyTrades, ")");
        }
        else if(allowBuy && buyCount < maxBuyTrades)
        {
            double lots = CalculateLotSize(POSITION_TYPE_BUY);
            
            // Adjust lot size based on trend alignment
            if(currentTrend == 1 && trendStrength > 50.0)
            {
                // Increase lot size slightly in strong uptrend
                lots *= 1.1;
            }
            else if(currentTrend == -1 && trendStrength > 50.0)
            {
                // Decrease lot size for counter-trend entries
                lots *= 0.8;
            }
            
            // Normalize lots
            double lotStep = symbol.LotsStep();
            lots = MathFloor(lots / lotStep) * lotStep;
            lots = MathMax(lots, MinLotSize);
            lots = MathMin(lots, MaxLotSize);
            
            double sl = CalculateStopLoss(POSITION_TYPE_BUY);
            double tp = CalculateTakeProfit(POSITION_TYPE_BUY);
            
            if(shouldLog)
            {
                Print("🚀 ATTEMPTING BUY ORDER:");
                Print("   Lots: ", DoubleToString(lots, 2));
                Print("   Entry: ", DoubleToString(symbol.Ask(), symbol.Digits()));
                Print("   SL: ", DoubleToString(sl, symbol.Digits()));
                Print("   TP: ", DoubleToString(tp, symbol.Digits()));
            }
            
            if(OpenTradeExness(POSITION_TYPE_BUY, lots, sl, tp))
            {
                Print("✅✅✅ BUY ORDER SUCCESSFUL! ✅✅✅");
                lastBuyPrice = symbol.Ask();
                lastEntryTime = TimeCurrent();
            }
            else
            {
                Print("❌ BUY ORDER FAILED! Error: ", GetLastError());
            }
        }
    }
    
    // Execute SELL trades with trend consideration
    if(EnableSell && sellSignal > 0)
    {
        // In strong uptrend, require stronger signal for counter-trend sells
        bool allowSell = true;
        if(currentTrend == 1 && trendStrength > 60.0)
        {
            // Require stronger signal for counter-trend entries
            if(sellSignal < 4) // Need stronger signal
            {
                allowSell = false;
                if(shouldLog) Print("❌ SELL BLOCKED: Counter-trend signal too weak (signal=", sellSignal, ", need >=4)");
            }
        }
        
        if(!allowSell)
        {
            if(shouldLog) Print("❌ SELL BLOCKED: allowSell = FALSE");
        }
        else if(sellCount >= maxSellTrades)
        {
            if(shouldLog) Print("❌ SELL BLOCKED: Max SELL positions reached (", sellCount, " >= ", maxSellTrades, ")");
        }
        else if(allowSell && sellCount < maxSellTrades)
        {
            double lots = CalculateLotSize(POSITION_TYPE_SELL);
            
            // Adjust lot size based on trend alignment
            if(currentTrend == -1 && trendStrength > 50.0)
            {
                // Increase lot size slightly in strong downtrend
                lots *= 1.1;
            }
            else if(currentTrend == 1 && trendStrength > 50.0)
            {
                // Decrease lot size for counter-trend entries
                lots *= 0.8;
            }
            
            // Normalize lots
            double lotStep = symbol.LotsStep();
            lots = MathFloor(lots / lotStep) * lotStep;
            lots = MathMax(lots, MinLotSize);
            lots = MathMin(lots, MaxLotSize);
            
            double sl = CalculateStopLoss(POSITION_TYPE_SELL);
            double tp = CalculateTakeProfit(POSITION_TYPE_SELL);
            
            if(shouldLog)
            {
                Print("🚀 ATTEMPTING SELL ORDER:");
                Print("   Lots: ", DoubleToString(lots, 2));
                Print("   Entry: ", DoubleToString(symbol.Bid(), symbol.Digits()));
                Print("   SL: ", DoubleToString(sl, symbol.Digits()));
                Print("   TP: ", DoubleToString(tp, symbol.Digits()));
            }
            
            if(OpenTradeExness(POSITION_TYPE_SELL, lots, sl, tp))
            {
                Print("✅✅✅ SELL ORDER SUCCESSFUL! ✅✅✅");
                lastSellPrice = symbol.Bid();
                lastEntryTime = TimeCurrent();
            }
            else
            {
                Print("❌ SELL ORDER FAILED! Error: ", GetLastError());
            }
        }
    }
    else
    {
        if(shouldLog)
        {
            if(!EnableSell) Print("❌ SELL: Disabled (EnableSell = FALSE)");
            if(sellSignal == 0) Print("❌ SELL: No signal (sellSignal = 0)");
        }
    }
    
    if(shouldLog) Print("═══════════════════════════════════════════════════════════");
}

// [Include all the helper functions from the original EA]
// The functions below are the Exness-specific additions:

//+------------------------------------------------------------------+
//| Check spread filter - EXNESS OPTIMIZED                            |
//+------------------------------------------------------------------+
bool CheckSpreadFilterExness()
{
    double currentSpread = PointsToPips((symbol.Ask() - symbol.Bid()));
    double maxAllowedSpread = MaxSpreadPips;
    
    // Exness gold typically has 2-5 pip spread
    // During high volatility, it can spike to 15-25 pips
    
    // Dynamic spread adjustment for Exness
    if(DynamicSpreadAdjustment && CompensateForSpreadWidening)
    {
        MqlDateTime currentTime;
        TimeToStruct(TimeCurrent(), currentTime);
        int hour = currentTime.hour;
        
        // London/NY overlap: allow higher spread
        if(hour >= 14 && hour <= 19) // London session in Cambodia time
        {
            maxAllowedSpread = MaxSpreadPips * 1.5; // 25 × 1.5 = 37.5 pips
        }
        // Asian session: tighter spread expected
        else if(hour >= 7 && hour <= 12)
        {
            maxAllowedSpread = MaxSpreadPips * 0.8; // 25 × 0.8 = 20 pips
        }
    }
    
    if(currentSpread > maxAllowedSpread)
    {
        if(LoggingLevel >= 3)
            Print("Exness spread too high: ", DoubleToString(currentSpread, 1), " pips (max: ", DoubleToString(maxAllowedSpread, 1), ")");
        return false;
    }
    
    // Exness-specific: Check for spread spikes (requotes)
    static double lastSpread = 0;
    if(lastSpread > 0 && currentSpread > lastSpread * 3.0)
    {
        if(LoggingLevel >= 2)
            Print("Exness spread spike detected: ", DoubleToString(currentSpread, 1), " pips (was ", DoubleToString(lastSpread, 1), " pips)");
        lastSpread = currentSpread;
        return false; // Skip this tick
    }
    
    lastSpread = currentSpread;
    return true;
}

//+------------------------------------------------------------------+
//| Open trade with Exness retry logic                                |
//+------------------------------------------------------------------+
bool OpenTradeExness(ENUM_POSITION_TYPE type, double lots, double sl, double tp)
{
    string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
    int magic = (type == POSITION_TYPE_BUY) ? BuyMagicNumber : SellMagicNumber;
    
    trade.SetExpertMagicNumber(magic);
    
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Validate and adjust SL/TP for broker requirements
    // ═══════════════════════════════════════════════════════
    symbol.RefreshRates();
    double entryPrice = (type == POSITION_TYPE_BUY) ? symbol.Ask() : symbol.Bid();
    
    // Get broker's minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * symbol.Point();
    double minStopDistancePips = PointsToPips(minStopDistance);
    
    // Validate and adjust SL
    if(sl > 0)
    {
        double slDistancePips = PointsToPips(MathAbs(entryPrice - sl));
        
        // Adjust SL if too close
        if(slDistancePips < minStopDistancePips)
        {
            slDistancePips = minStopDistancePips + 1.0; // Add 1 pip buffer
            if(type == POSITION_TYPE_BUY)
                sl = entryPrice - slDistancePips * GetPipValue();
            else
                sl = entryPrice + slDistancePips * GetPipValue();
        }
        
        // Validate SL is reasonable (not too far)
        double maxSLPips = g_isCentAccount ? 100.0 : 200.0;
        if(slDistancePips > maxSLPips)
        {
            slDistancePips = maxSLPips;
            if(type == POSITION_TYPE_BUY)
                sl = entryPrice - slDistancePips * GetPipValue();
            else
                sl = entryPrice + slDistancePips * GetPipValue();
        }
        
        // Final validation
        if((type == POSITION_TYPE_BUY && sl >= entryPrice) || 
           (type == POSITION_TYPE_SELL && sl <= entryPrice))
        {
            Print("❌ CRITICAL ERROR: Invalid SL level! Entry: ", DoubleToString(entryPrice, symbol.Digits()), 
                  " | SL: ", DoubleToString(sl, symbol.Digits()));
            return false;
        }
    }
    
    // Validate and adjust TP
    if(tp > 0)
    {
        double tpDistancePips = PointsToPips(MathAbs(tp - entryPrice));
        
        // Adjust TP if too close
        if(tpDistancePips < minStopDistancePips)
        {
            tpDistancePips = minStopDistancePips + 1.0; // Add 1 pip buffer
            if(type == POSITION_TYPE_BUY)
                tp = entryPrice + tpDistancePips * GetPipValue();
            else
                tp = entryPrice - tpDistancePips * GetPipValue();
        }
        
        // Validate TP is reasonable (not too far)
        double maxTPPips = g_isCentAccount ? 300.0 : 500.0;
        if(tpDistancePips > maxTPPips)
        {
            tpDistancePips = maxTPPips;
            if(type == POSITION_TYPE_BUY)
                tp = entryPrice + tpDistancePips * GetPipValue();
            else
                tp = entryPrice - tpDistancePips * GetPipValue();
        }
        
        // Final validation
        if((type == POSITION_TYPE_BUY && tp <= entryPrice) || 
           (type == POSITION_TYPE_SELL && tp >= entryPrice))
        {
            Print("❌ CRITICAL ERROR: Invalid TP level! Entry: ", DoubleToString(entryPrice, symbol.Digits()), 
                  " | TP: ", DoubleToString(tp, symbol.Digits()));
            return false;
        }
    }
    
    // Normalize to proper digits
    sl = NormalizeDouble(sl, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    tp = NormalizeDouble(tp, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    
    bool result = false;
    int retries = 0;
    
    // Exness retry loop
    while(!result && retries < ExnessMaxRetries)
    {
        // Refresh prices before each attempt
        symbol.RefreshRates();
        
        if(type == POSITION_TYPE_BUY)
            result = trade.Buy(lots, _Symbol, 0, sl, tp, "SmartGold-Exness");
        else
            result = trade.Sell(lots, _Symbol, 0, sl, tp, "SmartGold-Exness");
        
        if(!result)
        {
            uint errorCode = GetLastError();
            
            // Handle Exness-specific errors
            switch(errorCode)
            {
                case 10004: // Requote
                case 10006: // Request rejected
                case 10007: // Request canceled
                case 10018: // Market closed
                    if(LoggingLevel >= 2)
                        Print("Exness temporary error: ", errorCode, " - Retry ", retries + 1, "/", ExnessMaxRetries);
                    Sleep(ExnessReconnectDelaySeconds * 1000);
                    retries++;
                    break;
                    
                case 10013: // Invalid request
                case 10014: // Invalid volume
                case 10015: // Invalid price
                case 10016: // Invalid stops
                    if(LoggingLevel >= 1)
                        Print("Exness permanent error: ", errorCode, " - No retry");
                    return false;
                    
                case 10019: // No money
                    if(LoggingLevel >= 1)
                        Print("Insufficient funds for trade. Error: ", errorCode);
                    return false;
                    
                default:
                    if(LoggingLevel >= 1)
                        Print("Unknown Exness error: ", errorCode);
                    retries++;
            }
        }
    }
    
    if(result)
    {
        entriesThisSecond++;
        totalTrades++;
        
        double displayLots = lots / realAccountMultiplier; // Show actual lots for cent
        
        if(LoggingLevel >= 2)
        {
            Print("Opened ", typeStr, " position on Exness:");
            Print("- Ticket: ", trade.ResultOrder());
            Print("- Lots: ", DoubleToString(lots, 2), " (Display: ", DoubleToString(displayLots, 4), ")");
            Print("- Price: ", type == POSITION_TYPE_BUY ? symbol.Ask() : symbol.Bid());
            Print("- SL: ", DoubleToString(sl, symbol.Digits()));
            Print("- TP: ", DoubleToString(tp, symbol.Digits()));
            double spreadPips = PointsToPips((symbol.Ask() - symbol.Bid()));
            Print("- Spread: ", DoubleToString(spreadPips, 2), " pips");
            if(sl > 0)
            {
                double finalSLDistance = PointsToPips(MathAbs(entryPrice - sl));
                Print("✅ SL Distance: ", DoubleToString(finalSLDistance, 2), " pips from entry");
            }
            if(tp > 0)
            {
                double finalTPDistance = PointsToPips(MathAbs(tp - entryPrice));
                Print("✅ TP Distance: ", DoubleToString(finalTPDistance, 2), " pips from entry");
            }
        }
    }
    else
    {
        if(LoggingLevel >= 1)
            Print("Failed to open ", typeStr, " position on Exness after ", ExnessMaxRetries, " retries");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Check basket take profit - EXNESS CENT ADJUSTED                   |
//+------------------------------------------------------------------+
bool CheckBasketTakeProfit()
{
    double totalProfit = 0;
    int posCount = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() != _Symbol)
                continue;
            
            int magic = (int)position.Magic();
            if(magic != BuyMagicNumber && magic != SellMagicNumber)
                continue;
            
            totalProfit += position.Profit() + position.Swap() + position.Commission();
            posCount++;
        }
    }
    
    if(posCount == 0)
        return false;
    
    bool targetReached = false;
    
    // For Exness cent accounts, use money target primarily
    if(BasketTakeProfitMode == 1 || IsExnessCentAccount)
    {
        // Display profit in cents for cent accounts
        double displayProfit = totalProfit * realAccountMultiplier;
        double displayTarget = BasketTP_MinProfitMoney * realAccountMultiplier;
        
        if(totalProfit >= BasketTP_MinProfitMoney)
        {
            if(LoggingLevel >= 2)
                Print("Basket TP (Money): $", DoubleToString(displayProfit, 2), " cents reached (Target: $", DoubleToString(displayTarget, 2), " cents)");
            targetReached = true;
        }
    }
    else if(BasketTakeProfitMode == 0) // Pips
    {
        double avgProfitPips = (totalProfit / posCount) / symbol.Point() / 10.0;
        if(avgProfitPips >= BasketTP_FixedPips)
        {
            if(LoggingLevel >= 2)
                Print("Basket TP (Pips): ", DoubleToString(avgProfitPips, 1), " pips reached");
            targetReached = true;
        }
    }
    
    return targetReached;
}

//+------------------------------------------------------------------+
//| Check daily profit target - EXNESS CENT                           |
//+------------------------------------------------------------------+
bool CheckDailyProfitTarget()
{
    double currentEquity = account.Equity();
    dailyProfit = currentEquity - dailyStartEquity;
    
    bool targetReached = false;
    double displayProfit = dailyProfit * realAccountMultiplier;
    double displayTarget = DailyProfitMoneyTarget * realAccountMultiplier;
    
    if(DailyProfitMode == 0) // Percentage
    {
        double profitPercent = (dailyProfit / dailyStartEquity) * 100.0;
        if(profitPercent >= DailyGrossProfitLimit)
        {
            if(LoggingLevel >= 2)
                Print("Daily profit target (%) reached: ", DoubleToString(profitPercent, 2), "%");
            targetReached = true;
        }
    }
    else // Money (recommended for cent)
    {
        if(dailyProfit >= DailyProfitMoneyTarget)
        {
            if(LoggingLevel >= 2)
                Print("Daily profit target ($) reached: ", DoubleToString(displayProfit, 2), " cents (Target: ", DoubleToString(displayTarget, 2), " cents)");
            targetReached = true;
        }
    }
    
    return targetReached;
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                         |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
    // RSI
    if(UseMomentumFilter)
    {
        handleRSI = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE);
        if(handleRSI == INVALID_HANDLE)
        {
            Print("Failed to create RSI indicator");
            return false;
        }
    }
    
    // MACD
    if(UseMomentumFilter)
    {
        handleMACD = iMACD(_Symbol, PERIOD_CURRENT, MACDFast, MACDSlow, MACDSignal, PRICE_CLOSE);
        if(handleMACD == INVALID_HANDLE)
        {
            Print("Failed to create MACD indicator");
            return false;
        }
    }
    
    // Bollinger Bands
    if(UseBBEntrySignal || PipStepMode == 2 || PipStepMode == 3)
    {
        handleBB = iBands(_Symbol, PERIOD_CURRENT, BBPeriod, 0, BBDeviation, PRICE_CLOSE);
        if(handleBB == INVALID_HANDLE)
        {
            Print("Failed to create Bollinger Bands indicator");
            return false;
        }
    }
    
    // ATR
    if(PipStepMode == 1 || PipStepMode == 3 || UseDynamicStopLoss || UseDynamicTakeProfit)
    {
        handleATR = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
        if(handleATR == INVALID_HANDLE)
        {
            Print("Failed to create ATR indicator");
            return false;
        }
    }
    
    // Stochastic
    if(EnableStochFilter)
    {
        handleStoch = iStochastic(_Symbol, StochTimeframe, StochKPeriod, StochDPeriod, 
                                  StochSlowing, MODE_SMA, STO_LOWHIGH);
        if(handleStoch == INVALID_HANDLE)
        {
            Print("Failed to create Stochastic indicator");
            return false;
        }
    }
    
    // Set array as series
    ArraySetAsSeries(rsiBuffer, true);
    ArraySetAsSeries(macdMainBuffer, true);
    ArraySetAsSeries(macdSignalBuffer, true);
    ArraySetAsSeries(bbUpperBuffer, true);
    ArraySetAsSeries(bbMiddleBuffer, true);
    ArraySetAsSeries(bbLowerBuffer, true);
    ArraySetAsSeries(atrBuffer, true);
    ArraySetAsSeries(stochMainBuffer, true);
    ArraySetAsSeries(stochSignalBuffer, true);
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate license key                                              |
//+------------------------------------------------------------------+
bool ValidateLicense()
{
    // Simple validation - in production use proper encryption
    if(StringLen(InpLicenseKey) < 10)
        return false;
    
    if(StringFind(InpLicenseKey, "supertradingea") == -1)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check daily reset                                                 |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    
    MqlDateTime lastTime;
    TimeToStruct(lastDayCheck, lastTime);
    
    // Check if new day
    if(currentTime.day != lastTime.day)
    {
        // Reset daily counters
        dailyStartEquity = account.Equity();
        dailyProfit = 0;
        lastDayCheck = TimeCurrent();
        
        if(LoggingLevel >= 2)
            Print("New day started. Daily equity reset to: $", DoubleToString(dailyStartEquity, 2));
    }
}

//+------------------------------------------------------------------+
//| Check equity protection                                           |
//+------------------------------------------------------------------+
bool CheckEquityProtection()
{
    double currentEquity = account.Equity();
    double drawdown = ((startingEquity - currentEquity) / startingEquity) * 100.0;
    
    // Update peak equity
    if(currentEquity > peakEquity)
        peakEquity = currentEquity;
    
    // Check trailing drawdown
    if(UseTrailingDrawdown)
    {
        double trailingDD = ((peakEquity - currentEquity) / peakEquity) * 100.0;
        if(trailingDD >= TrailingDrawdownPercent)
        {
            if(LoggingLevel >= 1)
                Print("Trailing drawdown limit reached: ", DoubleToString(trailingDD, 2), "%");
            return true;
        }
    }
    
    // Check max drawdown
    if(drawdown >= StopLossDrawdownPercent)
    {
        if(LoggingLevel >= 1)
            Print("Max drawdown limit reached: ", DoubleToString(drawdown, 2), "%");
        return true;
    }
    
    // Check emergency drawdown
    if(drawdown >= EmergencyCloseDrawdown)
    {
        if(LoggingLevel >= 1)
            Print("EMERGENCY drawdown limit reached: ", DoubleToString(drawdown, 2), "%");
        return true;
    }
    
    // Check daily drawdown
    double dailyDD = ((dailyStartEquity - currentEquity) / dailyStartEquity) * 100.0;
    if(dailyDD >= MaxDailyDrawdownPercent)
    {
        if(LoggingLevel >= 1)
            Print("Daily drawdown limit reached: ", DoubleToString(dailyDD, 2), "%");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if within trading session                                   |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
{
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    
    int currentMinutes = currentTime.hour * 60 + currentTime.min;
    
    // Check Asia session
    if(TradeAsiaSession)
    {
        if(IsTimeInSession(currentMinutes, AsiaSessionLocal))
            return true;
    }
    
    // Check London session
    if(TradeLondonSession)
    {
        if(IsTimeInSession(currentMinutes, LondonSessionLocal))
            return true;
    }
    
    // Check New York session
    if(TradeNewYorkSession)
    {
        if(IsTimeInSession(currentMinutes, NewYorkSessionLocal))
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if time is in session                                       |
//+------------------------------------------------------------------+
bool IsTimeInSession(int currentMinutes, string sessionStr)
{
    string parts[];
    StringSplit(sessionStr, '-', parts);
    
    if(ArraySize(parts) != 2)
        return false;
    
    // Parse start time
    string startParts[];
    StringSplit(parts[0], ':', startParts);
    int startMinutes = StringToInteger(startParts[0]) * 60 + StringToInteger(startParts[1]);
    
    // Parse end time
    string endParts[];
    StringSplit(parts[1], ':', endParts);
    int endMinutes = StringToInteger(endParts[0]) * 60 + StringToInteger(endParts[1]);
    
    // Handle sessions that span midnight
    if(endMinutes < startMinutes)
    {
        return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
    }
    else
    {
        return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
    }
}

//+------------------------------------------------------------------+
//| Check time-based rules                                            |
//+------------------------------------------------------------------+
bool CheckTimeBasedRules()
{
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    
    // Check Monday morning
    if(AvoidMondayMorning && currentTime.day_of_week == 1) // Monday
    {
        if(currentTime.hour < MondayStartHour)
            return false;
    }
    
    // Check Friday evening
    if(AvoidFridayEvening && currentTime.day_of_week == 5) // Friday
    {
        if(currentTime.hour >= FridayStopHour)
            return false;
    }
    
    // Check weekend
    if(WeekendCloseAll && (currentTime.day_of_week == 0 || currentTime.day_of_week == 6))
    {
        CloseAllPositions();
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update adaptive pip step                                          |
//+------------------------------------------------------------------+
void UpdateAdaptivePipStep()
{
    double newStep = PipStep;
    
    // Copy ATR data
    if(handleATR != INVALID_HANDLE)
    {
        CopyBuffer(handleATR, 0, 0, 3, atrBuffer);
    }
    
    switch(PipStepMode)
    {
        case 1: // ATR-based
            if(ArraySize(atrBuffer) > 0)
            {
                double atr = atrBuffer[0];
                double atrPips = atr / symbol.Point() / 10.0;
                newStep = atrPips * ATRSimpleMultiplier;
            }
            break;
            
        case 2: // Bollinger Bands width
            if(handleBB != INVALID_HANDLE)
            {
                CopyBuffer(handleBB, 1, 0, 3, bbUpperBuffer);
                CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer);
                
                if(ArraySize(bbUpperBuffer) > 0 && ArraySize(bbLowerBuffer) > 0)
                {
                    double bbWidth = bbUpperBuffer[0] - bbLowerBuffer[0];
                    double bbWidthPips = bbWidth / symbol.Point() / 10.0;
                    newStep = bbWidthPips * BBWidthMasterMultiplier;
                }
            }
            break;
            
        case 3: // Hybrid
            if(ArraySize(atrBuffer) > 0 && handleBB != INVALID_HANDLE)
            {
                CopyBuffer(handleBB, 1, 0, 3, bbUpperBuffer);
                CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer);
                
                double atr = atrBuffer[0];
                double atrPips = atr / symbol.Point() / 10.0;
                
                if(ArraySize(bbUpperBuffer) > 0 && ArraySize(bbLowerBuffer) > 0)
                {
                    double bbWidth = bbUpperBuffer[0] - bbLowerBuffer[0];
                    double bbWidthPips = bbWidth / symbol.Point() / 10.0;
                    
                    // Weighted average
                    newStep = (atrPips * ATRSimpleMultiplier * 0.5) + (bbWidthPips * BBWidthMasterMultiplier * 0.5);
                }
            }
            break;
    }
    
    // Apply constraints
    newStep = MathMax(newStep, MinAdaptiveStepPips);
    newStep = MathMin(newStep, MaxAdaptiveStepPips);
    
    // Apply spread multiplier
    double spreadPips = PointsToPips((symbol.Ask() - symbol.Bid()));
    double minStepFromSpread = spreadPips * SpreadMinStepMultiplier;
    newStep = MathMax(newStep, minStepFromSpread);
    
    // Apply smoothing
    if(smoothedStep == 0)
        smoothedStep = newStep;
    else
        smoothedStep = smoothedStep * (1.0 - StepSmoothingAlpha) + newStep * StepSmoothingAlpha;
    
    // Apply rate of change limits
    if(currentAdaptiveStep > 0)
    {
        double maxIncrease = currentAdaptiveStep * (1.0 + StepMaxIncreasePctPerUpdate / 100.0);
        double maxDecrease = currentAdaptiveStep * (1.0 - StepMaxDecreasePctPerUpdate / 100.0);
        
        smoothedStep = MathMin(smoothedStep, maxIncrease);
        smoothedStep = MathMax(smoothedStep, maxDecrease);
    }
    
    currentAdaptiveStep = smoothedStep;
    
    if(LoggingLevel >= 3)
        Print("Adaptive Step Updated: ", DoubleToString(currentAdaptiveStep, 2), " pips");
}

//+------------------------------------------------------------------+
//| Detect market regime                                              |
//+------------------------------------------------------------------+
void DetectMarketRegime()
{
    // Simple ADX-like calculation for trend strength
    double highSum = 0, lowSum = 0;
    
    for(int i = 0; i < RegimeDetectionPeriod; i++)
    {
        highSum += iHigh(_Symbol, PERIOD_CURRENT, i);
        lowSum += iLow(_Symbol, PERIOD_CURRENT, i);
    }
    
    double avgHigh = highSum / RegimeDetectionPeriod;
    double avgLow = lowSum / RegimeDetectionPeriod;
    double range = avgHigh - avgLow;
    
    double currentRange = iHigh(_Symbol, PERIOD_CURRENT, 0) - iLow(_Symbol, PERIOD_CURRENT, 0);
    double volatilityRatio = currentRange / range;
    
    if(volatilityRatio > TrendingThreshold)
        currentRegime = 1; // Trending
    else if(volatilityRatio < RangingThreshold)
        currentRegime = 0; // Ranging
    
    if(LoggingLevel >= 3)
        Print("Market Regime: ", currentRegime == 1 ? "TRENDING" : "RANGING");
}

//+------------------------------------------------------------------+
//| Detect real-time trend direction and strength                    |
//+------------------------------------------------------------------+
void DetectRealTimeTrend()
{
    int lookbackPeriod = 20; // Bars to analyze for trend
    double upMoves = 0, downMoves = 0;
    double upStrength = 0, downStrength = 0;
    
    // Calculate price movement direction and strength
    for(int i = 1; i <= lookbackPeriod; i++)
    {
        double close0 = iClose(_Symbol, PERIOD_CURRENT, i - 1);
        double close1 = iClose(_Symbol, PERIOD_CURRENT, i);
        
        if(close0 > close1)
        {
            upMoves++;
            upStrength += (close0 - close1);
        }
        else if(close0 < close1)
        {
            downMoves++;
            downStrength += (close1 - close0);
        }
    }
    
    // Calculate trend direction using multiple methods
    double trendScore = 0.0;
    
    // Method 1: Price movement ratio
    double totalMoves = upMoves + downMoves;
    if(totalMoves > 0)
    {
        double moveRatio = (upMoves - downMoves) / totalMoves;
        trendScore += moveRatio * 40.0; // Weight: 40%
    }
    
    // Method 2: Price strength ratio
    double totalStrength = upStrength + downStrength;
    if(totalStrength > 0)
    {
        double strengthRatio = (upStrength - downStrength) / totalStrength;
        trendScore += strengthRatio * 30.0; // Weight: 30%
    }
    
    // Method 3: EMA comparison (fast vs slow)
    double emaFast = 0, emaSlow = 0;
    int fastPeriod = 9, slowPeriod = 21;
    
    for(int i = 0; i < fastPeriod; i++)
        emaFast += iClose(_Symbol, PERIOD_CURRENT, i);
    emaFast /= fastPeriod;
    
    for(int i = 0; i < slowPeriod; i++)
        emaSlow += iClose(_Symbol, PERIOD_CURRENT, i);
    emaSlow /= slowPeriod;
    
    double currentPrice = (symbol.Ask() + symbol.Bid()) / 2.0;
    if(emaSlow > 0)
    {
        double emaRatio = (emaFast - emaSlow) / emaSlow;
        trendScore += emaRatio * 10000.0 * 0.2; // Weight: 20% (scaled)
    }
    
    // Method 4: Current price vs recent range
    double recentHigh = 0, recentLow = DBL_MAX;
    for(int i = 0; i < 10; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(high > recentHigh) recentHigh = high;
        if(low < recentLow) recentLow = low;
    }
    
    if(recentHigh > recentLow)
    {
        double pricePosition = (currentPrice - recentLow) / (recentHigh - recentLow);
        // Above 0.6 = bullish bias, below 0.4 = bearish bias
        double positionScore = (pricePosition - 0.5) * 2.0; // -1 to +1
        trendScore += positionScore * 10.0; // Weight: 10%
    }
    
    // Determine trend direction
    int previousTrend = currentTrend;
    if(trendScore > 15.0)
        currentTrend = 1; // Uptrend
    else if(trendScore < -15.0)
        currentTrend = -1; // Downtrend
    else
        currentTrend = 0; // Neutral
    
    // Calculate trend strength (0-100)
    trendStrength = MathAbs(trendScore);
    if(trendStrength > 50.0) trendStrength = 50.0; // Cap at 50 for score
    trendStrength = (trendStrength / 50.0) * 100.0; // Convert to 0-100
    
    // Log trend changes
    if(previousTrend != currentTrend && LoggingLevel >= 2)
    {
        string trendStr = "";
        if(currentTrend == 1) trendStr = "UPTREND";
        else if(currentTrend == -1) trendStr = "DOWNTREND";
        else trendStr = "NEUTRAL";
        
        Print("Trend Changed: ", trendStr, " | Strength: ", DoubleToString(trendStrength, 1), "% | Score: ", DoubleToString(trendScore, 2));
    }
    
    if(LoggingLevel >= 3)
    {
        string trendStr = (currentTrend == 1) ? "UP" : (currentTrend == -1) ? "DOWN" : "NEUTRAL";
        Print("Real-Time Trend: ", trendStr, " | Strength: ", DoubleToString(trendStrength, 1), "%");
    }
}

//+------------------------------------------------------------------+
//| Manage existing positions - REAL-TIME SMART MANAGEMENT            |
//+------------------------------------------------------------------+
void ManagePositions()
{
    // Update ATR buffer for dynamic calculations
    if(handleATR != INVALID_HANDLE)
        CopyBuffer(handleATR, 0, 0, 10, atrBuffer);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() != _Symbol)
                continue;
            
            int magic = (int)position.Magic();
            if(magic != BuyMagicNumber && magic != SellMagicNumber)
                continue;
            
            ulong ticket = position.Ticket();
            
            // Check for smart exit conditions first
            if(CheckSmartExitConditions(ticket))
            {
                // Position will be closed by CheckSmartExitConditions
                continue;
            }
            
            // Real-time dynamic SL/TP adjustment
            UpdateDynamicSLTP(ticket);
            
            // Update trailing stop (enhanced)
            if(UseTrailingStop)
                UpdateSmartTrailingStop(ticket);
            
            // Update break-even stop (enhanced)
            if(UseBreakEvenStop)
                UpdateSmartBreakEvenStop(ticket);
            
            // Check partial closes for Fibonacci levels
            if(UseFibonacciLevels && TPMode == 3)
                CheckPartialClose(ticket);
            
            // Check for trend reversal exits
            CheckTrendReversalExit(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Update smart trailing stop - REAL-TIME ADAPTIVE                  |
//+------------------------------------------------------------------+
void UpdateSmartTrailingStop(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return;
    
    double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
    double openPrice = position.PriceOpen();
    double currentSL = position.StopLoss();
    
    double profitPips = 0;
    if(position.Type() == POSITION_TYPE_BUY)
        profitPips = PointsToPips(currentPrice - openPrice);
    else
        profitPips = PointsToPips(openPrice - currentPrice);
    
    // Dynamic trailing start based on volatility
    double dynamicTrailingStart = TrailingStartPips;
    if(ArraySize(atrBuffer) > 0)
    {
        double atr = atrBuffer[0];
        double atrPips = PointsToPips(atr);
        // In high volatility, start trailing earlier
        if(atrPips > 20.0)
            dynamicTrailingStart = TrailingStartPips * 0.8;
        // In low volatility, start trailing later
        else if(atrPips < 10.0)
            dynamicTrailingStart = TrailingStartPips * 1.2;
    }
    
    // Check if profit is enough to start trailing
    if(profitPips < dynamicTrailingStart)
        return;
    
    // Dynamic trailing distance based on volatility and trend
    double dynamicTrailingDistance = TrailingDistancePips;
    
    // Adjust based on volatility
    if(ArraySize(atrBuffer) > 0)
    {
        double atr = atrBuffer[0];
        double atrPips = PointsToPips(atr);
        // Wider trailing in high volatility
        if(atrPips > 20.0)
            dynamicTrailingDistance = TrailingDistancePips * 1.3;
        // Tighter trailing in low volatility
        else if(atrPips < 10.0)
            dynamicTrailingDistance = TrailingDistancePips * 0.8;
    }
    
    // Adjust based on trend alignment
    bool isTrendAligned = false;
    if(position.Type() == POSITION_TYPE_BUY && currentTrend == 1)
        isTrendAligned = true;
    else if(position.Type() == POSITION_TYPE_SELL && currentTrend == -1)
        isTrendAligned = true;
    
    // Wider trailing for trend-aligned positions
    if(isTrendAligned && trendStrength > 50.0)
        dynamicTrailingDistance *= 1.2;
    // Tighter trailing for counter-trend positions
    else if(!isTrendAligned && trendStrength > 50.0)
        dynamicTrailingDistance *= 0.9;
    
    double newSL = 0;
    
    if(position.Type() == POSITION_TYPE_BUY)
    {
        newSL = currentPrice - dynamicTrailingDistance * GetPipValue();
        
        // Only move SL up, never down
        if(newSL > currentSL && newSL < currentPrice)
        {
            newSL = NormalizeDouble(newSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
            if(trade.PositionModify(ticket, newSL, position.TakeProfit()))
            {
            if(LoggingLevel >= 2)
                    Print("[SMART TRAILING] BUY ticket ", ticket, " | SL: ", DoubleToString(newSL, symbol.Digits()), 
                          " | Profit: ", DoubleToString(profitPips, 2), " pips");
            }
        }
    }
    else // SELL
    {
        newSL = currentPrice + dynamicTrailingDistance * GetPipValue();
        
        // Only move SL down, never up
        if((currentSL == 0 || newSL < currentSL) && newSL > currentPrice)
        {
            if(trade.PositionModify(ticket, newSL, position.TakeProfit()))
            {
            if(LoggingLevel >= 2)
                    Print("[SMART TRAILING] SELL ticket ", ticket, " | SL: ", DoubleToString(newSL, symbol.Digits()), 
                          " | Profit: ", DoubleToString(profitPips, 1), " pips");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update smart break-even stop - REAL-TIME ADAPTIVE                |
//+------------------------------------------------------------------+
void UpdateSmartBreakEvenStop(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return;
    
    double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
    double openPrice = position.PriceOpen();
    double currentSL = position.StopLoss();
    
    double profitPips = 0;
    if(position.Type() == POSITION_TYPE_BUY)
        profitPips = PointsToPips(currentPrice - openPrice);
    else
        profitPips = PointsToPips(openPrice - currentPrice);
    
    // Dynamic break-even trigger based on volatility
    double dynamicBETrigger = BreakEvenTriggerPips;
    if(ArraySize(atrBuffer) > 0)
    {
        double atr = atrBuffer[0];
        double atrPips = PointsToPips(atr);
        // In high volatility, trigger BE earlier
        if(atrPips > 20.0)
            dynamicBETrigger = BreakEvenTriggerPips * 0.8;
    }
    
    // Check if profit is enough to move to break-even
    if(profitPips < dynamicBETrigger)
        return;
    
    // Dynamic break-even offset
    double dynamicBEOffset = BreakEvenOffsetPips;
    
    // Adjust offset based on spread
    double spreadPips = PointsToPips((symbol.Ask() - symbol.Bid()));
    dynamicBEOffset = MathMax(dynamicBEOffset, spreadPips * 1.5);
    
    double newSL = 0;
    
    if(position.Type() == POSITION_TYPE_BUY)
    {
        newSL = openPrice + dynamicBEOffset * GetPipValue();
        
        // Only set BE if not already done
        if(currentSL < openPrice)
        {
            newSL = NormalizeDouble(newSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
            if(trade.PositionModify(ticket, newSL, position.TakeProfit()))
            {
            if(LoggingLevel >= 2)
                    Print("[SMART BE] BUY ticket ", ticket, " | BE SL: ", DoubleToString(newSL, symbol.Digits()), 
                          " | Profit: ", DoubleToString(profitPips, 2), " pips");
            }
        }
    }
    else // SELL
    {
        newSL = openPrice - dynamicBEOffset * GetPipValue();
        
        // Only set BE if not already done
        if(currentSL == 0 || currentSL > openPrice)
        {
            if(trade.PositionModify(ticket, newSL, position.TakeProfit()))
            {
            if(LoggingLevel >= 2)
                    Print("[SMART BE] SELL ticket ", ticket, " | BE SL: ", DoubleToString(newSL, symbol.Digits()), 
                          " | Profit: ", DoubleToString(profitPips, 1), " pips");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check smart exit conditions - REAL-TIME EXIT LOGIC               |
//+------------------------------------------------------------------+
bool CheckSmartExitConditions(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return false;
    
    double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
    double openPrice = position.PriceOpen();
    double profitPips = 0;
    
    if(position.Type() == POSITION_TYPE_BUY)
        profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
    else
        profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
    
    // Exit condition 1: Strong trend reversal against position
    bool isCounterTrend = false;
    if(position.Type() == POSITION_TYPE_BUY && currentTrend == -1 && trendStrength > 70.0)
        isCounterTrend = true;
    else if(position.Type() == POSITION_TYPE_SELL && currentTrend == 1 && trendStrength > 70.0)
        isCounterTrend = true;
    
    if(isCounterTrend && profitPips > 5.0) // Exit if in profit and strong reversal
    {
        if(trade.PositionClose(ticket))
        {
            if(LoggingLevel >= 2)
                Print("[SMART EXIT] Trend reversal - Closed ticket ", ticket, " | Profit: ", DoubleToString(profitPips, 1), " pips");
            return true;
        }
    }
    
    // Exit condition 2: Extreme volatility spike (protect profits)
    if(ArraySize(atrBuffer) >= 5)
    {
        double currentATR = atrBuffer[0];
        double avgATR = 0;
        for(int i = 1; i < 5; i++)
            avgATR += atrBuffer[i];
        avgATR /= 4.0;
        
        if(avgATR > 0 && currentATR > avgATR * 2.5 && profitPips > 10.0)
        {
            // Extreme volatility spike - close profitable positions
            if(trade.PositionClose(ticket))
            {
                if(LoggingLevel >= 2)
                    Print("[SMART EXIT] Extreme volatility - Closed ticket ", ticket, " | Profit: ", DoubleToString(profitPips, 1), " pips");
                return true;
            }
        }
    }
    
    // Exit condition 3: Spread spike (requote protection)
    double spreadPips = (symbol.Ask() - symbol.Bid()) / symbol.Point() / 10.0;
    static double lastNormalSpread = 5.0;
    if(spreadPips > lastNormalSpread * 3.0 && profitPips > 5.0)
    {
        // Spread spike detected - close to avoid requotes
        if(trade.PositionClose(ticket))
        {
            if(LoggingLevel >= 2)
                Print("[SMART EXIT] Spread spike - Closed ticket ", ticket, " | Spread: ", DoubleToString(spreadPips, 1), " pips");
            return true;
        }
    }
    else if(spreadPips < MaxSpreadPips)
    {
        lastNormalSpread = spreadPips; // Update normal spread
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Update dynamic SL/TP - REAL-TIME SUPER SMART ADAPTIVE           |
//+------------------------------------------------------------------+
void UpdateDynamicSLTP(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return;
    
    // Only update if dynamic SL/TP is enabled
    if(!UseDynamicStopLoss && !UseDynamicTakeProfit)
        return;
    
    double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
    double openPrice = position.PriceOpen();
    double currentSL = position.StopLoss();
    double currentTP = position.TakeProfit();
    double profitPips = 0;
    
    if(position.Type() == POSITION_TYPE_BUY)
        profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
    else
        profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
    
    // Update indicator buffers for real-time analysis
    if(handleRSI != INVALID_HANDLE)
        CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer);
    if(handleBB != INVALID_HANDLE)
    {
        CopyBuffer(handleBB, 1, 0, 3, bbUpperBuffer);
        CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer);
    }
    
    // REAL-TIME SL UPDATE
    if(UseDynamicStopLoss)
    {
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)position.Type();
        double optimalSL = CalculateDynamicStopLoss(posType, openPrice, currentPrice);
        
        if(optimalSL > 0)
        {
            double slDiffPips = 0;
            if(currentSL > 0)
                slDiffPips = MathAbs(currentSL - optimalSL) / symbol.Point() / 10.0;
            else
                slDiffPips = 999; // Force update if no SL
            
            // Update threshold: 2 pips for profitable positions, 5 pips for losing
            double updateThreshold = (profitPips > 0) ? 2.0 : 5.0;
            
            if(slDiffPips > updateThreshold)
            {
                bool shouldUpdate = false;
                
                if(position.Type() == POSITION_TYPE_BUY)
                {
                    // Only move SL up (tighten), never down
                    if(optimalSL > currentSL || currentSL == 0)
                    {
                        // Additional check: don't move SL if price is near it (avoid immediate hit)
                        double distanceToSL = (currentPrice - optimalSL) / symbol.Point() / 10.0;
                        if(distanceToSL > 3.0) // At least 3 pips buffer
                            shouldUpdate = true;
                    }
                }
                else // SELL
                {
                    // Only move SL down (tighten), never up
                    if(currentSL == 0 || optimalSL < currentSL)
                    {
                        double distanceToSL = (optimalSL - currentPrice) / symbol.Point() / 10.0;
                        if(distanceToSL > 3.0) // At least 3 pips buffer
                            shouldUpdate = true;
                    }
                }
                
                if(shouldUpdate)
                {
                    // Use current TP or recalculate
                    double newTP = currentTP;
                    if(UseDynamicTakeProfit && !EnableBasketTakeProfit && currentTP > 0)
                    {
                        // Recalculate TP to maintain RR ratio
                        double slDistance = MathAbs(currentPrice - optimalSL);
                        double currentRR = 0;
                        if(currentSL > 0)
                        {
                            double oldSLDistance = MathAbs(openPrice - currentSL);
                            if(oldSLDistance > 0)
                            {
                                double oldTPDistance = MathAbs(currentTP - openPrice);
                                currentRR = oldTPDistance / oldSLDistance;
                            }
                        }
                        
                        if(currentRR > 0)
                            newTP = (position.Type() == POSITION_TYPE_BUY) ? 
                                    currentPrice + slDistance * currentRR : 
                                    currentPrice - slDistance * currentRR;
                    }
                    
                    if(trade.PositionModify(ticket, optimalSL, newTP))
                    {
                        if(LoggingLevel >= 2)
                            Print("[REAL-TIME SL] Ticket ", ticket, " | Old SL: ", DoubleToString(currentSL, symbol.Digits()), 
                                  " | New SL: ", DoubleToString(optimalSL, symbol.Digits()), 
                                  " | Profit: ", DoubleToString(profitPips, 1), " pips");
                    }
                }
            }
        }
    }
    
    // REAL-TIME TP UPDATE
    if(UseDynamicTakeProfit && !EnableBasketTakeProfit)
    {
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)position.Type();
        double optimalTP = CalculateDynamicTakeProfit(posType, openPrice, currentPrice, currentSL);
        
        if(optimalTP > 0)
        {
            double tpDiffPips = 0;
            if(currentTP > 0)
                tpDiffPips = MathAbs(currentTP - optimalTP) / symbol.Point() / 10.0;
            else
                tpDiffPips = 999; // Force update if no TP
            
            // Update threshold: 3 pips for profitable positions, 8 pips for losing
            double updateThreshold = (profitPips > 0) ? 3.0 : 8.0;
            
            if(tpDiffPips > updateThreshold)
            {
                bool shouldUpdate = false;
                
                if(position.Type() == POSITION_TYPE_BUY)
                {
                    // Only move TP up (widen), never down
                    if(optimalTP > currentTP || currentTP == 0)
                        shouldUpdate = true;
                }
                else // SELL
                {
                    // Only move TP down (widen), never up
                    if(currentTP == 0 || optimalTP < currentTP)
                        shouldUpdate = true;
                }
                
                // Additional check: only widen TP if trend is strong and aligned
                if(shouldUpdate)
                {
                    bool isTrendAligned = false;
                    if(position.Type() == POSITION_TYPE_BUY && currentTrend == 1)
                        isTrendAligned = true;
                    else if(position.Type() == POSITION_TYPE_SELL && currentTrend == -1)
                        isTrendAligned = true;
                    
                    // Only widen TP if trend is strong and aligned, or if no TP exists
                    if(currentTP == 0 || (isTrendAligned && trendStrength > 60.0 && profitPips > 10.0))
                    {
                        if(trade.PositionModify(ticket, currentSL, optimalTP))
                        {
                            if(LoggingLevel >= 2)
                                Print("[REAL-TIME TP] Ticket ", ticket, " | Old TP: ", DoubleToString(currentTP, symbol.Digits()), 
                                      " | New TP: ", DoubleToString(optimalTP, symbol.Digits()), 
                                      " | Profit: ", DoubleToString(profitPips, 1), " pips");
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic stop loss for existing position - SUPER SMART |
//+------------------------------------------------------------------+
double CalculateDynamicStopLoss(ENUM_POSITION_TYPE type, double openPrice, double currentPrice)
{
    double sl = 0;
    double spreadPips = (symbol.Ask() - symbol.Bid()) / symbol.Point() / 10.0;
    double profitPips = 0;
    
    if(type == POSITION_TYPE_BUY)
        profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
    else
        profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
    
    if(SLMode == 1 && ArraySize(atrBuffer) > 0) // ATR-based
    {
        double atr = atrBuffer[0];
        double slDistance = atr * ATRSLMultiplier;
        
        // Adjust based on current profit (tighten as profit increases)
        if(profitPips > 30.0)
            slDistance *= 0.7; // Much tighter for big profits
        else if(profitPips > 20.0)
            slDistance *= 0.8;
        else if(profitPips > 10.0)
            slDistance *= 0.9;
        
        // Adjust based on trend alignment
        bool isTrendAligned = false;
        if(type == POSITION_TYPE_BUY && currentTrend == 1)
            isTrendAligned = true;
        else if(type == POSITION_TYPE_SELL && currentTrend == -1)
            isTrendAligned = true;
        
        // Tighter SL for trend-aligned positions in profit
        if(isTrendAligned && trendStrength > 50.0 && profitPips > 5.0)
            slDistance *= 0.85;
        
        // Adjust based on volatility
        if(ArraySize(atrBuffer) >= 10)
        {
            double avgATR = 0;
            for(int i = 1; i < 10; i++)
                avgATR += atrBuffer[i];
            avgATR /= 9.0;
            
            if(avgATR > 0)
            {
                double atrRatio = atr / avgATR;
                // In high volatility, use wider SL
                if(atrRatio > 1.5)
                    slDistance *= 1.2;
                // In low volatility, use tighter SL
                else if(atrRatio < 0.7)
                    slDistance *= 0.9;
            }
        }
        
        // Minimum distance
        double minDistance = (spreadPips * 1.5 + 2.0) * symbol.Point() * 10.0;
        slDistance = MathMax(slDistance, minDistance);
        
        if(type == POSITION_TYPE_BUY)
            sl = currentPrice - slDistance;
        else
            sl = currentPrice + slDistance;
    }
    else if(SLMode == 2) // Support/Resistance
    {
        // Find nearest support/resistance
        if(type == POSITION_TYPE_BUY)
        {
            double swingLow = FindSwingLow(20);
            // Use current price if swing is too far
            if(swingLow < currentPrice - 50 * symbol.Point() * 10.0)
                swingLow = currentPrice - 30 * symbol.Point() * 10.0; // Use 30 pip fallback
            
            double buffer = 3.0;
            if(ArraySize(atrBuffer) > 0)
            {
                double atr = atrBuffer[0];
                double atrPips = atr / symbol.Point() / 10.0;
                buffer = MathMax(2.0, atrPips * 0.15);
            }
            
            sl = swingLow - buffer * symbol.Point() * 10.0;
            
            // Don't set SL below break-even if in profit
            if(profitPips > 5.0)
            {
                double beSL = openPrice + 1.0 * symbol.Point() * 10.0;
                sl = MathMax(sl, beSL);
            }
        }
        else // SELL
        {
            double swingHigh = FindSwingHigh(20);
            // Use current price if swing is too far
            if(swingHigh > currentPrice + 50 * symbol.Point() * 10.0)
                swingHigh = currentPrice + 30 * symbol.Point() * 10.0; // Use 30 pip fallback
            
            double buffer = 3.0;
            if(ArraySize(atrBuffer) > 0)
            {
                double atr = atrBuffer[0];
                double atrPips = atr / symbol.Point() / 10.0;
                buffer = MathMax(2.0, atrPips * 0.15);
            }
            
            sl = swingHigh + buffer * symbol.Point() * 10.0;
            
            // Don't set SL above break-even if in profit
            if(profitPips > 5.0)
            {
                double beSL = openPrice - 1.0 * symbol.Point() * 10.0;
                sl = MathMin(sl, beSL);
            }
        }
    }
    
    // Final validation
    if(sl > 0)
    {
        double slDistancePips = MathAbs(currentPrice - sl) / symbol.Point() / 10.0;
        double minSLPips = spreadPips * 1.5 + 2.0;
        double maxSLPips = 150.0; // Safety cap
        
        if(slDistancePips < minSLPips)
        {
            if(type == POSITION_TYPE_BUY)
                sl = currentPrice - minSLPips * symbol.Point() * 10.0;
            else
                sl = currentPrice + minSLPips * symbol.Point() * 10.0;
        }
        else if(slDistancePips > maxSLPips)
        {
            if(type == POSITION_TYPE_BUY)
                sl = currentPrice - maxSLPips * symbol.Point() * 10.0;
            else
                sl = currentPrice + maxSLPips * symbol.Point() * 10.0;
        }
    }
    
    return sl;
}

//+------------------------------------------------------------------+
//| Calculate dynamic take profit for existing position - SUPER SMART|
//+------------------------------------------------------------------+
double CalculateDynamicTakeProfit(ENUM_POSITION_TYPE type, double openPrice, double currentPrice, double currentSL)
{
    double tp = 0;
    double profitPips = 0;
    
    if(type == POSITION_TYPE_BUY)
        profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
    else
        profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
    
    if(TPMode == 1 && ArraySize(atrBuffer) > 0) // ATR-based
    {
        double atr = atrBuffer[0];
        double tpDistance = atr * ATRTPMultiplier;
        
        // Adjust based on trend alignment
        bool isTrendAligned = false;
        if(type == POSITION_TYPE_BUY && currentTrend == 1)
            isTrendAligned = true;
        else if(type == POSITION_TYPE_SELL && currentTrend == -1)
            isTrendAligned = true;
        
        // Wider TP for trend-aligned positions
        if(isTrendAligned && trendStrength > 50.0)
        {
            if(trendStrength > 70.0)
                tpDistance *= 1.5; // Very wide in strong trends
            else
                tpDistance *= 1.3;
        }
        // Tighter TP for counter-trend positions
        else if(!isTrendAligned && trendStrength > 50.0)
            tpDistance *= 0.8;
        
        // Adjust based on current profit (widen if already profitable)
        if(profitPips > 20.0)
            tpDistance *= 1.2; // Widen TP if already in good profit
        else if(profitPips > 10.0)
            tpDistance *= 1.1;
        
        // Adjust based on volatility
        if(ArraySize(atrBuffer) >= 10)
        {
            double avgATR = 0;
            for(int i = 1; i < 10; i++)
                avgATR += atrBuffer[i];
            avgATR /= 9.0;
            
            if(avgATR > 0)
            {
                double atrRatio = atr / avgATR;
                // In high volatility, use wider TP
                if(atrRatio > 1.5)
                    tpDistance *= 1.3;
            }
        }
        
        if(type == POSITION_TYPE_BUY)
            tp = currentPrice + tpDistance;
        else
            tp = currentPrice - tpDistance;
    }
    else if(TPMode == 2 && currentSL > 0) // Risk-Reward
    {
        double slDistance = MathAbs(currentPrice - currentSL);
        double dynamicRR = RiskRewardRatio;
        
        // Adjust RR based on trend alignment
        bool isTrendAligned = false;
        if(type == POSITION_TYPE_BUY && currentTrend == 1)
            isTrendAligned = true;
        else if(type == POSITION_TYPE_SELL && currentTrend == -1)
            isTrendAligned = true;
        
        // Increase RR in strong aligned trends
        if(isTrendAligned)
        {
            if(trendStrength > 70.0)
                dynamicRR *= 1.4; // Much higher RR in very strong trends
            else if(trendStrength > 50.0)
                dynamicRR *= 1.2;
        }
        
        // Increase RR if already in profit (let profits run)
        if(profitPips > 15.0)
            dynamicRR *= 1.3;
        else if(profitPips > 10.0)
            dynamicRR *= 1.15;
        
        // Minimum RR
        dynamicRR = MathMax(dynamicRR, 1.5);
        
        if(type == POSITION_TYPE_BUY)
            tp = currentPrice + slDistance * dynamicRR;
        else
            tp = currentPrice - slDistance * dynamicRR;
    }
    else if(TPMode == 3) // Fibonacci
    {
        double swingHigh = FindSwingHigh(50);
        double swingLow = FindSwingLow(50);
        double swingRange = swingHigh - swingLow;
        
        if(swingRange > 0)
        {
            // Check trend alignment
            bool isTrendAligned = false;
            if(type == POSITION_TYPE_BUY && currentTrend == 1)
                isTrendAligned = true;
            else if(type == POSITION_TYPE_SELL && currentTrend == -1)
                isTrendAligned = true;
            
            // Use appropriate Fib level based on trend and profit
            double fibLevel = FibTP1;
            
            if(isTrendAligned && trendStrength > 60.0 && profitPips > 10.0)
                fibLevel = FibTP2; // Use 0.618 for strong trend-aligned positions
            else if(profitPips > 20.0)
                fibLevel = (FibTP1 + FibTP2) / 2.0; // Average for good profits
            
            double tpDistance = swingRange * fibLevel;
            
            // Minimum TP distance
            tpDistance = MathMax(tpDistance, swingRange * 0.2);
            
            if(type == POSITION_TYPE_BUY)
                tp = currentPrice + tpDistance;
            else
                tp = currentPrice - tpDistance;
        }
    }
    
    // Final validation
    if(tp > 0)
    {
        double tpDistancePips = MathAbs(currentPrice - tp) / symbol.Point() / 10.0;
        double minTPPips = 8.0;
        
        if(tpDistancePips < minTPPips)
        {
            if(type == POSITION_TYPE_BUY)
                tp = currentPrice + minTPPips * symbol.Point() * 10.0;
            else
                tp = currentPrice - minTPPips * symbol.Point() * 10.0;
        }
    }
    
    return tp;
}

//+------------------------------------------------------------------+
//| Check real-time position actions (open/close) - SUPER SMART     |
//+------------------------------------------------------------------+
void CheckRealTimePositionActions()
{
    // Update indicator buffers for real-time analysis
    if(handleRSI != INVALID_HANDLE)
        CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer);
    if(handleMACD != INVALID_HANDLE)
    {
        CopyBuffer(handleMACD, 0, 0, 3, macdMainBuffer);
        CopyBuffer(handleMACD, 1, 0, 3, macdSignalBuffer);
    }
    if(handleBB != INVALID_HANDLE)
    {
        CopyBuffer(handleBB, 1, 0, 3, bbUpperBuffer);
        CopyBuffer(handleBB, 0, 0, 3, bbMiddleBuffer);
        CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer);
    }
    
    // Check all positions for real-time actions
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() != _Symbol)
                continue;
            
            int magic = (int)position.Magic();
            if(magic != BuyMagicNumber && magic != SellMagicNumber)
                continue;
            
            ulong ticket = position.Ticket();
            double profit = position.Profit() + position.Swap() + position.Commission();
            double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
            double openPrice = position.PriceOpen();
            double profitPips = 0;
            
            if(position.Type() == POSITION_TYPE_BUY)
                profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
            else
                profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
            
            // REAL-TIME CLOSE CONDITIONS
            
            // 1. Quick profit target reached (scalping exit)
            if(profitPips >= 15.0 && profitPips < 30.0)
            {
                // Check if momentum is weakening
                bool momentumWeakening = false;
                if(ArraySize(rsiBuffer) >= 2)
                {
                    double rsi = rsiBuffer[0];
                    double rsiPrev = rsiBuffer[1];
                    // RSI reversing from extreme
                    if(position.Type() == POSITION_TYPE_BUY && rsi > 70 && rsi < rsiPrev)
                        momentumWeakening = true;
                    else if(position.Type() == POSITION_TYPE_SELL && rsi < 30 && rsi > rsiPrev)
                        momentumWeakening = true;
                }
                
                if(momentumWeakening)
                {
                    if(trade.PositionClose(ticket))
                    {
                        if(LoggingLevel >= 2)
                            Print("[REAL-TIME CLOSE] Quick profit + momentum weakening | Ticket: ", ticket, 
                                  " | Profit: ", DoubleToString(profitPips, 1), " pips");
                        continue;
                    }
                }
            }
            
            // 2. Trend reversal exit (strong signal)
            if(position.Type() == POSITION_TYPE_BUY)
            {
                // Close BUY if strong downtrend and losing
                if(profit < 0 && currentTrend == -1 && trendStrength > 75.0)
                {
                    if(trade.PositionClose(ticket))
                    {
                        if(LoggingLevel >= 2)
                            Print("[REAL-TIME CLOSE] BUY trend reversal | Ticket: ", ticket, 
                                  " | Loss: ", DoubleToString(profitPips, 1), " pips");
                        continue;
                    }
                }
                
                // Close BUY if MACD bearish crossover in profit
                if(profitPips > 10.0 && ArraySize(macdMainBuffer) >= 2 && ArraySize(macdSignalBuffer) >= 2)
                {
                    double macdMain = macdMainBuffer[0];
                    double macdSignal = macdSignalBuffer[0];
                    double macdMainPrev = macdMainBuffer[1];
                    double macdSignalPrev = macdSignalBuffer[1];
                    
                    if(macdMainPrev > macdSignalPrev && macdMain < macdSignal) // Bearish crossover
                    {
                        if(trade.PositionClose(ticket))
                        {
                            if(LoggingLevel >= 2)
                                Print("[REAL-TIME CLOSE] BUY MACD bearish cross | Ticket: ", ticket, 
                                      " | Profit: ", DoubleToString(profitPips, 1), " pips");
                            continue;
                        }
                    }
                }
            }
            else // SELL
            {
                // Close SELL if strong uptrend and losing
                if(profit < 0 && currentTrend == 1 && trendStrength > 75.0)
                {
                    if(trade.PositionClose(ticket))
                    {
                        if(LoggingLevel >= 2)
                            Print("[REAL-TIME CLOSE] SELL trend reversal | Ticket: ", ticket, 
                                  " | Loss: ", DoubleToString(profitPips, 1), " pips");
                        continue;
                    }
                }
                
                // Close SELL if MACD bullish crossover in profit
                if(profitPips > 10.0 && ArraySize(macdMainBuffer) >= 2 && ArraySize(macdSignalBuffer) >= 2)
                {
                    double macdMain = macdMainBuffer[0];
                    double macdSignal = macdSignalBuffer[0];
                    double macdMainPrev = macdMainBuffer[1];
                    double macdSignalPrev = macdSignalBuffer[1];
                    
                    if(macdMainPrev < macdSignalPrev && macdMain > macdSignal) // Bullish crossover
                    {
                        if(trade.PositionClose(ticket))
                        {
                            if(LoggingLevel >= 2)
                                Print("[REAL-TIME CLOSE] SELL MACD bullish cross | Ticket: ", ticket, 
                                      " | Profit: ", DoubleToString(profitPips, 1), " pips");
                            continue;
                        }
                    }
                }
            }
            
            // 3. Bollinger Bands reversal exit
            if(ArraySize(bbUpperBuffer) >= 1 && ArraySize(bbLowerBuffer) >= 1 && profitPips > 5.0)
            {
                double upper = bbUpperBuffer[0];
                double lower = bbLowerBuffer[0];
                double currentPriceBB = (symbol.Ask() + symbol.Bid()) / 2.0;
                
                // Close BUY if price hits upper BB and reversing
                if(position.Type() == POSITION_TYPE_BUY && currentPriceBB >= upper)
                {
                    // Check if price is starting to reverse
                    double price1 = iClose(_Symbol, PERIOD_CURRENT, 0);
                    double price2 = iClose(_Symbol, PERIOD_CURRENT, 1);
                    if(price1 < price2) // Price declining
                    {
                        if(trade.PositionClose(ticket))
                        {
                            if(LoggingLevel >= 2)
                                Print("[REAL-TIME CLOSE] BUY BB upper reversal | Ticket: ", ticket, 
                                      " | Profit: ", DoubleToString(profitPips, 1), " pips");
                            continue;
                        }
                    }
                }
                
                // Close SELL if price hits lower BB and reversing
                if(position.Type() == POSITION_TYPE_SELL && currentPriceBB <= lower)
                {
                    // Check if price is starting to reverse
                    double price1 = iClose(_Symbol, PERIOD_CURRENT, 0);
                    double price2 = iClose(_Symbol, PERIOD_CURRENT, 1);
                    if(price1 > price2) // Price rising
                    {
                        if(trade.PositionClose(ticket))
                        {
                            if(LoggingLevel >= 2)
                                Print("[REAL-TIME CLOSE] SELL BB lower reversal | Ticket: ", ticket, 
                                      " | Profit: ", DoubleToString(profitPips, 1), " pips");
                            continue;
                        }
                    }
                }
            }
            
            // 4. Profit target reached - close immediately
            double tp = position.TakeProfit();
            if(tp > 0)
            {
                double tpDistance = MathAbs(tp - openPrice) / symbol.Point() / 10.0;
                // Close if within 2 pips of TP
                if(profitPips >= tpDistance * 0.95) // 95% of TP reached
                {
                    if(trade.PositionClose(ticket))
                    {
                        if(LoggingLevel >= 2)
                            Print("[REAL-TIME CLOSE] TP target reached | Ticket: ", ticket, 
                                  " | Profit: ", DoubleToString(profitPips, 1), " pips");
                        continue;
                    }
                }
            }
            
            // 5. Time-based exit (if position is old and not profitable)
            datetime positionTime = (datetime)position.Time();
            int positionAgeHours = (int)((TimeCurrent() - positionTime) / 3600);
            
            // Close old unprofitable positions (more than 4 hours)
            if(positionAgeHours > 4 && profit < 0 && profitPips < -20.0)
            {
                if(trade.PositionClose(ticket))
                {
                    if(LoggingLevel >= 2)
                        Print("[REAL-TIME CLOSE] Old losing position | Ticket: ", ticket, 
                              " | Age: ", positionAgeHours, "h | Loss: ", DoubleToString(profitPips, 1), " pips");
                    continue;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check real-time open opportunities - IMMEDIATE SIGNALS          |
//+------------------------------------------------------------------+
void CheckRealTimeOpenOpportunities()
{
    // Only check if we can open new trades
    if(!CanOpenNewTrade())
        return;
    
    // Update indicator buffers
    if(handleRSI != INVALID_HANDLE)
        CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer);
    if(handleMACD != INVALID_HANDLE)
    {
        CopyBuffer(handleMACD, 0, 0, 3, macdMainBuffer);
        CopyBuffer(handleMACD, 1, 0, 3, macdSignalBuffer);
    }
    if(handleBB != INVALID_HANDLE)
    {
        CopyBuffer(handleBB, 1, 0, 3, bbUpperBuffer);
        CopyBuffer(handleBB, 0, 0, 3, bbMiddleBuffer);
        CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer);
    }
    
    int buyCount = CountPositions(POSITION_TYPE_BUY);
    int sellCount = CountPositions(POSITION_TYPE_SELL);
    
    // Check for strong immediate BUY signals
    if(EnableBuy && buyCount < MaxTradesPerDirection)
    {
        bool strongBuySignal = false;
        
        // Signal 1: RSI oversold + MACD bullish cross
        if(ArraySize(rsiBuffer) >= 2 && ArraySize(macdMainBuffer) >= 2 && ArraySize(macdSignalBuffer) >= 2)
        {
            double rsi = rsiBuffer[0];
            double macdMain = macdMainBuffer[0];
            double macdSignal = macdSignalBuffer[0];
            double macdMainPrev = macdMainBuffer[1];
            double macdSignalPrev = macdSignalBuffer[1];
            
            if(rsi < 30 && macdMainPrev < macdSignalPrev && macdMain > macdSignal)
            {
                strongBuySignal = true;
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] Strong BUY signal: RSI oversold + MACD bullish cross");
            }
        }
        
        // Signal 2: Price bounces off lower BB + trend aligned
        if(!strongBuySignal && ArraySize(bbLowerBuffer) >= 1)
        {
            double lower = bbLowerBuffer[0];
            double currentPrice = symbol.Bid();
            
            if(currentPrice <= lower && currentTrend == 1 && trendStrength > 50.0)
            {
                strongBuySignal = true;
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] Strong BUY signal: BB lower bounce + uptrend");
            }
        }
        
        // Signal 3: Strong trend + price pullback
        if(!strongBuySignal && currentTrend == 1 && trendStrength > 70.0)
        {
            double price1 = iClose(_Symbol, PERIOD_CURRENT, 0);
            double price2 = iClose(_Symbol, PERIOD_CURRENT, 1);
            double price3 = iClose(_Symbol, PERIOD_CURRENT, 2);
            
            // Price pulled back but still in uptrend
            if(price1 > price3 && price1 < price2)
            {
                strongBuySignal = true;
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] Strong BUY signal: Pullback in strong uptrend");
            }
        }
        
        if(strongBuySignal)
        {
            double lots = CalculateLotSize(POSITION_TYPE_BUY);
            double sl = CalculateStopLoss(POSITION_TYPE_BUY);
            double tp = CalculateTakeProfit(POSITION_TYPE_BUY);
            
            if(OpenTradeExness(POSITION_TYPE_BUY, lots, sl, tp))
            {
                lastBuyPrice = symbol.Ask();
                lastEntryTime = TimeCurrent();
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] BUY position opened | Lots: ", DoubleToString(lots, 2), 
                          " | SL: ", DoubleToString(sl, symbol.Digits()), 
                          " | TP: ", DoubleToString(tp, symbol.Digits()));
            }
        }
    }
    
    // Check for strong immediate SELL signals
    if(EnableSell && sellCount < MaxTradesPerDirection)
    {
        bool strongSellSignal = false;
        
        // Signal 1: RSI overbought + MACD bearish cross
        if(ArraySize(rsiBuffer) >= 2 && ArraySize(macdMainBuffer) >= 2 && ArraySize(macdSignalBuffer) >= 2)
        {
            double rsi = rsiBuffer[0];
            double macdMain = macdMainBuffer[0];
            double macdSignal = macdSignalBuffer[0];
            double macdMainPrev = macdMainBuffer[1];
            double macdSignalPrev = macdSignalBuffer[1];
            
            if(rsi > 70 && macdMainPrev > macdSignalPrev && macdMain < macdSignal)
            {
                strongSellSignal = true;
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] Strong SELL signal: RSI overbought + MACD bearish cross");
            }
        }
        
        // Signal 2: Price bounces off upper BB + trend aligned
        if(!strongSellSignal && ArraySize(bbUpperBuffer) >= 1)
        {
            double upper = bbUpperBuffer[0];
            double currentPrice = symbol.Ask();
            
            if(currentPrice >= upper && currentTrend == -1 && trendStrength > 50.0)
            {
                strongSellSignal = true;
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] Strong SELL signal: BB upper bounce + downtrend");
            }
        }
        
        // Signal 3: Strong trend + price pullback
        if(!strongSellSignal && currentTrend == -1 && trendStrength > 70.0)
        {
            double price1 = iClose(_Symbol, PERIOD_CURRENT, 0);
            double price2 = iClose(_Symbol, PERIOD_CURRENT, 1);
            double price3 = iClose(_Symbol, PERIOD_CURRENT, 2);
            
            // Price pulled back but still in downtrend
            if(price1 < price3 && price1 > price2)
            {
                strongSellSignal = true;
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] Strong SELL signal: Pullback in strong downtrend");
            }
        }
        
        if(strongSellSignal)
        {
            double lots = CalculateLotSize(POSITION_TYPE_SELL);
            double sl = CalculateStopLoss(POSITION_TYPE_SELL);
            double tp = CalculateTakeProfit(POSITION_TYPE_SELL);
            
            if(OpenTradeExness(POSITION_TYPE_SELL, lots, sl, tp))
            {
                lastSellPrice = symbol.Bid();
                lastEntryTime = TimeCurrent();
                if(LoggingLevel >= 2)
                    Print("[REAL-TIME OPEN] SELL position opened | Lots: ", DoubleToString(lots, 2), 
                          " | SL: ", DoubleToString(sl, symbol.Digits()), 
                          " | TP: ", DoubleToString(tp, symbol.Digits()));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check trend reversal exit                                         |
//+------------------------------------------------------------------+
void CheckTrendReversalExit(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return;
    
    // Only check if trend is strong and reversed
    if(trendStrength < 60.0)
        return;
    
    bool shouldExit = false;
    double profitPips = 0;
    double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
    double openPrice = position.PriceOpen();
    
    if(position.Type() == POSITION_TYPE_BUY)
    {
        profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
        // Exit BUY if strong downtrend and in profit
        if(currentTrend == -1 && trendStrength > 70.0 && profitPips > 10.0)
            shouldExit = true;
    }
    else // SELL
    {
        profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
        // Exit SELL if strong uptrend and in profit
        if(currentTrend == 1 && trendStrength > 70.0 && profitPips > 10.0)
            shouldExit = true;
    }
    
    if(shouldExit)
    {
        if(trade.PositionClose(ticket))
        {
            if(LoggingLevel >= 2)
                Print("[TREND REVERSAL EXIT] Closed ticket ", ticket, " | Profit: ", DoubleToString(profitPips, 1), " pips");
        }
    }
}

//+------------------------------------------------------------------+
//| Check partial close at Fibonacci levels                           |
//+------------------------------------------------------------------+
void CheckPartialClose(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return;
    
    // Implementation for partial closes at Fib levels
    // This would check if price has reached Fib levels and close percentage
    // For now, use simple profit-based partial close
    
    double currentPrice = position.Type() == POSITION_TYPE_BUY ? symbol.Bid() : symbol.Ask();
    double openPrice = position.PriceOpen();
    double profitPips = 0;
    
    if(position.Type() == POSITION_TYPE_BUY)
        profitPips = (currentPrice - openPrice) / symbol.Point() / 10.0;
    else
        profitPips = (openPrice - currentPrice) / symbol.Point() / 10.0;
    
    // Partial close at 50% profit target
    double tp = position.TakeProfit();
    if(tp > 0)
    {
        double tpDistance = MathAbs(tp - openPrice) / symbol.Point() / 10.0;
        double partialCloseLevel = tpDistance * 0.5; // 50% of TP
        
        if(profitPips >= partialCloseLevel && profitPips < tpDistance * 0.8)
        {
            double volume = position.Volume();
            double closeVolume = volume * (PartialClosePercent / 100.0);
            
            // Normalize volume
            double lotStep = symbol.LotsStep();
            closeVolume = MathFloor(closeVolume / lotStep) * lotStep;
            closeVolume = MathMax(closeVolume, symbol.LotsMin());
            
            if(closeVolume < volume * 0.1) // Only if closing at least 10%
            {
                if(trade.PositionClosePartial(ticket, closeVolume))
                {
                    if(LoggingLevel >= 2)
                        Print("[PARTIAL CLOSE] Ticket ", ticket, " | Closed ", DoubleToString(closeVolume, 2), 
                              " lots | Profit: ", DoubleToString(profitPips, 1), " pips");
                }
            }
        }
    }
}

// Note: Exness-specific versions of CheckBasketTakeProfit() and
// CheckDailyProfitTarget() are defined earlier in this file.

//+------------------------------------------------------------------+
//| Check if can open new trade - TREND-AWARE                        |
//+------------------------------------------------------------------+
bool CanOpenNewTrade()
{
    int totalPos = CountPositions(POSITION_TYPE_BUY) + CountPositions(POSITION_TYPE_SELL);
    
    if(totalPos >= MaxTrades)
    {
        static datetime lastCanOpenLog = 0;
        if(TimeCurrent() - lastCanOpenLog >= 30)
        {
            Print("❌ CanOpenNewTrade: Max trades reached (", totalPos, " >= ", MaxTrades, ")");
            lastCanOpenLog = TimeCurrent();
        }
        return false;
    }
    
    // Trend-aware balance check
    if(AutoBalanceBuySell && BalanceDirections)
    {
        int buyCount = CountPositions(POSITION_TYPE_BUY);
        int sellCount = CountPositions(POSITION_TYPE_SELL);
        int imbalance = MathAbs(buyCount - sellCount);
        
        // In neutral trend, use standard balance
        if(currentTrend == 0 || trendStrength < 30.0)
        {
            if(imbalance > MaxBuySellImbalance)
            {
                static datetime lastBalanceLog = 0;
                if(TimeCurrent() - lastBalanceLog >= 30)
                {
                    Print("❌ CanOpenNewTrade: Buy/Sell imbalance too high (", imbalance, " > ", MaxBuySellImbalance, 
                          ") | BUY=", buyCount, " | SELL=", sellCount);
                    lastBalanceLog = TimeCurrent();
                }
                return false;
            }
        }
        else
        {
            // In trending market, allow more imbalance in trend direction
            int allowedImbalance = MaxBuySellImbalance;
            
            // Increase allowed imbalance based on trend strength
            if(trendStrength > 50.0)
                allowedImbalance = (int)(MaxBuySellImbalance * 1.5); // Allow 1.5x more imbalance
            
            if(currentTrend == 1) // Uptrend
            {
                // Allow more buys than sells
                if((buyCount - sellCount) > allowedImbalance)
                    return false;
                // But still limit excessive sells
                if((sellCount - buyCount) > MaxBuySellImbalance)
                    return false;
            }
            else if(currentTrend == -1) // Downtrend
            {
                // Allow more sells than buys
                if((sellCount - buyCount) > allowedImbalance)
                    return false;
                // But still limit excessive buys
                if((buyCount - sellCount) > MaxBuySellImbalance)
                    return false;
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check rate limiting                                               |
//+------------------------------------------------------------------+
bool CheckRateLimiting()
{
    datetime currentTime = TimeCurrent();
    
    // Check minimum interval between entries
    double timeSinceLastEntry = (currentTime - lastEntryTime) * 1000.0;
    if(timeSinceLastEntry < RapidEntryIntervalMS)
    {
        static datetime lastRateLog = 0;
        if(TimeCurrent() - lastRateLog >= 5)
        {
            Print("❌ CheckRateLimiting: Too soon since last entry (", DoubleToString(timeSinceLastEntry, 0), 
                  "ms < ", RapidEntryIntervalMS, "ms)");
            lastRateLog = TimeCurrent();
        }
        return false;
    }
    
    // Check entries per second
    datetime currentSec = currentTime - (currentTime % 1);
    
    if(currentSec != currentSecond)
    {
        currentSecond = currentSec;
        entriesThisSecond = 0;
    }
    
    if(entriesThisSecond >= MaxEntriesPerSecond)
    {
        static datetime lastEntriesLog = 0;
        if(TimeCurrent() - lastEntriesLog >= 5)
        {
            Print("❌ CheckRateLimiting: Max entries per second reached (", entriesThisSecond, 
                  " >= ", MaxEntriesPerSecond, ")");
            lastEntriesLog = TimeCurrent();
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check extreme volatility                                          |
//+------------------------------------------------------------------+
bool CheckExtremeVolatility()
{
    if(ArraySize(atrBuffer) < ATRNormalLookbackBars)
        return false;
    
    double currentATR = atrBuffer[0];
    
    // Calculate average ATR
    double sumATR = 0;
    for(int i = 1; i < ATRNormalLookbackBars; i++)
    {
        sumATR += atrBuffer[i];
    }
    double avgATR = sumATR / (ATRNormalLookbackBars - 1);
    
    double atrRatio = currentATR / avgATR;
    
    if(atrRatio > PauseIfATRMulAboveNormal)
    {
        if(LoggingLevel >= 2)
            Print("Extreme volatility detected. ATR ratio: ", DoubleToString(atrRatio, 2));
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check margin level                                                |
//+------------------------------------------------------------------+
bool CheckMarginLevel()
{
    double freeMargin = account.FreeMargin();
    double margin = account.Margin();
    double totalMargin = freeMargin + margin;
    
    if(totalMargin == 0)
        return true;
    
    double freeMarginPercent = (freeMargin / totalMargin) * 100.0;
    
    if(freeMarginPercent < MinFreeMarginPercentRequired)
    {
        if(LoggingLevel >= 2)
            Print("Insufficient free margin: ", DoubleToString(freeMarginPercent, 2), "%");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze entry signals                                             |
//+------------------------------------------------------------------+
void AnalyzeEntrySignals(int &buySignal, int &sellSignal)
{
    buySignal = 0;
    sellSignal = 0;
    
    int signalStrength = 0;
    
    // Grid-based signal (base layer)
    bool shouldBuy = ShouldOpenBuy();
    bool shouldSell = ShouldOpenSell();
    
    if(shouldBuy)
        buySignal += 1;
    if(shouldSell)
        sellSignal += 1;
    
    static datetime lastSignalLog = 0;
    if(TimeCurrent() - lastSignalLog >= 30)
    {
        Print("📊 AnalyzeEntrySignals: Grid signals - BUY=", shouldBuy ? "YES" : "NO", 
              " | SELL=", shouldSell ? "YES" : "NO");
        lastSignalLog = TimeCurrent();
    }
    
    // RSI signal
    if(UseMomentumFilter && handleRSI != INVALID_HANDLE)
    {
        CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer);
        
        if(ArraySize(rsiBuffer) >= 2)
        {
            double rsi = rsiBuffer[0];
            
            if(rsi < RSIOversold)
                buySignal += 2;
            else if(rsi > RSIOverbought)
                sellSignal += 2;
        }
    }
    
    // MACD signal
    if(UseMomentumFilter && handleMACD != INVALID_HANDLE)
    {
        CopyBuffer(handleMACD, 0, 0, 3, macdMainBuffer);
        CopyBuffer(handleMACD, 1, 0, 3, macdSignalBuffer);
        
        if(ArraySize(macdMainBuffer) >= 2 && ArraySize(macdSignalBuffer) >= 2)
        {
            double macdMain = macdMainBuffer[0];
            double macdSignal = macdSignalBuffer[0];
            double macdMainPrev = macdMainBuffer[1];
            double macdSignalPrev = macdSignalBuffer[1];
            
            // Bullish crossover
            if(macdMainPrev < macdSignalPrev && macdMain > macdSignal)
                buySignal += 2;
            
            // Bearish crossover
            if(macdMainPrev > macdSignalPrev && macdMain < macdSignal)
                sellSignal += 2;
        }
    }
    
    // Bollinger Bands signal
    if(UseBBEntrySignal && handleBB != INVALID_HANDLE)
    {
        CopyBuffer(handleBB, 1, 0, 3, bbUpperBuffer);
        CopyBuffer(handleBB, 0, 0, 3, bbMiddleBuffer);
        CopyBuffer(handleBB, 2, 0, 3, bbLowerBuffer);
        
        if(ArraySize(bbUpperBuffer) >= 1 && ArraySize(bbLowerBuffer) >= 1)
        {
            double currentPrice = symbol.Bid();
            double upper = bbUpperBuffer[0];
            double middle = bbMiddleBuffer[0];
            double lower = bbLowerBuffer[0];
            
            if(BBEntryMode == 0) // Breakout
            {
                if(currentPrice > upper)
                    buySignal += 1;
                if(currentPrice < lower)
                    sellSignal += 1;
            }
            else if(BBEntryMode == 1) // Bounce
            {
                if(currentPrice <= lower)
                    buySignal += 2;
                if(currentPrice >= upper)
                    sellSignal += 2;
            }
            else if(BBEntryMode == 2) // Squeeze
            {
                double bbWidth = upper - lower;
                double avgPrice = (symbol.Ask() + symbol.Bid()) / 2.0;
                double widthPercent = (bbWidth / avgPrice) * 100.0;
                
                // Detect squeeze (narrow bands)
                if(widthPercent < 0.1) // Adjust threshold as needed
                {
                    // Wait for breakout direction
                    if(currentPrice > middle)
                        buySignal += 1;
                    else
                        sellSignal += 1;
                }
            }
        }
    }
    
    // Stochastic signal
    if(EnableStochFilter && handleStoch != INVALID_HANDLE)
    {
        CopyBuffer(handleStoch, 0, 0, 3, stochMainBuffer);
        CopyBuffer(handleStoch, 1, 0, 3, stochSignalBuffer);
        
        if(ArraySize(stochMainBuffer) >= 2 && ArraySize(stochSignalBuffer) >= 2)
        {
            double stochMain = stochMainBuffer[0];
            double stochSignal = stochSignalBuffer[0];
            double stochMainPrev = stochMainBuffer[1];
            double stochSignalPrev = stochSignalBuffer[1];
            
            // Oversold
            if(stochMain < StochOversold)
                buySignal += 1;
            
            // Overbought
            if(stochMain > StochOverbought)
                sellSignal += 1;
            
            // Crossover signals
            if(StochCrossMode)
            {
                // Bullish cross
                if(stochMainPrev < stochSignalPrev && stochMain > stochSignal && stochMain < StochOversold)
                    buySignal += 2;
                
                // Bearish cross
                if(stochMainPrev > stochSignalPrev && stochMain < stochSignal && stochMain > StochOverbought)
                    sellSignal += 2;
            }
        }
    }
    
    // Price pattern detection
    if(EnablePricePatterns)
    {
        int patternSignal = DetectPricePatterns();
        if(patternSignal > 0)
            buySignal += patternSignal;
        else if(patternSignal < 0)
            sellSignal += MathAbs(patternSignal);
    }
    
    // In hybrid mode, require minimum signal strength
    if(EntrySignalMode == 2) // Hybrid
    {
        if(buySignal < 3) buySignal = 0;
        if(sellSignal < 3) sellSignal = 0;
    }
    
    if(LoggingLevel >= 3)
        Print("Entry Signals - Buy: ", buySignal, " | Sell: ", sellSignal);
}

//+------------------------------------------------------------------+
//| Detect price patterns                                             |
//+------------------------------------------------------------------+
int DetectPricePatterns()
{
    double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
    double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
    
    double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
    double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);
    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
    
    double body1 = MathAbs(close1 - open1);
    double body2 = MathAbs(close2 - open2);
    
    double minBody = PatternMinBodyPips * symbol.Point() * 10.0;
    
    // Pin Bar
    if(DetectPinBars)
    {
        double upperWick1 = high1 - MathMax(open1, close1);
        double lowerWick1 = MathMin(open1, close1) - low1;
        
        // Bullish pin bar
        if(lowerWick1 > body1 * 2 && upperWick1 < body1 && body1 > minBody)
            return 2;
        
        // Bearish pin bar
        if(upperWick1 > body1 * 2 && lowerWick1 < body1 && body1 > minBody)
            return -2;
    }
    
    // Engulfing
    if(DetectEngulfing)
    {
        // Bullish engulfing
        if(close2 < open2 && close1 > open1 && // Bar 2 red, Bar 1 green
           open1 < close2 && close1 > open2 &&  // Bar 1 engulfs Bar 2
           body1 > minBody)
            return 2;
        
        // Bearish engulfing
        if(close2 > open2 && close1 < open1 && // Bar 2 green, Bar 1 red
           open1 > close2 && close1 < open2 &&  // Bar 1 engulfs Bar 2
           body1 > minBody)
            return -2;
    }
    
    // Inside Bar
    if(DetectInsideBars)
    {
        if(high1 < high2 && low1 > low2) // Bar 1 inside Bar 2
        {
            // Bullish bias
            if(close1 > open1 && close1 > (high2 + low2) / 2)
                return 1;
            
            // Bearish bias
            if(close1 < open1 && close1 < (high2 + low2) / 2)
                return -1;
        }
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Check if should open buy                                          |
//+------------------------------------------------------------------+
bool ShouldOpenBuy()
{
    int buyCount = CountPositions(POSITION_TYPE_BUY);
    
    if(buyCount == 0)
        return true;
    
    if(lastBuyPrice == 0)
        return true;
    
    double currentPrice = symbol.Ask();
    double distancePips = PointsToPips(lastBuyPrice - currentPrice);
    
    double effectiveStep = (PipStepMode > 0) ? currentAdaptiveStep : PipStep;
    
    static datetime lastShouldBuyLog = 0;
    if(TimeCurrent() - lastShouldBuyLog >= 30)
    {
        Print("📊 ShouldOpenBuy: distance=", DoubleToString(distancePips, 2), " pips | step=", 
              DoubleToString(effectiveStep, 2), " pips | lastPrice=", DoubleToString(lastBuyPrice, symbol.Digits()));
        lastShouldBuyLog = TimeCurrent();
    }
    
    if(distancePips >= effectiveStep)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if should open sell                                         |
//+------------------------------------------------------------------+
bool ShouldOpenSell()
{
    int sellCount = CountPositions(POSITION_TYPE_SELL);
    
    if(sellCount == 0)
        return true;
    
    if(lastSellPrice == 0)
        return true;
    
    double currentPrice = symbol.Bid();
    double distancePips = PointsToPips(currentPrice - lastSellPrice);
    
    double effectiveStep = (PipStepMode > 0) ? currentAdaptiveStep : PipStep;
    
    static datetime lastShouldSellLog = 0;
    if(TimeCurrent() - lastShouldSellLog >= 30)
    {
        Print("📊 ShouldOpenSell: distance=", DoubleToString(distancePips, 2), " pips | step=", 
              DoubleToString(effectiveStep, 2), " pips | lastPrice=", DoubleToString(lastSellPrice, symbol.Digits()));
        lastShouldSellLog = TimeCurrent();
    }
    
    if(distancePips >= effectiveStep)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Calculate lot size                                                |
//+------------------------------------------------------------------+
double CalculateLotSize(ENUM_POSITION_TYPE type)
{
    int posCount = CountPositions(type);
    
    double lots = StartingLots;
    
    if(UseProgressiveLotScaling)
    {
        // Apply martingale-style progression
        for(int i = 0; i < posCount; i++)
        {
            lots *= LayerMultiplier;
        }
    }
    
    // Apply constraints
    lots = MathMax(lots, MinLotSize);
    lots = MathMin(lots, MaxLotSize);
    lots = MathMin(lots, MaximumLotSizeCap);
    
    // Normalize to broker's lot step
    double lotStep = symbol.LotsStep();
    lots = MathFloor(lots / lotStep) * lotStep;
    
    return lots;
}

//+------------------------------------------------------------------+
//| Calculate stop loss - ENHANCED SMART LOGIC                       |
//+------------------------------------------------------------------+
double CalculateStopLoss(ENUM_POSITION_TYPE type)
{
    if(!UseDynamicStopLoss)
    {
        if(FixedSLPips == 0)
            return 0;
        
        if(type == POSITION_TYPE_BUY)
            return symbol.Ask() - FixedSLPips * GetPipValue();
        else
            return symbol.Bid() + FixedSLPips * GetPipValue();
    }
    
    double sl = 0;
    double entryPrice = (type == POSITION_TYPE_BUY) ? symbol.Ask() : symbol.Bid();
    double spreadPips = PointsToPips((symbol.Ask() - symbol.Bid()));
    
    switch(SLMode)
    {
        case 0: // Fixed
            if(type == POSITION_TYPE_BUY)
                sl = entryPrice - FixedSLPips * GetPipValue();
            else
                sl = entryPrice + FixedSLPips * GetPipValue();
            break;
            
        case 1: // ATR-based (Enhanced)
            if(ArraySize(atrBuffer) > 0)
            {
                double atr = atrBuffer[0];
                
                // Calculate ATR percentile for better volatility assessment
                double atrPercentile = CalculateATRPercentile(ATRPeriod);
                double volatilityMultiplier = 1.0;
                
                // Adjust multiplier based on volatility percentile
                if(atrPercentile > 80.0) // High volatility
                    volatilityMultiplier = 1.3;
                else if(atrPercentile < 20.0) // Low volatility
                    volatilityMultiplier = 0.8;
                
                // Adjust for market regime
                if(currentRegime == 1) // Trending
                    volatilityMultiplier *= 1.1; // Wider stops in trends
                else // Ranging
                    volatilityMultiplier *= 0.9; // Tighter stops in ranges
                
                // Adjust for trend alignment
                bool isTrendAligned = false;
                if(type == POSITION_TYPE_BUY && currentTrend == 1)
                    isTrendAligned = true;
                else if(type == POSITION_TYPE_SELL && currentTrend == -1)
                    isTrendAligned = true;
                
                // Tighter SL for trend-aligned positions (less risk)
                if(isTrendAligned && trendStrength > 50.0)
                    volatilityMultiplier *= 0.9;
                // Wider SL for counter-trend positions (more risk)
                else if(!isTrendAligned && trendStrength > 50.0)
                    volatilityMultiplier *= 1.2;
                
                double slDistance = atr * ATRSLMultiplier * volatilityMultiplier;
                
                // Ensure minimum distance (spread + buffer)
                double minDistance = (spreadPips * 1.5 + 3.0) * GetPipValue();
                slDistance = MathMax(slDistance, minDistance);
                
                if(type == POSITION_TYPE_BUY)
                    sl = entryPrice - slDistance;
                else
                    sl = entryPrice + slDistance;
            }
            break;
            
        case 2: // Support/Resistance (Enhanced with smart detection)
            {
                double swingLevel = 0;
                double bufferPips = 5.0;
                
                if(type == POSITION_TYPE_BUY)
                {
                    // Find nearest support level (swing low)
                    swingLevel = FindSmartSwingLow(20, entryPrice);
                    
                    // Adjust buffer based on volatility
                    if(ArraySize(atrBuffer) > 0)
                    {
                        double atr = atrBuffer[0];
                        double atrPips = PointsToPips(atr);
                        bufferPips = MathMax(3.0, atrPips * 0.2); // Dynamic buffer
                    }
                    
                    sl = swingLevel - bufferPips * GetPipValue();
                    
                    // Ensure SL is not too close to entry
                    double minSLDistance = (spreadPips * 2.0 + 5.0) * GetPipValue();
                    double calculatedSL = entryPrice - minSLDistance;
                    if(sl > calculatedSL)
                        sl = calculatedSL;
                }
                else
                {
                    // Find nearest resistance level (swing high)
                    swingLevel = FindSmartSwingHigh(20, entryPrice);
                    
                    // Adjust buffer based on volatility
                    if(ArraySize(atrBuffer) > 0)
                    {
                        double atr = atrBuffer[0];
                        double atrPips = PointsToPips(atr);
                        bufferPips = MathMax(3.0, atrPips * 0.2); // Dynamic buffer
                    }
                    
                    sl = swingLevel + bufferPips * GetPipValue();
                    
                    // Ensure SL is not too close to entry
                    double minSLDistance = (spreadPips * 2.0 + 5.0) * GetPipValue();
                    double calculatedSL = entryPrice + minSLDistance;
                    if(sl < calculatedSL)
                        sl = calculatedSL;
                }
            }
            break;
            
        case 3: // Trailing (handled in ManagePositions)
            if(type == POSITION_TYPE_BUY)
                sl = entryPrice - FixedSLPips * GetPipValue();
            else
                sl = entryPrice + FixedSLPips * GetPipValue();
            break;
    }
    
    // Final validation: ensure SL is reasonable
    if(sl > 0)
    {
        double slDistancePips = PointsToPips(MathAbs(entryPrice - sl));
        
        // Minimum SL distance (adjust for cent accounts)
        double minSLPips = g_isCentAccount ? (spreadPips * 1.5 + 2.0) : (spreadPips * 1.5 + 3.0);
        if(slDistancePips < minSLPips)
        {
            if(type == POSITION_TYPE_BUY)
                sl = entryPrice - minSLPips * GetPipValue();
            else
                sl = entryPrice + minSLPips * GetPipValue();
        }
        
        // Maximum SL distance (safety cap - tighter for cent accounts)
        double maxSLPips = g_isCentAccount ? 100.0 : 200.0; // Cap at 100 pips for cent, 200 for standard
        if(slDistancePips > maxSLPips)
        {
            if(type == POSITION_TYPE_BUY)
                sl = entryPrice - maxSLPips * GetPipValue();
            else
                sl = entryPrice + maxSLPips * GetPipValue();
        }
        
        // Normalize to proper digits
        sl = NormalizeDouble(sl, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    }
    
    return sl;
}

//+------------------------------------------------------------------+
//| Calculate take profit - ENHANCED SMART LOGIC                     |
//+------------------------------------------------------------------+
double CalculateTakeProfit(ENUM_POSITION_TYPE type)
{
    if(!UseDynamicTakeProfit && !EnableBasketTakeProfit)
    {
        if(FixedTPPips == 0)
            return 0;
        
        if(type == POSITION_TYPE_BUY)
            return symbol.Ask() + FixedTPPips * GetPipValue();
        else
            return symbol.Bid() - FixedTPPips * GetPipValue();
    }
    
    // For basket TP, don't set individual TPs
    if(EnableBasketTakeProfit)
        return 0;
    
    double tp = 0;
    double entryPrice = (type == POSITION_TYPE_BUY) ? symbol.Ask() : symbol.Bid();
    
    switch(TPMode)
    {
        case 0: // Fixed
            if(type == POSITION_TYPE_BUY)
                tp = entryPrice + FixedTPPips * GetPipValue();
            else
                tp = entryPrice - FixedTPPips * GetPipValue();
            break;
            
        case 1: // ATR-based (Enhanced)
            if(ArraySize(atrBuffer) > 0)
            {
                double atr = atrBuffer[0];
                
                // Calculate ATR percentile for volatility adjustment
                double atrPercentile = CalculateATRPercentile(ATRPeriod);
                double volatilityMultiplier = 1.0;
                
                // Adjust multiplier based on volatility
                if(atrPercentile > 80.0) // High volatility - wider targets
                    volatilityMultiplier = 1.4;
                else if(atrPercentile < 20.0) // Low volatility - tighter targets
                    volatilityMultiplier = 0.7;
                
                // Market regime adjustment
                if(currentRegime == 1) // Trending - allow wider targets
                    volatilityMultiplier *= 1.2;
                else // Ranging - use tighter targets
                    volatilityMultiplier *= 0.9;
                
                // Adjust for trend alignment
                bool isTrendAligned = false;
                if(type == POSITION_TYPE_BUY && currentTrend == 1)
                    isTrendAligned = true;
                else if(type == POSITION_TYPE_SELL && currentTrend == -1)
                    isTrendAligned = true;
                
                // Wider TP for trend-aligned positions (let profits run)
                if(isTrendAligned && trendStrength > 50.0)
                    volatilityMultiplier *= 1.3;
                // Tighter TP for counter-trend positions (take profits faster)
                else if(!isTrendAligned && trendStrength > 50.0)
                    volatilityMultiplier *= 0.8;
                
                double tpDistance = atr * ATRTPMultiplier * volatilityMultiplier;
                
                if(type == POSITION_TYPE_BUY)
                    tp = entryPrice + tpDistance;
                else
                    tp = entryPrice - tpDistance;
            }
            break;
            
        case 2: // Risk-Reward (Enhanced with dynamic RR)
            {
                double sl = CalculateStopLoss(type);
                if(sl == 0)
                    break;
                
                double slDistance = MathAbs(entryPrice - sl);
                double dynamicRR = RiskRewardRatio;
                
                // Adjust RR based on market conditions
                if(ArraySize(atrBuffer) > 0)
                {
                    double atr = atrBuffer[0];
                    double atrPercentile = CalculateATRPercentile(ATRPeriod);
                    
                    // In high volatility, use higher RR
                    if(atrPercentile > 70.0)
                        dynamicRR = RiskRewardRatio * 1.2;
                    // In low volatility, use lower RR but still profitable
                    else if(atrPercentile < 30.0)
                        dynamicRR = MathMax(1.5, RiskRewardRatio * 0.9);
                }
                
                // Regime-based RR adjustment
                if(currentRegime == 1) // Trending
                    dynamicRR *= 1.1; // Slightly higher RR in trends
                
                // Trend alignment adjustment
                bool isTrendAligned = false;
                if(type == POSITION_TYPE_BUY && currentTrend == 1)
                    isTrendAligned = true;
                else if(type == POSITION_TYPE_SELL && currentTrend == -1)
                    isTrendAligned = true;
                
                // Higher RR for trend-aligned positions
                if(isTrendAligned && trendStrength > 50.0)
                    dynamicRR *= 1.2;
                // Lower RR for counter-trend positions
                else if(!isTrendAligned && trendStrength > 50.0)
                    dynamicRR *= 0.9;
                
                if(type == POSITION_TYPE_BUY)
                    tp = entryPrice + slDistance * dynamicRR;
                else
                    tp = entryPrice - slDistance * dynamicRR;
            }
            break;
            
        case 3: // Fibonacci (Enhanced with multiple levels)
            {
                double swingHigh = FindSmartSwingHigh(50, entryPrice);
                double swingLow = FindSmartSwingLow(50, entryPrice);
                double swingRange = swingHigh - swingLow;
                
                // Use the most appropriate Fib level based on entry position
                double fibLevel = FibTP1; // Default
                
                // If entry is near swing low, use higher Fib levels
                if(type == POSITION_TYPE_BUY)
                {
                    double distanceToLow = entryPrice - swingLow;
                    double distanceToHigh = swingHigh - entryPrice;
                    
                    if(distanceToLow < swingRange * 0.2) // Near support
                        fibLevel = FibTP2; // Use 0.618 for better target
                    else if(distanceToHigh < swingRange * 0.2) // Near resistance
                        fibLevel = FibTP1; // Use 0.382 for conservative target
                    else
                        fibLevel = (FibTP1 + FibTP2) / 2.0; // Average
                }
                else // SELL
                {
                    double distanceToHigh = swingHigh - entryPrice;
                    double distanceToLow = entryPrice - swingLow;
                    
                    if(distanceToHigh < swingRange * 0.2) // Near resistance
                        fibLevel = FibTP2; // Use 0.618 for better target
                    else if(distanceToLow < swingRange * 0.2) // Near support
                        fibLevel = FibTP1; // Use 0.382 for conservative target
                    else
                        fibLevel = (FibTP1 + FibTP2) / 2.0; // Average
                }
                
                // Ensure minimum TP distance
                double minTPDistance = swingRange * 0.2; // At least 20% of range
                double calculatedTPDistance = swingRange * fibLevel;
                calculatedTPDistance = MathMax(calculatedTPDistance, minTPDistance);
                
                if(type == POSITION_TYPE_BUY)
                    tp = entryPrice + calculatedTPDistance;
                else
                    tp = entryPrice - calculatedTPDistance;
            }
            break;
    }
    
    // Final validation: ensure TP is reasonable
    if(tp > 0)
    {
        double tpDistancePips = MathAbs(entryPrice - tp) / symbol.Point() / 10.0;
        double sl = CalculateStopLoss(type);
        
        if(sl > 0)
        {
            double slDistancePips = MathAbs(entryPrice - sl) / symbol.Point() / 10.0;
            
            // Ensure minimum RR ratio
            double actualRR = tpDistancePips / slDistancePips;
            if(actualRR < 1.2) // Minimum 1.2:1 RR
            {
                double minTPDistance = slDistancePips * 1.2;
                if(type == POSITION_TYPE_BUY)
                    tp = entryPrice + minTPDistance * symbol.Point() * 10.0;
                else
                    tp = entryPrice - minTPDistance * symbol.Point() * 10.0;
            }
        }
        
        // Minimum TP distance
        double minTPPips = 10.0; // At least 10 pips
        if(tpDistancePips < minTPPips)
        {
            if(type == POSITION_TYPE_BUY)
                tp = entryPrice + minTPPips * symbol.Point() * 10.0;
            else
                tp = entryPrice - minTPPips * symbol.Point() * 10.0;
        }
    }
    
    return tp;
}

//+------------------------------------------------------------------+
//| Find swing low - ENHANCED                                        |
//+------------------------------------------------------------------+
double FindSwingLow(int bars)
{
    double lowest = DBL_MAX;
    
    for(int i = 1; i <= bars; i++)
    {
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        if(low < lowest)
            lowest = low;
    }
    
    return lowest;
}

//+------------------------------------------------------------------+
//| Find smart swing low (nearest support below entry)               |
//+------------------------------------------------------------------+
double FindSmartSwingLow(int bars, double entryPrice)
{
    double nearestLow = DBL_MAX;
    double bestLow = entryPrice; // Fallback
    
    // Find the nearest swing low below entry price
    for(int i = 1; i <= bars; i++)
    {
        double low = iLow(_Symbol, PERIOD_CURRENT, i);
        
        // Check if this is a pivot low (local minimum)
        if(i > 2 && i < bars - 1)
        {
            double prevLow = iLow(_Symbol, PERIOD_CURRENT, i - 1);
            double nextLow = iLow(_Symbol, PERIOD_CURRENT, i + 1);
            
            // Pivot low: lower than neighbors
            if(low < prevLow && low < nextLow)
            {
                if(low < entryPrice && low < nearestLow)
                {
                    nearestLow = low;
                    bestLow = low;
                }
            }
        }
        
        // Also track absolute lowest
        if(low < bestLow && low < entryPrice)
            bestLow = low;
    }
    
    // If no pivot found, use absolute low
    if(nearestLow == DBL_MAX)
        return bestLow;
    
    return nearestLow;
}

//+------------------------------------------------------------------+
//| Find swing high - ENHANCED                                       |
//+------------------------------------------------------------------+
double FindSwingHigh(int bars)
{
    double highest = 0;
    
    for(int i = 1; i <= bars; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        if(high > highest)
            highest = high;
    }
    
    return highest;
}

//+------------------------------------------------------------------+
//| Find smart swing high (nearest resistance above entry)            |
//+------------------------------------------------------------------+
double FindSmartSwingHigh(int bars, double entryPrice)
{
    double nearestHigh = 0;
    double bestHigh = entryPrice; // Fallback
    
    // Find the nearest swing high above entry price
    for(int i = 1; i <= bars; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        
        // Check if this is a pivot high (local maximum)
        if(i > 2 && i < bars - 1)
        {
            double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, i - 1);
            double nextHigh = iHigh(_Symbol, PERIOD_CURRENT, i + 1);
            
            // Pivot high: higher than neighbors
            if(high > prevHigh && high > nextHigh)
            {
                if(high > entryPrice && high > nearestHigh)
                {
                    nearestHigh = high;
                    bestHigh = high;
                }
            }
        }
        
        // Also track absolute highest
        if(high > bestHigh && high > entryPrice)
            bestHigh = high;
    }
    
    // If no pivot found, use absolute high
    if(nearestHigh == 0)
        return bestHigh;
    
    return nearestHigh;
}

//+------------------------------------------------------------------+
//| Calculate ATR percentile for volatility assessment              |
//+------------------------------------------------------------------+
double CalculateATRPercentile(int period)
{
    if(ArraySize(atrBuffer) < period)
        return 50.0; // Default to median if not enough data
    
    double currentATR = atrBuffer[0];
    int countBelow = 0;
    
    // Count how many ATR values are below current
    for(int i = 1; i < period && i < ArraySize(atrBuffer); i++)
    {
        if(atrBuffer[i] < currentATR)
            countBelow++;
    }
    
    // Calculate percentile
    double percentile = ((double)countBelow / (period - 1)) * 100.0;
    
    return percentile;
}

//+------------------------------------------------------------------+
//| Open trade                                                        |
//+------------------------------------------------------------------+
bool OpenTrade(ENUM_POSITION_TYPE type, double lots, double sl, double tp)
{
    string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
    int magic = (type == POSITION_TYPE_BUY) ? BuyMagicNumber : SellMagicNumber;
    
    trade.SetExpertMagicNumber(magic);
    
    bool result = false;
    
    if(type == POSITION_TYPE_BUY)
        result = trade.Buy(lots, _Symbol, 0, sl, tp, "SuperSmartGold");
    else
        result = trade.Sell(lots, _Symbol, 0, sl, tp, "SuperSmartGold");
    
    if(result)
    {
        entriesThisSecond++;
        totalTrades++;
        
        if(LoggingLevel >= 2)
        {
            Print("Opened ", typeStr, " position: Ticket=", trade.ResultOrder(), 
                  " | Lots=", DoubleToString(lots, 2),
                  " | SL=", DoubleToString(sl, symbol.Digits()),
                  " | TP=", DoubleToString(tp, symbol.Digits()));
        }
    }
    else
    {
        if(LoggingLevel >= 1)
            Print("Failed to open ", typeStr, " position. Error: ", GetLastError());
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Count positions                                                   |
//+------------------------------------------------------------------+
int CountPositions(ENUM_POSITION_TYPE type)
{
    int count = 0;
    int magic = (type == POSITION_TYPE_BUY) ? BuyMagicNumber : SellMagicNumber;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() == _Symbol && position.Magic() == magic)
                count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Close all positions                                               |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(position.SelectByIndex(i))
        {
            if(position.Symbol() != _Symbol)
                continue;
            
            int magic = (int)position.Magic();
            if(magic != BuyMagicNumber && magic != SellMagicNumber)
                continue;
            
            trade.PositionClose(position.Ticket());
            
            if(LoggingLevel >= 2)
                Print("Closed position: ", position.Ticket());
        }
    }
}
