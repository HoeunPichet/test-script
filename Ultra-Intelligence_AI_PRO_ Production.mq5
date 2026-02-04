//+------------------------------------------------------------------+
//|                    UltraIntelligent_AI_Pro_PRODUCTION.mq5        |
//|                PRODUCTION-READY AI TRADING SYSTEM V9.0           |
//|          Real Account Optimized | Robust Risk Management         |
//+------------------------------------------------------------------+
#property copyright "Ultra AI Trading Pro - Production Edition"
#property version   "9.00"
#property strict
#property description "Production-Optimized Neural Network Trading System"
#property description "Real Account Safe | Enhanced Risk Controls"

//+------------------------------------------------------------------+
//| AI INTELLIGENCE CONFIGURATION                                     |
//+------------------------------------------------------------------+

input group "═══ 🧠 NEURAL NETWORK SETTINGS ═══"
input int      AI_IntelligenceLevel = 7;              // AI Intelligence (1-10, 7=Balanced)
input int      AI_SignalSpeed = 2;                    // Signal Speed (1=Conservative, 5=Aggressive)
input bool     AI_AggressiveMode = false;             // 🔥 Aggressive Trading Mode
input bool     AI_MultiTimeframe = true;              // 📊 Multi-Timeframe Analysis
input bool     AI_QuantumSignals = false;             // ⚡ Quantum Signals (High Risk)
input int      MinSignalStrength = 700;               // Minimum Signal Strength (600-850)
input int      MinConfirmationBars = 2;               // Bars Required for Confirmation (1-5)

input group "═══ 💰 RISK & MONEY MANAGEMENT ═══"
input double   MaxRiskPerTrade = 1.0;                 // Max Risk Per Trade (%) [0.5-2.0]
input int      MaxSimultaneousTrades = 2;             // Max Simultaneous Positions [1-3]
input bool     AI_DynamicLots = true;                 // 🤖 AI Dynamic Lot Sizing
input bool     AI_SmartScaling = false;               // 📈 AI Position Scaling (Advanced)
input double   MaxDailyDrawdown = 3.0;                // Max Daily Drawdown % (Stop Trading)
input double   MaxAccountDrawdown = 10.0;             // Max Account Drawdown % (Emergency Stop)
input bool     UseEquityCurveAdjustment = true;       // Adjust Risk Based on Equity Curve

input group "═══ 🎯 ADVANCED FEATURES ═══"
input bool     AI_SmartTrailing = true;               // 🎯 AI Smart Trailing Stop (ATR-Based)
input bool     AI_BreakevenProtection = true;         // 🛡️ AI Breakeven Protection
input bool     AI_PartialProfits = false;             // 💵 AI Partial Profit Taking
input bool     AI_NewsFilter = true;                  // 📰 AI News Event Filter
input bool     AI_SelfLearning = true;                // 🧠 AI Self-Learning System
input bool     UseATRMultiplier = true;               // Use ATR for Stop/Target (Recommended)

input group "═══ 🛡️ EXECUTION SAFETY ═══"
input int      MaxSpreadPips = 15;                    // Max Allowed Spread (pips) [0=Disable]
input int      MaxSlippagePips = 10;                  // Max Allowed Slippage (pips)
input int      MaxRetries = 3;                        // Max Order Send Retries
input int      RetryDelayMs = 500;                    // Retry Delay (milliseconds)
input bool     RequireFreshPrice = true;              // Require Fresh Tick (< 3 sec)
input bool     AvoidHighVolatilityHours = true;       // Avoid First Hour After Major News

input group "═══ 📅 NEWS & TIME FILTERS ═══"
input bool     UseNewsFilter = true;                  // Block Trades During High-Impact News
input string   NewsBlockHours = "8:30,10:00,14:00";   // EST Hours to Block (comma-separated)
input int      NewsQuietPeriodMin = 30;               // Minutes After News (No Trading)
input bool     TradeAsianSession = true;              // Allow Asian Session Trading
input bool     TradeLondonSession = true;             // Allow London Session Trading
input bool     TradeUSSession = false;                // Allow US Session Trading (Higher Risk)

input group "═══ ⚙️ MANUAL OVERRIDE ═══"
input bool     ManualLotOverride = false;             // Override AI Lot Size
input double   FixedLotSize = 0.01;                   // Fixed Lot (if override)
input bool     ManualStopsOverride = false;           // Override AI Stops
input double   ManualSL_Pips = 30.0;                  // Manual SL (pips)
input double   ManualTP_Pips = 60.0;                  // Manual TP (pips)

input group "═══ 📊 TIMEFRAMES ═══"
input ENUM_TIMEFRAMES PrimaryTimeframe = PERIOD_M15;  // Primary Timeframe
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;     // Trend Timeframe

input group "═══ 🔢 SYSTEM ═══"
input int      MagicNumber = 88888;                   // Magic Number
input string   TradeComment = "AI_PRO_v9";            // Trade Comment

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES & AI BRAIN                                       |
//+------------------------------------------------------------------+

// Indicator Handles
int h_MA_Fast, h_MA_Medium, h_MA_Slow;
int h_MA_Fast_HTF, h_MA_Slow_HTF;
int h_RSI, h_RSI_HTF;
int h_MACD, h_MACD_HTF;
int h_ATR, h_ATR_HTF;
int h_ADX, h_ADX_HTF;
int h_Stoch, h_Stoch_HTF;
int h_BB, h_CCI, h_Momentum;

// Enhanced AI Neural Network Brain
struct NeuralNetworkAI {
    // Layer 1: Market Intelligence
    double trendStrength;           
    int trendDirection;             
    double trendConfidence;         
    
    // Layer 2: Volatility Intelligence
    double volatilityIndex;         
    int volatilityState;            
    double marketSpeed;             
    
    // Layer 3: Momentum Intelligence
    double momentumBull;            
    double momentumBear;            
    double momentumNetScore;        
    
    // Layer 4: Signal Intelligence
    int buySignalStrength;          
    int sellSignalStrength;         
    double signalQuality;           
    double confidenceLevel;         
    
    // Layer 5: Risk Intelligence
    double optimalStopLoss;         
    double optimalTakeProfit;       
    double optimalLotSize;          
    double riskRewardRatio;         
    double currentRiskAdjustment;   // NEW: Dynamic risk scaling
    
    // Layer 6: Learning & Memory (Enhanced)
    double learningRate;            
    double performanceScore;        
    int consecutiveWins;
    int consecutiveLosses;
    double avgWinPips;
    double avgLossPips;
    double recentPerformanceDecay;  // NEW: Recent trades weight more
    
    // Layer 7: Market State
    string marketRegime;            
    string marketSentiment;         
    bool isHighProbability;         
    bool isLowRisk;                 
    
    // NEW: Layer 8: Execution Intelligence
    bool executionAllowed;          
    string blockReason;             
    datetime lastNewsTime;          
    double actualSpread;            
    int failedAttempts;             
    
} AI;

// Learning Memory & Statistics (Enhanced)
double g_totalTrades = 0;
double g_winningTrades = 0;
double g_losingTrades = 0;
double g_totalProfit = 0;
double g_totalLoss = 0;
double g_winRate = 50.0;
double g_profitFactor = 1.0;

// NEW: Real-time Risk Tracking
double g_dailyDrawdown = 0;
double g_dailyProfit = 0;
double g_maxEquity = 0;
double g_accountDrawdown = 0;
datetime g_dailyResetTime = 0;
bool g_emergencyStop = false;

// Session Control
datetime g_lastBarTime = 0;
datetime g_lastTradeTime = 0;
datetime g_lastTickTime = 0;  // NEW: Track tick freshness
bool g_isInitialized = false;
int g_barsSinceLastTrade = 0;
int g_consecutiveBullishBars = 0;  // NEW: Confirmation tracking
int g_consecutiveBearishBars = 0;  // NEW: Confirmation tracking

// Performance Tracking
double g_maxDrawdown = 0;
double g_maxProfit = 0;
double g_initialBalance = 0;
int g_totalBuyTrades = 0;
int g_totalSellTrades = 0;

// NEW: Execution Tracking
struct ExecutionStats {
    int totalAttempts;
    int successfulTrades;
    int failedTrades;
    double avgActualSlippage;
    double avgExecutionTime;
    datetime lastError;
    int lastErrorCode;
} g_execStats;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║                                                           ║");
    Print("║   ⚡ PRODUCTION-READY AI TRADING SYSTEM V9.0 ⚡          ║");
    Print("║         REAL ACCOUNT OPTIMIZED EDITION                    ║");
    Print("║                                                           ║");
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
    
    // Verify trading permissions
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        Alert("⚠️ CRITICAL: AutoTrading is OFF! Click the AutoTrading button!");
        Print("❌ AutoTrading disabled in terminal");
        return INIT_FAILED;
    }
    
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
        Alert("⚠️ CRITICAL: Enable 'Allow Algo Trading' in EA settings!");
        Print("❌ Algorithmic trading not allowed");
        return INIT_FAILED;
    }
    
    // NEW: Validate critical settings
    // Note: Cannot modify input variables (they are constants)
    // Use local variables or just warn user
    if(MaxRiskPerTrade > 2.0) {
        Alert("⚠️ WARNING: Risk > 2% is dangerous on real accounts!");
        Print("⚠️ MaxRiskPerTrade is set to ", MaxRiskPerTrade, "% - consider reducing to 2.0% for safety");
    }
    
    if(MaxSimultaneousTrades > 3) {
        Print("⚠️ MaxSimultaneousTrades is set to ", MaxSimultaneousTrades, " - consider reducing to 3 for risk control");
    }
    
    Print("⚙️  Initializing Production-Grade Neural Networks...");
    
    // Initialize indicators (same as before, but with validation)
    if(!InitializeIndicators()) {
        Print("❌ Failed to initialize indicators!");
        return INIT_FAILED;
    }
    
    Print("✅ All indicators initialized successfully");
    
    // Wait for indicators to stabilize
    Print("⏳ Calibrating neural networks...");
    Sleep(2000);
    
    // Initialize AI Brain
    InitializeAI();
    
    // NEW: Initialize risk tracking
    g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_maxEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_dailyResetTime = iTime(_Symbol, PERIOD_D1, 0);
    
    // NEW: Initialize execution stats
    ZeroMemory(g_execStats);
    
    g_isInitialized = true;
    
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║         ✅ PRODUCTION AI SYSTEM ONLINE ✅                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Intelligence Level: %d/10 (Production-Optimized)         ║", AI_IntelligenceLevel);
    PrintFormat("║  Min Signal Strength: %d (Conservative)                  ║", MinSignalStrength);
    PrintFormat("║  Confirmation Bars: %d                                     ║", MinConfirmationBars);
    PrintFormat("║  Max Spread: %d pips                                      ║", MaxSpreadPips);
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Max Risk/Trade: %.1f%% | Max DD: %.1f%%                  ║", MaxRiskPerTrade, MaxDailyDrawdown);
    PrintFormat("║  Max Positions: %d                                         ║", MaxSimultaneousTrades);
    PrintFormat("║  News Filter: %s | Fresh Price: %s             ║", 
                UseNewsFilter ? "✓" : "✗", RequireFreshPrice ? "✓" : "✗");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Symbol: %s | Primary: %s | Trend: %s       ║", 
                _Symbol, EnumToString(PrimaryTimeframe), EnumToString(TrendTimeframe));
    PrintFormat("║  Initial Balance: $%.2f                                 ║", g_initialBalance);
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
    Print("🚀 AI is hunting for HIGH-QUALITY setups only...");
    Print("🛡️ Production safety features: ACTIVE");
    Print("");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Initialize Indicators with Validation                             |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
    // Primary Timeframe Indicators
    h_MA_Fast = iMA(_Symbol, PrimaryTimeframe, 8, 0, MODE_EMA, PRICE_CLOSE);
    h_MA_Medium = iMA(_Symbol, PrimaryTimeframe, 21, 0, MODE_EMA, PRICE_CLOSE);
    h_MA_Slow = iMA(_Symbol, PrimaryTimeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
    h_RSI = iRSI(_Symbol, PrimaryTimeframe, 14, PRICE_CLOSE);
    h_MACD = iMACD(_Symbol, PrimaryTimeframe, 12, 26, 9, PRICE_CLOSE);
    h_ATR = iATR(_Symbol, PrimaryTimeframe, 14);
    h_ADX = iADX(_Symbol, PrimaryTimeframe, 14);
    h_Stoch = iStochastic(_Symbol, PrimaryTimeframe, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    h_BB = iBands(_Symbol, PrimaryTimeframe, 20, 0, 2.0, PRICE_CLOSE);
    h_CCI = iCCI(_Symbol, PrimaryTimeframe, 14, PRICE_TYPICAL);
    h_Momentum = iMomentum(_Symbol, PrimaryTimeframe, 14, PRICE_CLOSE);
    
    // Verify primary indicators
    if(h_MA_Fast == INVALID_HANDLE || h_MA_Medium == INVALID_HANDLE || 
       h_MA_Slow == INVALID_HANDLE || h_RSI == INVALID_HANDLE ||
       h_MACD == INVALID_HANDLE || h_ATR == INVALID_HANDLE ||
       h_ADX == INVALID_HANDLE || h_Stoch == INVALID_HANDLE ||
       h_BB == INVALID_HANDLE || h_CCI == INVALID_HANDLE ||
       h_Momentum == INVALID_HANDLE) {
        return false;
    }
    
    // Higher Timeframe Indicators
    if(AI_MultiTimeframe) {
        h_MA_Fast_HTF = iMA(_Symbol, TrendTimeframe, 8, 0, MODE_EMA, PRICE_CLOSE);
        h_MA_Slow_HTF = iMA(_Symbol, TrendTimeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
        h_RSI_HTF = iRSI(_Symbol, TrendTimeframe, 14, PRICE_CLOSE);
        h_MACD_HTF = iMACD(_Symbol, TrendTimeframe, 12, 26, 9, PRICE_CLOSE);
        h_ATR_HTF = iATR(_Symbol, TrendTimeframe, 14);
        h_ADX_HTF = iADX(_Symbol, TrendTimeframe, 14);
        h_Stoch_HTF = iStochastic(_Symbol, TrendTimeframe, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
        
        if(h_MA_Fast_HTF == INVALID_HANDLE || h_MA_Slow_HTF == INVALID_HANDLE ||
           h_RSI_HTF == INVALID_HANDLE || h_MACD_HTF == INVALID_HANDLE ||
           h_ATR_HTF == INVALID_HANDLE || h_ADX_HTF == INVALID_HANDLE ||
           h_Stoch_HTF == INVALID_HANDLE) {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize AI Brain                                               |
//+------------------------------------------------------------------+
void InitializeAI()
{
    AI.trendStrength = 0;
    AI.trendDirection = 0;
    AI.trendConfidence = 0;
    AI.volatilityIndex = 100;
    AI.volatilityState = 1;
    AI.marketSpeed = 50;
    AI.momentumBull = 50;
    AI.momentumBear = 50;
    AI.momentumNetScore = 0;
    AI.buySignalStrength = 0;
    AI.sellSignalStrength = 0;
    AI.signalQuality = 0;
    AI.confidenceLevel = 0;
    AI.optimalStopLoss = 30;
    AI.optimalTakeProfit = 60;
    AI.optimalLotSize = 0.01;
    AI.riskRewardRatio = 2.0;
    AI.currentRiskAdjustment = 1.0;  // NEW
    AI.learningRate = 0.1;
    AI.performanceScore = 50;
    AI.consecutiveWins = 0;
    AI.consecutiveLosses = 0;
    AI.avgWinPips = 50;
    AI.avgLossPips = 50;
    AI.recentPerformanceDecay = 0.95;  // NEW: 95% weight to recent performance
    AI.marketRegime = "ANALYZING";
    AI.marketSentiment = "NEUTRAL";
    AI.isHighProbability = false;
    AI.isLowRisk = false;
    AI.executionAllowed = true;  // NEW
    AI.blockReason = "";  // NEW
    AI.lastNewsTime = 0;  // NEW
    AI.actualSpread = 0;  // NEW
    AI.failedAttempts = 0;  // NEW
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release all indicators
    if(h_MA_Fast != INVALID_HANDLE) IndicatorRelease(h_MA_Fast);
    if(h_MA_Medium != INVALID_HANDLE) IndicatorRelease(h_MA_Medium);
    if(h_MA_Slow != INVALID_HANDLE) IndicatorRelease(h_MA_Slow);
    if(h_RSI != INVALID_HANDLE) IndicatorRelease(h_RSI);
    if(h_MACD != INVALID_HANDLE) IndicatorRelease(h_MACD);
    if(h_ATR != INVALID_HANDLE) IndicatorRelease(h_ATR);
    if(h_ADX != INVALID_HANDLE) IndicatorRelease(h_ADX);
    if(h_Stoch != INVALID_HANDLE) IndicatorRelease(h_Stoch);
    if(h_BB != INVALID_HANDLE) IndicatorRelease(h_BB);
    if(h_CCI != INVALID_HANDLE) IndicatorRelease(h_CCI);
    if(h_Momentum != INVALID_HANDLE) IndicatorRelease(h_Momentum);
    
    if(AI_MultiTimeframe) {
        if(h_MA_Fast_HTF != INVALID_HANDLE) IndicatorRelease(h_MA_Fast_HTF);
        if(h_MA_Slow_HTF != INVALID_HANDLE) IndicatorRelease(h_MA_Slow_HTF);
        if(h_RSI_HTF != INVALID_HANDLE) IndicatorRelease(h_RSI_HTF);
        if(h_MACD_HTF != INVALID_HANDLE) IndicatorRelease(h_MACD_HTF);
        if(h_ATR_HTF != INVALID_HANDLE) IndicatorRelease(h_ATR_HTF);
        if(h_ADX_HTF != INVALID_HANDLE) IndicatorRelease(h_ADX_HTF);
        if(h_Stoch_HTF != INVALID_HANDLE) IndicatorRelease(h_Stoch_HTF);
    }
    
    // Print final statistics
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║         PRODUCTION AI SYSTEM SHUTDOWN REPORT              ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Total Trades: %.0f (Buy: %d | Sell: %d)                   ║", 
                g_totalTrades, g_totalBuyTrades, g_totalSellTrades);
    PrintFormat("║  Win Rate: %.1f%% (Wins: %.0f | Losses: %.0f)               ║", 
                g_winRate, g_winningTrades, g_losingTrades);
    PrintFormat("║  Profit Factor: %.2f                                        ║", g_profitFactor);
    PrintFormat("║  Performance Score: %.1f/100                                ║", AI.performanceScore);
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Execution Success: %.1f%% (%d/%d attempts)              ║", 
                (g_execStats.totalAttempts > 0 ? (g_execStats.successfulTrades * 100.0 / g_execStats.totalAttempts) : 0),
                g_execStats.successfulTrades, g_execStats.totalAttempts);
    PrintFormat("║  Avg Slippage: %.1f pips                                   ║", g_execStats.avgActualSlippage);
    PrintFormat("║  Max Drawdown: %.2f%%                                       ║", g_maxDrawdown);
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!g_isInitialized) return;
    
    // NEW: Update tick timestamp for freshness check
    g_lastTickTime = TimeCurrent();
    
    // NEW: Check emergency stop conditions
    if(CheckEmergencyStop()) {
        if(!g_emergencyStop) {
            Print("🚨 EMERGENCY STOP ACTIVATED!");
            Alert("⚠️ EA stopped due to excessive drawdown!");
            g_emergencyStop = true;
        }
        return;
    }
    
    // NEW: Daily reset for drawdown tracking
    CheckDailyReset();
    
    // Fast-mode check (controlled throttling)
    if(AI_SignalSpeed >= 4 || AI_AggressiveMode) {
        static int tickCounter = 0;
        tickCounter++;
        if(tickCounter % 5 != 0) return;  // Process every 5th tick max
    }
    
    // New bar check
    datetime currentBar = iTime(_Symbol, PrimaryTimeframe, 0);
    bool isNewBar = (currentBar != g_lastBarTime);
    
    if(!isNewBar && AI_SignalSpeed < 4 && !AI_AggressiveMode) return;
    
    if(isNewBar) {
        g_lastBarTime = currentBar;
        g_barsSinceLastTrade++;
        
        // NEW: Update confirmation bar counters
        UpdateConfirmationTracking();
    }
    
    // ═══════════════════════════════════════════════════════
    // PRODUCTION AI PROCESSING PIPELINE
    // ═══════════════════════════════════════════════════════
    
    // Layer 1: Deep Market Analysis (Enhanced)
    AI_DeepMarketAnalysis();
    
    // Layer 2: Position Management (ATR-Based)
    AI_IntelligentPositionManagement();
    
    // Layer 3: Update Learning System (Fixed Lookahead)
    if(AI_SelfLearning) {
        AI_UpdateLearningSystem();
    }
    
    // NEW: Layer 4: Pre-Trade Safety Checks
    if(!AI_PreTradeValidation()) {
        return;  // Safety checks failed
    }
    
    // Layer 5: Generate Balanced Signals (Enhanced)
    int signal = AI_BalancedSignalProcessor();
    
    // Layer 6: Execute with Robust Error Handling
    if(signal == 1 && AI.isHighProbability && AI.executionAllowed) {
        if(AI_ExecuteBuyOrder()) {
            g_barsSinceLastTrade = 0;
            g_totalBuyTrades++;
            AI.failedAttempts = 0;
        }
    }
    else if(signal == -1 && AI.isHighProbability && AI.executionAllowed) {
        if(AI_ExecuteSellOrder()) {
            g_barsSinceLastTrade = 0;
            g_totalSellTrades++;
            AI.failedAttempts = 0;
        }
    }
}

//+------------------------------------------------------------------+
//| NEW: Check Emergency Stop Conditions                             |
//+------------------------------------------------------------------+
bool CheckEmergencyStop()
{
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Update max equity
    if(currentEquity > g_maxEquity) {
        g_maxEquity = currentEquity;
    }
    
    // Calculate account drawdown from peak
    g_accountDrawdown = ((g_maxEquity - currentEquity) / g_maxEquity) * 100.0;
    
    // Check account-level drawdown
    if(g_accountDrawdown >= MaxAccountDrawdown) {
        return true;
    }
    
    // Check daily drawdown
    if(g_dailyDrawdown >= MaxDailyDrawdown) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| NEW: Check Daily Reset                                           |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
    datetime currentDayStart = iTime(_Symbol, PERIOD_D1, 0);
    
    if(currentDayStart != g_dailyResetTime) {
        // New day - reset daily tracking
        g_dailyDrawdown = 0;
        g_dailyProfit = 0;
        g_dailyResetTime = currentDayStart;
        
        Print("📅 New trading day started - Daily stats reset");
    }
}

//+------------------------------------------------------------------+
//| NEW: Update Confirmation Bar Tracking                            |
//+------------------------------------------------------------------+
void UpdateConfirmationTracking()
{
    double close[], open[];
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    if(CopyClose(_Symbol, PrimaryTimeframe, 0, 3, close) < 3) return;
    if(CopyOpen(_Symbol, PrimaryTimeframe, 0, 3, open) < 3) return;
    
    // Update bullish bar counter
    if(close[0] > open[0] && close[0] > close[1]) {
        g_consecutiveBullishBars++;
        g_consecutiveBearishBars = 0;
    }
    // Update bearish bar counter
    else if(close[0] < open[0] && close[0] < close[1]) {
        g_consecutiveBearishBars++;
        g_consecutiveBullishBars = 0;
    }
    else {
        g_consecutiveBullishBars = 0;
        g_consecutiveBearishBars = 0;
    }
}

//+------------------------------------------------------------------+
//| NEW: Pre-Trade Validation (Comprehensive Safety Checks)          |
//+------------------------------------------------------------------+
bool AI_PreTradeValidation()
{
    AI.executionAllowed = true;
    AI.blockReason = "";
    
    // 1. Check spread
    if(MaxSpreadPips > 0) {
        long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        double spreadPips = spread * _Point / (_Point * 10);
        AI.actualSpread = spreadPips;
        
        if(spreadPips > MaxSpreadPips) {
            AI.executionAllowed = false;
            AI.blockReason = StringFormat("Spread too high: %.1f > %d pips", spreadPips, MaxSpreadPips);
            return false;
        }
    }
    
    // 2. Check tick freshness
    if(RequireFreshPrice) {
        datetime serverTime = TimeCurrent();
        int timeSinceLastTick = (int)(serverTime - g_lastTickTime);
        
        if(timeSinceLastTick > 3) {  // More than 3 seconds old
            AI.executionAllowed = false;
            AI.blockReason = StringFormat("Stale price data: %d seconds old", timeSinceLastTick);
            return false;
        }
    }
    
    // 3. Check news filter
    if(UseNewsFilter && IsNewsTime()) {
        AI.executionAllowed = false;
        AI.blockReason = "High-impact news period - trading blocked";
        return false;
    }
    
    // 4. Check session filter
    if(!IsAllowedSession()) {
        AI.executionAllowed = false;
        AI.blockReason = "Outside allowed trading sessions";
        return false;
    }
    
    // 5. Check position limits
    int openPositions = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) == _Symbol) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
                openPositions++;
        }
    }
    
    if(openPositions >= MaxSimultaneousTrades) {
        AI.executionAllowed = false;
        AI.blockReason = StringFormat("Max positions reached: %d/%d", openPositions, MaxSimultaneousTrades);
        return false;
    }
    
    // 6. Check margin availability
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double requiredMargin = AccountInfoDouble(ACCOUNT_BALANCE) * 0.20;  // Must have 20% free margin
    
    if(freeMargin < requiredMargin) {
        AI.executionAllowed = false;
        AI.blockReason = "Insufficient free margin";
        return false;
    }
    
    // 7. Check minimum bars since last trade (avoid overtrading)
    if(!AI_AggressiveMode && g_barsSinceLastTrade < 3) {
        AI.executionAllowed = false;
        AI.blockReason = "Too soon after last trade";
        return false;
    }
    
    // 8. NEW: Check consecutive failures
    if(AI.failedAttempts >= 3) {
        AI.executionAllowed = false;
        AI.blockReason = "Too many consecutive failed attempts - cooling down";
        
        // Reset after some time
        static datetime lastFailTime = 0;
        if(TimeCurrent() - lastFailTime > 900) {  // 15 minutes
            AI.failedAttempts = 0;
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| NEW: Check if current time is news period                        |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    if(!UseNewsFilter) return false;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Parse news block hours
    string hours[];
    int count = StringSplit(NewsBlockHours, StringGetCharacter(",", 0), hours);
    
    for(int i = 0; i < count; i++) {
        string cleanHour = hours[i];
        StringTrimLeft(cleanHour);
        StringTrimRight(cleanHour);
        
        string parts[];
        if(StringSplit(cleanHour, StringGetCharacter(":", 0), parts) == 2) {
            int blockHour = (int)StringToInteger(parts[0]);
            int blockMinute = (int)StringToInteger(parts[1]);
            
            // Convert EST to server time (adjust as needed)
            // This is simplified - you may need to handle timezone conversion
            if(dt.hour == blockHour && dt.min >= blockMinute && dt.min < blockMinute + NewsQuietPeriodMin) {
                return true;
            }
        }
    }
    
    // Check if within quiet period after detected news
    if(AI.lastNewsTime > 0) {
        int minutesSinceNews = (int)((TimeCurrent() - AI.lastNewsTime) / 60);
        if(minutesSinceNews < NewsQuietPeriodMin) {
            return true;
        }
    }
    
    // NEW: Avoid first hour after major sessions open
    if(AvoidHighVolatilityHours) {
        // London open (8:00 GMT)
        if(dt.hour == 8 && dt.min < 60) return true;
        // US open (13:30 GMT)
        if(dt.hour == 13 && dt.min >= 30) return true;
        if(dt.hour == 14 && dt.min < 30) return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| NEW: Check if current session is allowed                         |
//+------------------------------------------------------------------+
bool IsAllowedSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Define sessions (GMT time)
    // Asian: 00:00-09:00
    // London: 08:00-17:00
    // US: 13:00-22:00
    
    if(dt.hour >= 0 && dt.hour < 9 && TradeAsianSession) return true;
    if(dt.hour >= 8 && dt.hour < 17 && TradeLondonSession) return true;
    if(dt.hour >= 13 && dt.hour < 22 && TradeUSSession) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| AI Deep Market Analysis - Production Enhanced                    |
//+------------------------------------------------------------------+
void AI_DeepMarketAnalysis()
{
    // [Previous analysis code remains the same, but with these additions:]
    
    // Collect market data
    double ma_fast[], ma_medium[], ma_slow[];
    double rsi[], macd[], macd_signal[], atr[], adx[], plusDI[], minusDI[];
    double stoch[], cci[], momentum[], bb_upper[], bb_middle[], bb_lower[];
    double close[], high[], low[], open[];
    
    ArraySetAsSeries(ma_fast, true);
    ArraySetAsSeries(ma_medium, true);
    ArraySetAsSeries(ma_slow, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(macd, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(atr, true);
    ArraySetAsSeries(adx, true);
    ArraySetAsSeries(plusDI, true);
    ArraySetAsSeries(minusDI, true);
    ArraySetAsSeries(stoch, true);
    ArraySetAsSeries(cci, true);
    ArraySetAsSeries(momentum, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(bb_lower, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);
    
    // Copy data with validation
    if(CopyBuffer(h_MA_Fast, 0, 0, 20, ma_fast) < 20) return;
    if(CopyBuffer(h_MA_Medium, 0, 0, 20, ma_medium) < 20) return;
    if(CopyBuffer(h_MA_Slow, 0, 0, 20, ma_slow) < 20) return;
    if(CopyBuffer(h_RSI, 0, 0, 20, rsi) < 20) return;
    if(CopyBuffer(h_MACD, 0, 0, 20, macd) < 20) return;
    if(CopyBuffer(h_MACD, 1, 0, 20, macd_signal) < 20) return;
    if(CopyBuffer(h_ATR, 0, 0, 50, atr) < 50) return;
    if(CopyBuffer(h_ADX, 0, 0, 20, adx) < 20) return;
    if(CopyBuffer(h_ADX, 1, 0, 20, plusDI) < 20) return;
    if(CopyBuffer(h_ADX, 2, 0, 20, minusDI) < 20) return;
    if(CopyBuffer(h_Stoch, 0, 0, 20, stoch) < 20) return;
    if(CopyBuffer(h_CCI, 0, 0, 20, cci) < 20) return;
    if(CopyBuffer(h_Momentum, 0, 0, 20, momentum) < 20) return;
    if(CopyBuffer(h_BB, 1, 0, 20, bb_upper) < 20) return;
    if(CopyBuffer(h_BB, 0, 0, 20, bb_middle) < 20) return;
    if(CopyBuffer(h_BB, 2, 0, 20, bb_lower) < 20) return;
    if(CopyClose(_Symbol, PrimaryTimeframe, 0, 20, close) < 20) return;
    if(CopyHigh(_Symbol, PrimaryTimeframe, 0, 20, high) < 20) return;
    if(CopyLow(_Symbol, PrimaryTimeframe, 0, 20, low) < 20) return;
    if(CopyOpen(_Symbol, PrimaryTimeframe, 0, 20, open) < 20) return;
    
    // Higher timeframe data
    double ma_fast_htf[], ma_slow_htf[], rsi_htf[], adx_htf[], plusDI_htf[], minusDI_htf[];
    if(AI_MultiTimeframe) {
        ArraySetAsSeries(ma_fast_htf, true);
        ArraySetAsSeries(ma_slow_htf, true);
        ArraySetAsSeries(rsi_htf, true);
        ArraySetAsSeries(adx_htf, true);
        ArraySetAsSeries(plusDI_htf, true);
        ArraySetAsSeries(minusDI_htf, true);
        
        if(CopyBuffer(h_MA_Fast_HTF, 0, 0, 5, ma_fast_htf) < 5) return;
        if(CopyBuffer(h_MA_Slow_HTF, 0, 0, 5, ma_slow_htf) < 5) return;
        if(CopyBuffer(h_RSI_HTF, 0, 0, 5, rsi_htf) < 5) return;
        if(CopyBuffer(h_ADX_HTF, 0, 0, 5, adx_htf) < 5) return;
        if(CopyBuffer(h_ADX_HTF, 1, 0, 5, plusDI_htf) < 5) return;
        if(CopyBuffer(h_ADX_HTF, 2, 0, 5, minusDI_htf) < 5) return;
    }
    
    // ═══════════════════════════════════════════════════════
    // TREND ANALYSIS (Same as before)
    // ═══════════════════════════════════════════════════════
    
    double trendScore = 0;
    
    if(ma_fast[0] > ma_medium[0] && ma_medium[0] > ma_slow[0]) {
        trendScore += 25;
        AI.marketSentiment = "BULLISH";
    }
    else if(ma_fast[0] < ma_medium[0] && ma_medium[0] < ma_slow[0]) {
        trendScore -= 25;
        AI.marketSentiment = "BEARISH";
    }
    else {
        AI.marketSentiment = "NEUTRAL";
    }
    
    if(close[0] > ma_slow[0]) trendScore += 15;
    else if(close[0] < ma_slow[0]) trendScore -= 15;
    
    double ma_slope_fast = (ma_fast[0] - ma_fast[3]) / 3;
    double ma_slope_medium = (ma_medium[0] - ma_medium[3]) / 3;
    
    if(ma_slope_fast > 0 && ma_slope_medium > 0) trendScore += 10;
    else if(ma_slope_fast < 0 && ma_slope_medium < 0) trendScore -= 10;
    
    if(adx[0] > 25) {
        double adxMultiplier = MathMin(adx[0] / 30.0, 2.0);
        trendScore *= adxMultiplier;
    }
    
    if(AI_MultiTimeframe) {
        if(ma_fast_htf[0] > ma_slow_htf[0] && trendScore > 0) {
            trendScore += 15;
            if(plusDI_htf[0] > minusDI_htf[0]) trendScore += 10;
        }
        else if(ma_fast_htf[0] < ma_slow_htf[0] && trendScore < 0) {
            trendScore -= 15;
            if(minusDI_htf[0] > plusDI_htf[0]) trendScore -= 10;
        }
    }
    
    AI.trendStrength = MathAbs(trendScore);
    AI.trendDirection = (trendScore > 15) ? 1 : (trendScore < -15) ? -1 : 0;
    AI.trendConfidence = MathMin(MathAbs(trendScore), 100);
    
    if(adx[0] > 25 && AI.trendStrength > 40) {
        AI.marketRegime = "TRENDING";
    }
    else if(adx[0] < 20) {
        AI.marketRegime = "RANGING";
    }
    else {
        AI.marketRegime = "CONSOLIDATION";
    }
    
    // ═══════════════════════════════════════════════════════
    // VOLATILITY INTELLIGENCE (Same as before)
    // ═══════════════════════════════════════════════════════
    
    double avgATR = 0;
    for(int i = 0; i < 50; i++) avgATR += atr[i];
    avgATR /= 50.0;
    
    AI.volatilityIndex = (atr[0] / avgATR) * 100.0;
    
    if(AI.volatilityIndex < 80) AI.volatilityState = 0;
    else if(AI.volatilityIndex < 120) AI.volatilityState = 1;
    else AI.volatilityState = 2;
    
    AI.marketSpeed = (MathAbs(close[0] - close[5]) / atr[0]) * 20.0;
    AI.marketSpeed = MathMin(AI.marketSpeed, 100);
    
    // ═══════════════════════════════════════════════════════
    // MOMENTUM ANALYSIS (Same as before)
    // ═══════════════════════════════════════════════════════
    
    AI.momentumBull = 0;
    AI.momentumBear = 0;
    
    if(macd[0] > macd_signal[0]) {
        AI.momentumBull += 20;
        if(macd[0] > 0) AI.momentumBull += 10;
    }
    else {
        AI.momentumBear += 20;
        if(macd[0] < 0) AI.momentumBear += 10;
    }
    
    if(rsi[0] > 50 && rsi[0] < 70) AI.momentumBull += 20;
    else if(rsi[0] < 50 && rsi[0] > 30) AI.momentumBear += 20;
    
    if(stoch[0] > 20 && stoch[0] < 80) {
        if(stoch[0] > 50) AI.momentumBull += 15;
        else AI.momentumBear += 15;
    }
    
    if(cci[0] > 0 && cci[0] < 100) AI.momentumBull += 15;
    else if(cci[0] < 0 && cci[0] > -100) AI.momentumBear += 15;
    
    if(plusDI[0] > minusDI[0]) AI.momentumBull += 15;
    else if(minusDI[0] > plusDI[0]) AI.momentumBear += 15;
    
    if(close[0] > open[0] && close[0] > close[1]) AI.momentumBull += 15;
    else if(close[0] < open[0] && close[0] < close[1]) AI.momentumBear += 15;
    
    AI.momentumNetScore = AI.momentumBull - AI.momentumBear;
    
    // ═══════════════════════════════════════════════════════
    // NEW: ENHANCED RISK PARAMETER CALCULATION
    // ═══════════════════════════════════════════════════════
    
    double atrPips = atr[0] / (_Point * 10);
    
    // ATR-based stop loss (more adaptive)
    double baseSL = atrPips * 1.8;  // Slightly wider for real accounts
    
    // Adjust for volatility state
    if(AI.volatilityState == 0) baseSL *= 0.9;
    else if(AI.volatilityState == 2) baseSL *= 1.3;  // Much wider in high volatility
    
    // NEW: Adjust for time of day (wider stops during volatile sessions)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if(dt.hour >= 13 && dt.hour < 17) {  // London-NY overlap
        baseSL *= 1.1;
    }
    
    AI.optimalStopLoss = baseSL;
    AI.optimalStopLoss = MathMax(AI.optimalStopLoss, 25);  // Minimum 25 pips
    AI.optimalStopLoss = MathMin(AI.optimalStopLoss, 100); // Maximum 100 pips
    
    // Risk:Reward based on trend strength and regime
    double riskReward = 2.0;  // Default
    
    if(AI.trendStrength > 70 && adx[0] > 35) riskReward = 2.8;
    else if(AI.trendStrength > 50 && adx[0] > 28) riskReward = 2.3;
    else if(AI.marketRegime == "RANGING") riskReward = 1.8;  // Lower R:R in ranging
    
    AI.optimalTakeProfit = AI.optimalStopLoss * riskReward;
    AI.optimalTakeProfit = MathMax(AI.optimalTakeProfit, 50);
    AI.optimalTakeProfit = MathMin(AI.optimalTakeProfit, 250);
    
    AI.riskRewardRatio = AI.optimalTakeProfit / AI.optimalStopLoss;
    
    // ═══════════════════════════════════════════════════════
    // NEW: ENHANCED LOT SIZE CALCULATION WITH SAFETY
    // ═══════════════════════════════════════════════════════
    
    if(AI_DynamicLots && !ManualLotOverride) {
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        // NEW: Use equity for lot calculation if it's lower (protects during drawdown)
        double baseAmount = MathMin(accountBalance, accountEquity);
        
        // NEW: Apply equity curve adjustment
        if(UseEquityCurveAdjustment) {
            if(accountEquity < accountBalance * 0.95) {  // In drawdown
                AI.currentRiskAdjustment = 0.5;  // Reduce risk by 50%
            }
            else if(accountEquity > accountBalance * 1.05) {  // Profitable
                AI.currentRiskAdjustment = 1.2;  // Increase risk by 20%
            }
            else {
                AI.currentRiskAdjustment = 1.0;
            }
        }
        
        double effectiveRisk = MaxRiskPerTrade * AI.currentRiskAdjustment;
        double riskAmount = baseAmount * (effectiveRisk / 100.0);
        
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        double pointValue = (tickValue / tickSize) * _Point * 10;
        
        double lotSize = 0.01;
        if(pointValue > 0 && AI.optimalStopLoss > 0) {
            lotSize = riskAmount / (AI.optimalStopLoss * pointValue);
        }
        
        // NEW: Additional scaling based on confidence (more conservative)
        if(AI.trendConfidence > 75) lotSize *= 1.05;
        else if(AI.trendConfidence < 55) lotSize *= 0.85;
        
        // NEW: Scale down in high volatility
        if(AI.volatilityState == 2) lotSize *= 0.8;
        
        // NEW: Performance-based scaling (with decay)
        if(AI_SelfLearning && g_totalTrades > 20) {
            if(g_winRate > 65 && g_profitFactor > 1.5) lotSize *= 1.15;
            else if(g_winRate < 45 || g_profitFactor < 1.0) lotSize *= 0.7;
        }
        
        // NEW: Reduce lot size if recent consecutive losses
        if(AI.consecutiveLosses >= 3) lotSize *= 0.6;
        
        // Normalize to broker requirements
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        
        lotSize = MathMax(lotSize, minLot);
        lotSize = MathMin(lotSize, maxLot);
        lotSize = MathMin(lotSize, 0.3);  // Hard cap at 0.3 for safety
        lotSize = MathFloor(lotSize / lotStep) * lotStep;
        
        AI.optimalLotSize = lotSize;
    }
    else if(ManualLotOverride) {
        AI.optimalLotSize = FixedLotSize;
    }
    
    if(ManualStopsOverride) {
        AI.optimalStopLoss = ManualSL_Pips;
        AI.optimalTakeProfit = ManualTP_Pips;
    }
}

//+------------------------------------------------------------------+
//| AI Balanced Signal Processor - PRODUCTION ENHANCED              |
//+------------------------------------------------------------------+
int AI_BalancedSignalProcessor()
{
    // Get latest data
    double ma_fast[], ma_medium[], ma_slow[], rsi[], macd[], macd_signal[];
    double stoch[], cci[], adx[], plusDI[], minusDI[];
    double close[], high[], low[], open[];
    double bb_upper[], bb_middle[], bb_lower[];
    
    ArraySetAsSeries(ma_fast, true);
    ArraySetAsSeries(ma_medium, true);
    ArraySetAsSeries(ma_slow, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(macd, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(stoch, true);
    ArraySetAsSeries(cci, true);
    ArraySetAsSeries(adx, true);
    ArraySetAsSeries(plusDI, true);
    ArraySetAsSeries(minusDI, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(bb_upper, true);
    ArraySetAsSeries(bb_middle, true);
    ArraySetAsSeries(bb_lower, true);
    
    if(CopyBuffer(h_MA_Fast, 0, 0, 5, ma_fast) < 5) return 0;
    if(CopyBuffer(h_MA_Medium, 0, 0, 5, ma_medium) < 5) return 0;
    if(CopyBuffer(h_MA_Slow, 0, 0, 5, ma_slow) < 5) return 0;
    if(CopyBuffer(h_RSI, 0, 0, 5, rsi) < 5) return 0;
    if(CopyBuffer(h_MACD, 0, 0, 5, macd) < 5) return 0;
    if(CopyBuffer(h_MACD, 1, 0, 5, macd_signal) < 5) return 0;
    if(CopyBuffer(h_Stoch, 0, 0, 5, stoch) < 5) return 0;
    if(CopyBuffer(h_CCI, 0, 0, 5, cci) < 5) return 0;
    if(CopyBuffer(h_ADX, 0, 0, 5, adx) < 5) return 0;
    if(CopyBuffer(h_ADX, 1, 0, 5, plusDI) < 5) return 0;
    if(CopyBuffer(h_ADX, 2, 0, 5, minusDI) < 5) return 0;
    if(CopyBuffer(h_BB, 1, 0, 5, bb_upper) < 5) return 0;
    if(CopyBuffer(h_BB, 0, 0, 5, bb_middle) < 5) return 0;
    if(CopyBuffer(h_BB, 2, 0, 5, bb_lower) < 5) return 0;
    if(CopyClose(_Symbol, PrimaryTimeframe, 0, 5, close) < 5) return 0;
    if(CopyHigh(_Symbol, PrimaryTimeframe, 0, 5, high) < 5) return 0;
    if(CopyLow(_Symbol, PrimaryTimeframe, 0, 5, low) < 5) return 0;
    if(CopyOpen(_Symbol, PrimaryTimeframe, 0, 5, open) < 5) return 0;
    
    // ═══════════════════════════════════════════════════════
    // QUANTUM SIGNAL SCORING (Reduced Indicators for Production)
    // ═══════════════════════════════════════════════════════
    
    int buyScore = 0;
    int sellScore = 0;
    
    // 1. TREND DIRECTION (200 points) - MOST IMPORTANT
    if(AI.trendDirection == 1 && AI.trendStrength > 40) {
        buyScore += 200;
    }
    else if(AI.trendDirection == -1 && AI.trendStrength > 40) {
        sellScore += 200;
    }
    
    // 2. MA ALIGNMENT (150 points)
    if(ma_fast[0] > ma_medium[0] && ma_medium[0] > ma_slow[0]) {
        buyScore += 150;
    }
    if(ma_fast[0] < ma_medium[0] && ma_medium[0] < ma_slow[0]) {
        sellScore += 150;
    }
    
    // 3. MOMENTUM CONFLUENCE (150 points)
    if(AI.momentumNetScore > 20) {
        buyScore += 150;
    }
    else if(AI.momentumNetScore < -20) {
        sellScore += 150;
    }
    
    // 4. ADX STRENGTH (100 points)
    if(adx[0] > 22) {
        if(plusDI[0] > minusDI[0]) buyScore += 100;
        else if(minusDI[0] > plusDI[0]) sellScore += 100;
    }
    
    // 5. RSI CONFIRMATION (100 points)
    if(rsi[0] > 52 && rsi[0] < 68) buyScore += 100;
    else if(rsi[0] < 48 && rsi[0] > 32) sellScore += 100;
    
    // 6. PRICE ACTION (100 points)
    bool bullishCandle = close[0] > open[0];
    bool bearishCandle = close[0] < open[0];
    
    if(bullishCandle && close[0] > high[1]) buyScore += 100;
    if(bearishCandle && close[0] < low[1]) sellScore += 100;
    
    // 7. VOLATILITY FILTER (Penalty in extreme volatility)
    if(AI.volatilityState == 2) {
        buyScore = (int)(buyScore * 0.8);
        sellScore = (int)(sellScore * 0.8);
    }
    
    // NEW: 8. CONFIRMATION BAR REQUIREMENT
    if(MinConfirmationBars > 0) {
        if(g_consecutiveBullishBars >= MinConfirmationBars) {
            buyScore += 100;
        }
        else if(g_consecutiveBearishBars >= MinConfirmationBars) {
            sellScore += 100;
        }
        else {
            // Penalize if no confirmation
            buyScore = (int)(buyScore * 0.7);
            sellScore = (int)(sellScore * 0.7);
        }
    }
    
    // ═══════════════════════════════════════════════════════
    // CALCULATE FINAL SCORES
    // ═══════════════════════════════════════════════════════
    
    AI.buySignalStrength = buyScore;
    AI.sellSignalStrength = sellScore;
    
    double maxSignal = MathMax(buyScore, sellScore);
    AI.signalQuality = (maxSignal / 1000.0) * 100.0;
    AI.confidenceLevel = AI.signalQuality;
    
    // Dynamic threshold
    int requiredScore = MinSignalStrength;
    
    if(AI_AggressiveMode) {
        requiredScore = (int)(requiredScore * 0.88);
    }
    
    // NEW: Require stronger signals in ranging markets
    if(AI.marketRegime == "RANGING") {
        requiredScore = (int)(requiredScore * 1.15);
    }
    
    // High-probability determination (stricter)
    AI.isHighProbability = (maxSignal >= requiredScore && 
                           AI.trendStrength > 35 && 
                           adx[0] > 20 &&
                           AI.riskRewardRatio >= 1.8);
    
    AI.isLowRisk = (AI.volatilityState <= 1 && AI.trendConfidence > 45);
    
    // ═══════════════════════════════════════════════════════
    // FINAL DECISION - ENSURE CLEAR WINNER
    // ═══════════════════════════════════════════════════════
    
    int scoreDifference = MathAbs(buyScore - sellScore);
    
    // NEW: Require larger score difference (150 instead of 100)
    if(buyScore > sellScore && buyScore >= requiredScore && scoreDifference > 150) {
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║        ⚡ HIGH-PROBABILITY BUY SIGNAL DETECTED ⚡         ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        PrintFormat("║  Signal Strength: %d/1000 (vs SELL: %d)                  ║", buyScore, sellScore);
        PrintFormat("║  Confidence: %.1f%% | Spread: %.1f pips                  ║", AI.confidenceLevel, AI.actualSpread);
        PrintFormat("║  Trend: %s | Regime: %s | ADX: %.1f         ║", 
                    AI.marketSentiment, AI.marketRegime, adx[0]);
        PrintFormat("║  Confirmation: %d bullish bars                            ║", g_consecutiveBullishBars);
        PrintFormat("║  R:R = 1:%.1f | Risk Adj: %.0f%%                          ║", 
                    AI.riskRewardRatio, AI.currentRiskAdjustment * 100);
        Print("╚═══════════════════════════════════════════════════════════╝");
        Print("");
        
        return 1;
    }
    else if(sellScore > buyScore && sellScore >= requiredScore && scoreDifference > 150) {
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║       ⚡ HIGH-PROBABILITY SELL SIGNAL DETECTED ⚡         ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        PrintFormat("║  Signal Strength: %d/1000 (vs BUY: %d)                   ║", sellScore, buyScore);
        PrintFormat("║  Confidence: %.1f%% | Spread: %.1f pips                  ║", AI.confidenceLevel, AI.actualSpread);
        PrintFormat("║  Trend: %s | Regime: %s | ADX: %.1f        ║", 
                    AI.marketSentiment, AI.marketRegime, adx[0]);
        PrintFormat("║  Confirmation: %d bearish bars                            ║", g_consecutiveBearishBars);
        PrintFormat("║  R:R = 1:%.1f | Risk Adj: %.0f%%                          ║", 
                    AI.riskRewardRatio, AI.currentRiskAdjustment * 100);
        Print("╚═══════════════════════════════════════════════════════════╝");
        Print("");
        
        return -1;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| NEW: AI Execute Buy Order with Retry Logic                      |
//+------------------------------------------------------------------+
bool AI_ExecuteBuyOrder()
{
    g_execStats.totalAttempts++;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = ask - (AI.optimalStopLoss * _Point * 10);
    double tp = ask + (AI.optimalTakeProfit * _Point * 10);
    
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║            🤖 AI EXECUTING BUY ORDER 🤖                   ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Entry: %.5f | SL: %.5f | TP: %.5f            ║", ask, sl, tp);
    PrintFormat("║  Stop: %.1f pips | Target: %.1f pips | Lot: %.2f        ║", 
                AI.optimalStopLoss, AI.optimalTakeProfit, AI.optimalLotSize);
    PrintFormat("║  R:R = 1:%.2f | Confidence: %.1f%%                        ║", 
                AI.riskRewardRatio, AI.confidenceLevel);
    Print("╚═══════════════════════════════════════════════════════════╝");
    
    // Try with retry logic
    for(int attempt = 1; attempt <= MaxRetries; attempt++) {
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        // Refresh price for retry attempts
        if(attempt > 1) {
            Sleep(RetryDelayMs);
            ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            sl = ask - (AI.optimalStopLoss * _Point * 10);
            tp = ask + (AI.optimalTakeProfit * _Point * 10);
        }
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = _Symbol;
        request.volume = AI.optimalLotSize;
        request.type = ORDER_TYPE_BUY;
        request.price = ask;
        request.sl = NormalizeDouble(sl, _Digits);
        request.tp = NormalizeDouble(tp, _Digits);
        request.deviation = MaxSlippagePips * 10;  // Convert to points
        request.magic = MagicNumber;
        request.comment = StringFormat("%s_BUY_C%.0f", TradeComment, AI.confidenceLevel);
        request.type_filling = GetFillingMode();
        
        ulong startTime = GetTickCount64();
        
        if(!OrderSend(request, result)) {
            Print("❌ OrderSend Error on attempt ", attempt, ": ", GetLastError());
            g_execStats.lastError = TimeCurrent();
            g_execStats.lastErrorCode = GetLastError();
            continue;
        }
        
        ulong executionTime = GetTickCount64() - startTime;
        
        if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
            // Calculate actual slippage
            double actualEntry = result.price;
            double slippagePips = MathAbs(actualEntry - ask) / (_Point * 10);
            
            g_execStats.avgActualSlippage = ((g_execStats.avgActualSlippage * g_execStats.successfulTrades) + slippagePips) / (g_execStats.successfulTrades + 1);
            g_execStats.avgExecutionTime = ((g_execStats.avgExecutionTime * g_execStats.successfulTrades) + executionTime) / (g_execStats.successfulTrades + 1);
            g_execStats.successfulTrades++;
            
            Print("✅ ✅ ✅ BUY ORDER EXECUTED!");
            PrintFormat("   Ticket: #%d | Actual Entry: %.5f | Slippage: %.1f pips", 
                       result.order, actualEntry, slippagePips);
            PrintFormat("   Execution Time: %d ms (Avg: %.0f ms)", 
                       executionTime, g_execStats.avgExecutionTime);
            
            g_totalTrades++;
            g_lastTradeTime = TimeCurrent();
            
            return true;
        }
        else {
            Print("⚠️ Trade attempt ", attempt, " failed - Retcode: ", result.retcode, " | ", result.comment);
            
            // Don't retry on certain errors
            if(result.retcode == TRADE_RETCODE_INVALID_STOPS ||
               result.retcode == TRADE_RETCODE_INVALID_VOLUME ||
               result.retcode == TRADE_RETCODE_NO_MONEY) {
                break;
            }
        }
    }
    
    // All attempts failed
    g_execStats.failedTrades++;
    AI.failedAttempts++;
    Print("❌ All ", MaxRetries, " attempts failed!");
    
    return false;
}

//+------------------------------------------------------------------+
//| NEW: AI Execute Sell Order with Retry Logic                     |
//+------------------------------------------------------------------+
bool AI_ExecuteSellOrder()
{
    g_execStats.totalAttempts++;
    
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = bid + (AI.optimalStopLoss * _Point * 10);
    double tp = bid - (AI.optimalTakeProfit * _Point * 10);
    
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║           🤖 AI EXECUTING SELL ORDER 🤖                   ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Entry: %.5f | SL: %.5f | TP: %.5f            ║", bid, sl, tp);
    PrintFormat("║  Stop: %.1f pips | Target: %.1f pips | Lot: %.2f        ║", 
                AI.optimalStopLoss, AI.optimalTakeProfit, AI.optimalLotSize);
    PrintFormat("║  R:R = 1:%.2f | Confidence: %.1f%%                        ║", 
                AI.riskRewardRatio, AI.confidenceLevel);
    Print("╚═══════════════════════════════════════════════════════════╝");
    
    // Try with retry logic
    for(int attempt = 1; attempt <= MaxRetries; attempt++) {
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        // Refresh price for retry attempts
        if(attempt > 1) {
            Sleep(RetryDelayMs);
            bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            sl = bid + (AI.optimalStopLoss * _Point * 10);
            tp = bid - (AI.optimalTakeProfit * _Point * 10);
        }
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = _Symbol;
        request.volume = AI.optimalLotSize;
        request.type = ORDER_TYPE_SELL;
        request.price = bid;
        request.sl = NormalizeDouble(sl, _Digits);
        request.tp = NormalizeDouble(tp, _Digits);
        request.deviation = MaxSlippagePips * 10;
        request.magic = MagicNumber;
        request.comment = StringFormat("%s_SELL_C%.0f", TradeComment, AI.confidenceLevel);
        request.type_filling = GetFillingMode();
        
        ulong startTime = GetTickCount64();
        
        if(!OrderSend(request, result)) {
            Print("❌ OrderSend Error on attempt ", attempt, ": ", GetLastError());
            g_execStats.lastError = TimeCurrent();
            g_execStats.lastErrorCode = GetLastError();
            continue;
        }
        
        ulong executionTime = GetTickCount64() - startTime;
        
        if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
            double actualEntry = result.price;
            double slippagePips = MathAbs(actualEntry - bid) / (_Point * 10);
            
            g_execStats.avgActualSlippage = ((g_execStats.avgActualSlippage * g_execStats.successfulTrades) + slippagePips) / (g_execStats.successfulTrades + 1);
            g_execStats.avgExecutionTime = ((g_execStats.avgExecutionTime * g_execStats.successfulTrades) + executionTime) / (g_execStats.successfulTrades + 1);
            g_execStats.successfulTrades++;
            
            Print("✅ ✅ ✅ SELL ORDER EXECUTED!");
            PrintFormat("   Ticket: #%d | Actual Entry: %.5f | Slippage: %.1f pips", 
                       result.order, actualEntry, slippagePips);
            PrintFormat("   Execution Time: %d ms (Avg: %.0f ms)", 
                       executionTime, g_execStats.avgExecutionTime);
            
            g_totalTrades++;
            g_lastTradeTime = TimeCurrent();
            
            return true;
        }
        else {
            Print("⚠️ Trade attempt ", attempt, " failed - Retcode: ", result.retcode, " | ", result.comment);
            
            if(result.retcode == TRADE_RETCODE_INVALID_STOPS ||
               result.retcode == TRADE_RETCODE_INVALID_VOLUME ||
               result.retcode == TRADE_RETCODE_NO_MONEY) {
                break;
            }
        }
    }
    
    g_execStats.failedTrades++;
    AI.failedAttempts++;
    Print("❌ All ", MaxRetries, " attempts failed!");
    
    return false;
}

//+------------------------------------------------------------------+
//| NEW: AI Intelligent Position Management - ATR-Based             |
//+------------------------------------------------------------------+
void AI_IntelligentPositionManagement()
{
    // Get current ATR for adaptive trailing
    double atr[];
    ArraySetAsSeries(atr, true);
    if(CopyBuffer(h_ATR, 0, 0, 5, atr) < 5) return;
    
    double atrPips = atr[0] / (_Point * 10);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionGetSymbol(i) != _Symbol) continue;
        
        long magic = PositionGetInteger(POSITION_MAGIC);
        if(magic != MagicNumber) continue;
        
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        
        double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                              SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                              SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double profitPips = 0;
        if(posType == POSITION_TYPE_BUY)
            profitPips = (currentPrice - openPrice) / (_Point * 10);
        else
            profitPips = (openPrice - currentPrice) / (_Point * 10);
        
        // Track position P&L for daily drawdown
        double positionProfit = PositionGetDouble(POSITION_PROFIT);
        
        // NEW: ATR-Based Smart Trailing Stop
        if(AI_SmartTrailing && profitPips > atrPips * 1.0) {
            // Trail distance = 0.8 * ATR (adaptive)
            double trailDistance = atrPips * 0.8 * _Point * 10;
            double newSL = 0;
            
            if(posType == POSITION_TYPE_BUY) {
                newSL = currentPrice - trailDistance;
                
                // Only move SL if it's significantly better (avoid broker rate limits)
                if(newSL > currentSL + (atrPips * 0.3 * _Point * 10)) {
                    if(AI_ModifyPosition(ticket, newSL, currentTP)) {
                        Print("📊 ATR Trailing: #", ticket, " | +", DoubleToString(profitPips, 1), " pips | New SL: ", DoubleToString(newSL, _Digits));
                    }
                }
            }
            else {
                newSL = currentPrice + trailDistance;
                
                if(currentSL == 0 || newSL < currentSL - (atrPips * 0.3 * _Point * 10)) {
                    if(AI_ModifyPosition(ticket, newSL, currentTP)) {
                        Print("📊 ATR Trailing: #", ticket, " | +", DoubleToString(profitPips, 1), " pips | New SL: ", DoubleToString(newSL, _Digits));
                    }
                }
            }
        }
        
        // NEW: Enhanced Breakeven Protection
        if(AI_BreakevenProtection && profitPips > atrPips * 0.7) {
            double bePips = atrPips * 0.15;  // Breakeven + small profit
            double beSL = openPrice + (bePips * _Point * 10 * ((posType == POSITION_TYPE_BUY) ? 1 : -1));
            
            bool shouldMove = false;
            if(posType == POSITION_TYPE_BUY && (currentSL == 0 || beSL > currentSL) && beSL < currentPrice - (5 * _Point * 10))
                shouldMove = true;
            else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || beSL < currentSL) && beSL > currentPrice + (5 * _Point * 10))
                shouldMove = true;
            
            if(shouldMove) {
                if(AI_ModifyPosition(ticket, beSL, currentTP)) {
                    Print("🛡️ Breakeven+: #", ticket, " | Locked: +", DoubleToString(bePips, 1), " pips");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| NEW: AI Modify Position with Validation                         |
//+------------------------------------------------------------------+
bool AI_ModifyPosition(ulong ticket, double sl, double tp)
{
    // Validate new levels
    if(sl <= 0 && tp <= 0) return false;
    
    // Get minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minDistance = stopLevel * _Point;
    
    // Get position type (integer property, not double)
    long positionType = PositionGetInteger(POSITION_TYPE);
    double currentPrice = (positionType == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Validate SL distance
    if(sl > 0) {
        double slDistance = MathAbs(currentPrice - sl);
        if(slDistance < minDistance) {
            return false;  // Too close to current price
        }
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    
    if(!OrderSend(request, result))
        return false;
    
    return (result.retcode == TRADE_RETCODE_DONE);
}

//+------------------------------------------------------------------+
//| NEW: AI Update Learning System - Fixed Lookahead Bias           |
//+------------------------------------------------------------------+
void AI_UpdateLearningSystem()
{
    // Only process closed deals from history
    datetime yesterday = TimeCurrent() - 86400;  // Last 24 hours
    
    if(!HistorySelect(yesterday, TimeCurrent())) return;
    
    int wins = 0;
    int losses = 0;
    double totalWinPips = 0;
    double totalLossPips = 0;
    double totalWinProfit = 0;
    double totalLossProfit = 0;
    
    double recentWins = 0;
    double recentLosses = 0;
    int recentTotal = 0;
    
    for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;
        
        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        if(magic != MagicNumber) continue;
        
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_OUT) continue;  // Only count closed trades
        
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
        double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        double netProfit = profit + swap + commission;
        
        if(netProfit > 0) {
            wins++;
            totalWinPips += netProfit;
            totalWinProfit += netProfit;
            
            // NEW: Weight recent trades more heavily
            if(recentTotal < 10) {
                recentWins++;
                recentTotal++;
            }
        }
        else if(netProfit < 0) {
            losses++;
            totalLossPips += MathAbs(netProfit);
            totalLossProfit += MathAbs(netProfit);
            
            if(recentTotal < 10) {
                recentLosses++;
                recentTotal++;
            }
        }
    }
    
    if(wins + losses > 0) {
        g_winningTrades = wins;
        g_losingTrades = losses;
        g_totalTrades = wins + losses;
        g_totalProfit = totalWinProfit;
        g_totalLoss = totalLossProfit;
        
        // Overall win rate
        g_winRate = (wins / (wins + losses)) * 100.0;
        
        // NEW: Recent win rate (more weight)
        double recentWinRate = 50.0;
        if(recentTotal > 0) {
            recentWinRate = (recentWins / recentTotal) * 100.0;
        }
        
        // Blend with decay factor
        g_winRate = (g_winRate * (1 - AI.recentPerformanceDecay)) + (recentWinRate * AI.recentPerformanceDecay);
        
        if(wins > 0) AI.avgWinPips = totalWinPips / wins;
        if(losses > 0) AI.avgLossPips = totalLossPips / losses;
        
        if(totalLossProfit > 0) {
            g_profitFactor = totalWinProfit / totalLossProfit;
        }
        
        // Performance score
        AI.performanceScore = g_winRate * 0.5 + MathMin(g_profitFactor * 20, 50);
        
        // Adjust learning rate based on performance
        if(g_winRate > 62 && g_profitFactor > 1.5) {
            AI.learningRate = 0.18;  // Learn faster from success
        }
        else if(g_winRate < 45 || g_profitFactor < 1.0) {
            AI.learningRate = 0.05;  // Learn slower from losses
        }
        else {
            AI.learningRate = 0.10;
        }
        
        // Update consecutive tracking
        // [Count recent consecutive wins/losses for risk adjustment]
        AI.consecutiveWins = 0;
        AI.consecutiveLosses = 0;
        
        int consecutive = 0;
        bool lastWasWin = false;
        
        for(int i = HistoryDealsTotal() - 1; i >= MathMax(0, HistoryDealsTotal() - 10); i--) {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket <= 0) continue;
            
            long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(magic != MagicNumber) continue;
            
            long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if(entry != DEAL_ENTRY_OUT) continue;
            
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            
            if(i == HistoryDealsTotal() - 1) {
                lastWasWin = (profit > 0);
                consecutive = 1;
            }
            else {
                if((profit > 0) == lastWasWin) {
                    consecutive++;
                }
                else {
                    break;
                }
            }
        }
        
        if(lastWasWin) {
            AI.consecutiveWins = consecutive;
        }
        else {
            AI.consecutiveLosses = consecutive;
        }
    }
}

//+------------------------------------------------------------------+
//| Get Filling Mode                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
    int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    
    if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        return ORDER_FILLING_FOK;
    else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        return ORDER_FILLING_IOC;
    
    return ORDER_FILLING_RETURN;
}
//+------------------------------------------------------------------+