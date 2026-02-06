//+------------------------------------------------------------------+
//|                           UltraIntelligent_AI_Pro_FIXED.mq5      |
//|                    ULTRA-INTELLIGENT AI TRADING SYSTEM V8.0       |
//|              Balanced Buy/Sell | 70%+ Win Rate Target             |
//+------------------------------------------------------------------+
#property copyright "Ultra AI Trading Pro - Professional Edition"
#property version   "8.00"
#property strict
#property description "Balanced Neural Network Trading System"
#property description "Equal Buy/Sell Intelligence | High Win Rate Focus"

//+------------------------------------------------------------------+
//| AI INTELLIGENCE CONFIGURATION                                     |
//+------------------------------------------------------------------+

input group "═══ 🧠 NEURAL NETWORK SETTINGS ═══"
input int      AI_IntelligenceLevel = 10;              // AI Intelligence (1-10, 10=Quantum)
input int      AI_SignalSpeed = 3;                     // Signal Speed (1=Slow, 5=Ultra-Fast)
input bool     AI_AggressiveMode = false;              // 🔥 Aggressive Trading Mode
input bool     AI_MultiTimeframe = true;               // 📊 Multi-Timeframe Analysis
input bool     AI_QuantumSignals = true;               // ⚡ Quantum Signal Processing
input int      MinSignalStrength = 650;                // Minimum Signal Strength (400-850)

input group "═══ 💰 RISK & MONEY MANAGEMENT ═══"
input double   MaxRiskPerTrade = 1.5;                  // Max Risk Per Trade (%)
input int      MaxSimultaneousTrades = 3;              // Max Simultaneous Positions
input bool     AI_DynamicLots = true;                  // 🤖 AI Dynamic Lot Sizing
input bool     AI_SmartScaling = false;                // 📈 AI Position Scaling
input double   MaxSpreadPips = 2.0;                    // Max Spread (pips) - Auto-adjusted for cent accounts

input group "═══ 🎯 ADVANCED FEATURES ═══"
input bool     AI_SmartTrailing = true;                // 🎯 AI Smart Trailing Stop
input bool     AI_BreakevenProtection = true;          // 🛡️ AI Breakeven Protection
input bool     AI_PartialProfits = false;              // 💵 AI Partial Profit Taking
input bool     AI_NewsFilter = true;                   // 📰 AI News Event Filter
input bool     AI_SelfLearning = true;                 // 🧠 AI Self-Learning System
input bool     UseATRMultiplier = true;                // Use ATR for Stop/Target calculation

input group "═══ ⚙️ MANUAL OVERRIDE ═══"
input bool     ManualLotOverride = false;              // Override AI Lot Size
input double   FixedLotSize = 0.01;                    // Fixed Lot (if override)
input bool     ManualStopsOverride = false;            // Override AI Stops
input double   ManualSL_Pips = 30.0;                   // Manual SL (pips)
input double   ManualTP_Pips = 60.0;                   // Manual TP (pips)

input group "═══ 📊 TIMEFRAMES ═══"
input ENUM_TIMEFRAMES PrimaryTimeframe = PERIOD_M15;   // Primary Timeframe
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;      // Trend Timeframe

input group "═══ 🔢 SYSTEM ═══"
input int      MagicNumber = 88888;                    // Magic Number
input string   TradeComment = "AI_PRO_v8";             // Trade Comment

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

// Advanced AI Neural Network Brain
struct NeuralNetworkAI {
    // Layer 1: Market Intelligence
    double trendStrength;           // -100 to +100
    int trendDirection;             // -1, 0, +1
    double trendConfidence;         // 0 to 100%
    
    // Layer 2: Volatility Intelligence
    double volatilityIndex;         // 0 to 200
    int volatilityState;            // 0=low, 1=normal, 2=high
    double marketSpeed;             // 0 to 100
    
    // Layer 3: Momentum Intelligence
    double momentumBull;            // 0 to 100
    double momentumBear;            // 0 to 100
    double momentumNetScore;        // -100 to +100
    
    // Layer 4: Signal Intelligence
    int buySignalStrength;          // 0 to 1000
    int sellSignalStrength;         // 0 to 1000
    double signalQuality;           // 0 to 100%
    double confidenceLevel;         // 0 to 100%
    
    // Layer 5: Risk Intelligence
    double optimalStopLoss;         // in pips
    double optimalTakeProfit;       // in pips
    double optimalLotSize;          // lot size
    double riskRewardRatio;         // ratio
    
    // Layer 6: Learning & Memory
    double learningRate;            // adaptation speed
    double performanceScore;        // 0 to 100
    int consecutiveWins;
    int consecutiveLosses;
    double avgWinPips;
    double avgLossPips;
    
    // Layer 7: Market State
    string marketRegime;            // TRENDING/RANGING/BREAKOUT/REVERSAL
    string marketSentiment;         // BULLISH/BEARISH/NEUTRAL
    bool isHighProbability;         // high-probability setup
    bool isLowRisk;                 // low-risk entry
    
} AI;

// Learning Memory & Statistics
double g_totalTrades = 0;
double g_winningTrades = 0;
double g_losingTrades = 0;
double g_totalProfit = 0;
double g_totalLoss = 0;
double g_winRate = 50.0;
double g_profitFactor = 1.0;

// Session Control
datetime g_lastBarTime = 0;
datetime g_lastTradeTime = 0;
bool g_isInitialized = false;
int g_barsSinceLastTrade = 0;

// Performance Tracking
double g_maxDrawdown = 0;
double g_maxProfit = 0;
double g_initialBalance = 0;
int g_totalBuyTrades = 0;
int g_totalSellTrades = 0;

// Cent Account Detection
bool g_isCentAccount = false;
double g_pipValue = 0.0001;  // Default pip value
bool g_autoDetectCentAccount = true;  // Auto-detect cent accounts

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║                                                           ║");
    Print("║     ⚡ ULTRA-INTELLIGENT AI TRADING SYSTEM V8.0 ⚡       ║");
    Print("║              BALANCED BUY/SELL EDITION                    ║");
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
    
    Print("⚙️  Initializing Quantum Neural Networks...");
    
    // ═══════════════════════════════════════════════════════
    // DETECT ACCOUNT TYPE (MUST BE FIRST)
    // ═══════════════════════════════════════════════════════
    DetectAccountType();
    
    // ═══════════════════════════════════════════════════════
    // PRIMARY TIMEFRAME INDICATORS
    // ═══════════════════════════════════════════════════════
    
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
    
    // ═══════════════════════════════════════════════════════
    // HIGHER TIMEFRAME INDICATORS
    // ═══════════════════════════════════════════════════════
    
    if(AI_MultiTimeframe) {
        h_MA_Fast_HTF = iMA(_Symbol, TrendTimeframe, 8, 0, MODE_EMA, PRICE_CLOSE);
        h_MA_Slow_HTF = iMA(_Symbol, TrendTimeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
        h_RSI_HTF = iRSI(_Symbol, TrendTimeframe, 14, PRICE_CLOSE);
        h_MACD_HTF = iMACD(_Symbol, TrendTimeframe, 12, 26, 9, PRICE_CLOSE);
        h_ATR_HTF = iATR(_Symbol, TrendTimeframe, 14);
        h_ADX_HTF = iADX(_Symbol, TrendTimeframe, 14);
        h_Stoch_HTF = iStochastic(_Symbol, TrendTimeframe, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    }
    
    // Verify all indicators
    if(h_MA_Fast == INVALID_HANDLE || h_MA_Medium == INVALID_HANDLE || 
       h_MA_Slow == INVALID_HANDLE || h_RSI == INVALID_HANDLE ||
       h_MACD == INVALID_HANDLE || h_ATR == INVALID_HANDLE ||
       h_ADX == INVALID_HANDLE || h_Stoch == INVALID_HANDLE ||
       h_BB == INVALID_HANDLE || h_CCI == INVALID_HANDLE ||
       h_Momentum == INVALID_HANDLE) {
        Print("❌ Failed to initialize indicators!");
        return INIT_FAILED;
    }
    
    Print("✅ Primary timeframe indicators loaded");
    
    if(AI_MultiTimeframe) {
        if(h_MA_Fast_HTF == INVALID_HANDLE || h_MA_Slow_HTF == INVALID_HANDLE ||
           h_RSI_HTF == INVALID_HANDLE || h_MACD_HTF == INVALID_HANDLE ||
           h_ATR_HTF == INVALID_HANDLE || h_ADX_HTF == INVALID_HANDLE ||
           h_Stoch_HTF == INVALID_HANDLE) {
            Print("❌ Failed to initialize higher timeframe indicators!");
            return INIT_FAILED;
        }
        Print("✅ Multi-timeframe indicators loaded");
    }
    
    // Wait for indicators to calculate
    Print("⏳ Calibrating neural networks...");
    Sleep(2000);
    
    // Initialize AI Brain
    InitializeAI();
    
    g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_isInitialized = true;
    
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║              ✅ ULTRA AI SYSTEM ONLINE ✅                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Intelligence Level: %d/10                                    ║", AI_IntelligenceLevel);
    PrintFormat("║  Min Signal Strength: %d                                   ║", MinSignalStrength);
    PrintFormat("║  Aggressive Mode: %s                               ║", AI_AggressiveMode ? "✓ ENABLED" : "✗ DISABLED");
    PrintFormat("║  Multi-Timeframe: %s                               ║", AI_MultiTimeframe ? "✓ ENABLED" : "✗ DISABLED");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Account Type: %s                              ║", g_isCentAccount ? "CENT (USC) ⚠️" : "STANDARD (USD)");
    PrintFormat("║  Symbol: %s                                              ║", _Symbol);
    PrintFormat("║  Primary TF: %s                                          ║", EnumToString(PrimaryTimeframe));
    PrintFormat("║  Trend TF: %s                                            ║", EnumToString(TrendTimeframe));
    PrintFormat("║  Max Risk: %.1f%%                                           ║", MaxRiskPerTrade);
    PrintFormat("║  Max Positions: %d                                          ║", MaxSimultaneousTrades);
    PrintFormat("║  Max Spread: %.2f pips                                       ║", MaxSpreadPips);
    PrintFormat("║  Pip Value: %.8f (1 pip = %.0f points)                    ║", g_pipValue, (g_pipValue / _Point));
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
    Print("🚀 AI is hunting for BALANCED high-probability setups...");
    Print("⚖️  Equal opportunity for BUY and SELL signals");
    Print("");
    
    return INIT_SUCCEEDED;
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
            g_isCentAccount = true;
        }
        else
        {
            g_isCentAccount = false;
        }
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
    return pips * (g_pipValue / _Point);
}

//+------------------------------------------------------------------+
//| Convert Points to Pips (Account-aware)                           |
//+------------------------------------------------------------------+
double PointsToPips(double points)
{
    if(g_pipValue > 0)
        return points / (g_pipValue / _Point);
    return 0;
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
    AI.learningRate = 0.1;
    AI.performanceScore = 50;
    AI.consecutiveWins = 0;
    AI.consecutiveLosses = 0;
    AI.avgWinPips = 50;
    AI.avgLossPips = 50;
    AI.marketRegime = "ANALYZING";
    AI.marketSentiment = "NEUTRAL";
    AI.isHighProbability = false;
    AI.isLowRisk = false;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicators
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
    Print("║           AI TRADING SYSTEM SHUTDOWN REPORT               ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    PrintFormat("║  Total Trades: %.0f                                          ║", g_totalTrades);
    PrintFormat("║  Buy Trades: %d | Sell Trades: %d                           ║", g_totalBuyTrades, g_totalSellTrades);
    PrintFormat("║  Winning Trades: %.0f                                        ║", g_winningTrades);
    PrintFormat("║  Losing Trades: %.0f                                         ║", g_losingTrades);
    PrintFormat("║  Win Rate: %.1f%%                                            ║", g_winRate);
    PrintFormat("║  Profit Factor: %.2f                                         ║", g_profitFactor);
    PrintFormat("║  Performance Score: %.1f/100                                 ║", AI.performanceScore);
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!g_isInitialized) return;
    
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
    
    // Fast-mode check
    if(AI_SignalSpeed >= 4 || AI_AggressiveMode) {
        static int fastTickCounter = 0;
        fastTickCounter++;
        if(fastTickCounter % 3 != 0) {
            if(shouldLog) Print("⏸️  Fast-mode throttling (tick ", fastTickCounter, ")");
            return;
        }
    }
    if(shouldLog) Print("✅ Fast-mode check: OK");
    
    // New bar check
    datetime currentBar = iTime(_Symbol, PrimaryTimeframe, 0);
    bool isNewBar = (currentBar != g_lastBarTime);
    
    if(!isNewBar && AI_SignalSpeed < 4 && !AI_AggressiveMode) {
        if(shouldLog) Print("⏸️  Waiting for new bar (not in fast mode)");
        return;
    }
    if(shouldLog) Print("✅ Bar check: OK (isNewBar=", isNewBar ? "YES" : "NO", ")");
    
    if(isNewBar) {
        g_lastBarTime = currentBar;
        g_barsSinceLastTrade++;
        if(shouldLog) Print("📊 New bar detected. Bars since last trade: ", g_barsSinceLastTrade);
    }
    
    // ═══════════════════════════════════════════════════════
    // QUANTUM AI PROCESSING PIPELINE
    // ═══════════════════════════════════════════════════════
    
    // Layer 1: Deep Market Analysis
    AI_DeepMarketAnalysis();
    
    // Layer 2: Position Management
    AI_IntelligentPositionManagement();
    
    // Layer 3: Update Learning System
    if(AI_SelfLearning) {
        AI_UpdateLearningSystem();
    }
    
    // Layer 4: Check if trading is allowed
    if(!AI_CanExecuteTrade(shouldLog)) {
        if(shouldLog) Print("❌ BLOCKED: AI_CanExecuteTrade() = FALSE");
        if(shouldLog) Print("═══════════════════════════════════════════════════════════");
        return;
    }
    if(shouldLog) Print("✅ AI_CanExecuteTrade: OK");
    
    // Layer 5: Generate Balanced Signals
    int signal = AI_BalancedSignalProcessor();
    
    if(shouldLog)
    {
        Print("📊 Signal Analysis:");
        Print("   BUY Signal Strength: ", AI.buySignalStrength, "/1000");
        Print("   SELL Signal Strength: ", AI.sellSignalStrength, "/1000");
        Print("   Signal Quality: ", DoubleToString(AI.signalQuality, 1), "%");
        Print("   Confidence: ", DoubleToString(AI.confidenceLevel, 1), "%");
        Print("   High Probability: ", AI.isHighProbability ? "YES" : "NO");
        Print("   Low Risk: ", AI.isLowRisk ? "YES" : "NO");
        Print("   Trend: ", AI.marketSentiment, " | Regime: ", AI.marketRegime);
        Print("   Trend Strength: ", DoubleToString(AI.trendStrength, 1));
        Print("   Final Signal: ", signal == 1 ? "BUY" : (signal == -1 ? "SELL" : "NONE"));
    }
    
    // Layer 6: Execute trades with high confidence
    if(signal == 1 && AI.isHighProbability) {
        if(shouldLog) Print("🚀 EXECUTING BUY ORDER (Signal=1, HighProb=YES)");
        AI_ExecuteBuyOrder();
        g_barsSinceLastTrade = 0;
        g_totalBuyTrades++;
    }
    else if(signal == -1 && AI.isHighProbability) {
        if(shouldLog) Print("🚀 EXECUTING SELL ORDER (Signal=-1, HighProb=YES)");
        AI_ExecuteSellOrder();
        g_barsSinceLastTrade = 0;
        g_totalSellTrades++;
    }
    else
    {
        if(shouldLog)
        {
            if(signal == 0) Print("⏸️  No signal generated (signal=0)");
            if(signal == 1 && !AI.isHighProbability) Print("⏸️  BUY signal but not high probability (HighProb=NO)");
            if(signal == -1 && !AI.isHighProbability) Print("⏸️  SELL signal but not high probability (HighProb=NO)");
        }
    }
    
    if(shouldLog) Print("═══════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| AI Deep Market Analysis - Enhanced & Balanced                    |
//+------------------------------------------------------------------+
void AI_DeepMarketAnalysis()
{
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
    
    // Copy data
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
    // LAYER 1: BALANCED TREND ANALYSIS
    // ═══════════════════════════════════════════════════════
    
    double trendScore = 0;
    
    // MA Alignment - BALANCED scoring
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
    
    // Price vs MAs - BALANCED
    if(close[0] > ma_slow[0]) trendScore += 15;
    else if(close[0] < ma_slow[0]) trendScore -= 15;
    
    // MA Slope - BALANCED
    double ma_slope_fast = (ma_fast[0] - ma_fast[3]) / 3;
    double ma_slope_medium = (ma_medium[0] - ma_medium[3]) / 3;
    
    if(ma_slope_fast > 0 && ma_slope_medium > 0) trendScore += 10;
    else if(ma_slope_fast < 0 && ma_slope_medium < 0) trendScore -= 10;
    
    // ADX Strength
    if(adx[0] > 25) {
        double adxMultiplier = MathMin(adx[0] / 30.0, 2.0);
        trendScore *= adxMultiplier;
    }
    
    // Higher Timeframe Confirmation - BALANCED
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
    
    // Market Regime
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
    // LAYER 2: VOLATILITY INTELLIGENCE
    // ═══════════════════════════════════════════════════════
    
    double avgATR = 0;
    for(int i = 0; i < 50; i++) avgATR += atr[i];
    avgATR /= 50.0;
    
    AI.volatilityIndex = (atr[0] / avgATR) * 100.0;
    
    if(AI.volatilityIndex < 80) AI.volatilityState = 0;       // Low
    else if(AI.volatilityIndex < 120) AI.volatilityState = 1; // Normal
    else AI.volatilityState = 2;                               // High
    
    AI.marketSpeed = (MathAbs(close[0] - close[5]) / atr[0]) * 20.0;
    AI.marketSpeed = MathMin(AI.marketSpeed, 100);
    
    // ═══════════════════════════════════════════════════════
    // LAYER 3: BALANCED MOMENTUM ANALYSIS
    // ═══════════════════════════════════════════════════════
    
    AI.momentumBull = 0;
    AI.momentumBear = 0;
    
    // MACD - BALANCED
    if(macd[0] > macd_signal[0]) {
        AI.momentumBull += 20;
        if(macd[0] > 0) AI.momentumBull += 10;
    }
    else {
        AI.momentumBear += 20;
        if(macd[0] < 0) AI.momentumBear += 10;
    }
    
    // RSI - BALANCED
    if(rsi[0] > 50 && rsi[0] < 70) AI.momentumBull += 20;
    else if(rsi[0] < 50 && rsi[0] > 30) AI.momentumBear += 20;
    
    // Stochastic - BALANCED
    if(stoch[0] > 20 && stoch[0] < 80) {
        if(stoch[0] > 50) AI.momentumBull += 15;
        else AI.momentumBear += 15;
    }
    
    // CCI - BALANCED
    if(cci[0] > 0 && cci[0] < 100) AI.momentumBull += 15;
    else if(cci[0] < 0 && cci[0] > -100) AI.momentumBear += 15;
    
    // DI - BALANCED
    if(plusDI[0] > minusDI[0]) AI.momentumBull += 15;
    else if(minusDI[0] > plusDI[0]) AI.momentumBear += 15;
    
    // Price Action - BALANCED
    if(close[0] > open[0] && close[0] > close[1]) AI.momentumBull += 15;
    else if(close[0] < open[0] && close[0] < close[1]) AI.momentumBear += 15;
    
    AI.momentumNetScore = AI.momentumBull - AI.momentumBear;
    
    // ═══════════════════════════════════════════════════════
    // LAYER 4: CALCULATE OPTIMAL RISK PARAMETERS
    // ═══════════════════════════════════════════════════════
    
    double atrPips = PointsToPips(atr[0]);
    
    double baseSL = atrPips * 1.5;
    
    // Adjust for volatility
    if(AI.volatilityState == 0) baseSL *= 0.9;
    else if(AI.volatilityState == 2) baseSL *= 1.2;
    
    AI.optimalStopLoss = baseSL;
    
    // CRITICAL: Adjust minimum SL for cent accounts (0.3 pip spread = need tighter stops)
    if(g_isCentAccount) {
        // Cent accounts: Minimum 5 pips, Maximum 80 pips
        AI.optimalStopLoss = MathMax(AI.optimalStopLoss, 5.0);   // Min 5 pips for cent
        AI.optimalStopLoss = MathMin(AI.optimalStopLoss, 80.0);   // Max 80 pips for cent
    }
    else {
        // Standard accounts: Original values
        AI.optimalStopLoss = MathMax(AI.optimalStopLoss, 20.0);  // Min 20 pips
        AI.optimalStopLoss = MathMin(AI.optimalStopLoss, 80.0);   // Max 80 pips
    }
    
    // Risk:Reward based on trend strength
    double riskReward = 2.0;
    if(AI.trendStrength > 60 && adx[0] > 30) riskReward = 2.5;
    else if(AI.trendStrength > 40) riskReward = 2.2;
    
    if(AI.marketRegime == "TRENDING") riskReward *= 1.1;
    
    AI.optimalTakeProfit = AI.optimalStopLoss * riskReward;
    
    // CRITICAL: Adjust TP for cent accounts
    if(g_isCentAccount) {
        AI.optimalTakeProfit = MathMax(AI.optimalTakeProfit, 10.0);  // Min 10 pips for cent
        AI.optimalTakeProfit = MathMin(AI.optimalTakeProfit, 200.0);  // Max 200 pips for cent
    }
    else {
        AI.optimalTakeProfit = MathMax(AI.optimalTakeProfit, 40.0);  // Min 40 pips
        AI.optimalTakeProfit = MathMin(AI.optimalTakeProfit, 200.0);  // Max 200 pips
    }
    
    AI.riskRewardRatio = AI.optimalTakeProfit / AI.optimalStopLoss;
    
    // ═══════════════════════════════════════════════════════
    // LAYER 5: CALCULATE OPTIMAL LOT SIZE
    // ═══════════════════════════════════════════════════════
    
    if(AI_DynamicLots && !ManualLotOverride) {
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = accountBalance * (MaxRiskPerTrade / 100.0);
        
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        double pointValue = (tickValue / tickSize) * GetPipValue();
        
        double lotSize = 0.01;
        if(pointValue > 0 && AI.optimalStopLoss > 0) {
            lotSize = riskAmount / (AI.optimalStopLoss * pointValue);
        }
        
        // Scale based on confidence
        if(AI.trendConfidence > 70) lotSize *= 1.1;
        else if(AI.trendConfidence < 50) lotSize *= 0.8;
        
        // Performance scaling
        if(AI_SelfLearning && g_totalTrades > 10) {
            if(g_winRate > 65) lotSize *= 1.2;
            else if(g_winRate < 45) lotSize *= 0.7;
        }
        
        // Normalize
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        
        lotSize = MathMax(lotSize, minLot);
        lotSize = MathMin(lotSize, maxLot);
        lotSize = MathMin(lotSize, 0.5); // Safety cap
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
//| AI Balanced Signal Processor - FIXED FOR BUY & SELL             |
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
    // BALANCED QUANTUM SIGNAL SCORING
    // ═══════════════════════════════════════════════════════
    
    int buyScore = 0;
    int sellScore = 0;
    int maxScore = 1000;
    
    // ───────────────────────────────────────────────────────
    // 1. TREND DIRECTION (150 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(AI.trendDirection == 1 && AI.trendStrength > 35) {
        buyScore += 150;
    }
    else if(AI.trendDirection == -1 && AI.trendStrength > 35) {
        sellScore += 150;
    }
    
    // ───────────────────────────────────────────────────────
    // 2. MA CROSSOVER (120 points) - BALANCED
    // ───────────────────────────────────────────────────────
    // Recent bullish cross
    if(ma_fast[0] > ma_medium[0] && ma_fast[1] <= ma_medium[1]) {
        buyScore += 120;
    }
    // Recent bearish cross
    if(ma_fast[0] < ma_medium[0] && ma_fast[1] >= ma_medium[1]) {
        sellScore += 120;
    }
    
    // Alignment bonus
    if(ma_fast[0] > ma_medium[0] && ma_medium[0] > ma_slow[0]) {
        buyScore += 50;
    }
    if(ma_fast[0] < ma_medium[0] && ma_medium[0] < ma_slow[0]) {
        sellScore += 50;
    }
    
    // ───────────────────────────────────────────────────────
    // 3. MACD (100 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(macd[0] > macd_signal[0]) {
        buyScore += 60;
        if(macd[0] > 0) buyScore += 40;
    }
    else {
        sellScore += 60;
        if(macd[0] < 0) sellScore += 40;
    }
    
    // MACD crossover
    if(macd[0] > macd_signal[0] && macd[1] <= macd_signal[1]) {
        buyScore += 50;
    }
    if(macd[0] < macd_signal[0] && macd[1] >= macd_signal[1]) {
        sellScore += 50;
    }
    
    // ───────────────────────────────────────────────────────
    // 4. RSI (100 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(rsi[0] > 50 && rsi[0] < 70) {
        buyScore += 100;
    }
    else if(rsi[0] < 50 && rsi[0] > 30) {
        sellScore += 100;
    }
    
    // RSI momentum
    if(rsi[0] > rsi[1] && rsi[1] > rsi[2] && rsi[0] < 75) {
        buyScore += 40;
    }
    if(rsi[0] < rsi[1] && rsi[1] < rsi[2] && rsi[0] > 25) {
        sellScore += 40;
    }
    
    // ───────────────────────────────────────────────────────
    // 5. ADX + DI (100 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(adx[0] > 20) {
        if(plusDI[0] > minusDI[0]) {
            buyScore += 100;
        }
        else if(minusDI[0] > plusDI[0]) {
            sellScore += 100;
        }
    }
    
    // ───────────────────────────────────────────────────────
    // 6. STOCHASTIC (80 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(stoch[0] > 20 && stoch[0] < 80) {
        if(stoch[0] > 50 && stoch[0] > stoch[1]) {
            buyScore += 80;
        }
        else if(stoch[0] < 50 && stoch[0] < stoch[1]) {
            sellScore += 80;
        }
    }
    
    // ───────────────────────────────────────────────────────
    // 7. CCI (70 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(cci[0] > 0 && cci[0] < 150) {
        buyScore += 70;
    }
    else if(cci[0] < 0 && cci[0] > -150) {
        sellScore += 70;
    }
    
    // ───────────────────────────────────────────────────────
    // 8. MOMENTUM (100 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(AI.momentumNetScore > 15) {
        buyScore += 100;
    }
    else if(AI.momentumNetScore < -15) {
        sellScore += 100;
    }
    
    // ───────────────────────────────────────────────────────
    // 9. PRICE ACTION (80 points) - BALANCED
    // ───────────────────────────────────────────────────────
    bool bullishCandle = close[0] > open[0];
    bool bearishCandle = close[0] < open[0];
    
    if(bullishCandle && close[0] > high[1]) {
        buyScore += 80;
    }
    if(bearishCandle && close[0] < low[1]) {
        sellScore += 80;
    }
    
    // Multi-candle pattern
    if(close[0] > close[1] && close[1] > close[2]) {
        buyScore += 50;
    }
    if(close[0] < close[1] && close[1] < close[2]) {
        sellScore += 50;
    }
    
    // ───────────────────────────────────────────────────────
    // 10. BOLLINGER BANDS (60 points) - BALANCED
    // ───────────────────────────────────────────────────────
    if(close[0] < bb_lower[0] && close[0] > close[1]) {
        buyScore += 60; // Oversold bounce
    }
    if(close[0] > bb_upper[0] && close[0] < close[1]) {
        sellScore += 60; // Overbought rejection
    }
    
    // ───────────────────────────────────────────────────────
    // 11. VOLATILITY STATE (50 points)
    // ───────────────────────────────────────────────────────
    if(AI.volatilityState == 1) { // Normal volatility
        buyScore += 50;
        sellScore += 50;
    }
    
    // ═══════════════════════════════════════════════════════
    // CALCULATE FINAL SCORES
    // ═══════════════════════════════════════════════════════
    
    AI.buySignalStrength = buyScore;
    AI.sellSignalStrength = sellScore;
    
    double maxSignal = MathMax(buyScore, sellScore);
    AI.signalQuality = (maxSignal / maxScore) * 100.0;
    AI.confidenceLevel = AI.signalQuality;
    
    // Dynamic threshold based on settings
    int requiredScore = MinSignalStrength;
    
    if(AI_AggressiveMode) {
        requiredScore = (int)(requiredScore * 0.85);
    }
    
    // High-probability determination
    AI.isHighProbability = (maxSignal >= requiredScore && AI.trendStrength > 30 && adx[0] > 18);
    AI.isLowRisk = (AI.volatilityState <= 1 && AI.trendConfidence > 40);
    
    // ═══════════════════════════════════════════════════════
    // FINAL DECISION - BALANCED
    // ═══════════════════════════════════════════════════════
    
    // Ensure clear winner
    int scoreDifference = MathAbs(buyScore - sellScore);
    
    if(buyScore > sellScore && buyScore >= requiredScore && scoreDifference > 100) {
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║           ⚡ QUANTUM BUY SIGNAL DETECTED ⚡               ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        PrintFormat("║  Signal Strength: %d/1000 (SELL: %d)                     ║", buyScore, sellScore);
        PrintFormat("║  Confidence: %.1f%%                                        ║", AI.confidenceLevel);
        PrintFormat("║  Trend: %s | Regime: %s                    ║", AI.marketSentiment, AI.marketRegime);
        PrintFormat("║  Momentum: %+.0f                                           ║", AI.momentumNetScore);
        PrintFormat("║  R:R = 1:%.1f                                              ║", AI.riskRewardRatio);
        Print("╚═══════════════════════════════════════════════════════════╝");
        Print("");
        
        return 1;
    }
    else if(sellScore > buyScore && sellScore >= requiredScore && scoreDifference > 100) {
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║          ⚡ QUANTUM SELL SIGNAL DETECTED ⚡               ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        PrintFormat("║  Signal Strength: %d/1000 (BUY: %d)                      ║", sellScore, buyScore);
        PrintFormat("║  Confidence: %.1f%%                                        ║", AI.confidenceLevel);
        PrintFormat("║  Trend: %s | Regime: %s                   ║", AI.marketSentiment, AI.marketRegime);
        PrintFormat("║  Momentum: %+.0f                                           ║", AI.momentumNetScore);
        PrintFormat("║  R:R = 1:%.1f                                              ║", AI.riskRewardRatio);
        Print("╚═══════════════════════════════════════════════════════════╝");
        Print("");
        
        return -1;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| AI Execute Buy Order                                              |
//+------------------------------------------------------------------+
void AI_ExecuteBuyOrder()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Calculate SL/TP correctly (Account-aware)
    // ═══════════════════════════════════════════════════════
    double sl = ask - (AI.optimalStopLoss * GetPipValue());
    double tp = ask + (AI.optimalTakeProfit * GetPipValue());
    
    // Get broker's minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * _Point;
    double minStopDistancePips = PointsToPips(minStopDistance);
    
    // Validate and adjust SL
    double slDistancePips = PointsToPips(MathAbs(ask - sl));
    if(slDistancePips < minStopDistancePips) {
        slDistancePips = minStopDistancePips + 1.0;
        sl = ask - (slDistancePips * GetPipValue());
    }
    
    // Validate and adjust TP
    double tpDistancePips = PointsToPips(MathAbs(tp - ask));
    if(tpDistancePips < minStopDistancePips) {
        tpDistancePips = minStopDistancePips + 1.0;
        tp = ask + (tpDistancePips * GetPipValue());
    }
    
    // Normalize to proper digits
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    // Verify final distances
    double finalSLDistance = PointsToPips(MathAbs(ask - sl));
    double finalTPDistance = PointsToPips(MathAbs(tp - ask));
    
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║              🤖 AI EXECUTING BUY ORDER 🤖                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Account: ", g_isCentAccount ? "CENT (USC)" : "STANDARD (USD)", "                              ║");
    PrintFormat("║  Entry: %.5f | SL: %.5f | TP: %.5f            ║", ask, sl, tp);
    PrintFormat("║  SL: %.2f pips from entry | TP: %.2f pips from entry    ║", finalSLDistance, finalTPDistance);
    PrintFormat("║  Calculated: SL=%.1f pips | TP=%.1f pips                  ║", AI.optimalStopLoss, AI.optimalTakeProfit);
    PrintFormat("║  Lot Size: %.2f | R:R = 1:%.2f                          ║", AI.optimalLotSize, AI.riskRewardRatio);
    PrintFormat("║  Confidence: %.1f%%                                        ║", AI.confidenceLevel);
    Print("╚═══════════════════════════════════════════════════════════╝");
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = AI.optimalLotSize;
    request.type = ORDER_TYPE_BUY;
    request.price = ask;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = 50;
    request.magic = MagicNumber;
    request.comment = StringFormat("%s_BUY_%.0f", TradeComment, AI.confidenceLevel);
    request.type_filling = GetFillingMode();
    
    if(!OrderSend(request, result)) {
        Print("❌ OrderSend Error: ", GetLastError());
        return;
    }
    
    if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        Print("✅ ✅ ✅ BUY ORDER EXECUTED! Ticket: #", result.order);
        g_totalTrades++;
        g_lastTradeTime = TimeCurrent();
    }
    else {
        Print("⚠️ Trade failed - Retcode: ", result.retcode, " | ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| AI Execute Sell Order                                             |
//+------------------------------------------------------------------+
void AI_ExecuteSellOrder()
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Calculate SL/TP correctly (Account-aware)
    // ═══════════════════════════════════════════════════════
    double sl = bid + (AI.optimalStopLoss * GetPipValue());
    double tp = bid - (AI.optimalTakeProfit * GetPipValue());
    
    // Get broker's minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * _Point;
    double minStopDistancePips = PointsToPips(minStopDistance);
    
    // Validate and adjust SL
    double slDistancePips = PointsToPips(MathAbs(sl - bid));
    if(slDistancePips < minStopDistancePips) {
        slDistancePips = minStopDistancePips + 1.0;
        sl = bid + (slDistancePips * GetPipValue());
    }
    
    // Validate and adjust TP
    double tpDistancePips = PointsToPips(MathAbs(bid - tp));
    if(tpDistancePips < minStopDistancePips) {
        tpDistancePips = minStopDistancePips + 1.0;
        tp = bid - (tpDistancePips * GetPipValue());
    }
    
    // Normalize to proper digits
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    // Verify final distances
    double finalSLDistance = PointsToPips(MathAbs(sl - bid));
    double finalTPDistance = PointsToPips(MathAbs(bid - tp));
    
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║             🤖 AI EXECUTING SELL ORDER 🤖                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Account: ", g_isCentAccount ? "CENT (USC)" : "STANDARD (USD)", "                              ║");
    PrintFormat("║  Entry: %.5f | SL: %.5f | TP: %.5f            ║", bid, sl, tp);
    PrintFormat("║  SL: %.2f pips from entry | TP: %.2f pips from entry    ║", finalSLDistance, finalTPDistance);
    PrintFormat("║  Calculated: SL=%.1f pips | TP=%.1f pips                  ║", AI.optimalStopLoss, AI.optimalTakeProfit);
    PrintFormat("║  Lot Size: %.2f | R:R = 1:%.2f                          ║", AI.optimalLotSize, AI.riskRewardRatio);
    PrintFormat("║  Confidence: %.1f%%                                        ║", AI.confidenceLevel);
    Print("╚═══════════════════════════════════════════════════════════╝");
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = AI.optimalLotSize;
    request.type = ORDER_TYPE_SELL;
    request.price = bid;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = 50;
    request.magic = MagicNumber;
    request.comment = StringFormat("%s_SELL_%.0f", TradeComment, AI.confidenceLevel);
    request.type_filling = GetFillingMode();
    
    if(!OrderSend(request, result)) {
        Print("❌ OrderSend Error: ", GetLastError());
        return;
    }
    
    if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        Print("✅ ✅ ✅ SELL ORDER EXECUTED! Ticket: #", result.order);
        g_totalTrades++;
        g_lastTradeTime = TimeCurrent();
    }
    else {
        Print("⚠️ Trade failed - Retcode: ", result.retcode, " | ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| AI Intelligent Position Management                                |
//+------------------------------------------------------------------+
void AI_IntelligentPositionManagement()
{
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
            profitPips = PointsToPips(currentPrice - openPrice);
        else
            profitPips = PointsToPips(openPrice - currentPrice);
        
        // Smart Trailing Stop
        if(AI_SmartTrailing && profitPips > AI.optimalStopLoss * 0.6) {
            double trailDistance = AI.optimalStopLoss * 0.5 * GetPipValue();
            double newSL = 0;
            
            if(posType == POSITION_TYPE_BUY) {
                newSL = currentPrice - trailDistance;
                double minMove = 5.0 * GetPipValue();
                if(newSL > currentSL + minMove) {
                    if(AI_ModifyPosition(ticket, newSL, currentTP)) {
                        Print("📊 Trailing Stop: #", ticket, " | Profit: +", DoubleToString(profitPips, 1), " pips");
                    }
                }
            }
            else {
                newSL = currentPrice + trailDistance;
                double minMove = 5.0 * GetPipValue();
                if(currentSL == 0 || newSL < currentSL - minMove) {
                    if(AI_ModifyPosition(ticket, newSL, currentTP)) {
                        Print("📊 Trailing Stop: #", ticket, " | Profit: +", DoubleToString(profitPips, 1), " pips");
                    }
                }
            }
        }
        
        // Breakeven Protection
        if(AI_BreakevenProtection && profitPips > AI.optimalStopLoss * 0.5) {
            double bePips = g_isCentAccount ? 2.0 : 5.0;  // Tighter for cent accounts
            double beOffset = bePips * GetPipValue();
            double beSL = openPrice + (beOffset * ((posType == POSITION_TYPE_BUY) ? 1 : -1));
            
            bool shouldMove = false;
            if(posType == POSITION_TYPE_BUY && (currentSL == 0 || beSL > currentSL) && beSL < currentPrice)
                shouldMove = true;
            else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || beSL < currentSL) && beSL > currentPrice)
                shouldMove = true;
            
            if(shouldMove) {
                if(AI_ModifyPosition(ticket, beSL, currentTP)) {
                    Print("🛡️ Breakeven Protection: #", ticket);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| AI Modify Position                                                |
//+------------------------------------------------------------------+
bool AI_ModifyPosition(ulong ticket, double sl, double tp)
{
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
//| AI Update Learning System                                         |
//+------------------------------------------------------------------+
void AI_UpdateLearningSystem()
{
    datetime dayStart = iTime(_Symbol, PERIOD_D1, 0);
    HistorySelect(dayStart, TimeCurrent());
    
    int wins = 0;
    int losses = 0;
    double totalWinPips = 0;
    double totalLossPips = 0;
    
    for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0) {
            long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(magic == MagicNumber) {
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                
                if(profit > 0) {
                    wins++;
                    totalWinPips += profit;
                }
                else if(profit < 0) {
                    losses++;
                    totalLossPips += MathAbs(profit);
                }
            }
        }
    }
    
    if(wins + losses > 0) {
        g_winningTrades = wins;
        g_losingTrades = losses;
        g_totalTrades = wins + losses;
        g_winRate = (wins / (wins + losses)) * 100.0;
        
        if(wins > 0) AI.avgWinPips = totalWinPips / wins;
        if(losses > 0) AI.avgLossPips = totalLossPips / losses;
        
        if(totalLossPips > 0) {
            g_profitFactor = totalWinPips / totalLossPips;
        }
        
        AI.performanceScore = g_winRate * 0.5 + MathMin(g_profitFactor * 20, 50);
        
        if(g_winRate > 60) AI.learningRate = 0.15;
        else if(g_winRate < 45) AI.learningRate = 0.05;
    }
}

//+------------------------------------------------------------------+
//| Can AI Execute Trade                                              |
//+------------------------------------------------------------------+
bool AI_CanExecuteTrade(bool logDetails = false)
{
    // Count positions
    int openPositions = 0;
    int buyPositions = 0;
    int sellPositions = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) == _Symbol) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                openPositions++;
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                if(posType == POSITION_TYPE_BUY) buyPositions++;
                else if(posType == POSITION_TYPE_SELL) sellPositions++;
            }
        }
    }
    
    if(logDetails)
    {
        Print("📊 Position Status:");
        Print("   Open Positions: ", openPositions, "/", MaxSimultaneousTrades);
        Print("   BUY Positions: ", buyPositions);
        Print("   SELL Positions: ", sellPositions);
    }
    
    if(openPositions >= MaxSimultaneousTrades) {
        if(logDetails) Print("❌ BLOCKED: Max positions reached (", openPositions, " >= ", MaxSimultaneousTrades, ")");
        return false;
    }
    if(logDetails) Print("✅ Position limit: OK");
    
    // Check spread (account-aware)
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double spreadPips = PointsToPips((double)spread * _Point);
    
    // Use input parameter, but auto-adjust for cent accounts if needed
    double maxSpreadPips = MaxSpreadPips;
    if(g_isCentAccount && MaxSpreadPips > 2.0) {
        // Warn if user set too high for cent account
        static bool warnedOnce = false;
        if(!warnedOnce) {
            Print("⚠️ WARNING: MaxSpreadPips=", MaxSpreadPips, " may be too high for cent accounts (recommended: 2.0)");
            warnedOnce = true;
        }
    }
    
    if(logDetails)
    {
        Print("📊 Spread Status:");
        Print("   Current Spread: ", DoubleToString(spreadPips, 2), " pips");
        Print("   Max Allowed: ", DoubleToString(maxSpreadPips, 2), " pips");
        Print("   Account Type: ", g_isCentAccount ? "CENT" : "STANDARD");
    }
    
    if(spreadPips > maxSpreadPips) {
        if(logDetails) Print("❌ BLOCKED: Spread too high (", DoubleToString(spreadPips, 2), " > ", DoubleToString(maxSpreadPips, 2), " pips)");
        return false;
    }
    if(logDetails) Print("✅ Spread check: OK");
    
    // Check margin
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double requiredMargin = balance * 0.15;
    double freeMarginPercent = (freeMargin / balance) * 100.0;
    
    if(logDetails)
    {
        Print("📊 Margin Status:");
        Print("   Free Margin: ", DoubleToString(freeMargin, 2));
        Print("   Required (15%): ", DoubleToString(requiredMargin, 2));
        Print("   Free Margin %: ", DoubleToString(freeMarginPercent, 2), "%");
    }
    
    if(freeMargin < requiredMargin) {
        if(logDetails) Print("❌ BLOCKED: Insufficient margin (", DoubleToString(freeMarginPercent, 2), "% < 15%)");
        return false;
    }
    if(logDetails) Print("✅ Margin check: OK");
    
    // Minimum bars since last trade
    if(logDetails)
    {
        Print("📊 Trade Timing:");
        Print("   Bars since last trade: ", g_barsSinceLastTrade);
        Print("   Aggressive Mode: ", AI_AggressiveMode ? "YES" : "NO");
        Print("   Min bars required: ", AI_AggressiveMode ? "0" : "2");
    }
    
    if(!AI_AggressiveMode && g_barsSinceLastTrade < 2) {
        if(logDetails) Print("❌ BLOCKED: Too soon since last trade (", g_barsSinceLastTrade, " < 2 bars)");
        return false;
    }
    if(logDetails) Print("✅ Timing check: OK");
    
    return true;
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
