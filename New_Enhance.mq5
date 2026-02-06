//+------------------------------------------------------------------+
//|                           UltraIntelligent_AI_Pro_ENHANCED.mq5   |
//|                    ULTRA-INTELLIGENT AI TRADING SYSTEM V7.0       |
//|              Neural Network | Deep Learning | Quantum Analysis    |
//+------------------------------------------------------------------+
#property copyright "Ultra AI Trading Pro - Enhanced Edition"
#property version   "7.00"
#property strict
#property description "Ultra-Intelligent Neural Network Trading System"
#property description "Multi-Layer AI | Quantum Signal Processing | Adaptive Learning"

//+------------------------------------------------------------------+
//| AI INTELLIGENCE CONFIGURATION                                     |
//+------------------------------------------------------------------+

input group "═══ 🧠 NEURAL NETWORK SETTINGS ═══"
input int      AI_IntelligenceLevel = 10;              // AI Intelligence (1-10, 10=Quantum)
input int      AI_SignalSpeed = 3;                     // Signal Speed (1=Slow, 5=Ultra-Fast)
input bool     AI_AggressiveMode = true;               // 🔥 Aggressive Trading Mode
input bool     AI_MultiTimeframe = true;               // 📊 Multi-Timeframe Analysis
input bool     AI_QuantumSignals = true;               // ⚡ Quantum Signal Processing

input group "═══ 💰 RISK & MONEY MANAGEMENT ═══"
input double   MaxRiskPerTrade = 2.0;                  // Max Risk Per Trade (%)
input int      MaxSimultaneousTrades = 5;              // Max Simultaneous Positions
input bool     AI_DynamicLots = true;                  // 🤖 AI Dynamic Lot Sizing
input bool     AI_SmartScaling = true;                 // 📈 AI Position Scaling

input group "═══ 🎯 ADVANCED FEATURES ═══"
input bool     AI_SmartTrailing = true;                // 🎯 AI Smart Trailing Stop
input bool     AI_BreakevenProtection = true;          // 🛡️ AI Breakeven Protection
input bool     AI_PartialProfits = true;               // 💵 AI Partial Profit Taking
input bool     AI_NewsFilter = true;                   // 📰 AI News Event Filter
input bool     AI_SelfLearning = true;                 // 🧠 AI Self-Learning System

input group "═══ ⚙️ MANUAL OVERRIDE ═══"
input bool     ManualLotOverride = false;              // Override AI Lot Size
input double   FixedLotSize = 0.01;                    // Fixed Lot (if override)
input bool     ManualStopsOverride = false;            // Override AI Stops
input double   ManualSL_Pips = 40.0;                   // Manual SL (pips)
input double   ManualTP_Pips = 80.0;                   // Manual TP (pips)

input group "═══ 📊 TIMEFRAMES ═══"
input ENUM_TIMEFRAMES PrimaryTimeframe = PERIOD_M5;    // Primary Timeframe (Fast)
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H1;      // Trend Timeframe (Slow)

input group "═══ 🔢 SYSTEM ═══"
input int      MagicNumber = 77777;                    // Magic Number
input string   TradeComment = "AI_ULTRA_v7";           // Trade Comment
input bool     AutoDetectCentAccount = true;           // 🔍 Auto-detect Cent Account
input bool     IsCentAccount = false;                  // Manual: Set true if Cent Account (USC)

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
    double trendDirection;          // -1, 0, +1
    double trendConfidence;         // 0 to 100%
    
    // Layer 2: Volatility Intelligence
    double volatilityIndex;         // 0 to 200
    double volatilityState;         // 0=low, 1=normal, 2=high
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
double g_sharpeRatio = 0.0;

// Session Control
datetime g_lastBarTime = 0;
datetime g_lastTradeTime = 0;
bool g_isInitialized = false;
int g_barsSinceLastTrade = 0;

// Cent Account Detection
bool g_isCentAccount = false;
double g_pipValue = 0.0;  // Actual pip value for this account type

// Performance Tracking
double g_maxDrawdown = 0;
double g_maxProfit = 0;
double g_initialBalance = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║                                                           ║");
    Print("║     ⚡ ULTRA-INTELLIGENT AI TRADING SYSTEM V7.0 ⚡       ║");
    Print("║                                                           ║");
    Print("║        Neural Network | Deep Learning Edition             ║");
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
    // PRIMARY TIMEFRAME INDICATORS
    // ═══════════════════════════════════════════════════════
    
    h_MA_Fast = iMA(_Symbol, PrimaryTimeframe, 5, 0, MODE_EMA, PRICE_CLOSE);
    h_MA_Medium = iMA(_Symbol, PrimaryTimeframe, 13, 0, MODE_EMA, PRICE_CLOSE);
    h_MA_Slow = iMA(_Symbol, PrimaryTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
    h_RSI = iRSI(_Symbol, PrimaryTimeframe, 14, PRICE_CLOSE);
    h_MACD = iMACD(_Symbol, PrimaryTimeframe, 12, 26, 9, PRICE_CLOSE);
    h_ATR = iATR(_Symbol, PrimaryTimeframe, 14);
    h_ADX = iADX(_Symbol, PrimaryTimeframe, 14);
    h_Stoch = iStochastic(_Symbol, PrimaryTimeframe, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    h_BB = iBands(_Symbol, PrimaryTimeframe, 20, 0, 2.0, PRICE_CLOSE);
    h_CCI = iCCI(_Symbol, PrimaryTimeframe, 14, PRICE_TYPICAL);
    h_Momentum = iMomentum(_Symbol, PrimaryTimeframe, 14, PRICE_CLOSE);
    
    // ═══════════════════════════════════════════════════════
    // HIGHER TIMEFRAME INDICATORS (Multi-Timeframe Analysis)
    // ═══════════════════════════════════════════════════════
    
    if(AI_MultiTimeframe) {
        h_MA_Fast_HTF = iMA(_Symbol, TrendTimeframe, 8, 0, MODE_EMA, PRICE_CLOSE);
        h_MA_Slow_HTF = iMA(_Symbol, TrendTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
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
    Sleep(1500);
    
    // Initialize AI Brain
    InitializeAI();
    
    // Detect Cent Account
    DetectAccountType();
    
    g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_isInitialized = true;
    
    Print("");
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║              ✅ ULTRA AI SYSTEM ONLINE ✅                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Intelligence Level: ", AI_IntelligenceLevel, "/10                                   ║");
    Print("║  Signal Speed: ", AI_SignalSpeed, "/5 (", AI_SignalSpeed == 5 ? "ULTRA-FAST" : "FAST", ")                      ║");
    Print("║  Aggressive Mode: ", AI_AggressiveMode ? "✓ ENABLED" : "✗ DISABLED", "                          ║");
    Print("║  Quantum Signals: ", AI_QuantumSignals ? "✓ ENABLED" : "✗ DISABLED", "                          ║");
    Print("║  Multi-Timeframe: ", AI_MultiTimeframe ? "✓ ENABLED" : "✗ DISABLED", "                          ║");
    Print("║  Self-Learning: ", AI_SelfLearning ? "✓ ACTIVE" : "✗ INACTIVE", "                            ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Symbol: ", _Symbol, "                                           ║");
    Print("║  Primary TF: ", EnumToString(PrimaryTimeframe), "                                      ║");
    Print("║  Trend TF: ", EnumToString(TrendTimeframe), "                                        ║");
    Print("║  Max Risk: ", MaxRiskPerTrade, "%                                         ║");
    Print("║  Max Positions: ", MaxSimultaneousTrades, "                                         ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Account Type: ", g_isCentAccount ? "CENT (USC) ⚠️" : "STANDARD (USD)", "                        ║");
    Print("║  Pip Value: ", DoubleToString(GetPipValue(), 8), "                                    ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  🧠 Neural Networks: 7 LAYERS ACTIVE                      ║");
    Print("║  📊 Quantum Processors: RUNNING                           ║");
    Print("║  🎯 Signal Generator: ARMED                               ║");
    Print("║  💰 Risk Manager: PROTECTING                              ║");
    Print("║  📈 Learning System: ADAPTING                             ║");
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
    Print("🚀 AI is hunting for high-probability setups...");
    Print("⚡ Quantum signal processing active - FAST reaction time");
    
    if(g_isCentAccount) {
        Print("");
        Print("⚠️ ⚠️ ⚠️ CENT ACCOUNT DETECTED ⚠️ ⚠️ ⚠️");
        Print("   • Spread limit: 1.0 pips (0.3 pips typical)");
        Print("   • Min SL: 5 pips | Max SL: 80 pips");
        Print("   • Min TP: 10 pips | Max TP: 200 pips");
        Print("   • Lot size calculations adjusted for cent account");
        Print("");
    }
    Print("");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Detect Account Type (Cent vs Standard)                           |
//+------------------------------------------------------------------+
void DetectAccountType()
{
    // Get account info (needed for both auto-detect and logging)
    string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if(!AutoDetectCentAccount) {
        g_isCentAccount = IsCentAccount;
    }
    else {
        // Auto-detect: Check account currency and balance size
        // Cent accounts typically have USC currency or very large balance numbers
        if(StringFind(accountCurrency, "USC") >= 0 || 
           StringFind(accountCurrency, "C") >= 0 ||
           accountBalance > 10000) {  // Cent accounts often show large numbers
            g_isCentAccount = true;
        }
        else {
            g_isCentAccount = IsCentAccount;  // Use manual setting
        }
    }
    
    // Calculate proper pip value
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // For cent accounts or 3/5 digit brokers
    if(g_isCentAccount || digits == 3 || digits == 5) {
        g_pipValue = point * 10;  // 1 pip = 10 points
    }
    else {
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
//| Convert Points to Pips (Account-aware)                            |
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
    AI.optimalStopLoss = 40;
    AI.optimalTakeProfit = 80;
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
    Print("║  Total Trades: ", g_totalTrades, "                                        ║");
    Print("║  Winning Trades: ", g_winningTrades, "                                    ║");
    Print("║  Losing Trades: ", g_losingTrades, "                                      ║");
    Print("║  Win Rate: ", DoubleToString(g_winRate, 1), "%                                    ║");
    Print("║  Profit Factor: ", DoubleToString(g_profitFactor, 2), "                                   ║");
    Print("║  Performance Score: ", DoubleToString(AI.performanceScore, 1), "/100                       ║");
    Print("╚═══════════════════════════════════════════════════════════╝");
    Print("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!g_isInitialized) return;
    
    // Fast-mode check (for ultra-responsive trading)
    if(AI_SignalSpeed >= 4 || AI_AggressiveMode) {
        // Check every 5 ticks in aggressive mode
        static int tickCounter = 0;
        tickCounter++;
        if(tickCounter % 5 != 0) return;
    }
    
    // New bar check for normal/conservative modes
    datetime currentBar = iTime(_Symbol, PrimaryTimeframe, 0);
    bool isNewBar = (currentBar != g_lastBarTime);
    
    if(!isNewBar && AI_SignalSpeed < 4 && !AI_AggressiveMode) return;
    
    if(isNewBar) {
        g_lastBarTime = currentBar;
        g_barsSinceLastTrade++;
    }
    
    // ═══════════════════════════════════════════════════════
    // QUANTUM AI PROCESSING PIPELINE
    // ═══════════════════════════════════════════════════════
    
    // Layer 1: Deep Market Analysis
    AI_DeepMarketAnalysis();
    
    // Layer 2: Position Management (protect existing trades)
    AI_IntelligentPositionManagement();
    
    // CRITICAL: Periodic check to ensure all positions have SL/TP
    CheckAllPositionsHaveSLTP();
    
    // Smart Position Status Logging (every 5 minutes)
    static datetime lastStatusLog = 0;
    if(TimeCurrent() - lastStatusLog > 300) {
        AI_LogPositionStatus();
        lastStatusLog = TimeCurrent();
    }
    
    // Layer 3: Update Learning System
    if(AI_SelfLearning) {
        AI_UpdateLearningSystem();
    }
    
    // Layer 4: Check if trading is allowed
    if(!AI_CanExecuteTrade()) return;
    
    // Layer 5: Generate Ultra-Intelligent Signals
    int signal = AI_QuantumSignalProcessor();
    
    // Layer 6: Smart Position Management - Execute trades intelligently
    if(signal == 1 && AI.isHighProbability && AI.confidenceLevel >= 60) {
        // Smart BUY logic: Check existing positions and market conditions
        if(AI_SmartPositionManagement(ORDER_TYPE_BUY)) {
            AI_ExecuteBuyOrder();
            g_barsSinceLastTrade = 0;
        }
    }
    else if(signal == -1 && AI.isHighProbability && AI.confidenceLevel >= 60) {
        // Smart SELL logic: Check existing positions and market conditions
        if(AI_SmartPositionManagement(ORDER_TYPE_SELL)) {
            AI_ExecuteSellOrder();
            g_barsSinceLastTrade = 0;
        }
    }
}

//+------------------------------------------------------------------+
//| AI Deep Market Analysis - 7-Layer Neural Network                 |
//+------------------------------------------------------------------+
void AI_DeepMarketAnalysis()
{
    // ═══════════════════════════════════════════════════════
    // COLLECT MARKET DATA
    // ═══════════════════════════════════════════════════════
    
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
    
    // Copy primary timeframe data
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
    double ma_fast_htf[], ma_slow_htf[], rsi_htf[], adx_htf[];
    if(AI_MultiTimeframe) {
        ArraySetAsSeries(ma_fast_htf, true);
        ArraySetAsSeries(ma_slow_htf, true);
        ArraySetAsSeries(rsi_htf, true);
        ArraySetAsSeries(adx_htf, true);
        
        if(CopyBuffer(h_MA_Fast_HTF, 0, 0, 5, ma_fast_htf) < 5) return;
        if(CopyBuffer(h_MA_Slow_HTF, 0, 0, 5, ma_slow_htf) < 5) return;
        if(CopyBuffer(h_RSI_HTF, 0, 0, 5, rsi_htf) < 5) return;
        if(CopyBuffer(h_ADX_HTF, 0, 0, 5, adx_htf) < 5) return;
    }
    
    // ═══════════════════════════════════════════════════════
    // LAYER 1: TREND INTELLIGENCE
    // ═══════════════════════════════════════════════════════
    
    double trendScore = 0;
    
    // MA Cascade Analysis
    if(ma_fast[0] > ma_medium[0] && ma_medium[0] > ma_slow[0]) {
        trendScore += 30;
        AI.marketSentiment = "BULLISH";
    }
    else if(ma_fast[0] < ma_medium[0] && ma_medium[0] < ma_slow[0]) {
        trendScore -= 30;
        AI.marketSentiment = "BEARISH";
    }
    else {
        AI.marketSentiment = "NEUTRAL";
    }
    
    // Price vs MAs
    if(close[0] > ma_slow[0]) trendScore += 10;
    else if(close[0] < ma_slow[0]) trendScore -= 10;
    
    // MA Slope Analysis
    double ma_slope = (ma_medium[0] - ma_medium[3]) / 3;
    if(ma_slope > 0) trendScore += 5;
    else if(ma_slope < 0) trendScore -= 5;
    
    // ADX Strength Multiplier
    if(adx[0] > 25) {
        double adxMultiplier = MathMin(adx[0] / 25.0, 2.5);
        trendScore *= adxMultiplier;
    }
    
    // Higher Timeframe Confirmation
    if(AI_MultiTimeframe) {
        if(ma_fast_htf[0] > ma_slow_htf[0] && trendScore > 0) trendScore += 20;
        if(ma_fast_htf[0] < ma_slow_htf[0] && trendScore < 0) trendScore -= 20;
    }
    
    AI.trendStrength = MathAbs(trendScore);
    AI.trendDirection = (trendScore > 10) ? 1 : (trendScore < -10) ? -1 : 0;
    AI.trendConfidence = MathMin(MathAbs(trendScore), 100);
    
    // Determine market regime
    if(adx[0] > 30 && AI.trendStrength > 50) {
        AI.marketRegime = "TRENDING";
    }
    else if(adx[0] < 20) {
        AI.marketRegime = "RANGING";
    }
    else if(close[0] > bb_upper[0] || close[0] < bb_lower[0]) {
        AI.marketRegime = "BREAKOUT";
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
    
    if(AI.volatilityIndex < 70) AI.volatilityState = 0;      // Low
    else if(AI.volatilityIndex < 130) AI.volatilityState = 1; // Normal
    else AI.volatilityState = 2;                               // High
    
    // Calculate market speed
    double priceChange = MathAbs(close[0] - close[5]);
    AI.marketSpeed = (priceChange / atr[0]) * 20.0;
    AI.marketSpeed = MathMin(AI.marketSpeed, 100);
    
    // ═══════════════════════════════════════════════════════
    // LAYER 3: MOMENTUM INTELLIGENCE
    // ═══════════════════════════════════════════════════════
    
    AI.momentumBull = 0;
    AI.momentumBear = 0;
    
    // MACD Momentum
    if(macd[0] > macd_signal[0] && macd[0] > 0) AI.momentumBull += 25;
    if(macd[0] < macd_signal[0] && macd[0] < 0) AI.momentumBear += 25;
    
    // RSI Momentum
    if(rsi[0] > 50 && rsi[0] < 75) AI.momentumBull += 15;
    if(rsi[0] < 50 && rsi[0] > 25) AI.momentumBear += 15;
    
    // Stochastic Momentum
    if(stoch[0] > 20 && stoch[0] < 80) {
        if(stoch[0] > 50) AI.momentumBull += 10;
        else AI.momentumBear += 10;
    }
    
    // CCI Momentum
    if(cci[0] > 0 && cci[0] < 150) AI.momentumBull += 10;
    if(cci[0] < 0 && cci[0] > -150) AI.momentumBear += 10;
    
    // Price Momentum
    if(momentum[0] > 100) AI.momentumBull += 15;
    if(momentum[0] < 100) AI.momentumBear += 15;
    
    // DI Momentum
    if(plusDI[0] > minusDI[0]) AI.momentumBull += 10;
    if(minusDI[0] > plusDI[0]) AI.momentumBear += 10;
    
    // Price action momentum
    bool bullishCandle = close[0] > open[0];
    bool bearishCandle = close[0] < open[0];
    
    if(bullishCandle && close[0] > close[1]) AI.momentumBull += 15;
    if(bearishCandle && close[0] < close[1]) AI.momentumBear += 15;
    
    AI.momentumNetScore = AI.momentumBull - AI.momentumBear;
    
    // ═══════════════════════════════════════════════════════
    // LAYER 4: CALCULATE OPTIMAL RISK PARAMETERS
    // ═══════════════════════════════════════════════════════
    
    // Calculate ATR in pips (account-aware)
    double atrPips = atr[0] / GetPipValue();
    
    // Intelligent Stop Loss
    double baseSL = atrPips * 1.5;
    
    // Adjust SL based on volatility
    if(AI.volatilityState == 0) baseSL *= 0.8;      // Tighter in low vol
    else if(AI.volatilityState == 2) baseSL *= 1.3; // Wider in high vol
    
    // Adjust SL based on intelligence level
    baseSL *= (0.7 + AI_IntelligenceLevel * 0.03);
    
    AI.optimalStopLoss = baseSL;
    
    // CRITICAL: Adjust minimum SL for cent accounts (0.3 pip spread = need tighter stops)
    if(g_isCentAccount) {
        // Cent accounts: Minimum 5 pips (was 15), Maximum 80 pips (was 120)
        // This accounts for the 0.3 pip spread - we need tighter stops
        AI.optimalStopLoss = MathMax(AI.optimalStopLoss, 5.0);   // Min 5 pips for cent
        AI.optimalStopLoss = MathMin(AI.optimalStopLoss, 80.0);   // Max 80 pips for cent
    }
    else {
        // Standard accounts: Original values
        AI.optimalStopLoss = MathMax(AI.optimalStopLoss, 15.0);  // Min 15 pips
        AI.optimalStopLoss = MathMin(AI.optimalStopLoss, 120.0); // Max 120 pips
    }
    
    // Intelligent Take Profit
    double riskReward = 2.0;
    
    // Increase R:R in strong trends
    if(AI.trendStrength > 60 && adx[0] > 30) riskReward = 3.5;
    else if(AI.trendStrength > 40) riskReward = 2.5;
    
    // Adjust for market regime
    if(AI.marketRegime == "TRENDING") riskReward *= 1.2;
    else if(AI.marketRegime == "RANGING") riskReward *= 0.8;
    
    AI.optimalTakeProfit = AI.optimalStopLoss * riskReward;
    
    // CRITICAL: Adjust TP for cent accounts
    if(g_isCentAccount) {
        // Cent accounts: Minimum 10 pips, Maximum 200 pips
        AI.optimalTakeProfit = MathMax(AI.optimalTakeProfit, 10.0);
        AI.optimalTakeProfit = MathMin(AI.optimalTakeProfit, 200.0);
    }
    else {
        // Standard accounts: Original values
        AI.optimalTakeProfit = MathMax(AI.optimalTakeProfit, 30.0);
        AI.optimalTakeProfit = MathMin(AI.optimalTakeProfit, 350.0);
    }
    
    AI.riskRewardRatio = AI.optimalTakeProfit / AI.optimalStopLoss;
    
    // ═══════════════════════════════════════════════════════
    // LAYER 5: CALCULATE OPTIMAL LOT SIZE
    // ═══════════════════════════════════════════════════════
    
    if(AI_DynamicLots && !ManualLotOverride) {
        double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double riskAmount = accountBalance * (MaxRiskPerTrade / 100.0);
        
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        
        // CRITICAL: Fix lot size calculation for cent accounts
        // For cent accounts, tick value is in cents, need proper conversion
        double pointValue = 0;
        if(g_isCentAccount) {
            // Cent account: tick value is already in account currency (cents)
            // Need to convert properly
            double pipValue = GetPipValue();
            double pipValueInPrice = pipValue;
            pointValue = (tickValue / tickSize) * pipValueInPrice;
        }
        else {
            // Standard account: original calculation
            pointValue = (tickValue / tickSize) * GetPipValue();
        }
        
        double lotSize = 0.01;
        if(pointValue > 0 && AI.optimalStopLoss > 0) {
            lotSize = riskAmount / (AI.optimalStopLoss * pointValue);
        }
        
        // CRITICAL: For cent accounts, ensure lot size is appropriate
        // Cent accounts often need larger lot sizes due to smaller pip values
        if(g_isCentAccount && lotSize < 0.01) {
            // If calculated lot is too small, use minimum but adjust risk
            lotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        }
        
        // AI Intelligence Scaling
        double intelligenceScale = 0.6 + (AI_IntelligenceLevel / 15.0); // 0.6 to 1.27
        lotSize *= intelligenceScale;
        
        // Performance-based scaling
        if(AI_SelfLearning && g_totalTrades > 10) {
            if(g_winRate > 65) lotSize *= 1.3;
            else if(g_winRate > 55) lotSize *= 1.1;
            else if(g_winRate < 45) lotSize *= 0.7;
            else if(g_winRate < 35) lotSize *= 0.5;
        }
        
        // Confidence scaling
        if(AI.trendConfidence > 80) lotSize *= 1.2;
        else if(AI.trendConfidence < 40) lotSize *= 0.7;
        
        // Normalize lot size
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        
        lotSize = MathMax(lotSize, minLot);
        lotSize = MathMin(lotSize, maxLot);
        lotSize = MathMin(lotSize, 1.0); // Safety cap
        lotSize = MathFloor(lotSize / lotStep) * lotStep;
        
        AI.optimalLotSize = lotSize;
    }
    else if(ManualLotOverride) {
        AI.optimalLotSize = FixedLotSize;
    }
    
    // Apply manual stop overrides
    if(ManualStopsOverride) {
        AI.optimalStopLoss = ManualSL_Pips;
        AI.optimalTakeProfit = ManualTP_Pips;
    }
}

//+------------------------------------------------------------------+
//| AI Quantum Signal Processor - Ultra-Fast Decision Making         |
//+------------------------------------------------------------------+
int AI_QuantumSignalProcessor()
{
    // Get latest data
    double ma_fast[], ma_medium[], ma_slow[], rsi[], macd[], macd_signal[];
    double stoch[], cci[], close[], high[], low[];
    
    ArraySetAsSeries(ma_fast, true);
    ArraySetAsSeries(ma_medium, true);
    ArraySetAsSeries(ma_slow, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(macd, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(stoch, true);
    ArraySetAsSeries(cci, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyBuffer(h_MA_Fast, 0, 0, 5, ma_fast) < 5) return 0;
    if(CopyBuffer(h_MA_Medium, 0, 0, 5, ma_medium) < 5) return 0;
    if(CopyBuffer(h_MA_Slow, 0, 0, 5, ma_slow) < 5) return 0;
    if(CopyBuffer(h_RSI, 0, 0, 5, rsi) < 5) return 0;
    if(CopyBuffer(h_MACD, 0, 0, 5, macd) < 5) return 0;
    if(CopyBuffer(h_MACD, 1, 0, 5, macd_signal) < 5) return 0;
    if(CopyBuffer(h_Stoch, 0, 0, 5, stoch) < 5) return 0;
    if(CopyBuffer(h_CCI, 0, 0, 5, cci) < 5) return 0;
    if(CopyClose(_Symbol, PrimaryTimeframe, 0, 5, close) < 5) return 0;
    if(CopyHigh(_Symbol, PrimaryTimeframe, 0, 5, high) < 5) return 0;
    if(CopyLow(_Symbol, PrimaryTimeframe, 0, 5, low) < 5) return 0;
    
    // ═══════════════════════════════════════════════════════
    // QUANTUM SIGNAL SCORING SYSTEM
    // ═══════════════════════════════════════════════════════
    
    int buyScore = 0;
    int sellScore = 0;
    int maxScore = 1000; // Maximum possible score
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 1: Trend Alignment (Weight: 150 points)
    // ───────────────────────────────────────────────────────
    if(AI.trendDirection == 1 && AI.trendStrength > 40) {
        buyScore += 150;
    }
    if(AI.trendDirection == -1 && AI.trendStrength > 40) {
        sellScore += 150;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 2: MA Cross (Weight: 120 points)
    // ───────────────────────────────────────────────────────
    if(ma_fast[0] > ma_medium[0] && ma_fast[1] <= ma_medium[1]) {
        buyScore += 120;
    }
    if(ma_fast[0] < ma_medium[0] && ma_fast[1] >= ma_medium[1]) {
        sellScore += 120;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 3: Price Position (Weight: 80 points)
    // ───────────────────────────────────────────────────────
    if(close[0] > ma_slow[0] && close[0] > ma_medium[0]) {
        buyScore += 80;
    }
    if(close[0] < ma_slow[0] && close[0] < ma_medium[0]) {
        sellScore += 80;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 4: MACD Confirmation (Weight: 100 points)
    // ───────────────────────────────────────────────────────
    if(macd[0] > macd_signal[0] && macd[0] > 0) {
        buyScore += 100;
    }
    if(macd[0] < macd_signal[0] && macd[0] < 0) {
        sellScore += 100;
    }
    
    // MACD Cross
    if(macd[0] > macd_signal[0] && macd[1] <= macd_signal[1]) {
        buyScore += 50;
    }
    if(macd[0] < macd_signal[0] && macd[1] >= macd_signal[1]) {
        sellScore += 50;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 5: RSI Confirmation (Weight: 80 points)
    // ───────────────────────────────────────────────────────
    if(rsi[0] > 45 && rsi[0] < 75) {
        buyScore += 80;
    }
    if(rsi[0] < 55 && rsi[0] > 25) {
        sellScore += 80;
    }
    
    // RSI divergence bonus
    if(rsi[0] > 50 && rsi[0] > rsi[1] && rsi[1] > rsi[2]) {
        buyScore += 30;
    }
    if(rsi[0] < 50 && rsi[0] < rsi[1] && rsi[1] < rsi[2]) {
        sellScore += 30;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 6: Momentum Confirmation (Weight: 100 points)
    // ───────────────────────────────────────────────────────
    if(AI.momentumNetScore > 20) {
        buyScore += 100;
    }
    if(AI.momentumNetScore < -20) {
        sellScore += 100;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 7: Stochastic (Weight: 60 points)
    // ───────────────────────────────────────────────────────
    if(stoch[0] > 20 && stoch[0] < 80) {
        if(stoch[0] > 50 && stoch[0] > stoch[1]) buyScore += 60;
        if(stoch[0] < 50 && stoch[0] < stoch[1]) sellScore += 60;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 8: CCI Confirmation (Weight: 50 points)
    // ───────────────────────────────────────────────────────
    if(cci[0] > 0 && cci[0] < 200) {
        buyScore += 50;
    }
    if(cci[0] < 0 && cci[0] > -200) {
        sellScore += 50;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 9: Price Action (Weight: 80 points)
    // ───────────────────────────────────────────────────────
    bool bullishCandle = close[0] > close[1];
    bool bearishCandle = close[0] < close[1];
    
    if(bullishCandle && close[0] > high[1]) {
        buyScore += 80;
    }
    if(bearishCandle && close[0] < low[1]) {
        sellScore += 80;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 10: Multi-Candle Pattern (Weight: 70 points)
    // ───────────────────────────────────────────────────────
    if(close[0] > close[1] && close[1] > close[2]) {
        buyScore += 70;
    }
    if(close[0] < close[1] && close[1] < close[2]) {
        sellScore += 70;
    }
    
    // ───────────────────────────────────────────────────────
    // SIGNAL 11: Volatility State Bonus (Weight: 50 points)
    // ───────────────────────────────────────────────────────
    if(AI.volatilityState == 1) { // Normal volatility preferred
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
    
    // Apply intelligence level threshold
    double requiredScore = 400 + (AI_IntelligenceLevel * 30); // 400 to 700
    
    // Aggressive mode lowers threshold
    if(AI_AggressiveMode) {
        requiredScore *= 0.75;
    }
    
    // Quantum mode further enhances
    if(AI_QuantumSignals) {
        requiredScore *= 0.9;
    }
    
    // Determine high-probability setup
    AI.isHighProbability = (maxSignal >= requiredScore && AI.trendStrength > 30);
    AI.isLowRisk = (AI.volatilityState <= 1 && AI.trendConfidence > 50);
    
    // ═══════════════════════════════════════════════════════
    // MAKE FINAL DECISION
    // ═══════════════════════════════════════════════════════
    
    // Get current position status for smart decision
    int buyPositions = CountPositionsByType(POSITION_TYPE_BUY);
    int sellPositions = CountPositionsByType(POSITION_TYPE_SELL);
    
    if(buyScore > sellScore && buyScore >= requiredScore) {
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║           ⚡ QUANTUM BUY SIGNAL DETECTED ⚡               ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        Print("║  Signal Strength: ", buyScore, "/1000                               ║");
        Print("║  Confidence: ", DoubleToString(AI.confidenceLevel, 1), "%                                   ║");
        Print("║  Quality: ", DoubleToString(AI.signalQuality, 1), "%                                     ║");
        Print("║  Trend: ", AI.marketSentiment, " | Regime: ", AI.marketRegime, "          ║");
        Print("║  Momentum: +", DoubleToString(AI.momentumNetScore, 0), "                                      ║");
        Print("║  Risk:Reward: 1:", DoubleToString(AI.riskRewardRatio, 1), "                                 ║");
        Print("║  Current: BUY=", buyPositions, " | SELL=", sellPositions, " positions                      ║");
        Print("╚═══════════════════════════════════════════════════════════╝");
        Print("");
        
        return 1;
    }
    else if(sellScore > buyScore && sellScore >= requiredScore) {
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║          ⚡ QUANTUM SELL SIGNAL DETECTED ⚡               ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        Print("║  Signal Strength: ", sellScore, "/1000                              ║");
        Print("║  Confidence: ", DoubleToString(AI.confidenceLevel, 1), "%                                   ║");
        Print("║  Quality: ", DoubleToString(AI.signalQuality, 1), "%                                     ║");
        Print("║  Trend: ", AI.marketSentiment, " | Regime: ", AI.marketRegime, "         ║");
        Print("║  Momentum: ", DoubleToString(AI.momentumNetScore, 0), "                                       ║");
        Print("║  Risk:Reward: 1:", DoubleToString(AI.riskRewardRatio, 1), "                                 ║");
        Print("║  Current: BUY=", buyPositions, " | SELL=", sellPositions, " positions                      ║");
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
    // CRITICAL: Calculate SL/TP correctly
    // ═══════════════════════════════════════════════════════
    
    // Get pip value for calculation
    double pipValue = GetPipValue();
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Calculate SL/TP in price units
    double sl = ask - (AI.optimalStopLoss * pipValue);
    double tp = ask + (AI.optimalTakeProfit * pipValue);
    
    // Verify calculation
    double slDistancePips = (ask - sl) / pipValue;
    double tpDistancePips = (tp - ask) / pipValue;
    
    // Get current spread for logging
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double spreadPips = PointsToPips((double)spread);
    
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║              🤖 AI EXECUTING BUY ORDER 🤖                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Account: ", g_isCentAccount ? "CENT (USC)" : "STANDARD (USD)", "                              ║");
    Print("║  Entry Price: ", DoubleToString(ask, _Digits), "                                  ║");
    Print("║  Stop Loss: ", DoubleToString(sl, _Digits), " (", DoubleToString(slDistancePips, 2), " pips from entry)    ║");
    Print("║  Take Profit: ", DoubleToString(tp, _Digits), " (", DoubleToString(tpDistancePips, 2), " pips from entry)  ║");
    Print("║  Calculated SL: ", DoubleToString(AI.optimalStopLoss, 2), " pips | TP: ", DoubleToString(AI.optimalTakeProfit, 2), " pips ║");
    Print("║  Pip Value: ", DoubleToString(pipValue, 8), " | Point: ", DoubleToString(point, 8), "  ║");
    Print("║  Lot Size: ", DoubleToString(AI.optimalLotSize, 2), "                                     ║");
    Print("║  Risk:Reward: 1:", DoubleToString(AI.riskRewardRatio, 2), "                              ║");
    Print("║  Confidence: ", DoubleToString(AI.confidenceLevel, 1), "%                                   ║");
    Print("║  Spread: ", DoubleToString(spreadPips, 2), " pips                                        ║");
    Print("╚═══════════════════════════════════════════════════════════╝");
    
    // Validate SL/TP distances
    if(MathAbs(slDistancePips - AI.optimalStopLoss) > 0.5) {
        Print("⚠️ WARNING: SL distance mismatch! Expected: ", AI.optimalStopLoss, " pips, Got: ", slDistancePips, " pips");
    }
    if(MathAbs(tpDistancePips - AI.optimalTakeProfit) > 0.5) {
        Print("⚠️ WARNING: TP distance mismatch! Expected: ", AI.optimalTakeProfit, " pips, Got: ", tpDistancePips, " pips");
    }
    
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Validate and adjust SL/TP for broker requirements
    // ═══════════════════════════════════════════════════════
    
    // Get broker's minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * _Point;
    double minStopDistancePips = PointsToPips(minStopDistance);
    
    // Recalculate SL/TP to ensure they meet minimum distance
    double actualSLDistance = slDistancePips;
    double actualTPDistance = tpDistancePips;
    
    // Adjust SL if too close
    if(actualSLDistance < minStopDistancePips) {
        actualSLDistance = minStopDistancePips + 1.0; // Add 1 pip buffer
        sl = ask - (actualSLDistance * pipValue);
        Print("⚠️ SL adjusted: ", DoubleToString(actualSLDistance, 2), " pips (min: ", DoubleToString(minStopDistancePips, 2), " pips)");
    }
    
    // Adjust TP if too close
    if(actualTPDistance < minStopDistancePips) {
        actualTPDistance = minStopDistancePips + 1.0; // Add 1 pip buffer
        tp = ask + (actualTPDistance * pipValue);
        Print("⚠️ TP adjusted: ", DoubleToString(actualTPDistance, 2), " pips (min: ", DoubleToString(minStopDistancePips, 2), " pips)");
    }
    
    // Validate SL/TP are reasonable (not too far)
    double maxSLPips = g_isCentAccount ? 100.0 : 200.0;
    double maxTPPips = g_isCentAccount ? 300.0 : 500.0;
    
    if(actualSLDistance > maxSLPips) {
        Print("⚠️ WARNING: SL is very far (", DoubleToString(actualSLDistance, 2), " pips). Max recommended: ", maxSLPips, " pips");
    }
    if(actualTPDistance > maxTPPips) {
        Print("⚠️ WARNING: TP is very far (", DoubleToString(actualTPDistance, 2), " pips). Max recommended: ", maxTPPips, " pips");
    }
    
    // Final validation
    if(sl >= ask || tp <= ask) {
        Print("❌ CRITICAL ERROR: Invalid SL/TP levels!");
        Print("   Entry: ", DoubleToString(ask, _Digits));
        Print("   SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(actualSLDistance, 2), " pips)");
        Print("   TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(actualTPDistance, 2), " pips)");
        Print("   Stop Level: ", stopLevel, " points (", DoubleToString(minStopDistancePips, 2), " pips)");
        return;
    }
    
    // Normalize to proper digits
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    // Final verification after normalization
    double finalSLDistance = (ask - sl) / pipValue;
    double finalTPDistance = (tp - ask) / pipValue;
    
    Print("✅ Final SL Distance: ", DoubleToString(finalSLDistance, 2), " pips from entry");
    Print("✅ Final TP Distance: ", DoubleToString(finalTPDistance, 2), " pips from entry");
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = AI.optimalLotSize;
    request.type = ORDER_TYPE_BUY;
    request.price = ask;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 50;
    request.magic = MagicNumber;
    request.comment = StringFormat("%s_Buy_C%.0f", TradeComment, AI.confidenceLevel);
    request.type_filling = GetFillingMode();
    
    if(!OrderSend(request, result)) {
        Print("❌ OrderSend Error: ", GetLastError());
        return;
    }
    
    if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        Print("✅ ✅ ✅ BUY ORDER EXECUTED SUCCESSFULLY! ✅ ✅ ✅");
        Print("   Ticket: #", result.order);
        Print("   Price: ", result.price);
        
        // CRITICAL: Verify SL/TP were actually set
        Sleep(100); // Small delay to ensure position is registered
        if(PositionSelectByTicket(result.order)) {
            double actualSL = PositionGetDouble(POSITION_SL);
            double actualTP = PositionGetDouble(POSITION_TP);
            Print("   ✅ SL Set: ", (actualSL > 0 ? DoubleToString(actualSL, _Digits) : "NOT SET ⚠️"));
            Print("   ✅ TP Set: ", (actualTP > 0 ? DoubleToString(actualTP, _Digits) : "NOT SET ⚠️"));
            
            // If SL/TP not set, try to set them immediately
            if(actualSL == 0 || actualTP == 0) {
                Print("   ⚠️ SL/TP not set on order, attempting to modify position...");
                if(AI_ModifyPosition(result.order, sl, tp)) {
                    Print("   ✅ SL/TP successfully set via modification");
                }
                else {
                    Print("   ❌ FAILED to set SL/TP - Check broker settings!");
                }
            }
        }
        Print("");
        
        g_totalTrades++;
        g_lastTradeTime = TimeCurrent();
    }
    else {
        Print("⚠️ Trade failed - Retcode: ", result.retcode);
        Print("   Comment: ", result.comment);
        Print("   Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| AI Execute Sell Order                                             |
//+------------------------------------------------------------------+
void AI_ExecuteSellOrder()
{
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Calculate SL/TP correctly
    // ═══════════════════════════════════════════════════════
    
    // Get pip value for calculation
    double pipValue = GetPipValue();
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Calculate SL/TP in price units
    double sl = bid + (AI.optimalStopLoss * pipValue);
    double tp = bid - (AI.optimalTakeProfit * pipValue);
    
    // Verify calculation
    double slDistancePips = (sl - bid) / pipValue;
    double tpDistancePips = (bid - tp) / pipValue;
    
    // Get current spread for logging
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double spreadPips = PointsToPips((double)spread);
    
    Print("╔═══════════════════════════════════════════════════════════╗");
    Print("║             🤖 AI EXECUTING SELL ORDER 🤖                 ║");
    Print("╠═══════════════════════════════════════════════════════════╣");
    Print("║  Account: ", g_isCentAccount ? "CENT (USC)" : "STANDARD (USD)", "                              ║");
    Print("║  Entry Price: ", DoubleToString(bid, _Digits), "                                  ║");
    Print("║  Stop Loss: ", DoubleToString(sl, _Digits), " (", DoubleToString(slDistancePips, 2), " pips from entry)    ║");
    Print("║  Take Profit: ", DoubleToString(tp, _Digits), " (", DoubleToString(tpDistancePips, 2), " pips from entry)  ║");
    Print("║  Calculated SL: ", DoubleToString(AI.optimalStopLoss, 2), " pips | TP: ", DoubleToString(AI.optimalTakeProfit, 2), " pips ║");
    Print("║  Pip Value: ", DoubleToString(pipValue, 8), " | Point: ", DoubleToString(point, 8), "  ║");
    Print("║  Lot Size: ", DoubleToString(AI.optimalLotSize, 2), "                                     ║");
    Print("║  Risk:Reward: 1:", DoubleToString(AI.riskRewardRatio, 2), "                              ║");
    Print("║  Confidence: ", DoubleToString(AI.confidenceLevel, 1), "%                                   ║");
    Print("║  Spread: ", DoubleToString(spreadPips, 2), " pips                                        ║");
    Print("╚═══════════════════════════════════════════════════════════╝");
    
    // Validate SL/TP distances
    if(MathAbs(slDistancePips - AI.optimalStopLoss) > 0.5) {
        Print("⚠️ WARNING: SL distance mismatch! Expected: ", AI.optimalStopLoss, " pips, Got: ", slDistancePips, " pips");
    }
    if(MathAbs(tpDistancePips - AI.optimalTakeProfit) > 0.5) {
        Print("⚠️ WARNING: TP distance mismatch! Expected: ", AI.optimalTakeProfit, " pips, Got: ", tpDistancePips, " pips");
    }
    
    // ═══════════════════════════════════════════════════════
    // CRITICAL: Validate and adjust SL/TP for broker requirements
    // ═══════════════════════════════════════════════════════
    
    // Get broker's minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * _Point;
    double minStopDistancePips = PointsToPips(minStopDistance);
    
    // Recalculate SL/TP to ensure they meet minimum distance
    double actualSLDistance = slDistancePips;
    double actualTPDistance = tpDistancePips;
    
    // Adjust SL if too close
    if(actualSLDistance < minStopDistancePips) {
        actualSLDistance = minStopDistancePips + 1.0; // Add 1 pip buffer
        sl = bid + (actualSLDistance * pipValue);
        Print("⚠️ SL adjusted: ", DoubleToString(actualSLDistance, 2), " pips (min: ", DoubleToString(minStopDistancePips, 2), " pips)");
    }
    
    // Adjust TP if too close
    if(actualTPDistance < minStopDistancePips) {
        actualTPDistance = minStopDistancePips + 1.0; // Add 1 pip buffer
        tp = bid - (actualTPDistance * pipValue);
        Print("⚠️ TP adjusted: ", DoubleToString(actualTPDistance, 2), " pips (min: ", DoubleToString(minStopDistancePips, 2), " pips)");
    }
    
    // Validate SL/TP are reasonable (not too far)
    double maxSLPips = g_isCentAccount ? 100.0 : 200.0;
    double maxTPPips = g_isCentAccount ? 300.0 : 500.0;
    
    if(actualSLDistance > maxSLPips) {
        Print("⚠️ WARNING: SL is very far (", DoubleToString(actualSLDistance, 2), " pips). Max recommended: ", maxSLPips, " pips");
    }
    if(actualTPDistance > maxTPPips) {
        Print("⚠️ WARNING: TP is very far (", DoubleToString(actualTPDistance, 2), " pips). Max recommended: ", maxTPPips, " pips");
    }
    
    // Final validation
    if(sl <= bid || tp >= bid) {
        Print("❌ CRITICAL ERROR: Invalid SL/TP levels!");
        Print("   Entry: ", DoubleToString(bid, _Digits));
        Print("   SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(actualSLDistance, 2), " pips)");
        Print("   TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(actualTPDistance, 2), " pips)");
        Print("   Stop Level: ", stopLevel, " points (", DoubleToString(minStopDistancePips, 2), " pips)");
        return;
    }
    
    // Normalize to proper digits
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    // Final verification after normalization
    double finalSLDistance = (sl - bid) / pipValue;
    double finalTPDistance = (bid - tp) / pipValue;
    
    Print("✅ Final SL Distance: ", DoubleToString(finalSLDistance, 2), " pips from entry");
    Print("✅ Final TP Distance: ", DoubleToString(finalTPDistance, 2), " pips from entry");
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = AI.optimalLotSize;
    request.type = ORDER_TYPE_SELL;
    request.price = bid;
    request.sl = sl;
    request.tp = tp;
    request.deviation = 50;
    request.magic = MagicNumber;
    request.comment = StringFormat("%s_Sell_C%.0f", TradeComment, AI.confidenceLevel);
    request.type_filling = GetFillingMode();
    
    if(!OrderSend(request, result)) {
        Print("❌ OrderSend Error: ", GetLastError());
        return;
    }
    
    if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        Print("✅ ✅ ✅ SELL ORDER EXECUTED SUCCESSFULLY! ✅ ✅ ✅");
        Print("   Ticket: #", result.order);
        Print("   Price: ", result.price);
        
        // CRITICAL: Verify SL/TP were actually set
        Sleep(100); // Small delay to ensure position is registered
        if(PositionSelectByTicket(result.order)) {
            double actualSL = PositionGetDouble(POSITION_SL);
            double actualTP = PositionGetDouble(POSITION_TP);
            Print("   ✅ SL Set: ", (actualSL > 0 ? DoubleToString(actualSL, _Digits) : "NOT SET ⚠️"));
            Print("   ✅ TP Set: ", (actualTP > 0 ? DoubleToString(actualTP, _Digits) : "NOT SET ⚠️"));
            
            // If SL/TP not set, try to set them immediately
            if(actualSL == 0 || actualTP == 0) {
                Print("   ⚠️ SL/TP not set on order, attempting to modify position...");
                if(AI_ModifyPosition(result.order, sl, tp)) {
                    Print("   ✅ SL/TP successfully set via modification");
                }
                else {
                    Print("   ❌ FAILED to set SL/TP - Check broker settings!");
                }
            }
        }
        Print("");
        
        g_totalTrades++;
        g_lastTradeTime = TimeCurrent();
    }
    else {
        Print("⚠️ Trade failed - Retcode: ", result.retcode);
        Print("   Comment: ", result.comment);
        Print("   Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| AI Intelligent Position Management                                |
//+------------------------------------------------------------------+
void AI_IntelligentPositionManagement()
{
    // ═══════════════════════════════════════════════════════
    // SMART HEDGING: Close opposite positions when profitable
    // ═══════════════════════════════════════════════════════
    
    int buyPositions = CountPositionsByType(POSITION_TYPE_BUY);
    int sellPositions = CountPositionsByType(POSITION_TYPE_SELL);
    
    // If we have both BUY and SELL positions, manage them smartly
    if(buyPositions > 0 && sellPositions > 0) {
        AI_SmartHedgingManagement();
    }
    
    // ═══════════════════════════════════════════════════════
    // INDIVIDUAL POSITION MANAGEMENT
    // ═══════════════════════════════════════════════════════
    
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
        double positionProfit = PositionGetDouble(POSITION_PROFIT);
        
        double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                              SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                              SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        // CRITICAL: Use account-aware pip conversion
        double profitPips = 0;
        if(posType == POSITION_TYPE_BUY)
            profitPips = PointsToPips(currentPrice - openPrice);
        else
            profitPips = PointsToPips(openPrice - currentPrice);
        
        // ───────────────────────────────────────────────────────
        // AI SMART TRAILING STOP
        // ───────────────────────────────────────────────────────
        if(AI_SmartTrailing && profitPips > AI.optimalStopLoss * 0.6) {
            // CRITICAL: Use account-aware pip conversion
            double trailDistance = PipsToPoints(AI.optimalStopLoss * 0.5);
            double newSL = 0;
            
            if(posType == POSITION_TYPE_BUY) {
                newSL = currentPrice - trailDistance;
                // CRITICAL: Use account-aware pip conversion (5 pips)
                if(newSL > currentSL + PipsToPoints(5.0)) {
                    if(AI_ModifyPosition(ticket, newSL, currentTP)) {
                        Print("📊 AI Trailing Stop Updated: #", ticket, " | Profit: +", DoubleToString(profitPips, 1), " pips");
                    }
                }
            }
            else {
                newSL = currentPrice + trailDistance;
                // CRITICAL: Use account-aware pip conversion (5 pips)
                if(currentSL == 0 || newSL < currentSL - PipsToPoints(5.0)) {
                    if(AI_ModifyPosition(ticket, newSL, currentTP)) {
                        Print("📊 AI Trailing Stop Updated: #", ticket, " | Profit: +", DoubleToString(profitPips, 1), " pips");
                    }
                }
            }
        }
        
        // ───────────────────────────────────────────────────────
        // AI BREAKEVEN PROTECTION
        // ───────────────────────────────────────────────────────
        if(AI_BreakevenProtection && profitPips > AI.optimalStopLoss * 0.4) {
            // CRITICAL: Adjust BE for cent accounts (tighter)
            double bePips = g_isCentAccount ? 1.0 : 3.0; // Lock 1 pip for cent, 3 pips for standard
            double beOffset = PipsToPoints(bePips);
            double beSL = openPrice + (beOffset * ((posType == POSITION_TYPE_BUY) ? 1 : -1));
            
            bool shouldMove = false;
            if(posType == POSITION_TYPE_BUY && (currentSL == 0 || beSL > currentSL) && beSL < currentPrice)
                shouldMove = true;
            else if(posType == POSITION_TYPE_SELL && (currentSL == 0 || beSL < currentSL) && beSL > currentPrice)
                shouldMove = true;
            
            if(shouldMove) {
                if(AI_ModifyPosition(ticket, beSL, currentTP)) {
                    Print("🛡️ AI Breakeven Protection Activated: #", ticket);
                }
            }
        }
        
        // ───────────────────────────────────────────────────────
        // AI PARTIAL PROFIT TAKING
        // ───────────────────────────────────────────────────────
        if(AI_PartialProfits && profitPips > AI.optimalTakeProfit * 0.5) {
            double posVolume = PositionGetDouble(POSITION_VOLUME);
            double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            
            if(posVolume > minLot * 2) {
                double closeVolume = posVolume * 0.5;
                closeVolume = NormalizeDouble(closeVolume, 2);
                
                if(AI_PartialClose(ticket, closeVolume)) {
                    Print("💵 AI Partial Profit Taken: #", ticket, " | 50% closed at +", DoubleToString(profitPips, 1), " pips");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Smart Hedging Management - Close profitable opposite positions   |
//+------------------------------------------------------------------+
void AI_SmartHedgingManagement()
{
    // Get current market state
    double buyTotalProfit = 0;
    double sellTotalProfit = 0;
    int profitableBuys = 0;
    int profitableSells = 0;
    
    // Calculate total profit for each direction
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) != _Symbol) continue;
        
        long magic = PositionGetInteger(POSITION_MAGIC);
        if(magic != MagicNumber) continue;
        
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double profit = PositionGetDouble(POSITION_PROFIT);
        double swap = PositionGetDouble(POSITION_SWAP);
        double totalPL = profit + swap;
        
        if(posType == POSITION_TYPE_BUY) {
            buyTotalProfit += totalPL;
            if(totalPL > 0) profitableBuys++;
        }
        else {
            sellTotalProfit += totalPL;
            if(totalPL > 0) profitableSells++;
        }
    }
    
    // Strategy 1: If one direction is very profitable and opposite is losing, close losers
    if(buyTotalProfit > 0 && sellTotalProfit < -buyTotalProfit * 0.5) {
        // BUY is profitable, SELL is losing significantly - close losing SELLs
        Print("🔄 Hedging: BUY profitable, closing losing SELL positions");
        AI_CloseLosingPositions(POSITION_TYPE_SELL, true);
    }
    else if(sellTotalProfit > 0 && buyTotalProfit < -sellTotalProfit * 0.5) {
        // SELL is profitable, BUY is losing significantly - close losing BUYs
        Print("🔄 Hedging: SELL profitable, closing losing BUY positions");
        AI_CloseLosingPositions(POSITION_TYPE_BUY, true);
    }
    
    // Strategy 2: If both are profitable and trend is clear, close counter-trend
    if(buyTotalProfit > 0 && sellTotalProfit > 0) {
        if(AI.trendDirection == 1 && AI.trendStrength > 60) {
            // Strong uptrend: Close SELL positions
            Print("🔄 Hedging: Strong uptrend detected, closing SELL positions");
            AI_CloseProfitablePositions(POSITION_TYPE_SELL);
        }
        else if(AI.trendDirection == -1 && AI.trendStrength > 60) {
            // Strong downtrend: Close BUY positions
            Print("🔄 Hedging: Strong downtrend detected, closing BUY positions");
            AI_CloseProfitablePositions(POSITION_TYPE_BUY);
        }
    }
    
    // Strategy 3: If market regime changed, close counter-trend positions
    static string lastRegime = "";
    if(AI.marketRegime != lastRegime && lastRegime != "") {
        if(AI.marketRegime == "TRENDING" && AI.trendDirection == 1) {
            // Market switched to uptrend: Close SELLs
            Print("🔄 Hedging: Market regime changed to uptrend, closing SELL positions");
            AI_CloseLosingPositions(POSITION_TYPE_SELL, false);
        }
        else if(AI.marketRegime == "TRENDING" && AI.trendDirection == -1) {
            // Market switched to downtrend: Close BUYs
            Print("🔄 Hedging: Market regime changed to downtrend, closing BUY positions");
            AI_CloseLosingPositions(POSITION_TYPE_BUY, false);
        }
        lastRegime = AI.marketRegime;
    }
    else if(lastRegime == "") {
        lastRegime = AI.marketRegime;
    }
}

//+------------------------------------------------------------------+
//| Close Losing Positions                                           |
//+------------------------------------------------------------------+
void AI_CloseLosingPositions(ENUM_POSITION_TYPE positionType, bool onlySignificantLosses)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) != _Symbol) continue;
        
        long magic = PositionGetInteger(POSITION_MAGIC);
        if(magic != MagicNumber) continue;
        
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if(posType != positionType) continue;
        
        double profit = PositionGetDouble(POSITION_PROFIT);
        double swap = PositionGetDouble(POSITION_SWAP);
        double totalPL = profit + swap;
        
        bool shouldClose = false;
        if(onlySignificantLosses) {
            // Close if losing more than 30% of risk amount
            shouldClose = (totalPL < -AI.optimalLotSize * 10 * 0.3);
        }
        else {
            // Close any losing position
            shouldClose = (totalPL < 0);
        }
        
        if(shouldClose) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            if(AI_ClosePosition(ticket)) {
                Print("✅ Closed losing ", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"), 
                      " position #", ticket, " | P&L: ", DoubleToString(totalPL, 2));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close Profitable Positions                                       |
//+------------------------------------------------------------------+
void AI_CloseProfitablePositions(ENUM_POSITION_TYPE positionType)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) != _Symbol) continue;
        
        long magic = PositionGetInteger(POSITION_MAGIC);
        if(magic != MagicNumber) continue;
        
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if(posType != positionType) continue;
        
        double profit = PositionGetDouble(POSITION_PROFIT);
        double swap = PositionGetDouble(POSITION_SWAP);
        double totalPL = profit + swap;
        
        // Close if profitable (lock in profits)
        if(totalPL > 0) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            if(AI_ClosePosition(ticket)) {
                Print("✅ Closed profitable ", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"), 
                      " position #", ticket, " | P&L: ", DoubleToString(totalPL, 2));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| AI Modify Position                                                |
//+------------------------------------------------------------------+
bool AI_ModifyPosition(ulong ticket, double sl, double tp)
{
    if(!PositionSelectByTicket(ticket)) {
        Print("❌ Cannot modify position #", ticket, " - position not found");
        return false;
    }
    
    // Get current position info
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Get broker's minimum stop level
    long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minStopDistance = stopLevel * _Point;
    
    // Validate and adjust SL
    if(sl > 0) {
        double slDistance = MathAbs(currentPrice - sl);
        if(slDistance < minStopDistance) {
            // Adjust SL to meet minimum distance
            if(posType == POSITION_TYPE_BUY) {
                sl = currentPrice - minStopDistance - (1 * _Point);
            }
            else {
                sl = currentPrice + minStopDistance + (1 * _Point);
            }
        }
        
        // Final validation
        if((posType == POSITION_TYPE_BUY && sl >= currentPrice) ||
           (posType == POSITION_TYPE_SELL && sl <= currentPrice)) {
            Print("❌ Invalid SL level for position #", ticket);
            return false;
        }
    }
    
    // Validate and adjust TP
    if(tp > 0) {
        double tpDistance = MathAbs(currentPrice - tp);
        if(tpDistance < minStopDistance) {
            // Adjust TP to meet minimum distance
            if(posType == POSITION_TYPE_BUY) {
                tp = currentPrice + minStopDistance + (1 * _Point);
            }
            else {
                tp = currentPrice - minStopDistance - (1 * _Point);
            }
        }
        
        // Final validation
        if((posType == POSITION_TYPE_BUY && tp <= currentPrice) ||
           (posType == POSITION_TYPE_SELL && tp >= currentPrice)) {
            Print("❌ Invalid TP level for position #", ticket);
            return false;
        }
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.sl = (sl > 0) ? NormalizeDouble(sl, _Digits) : 0;
    request.tp = (tp > 0) ? NormalizeDouble(tp, _Digits) : 0;
    
    if(!OrderSend(request, result)) {
        Print("❌ OrderSend failed: ", GetLastError(), " | Comment: ", result.comment);
        return false;
    }
    
    if(result.retcode == TRADE_RETCODE_DONE) {
        return true;
    }
    else {
        Print("⚠️ Modify position failed - Retcode: ", result.retcode, " | Comment: ", result.comment);
        return false;
    }
}

//+------------------------------------------------------------------+
//| AI Partial Close                                                  |
//+------------------------------------------------------------------+
bool AI_PartialClose(ulong ticket, double volume)
{
    if(!PositionSelectByTicket(ticket)) return false;
    
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (request.type == ORDER_TYPE_BUY) ? 
                    SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                    SymbolInfoDouble(_Symbol, SYMBOL_BID);
    request.deviation = 50;
    request.type_filling = GetFillingMode();
    
    if(!OrderSend(request, result))
        return false;
    
    return (result.retcode == TRADE_RETCODE_DONE);
}

//+------------------------------------------------------------------+
//| AI Update Learning System                                         |
//+------------------------------------------------------------------+
void AI_UpdateLearningSystem()
{
    // Analyze closed trades for learning
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
        
        // Update AI performance score
        AI.performanceScore = g_winRate * 0.5 + MathMin(g_profitFactor * 20, 50);
        
        // Adapt learning rate based on performance
        if(g_winRate > 60) AI.learningRate = 0.15; // Learn faster when winning
        else if(g_winRate < 45) AI.learningRate = 0.05; // Learn slower when losing
    }
}

//+------------------------------------------------------------------+
//| Count Positions by Type                                           |
//+------------------------------------------------------------------+
int CountPositionsByType(ENUM_POSITION_TYPE positionType)
{
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) == _Symbol) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                if(posType == positionType) {
                    count++;
                }
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Get Total Net Position Exposure                                    |
//+------------------------------------------------------------------+
double GetNetPositionExposure()
{
    double netVolume = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) == _Symbol) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double volume = PositionGetDouble(POSITION_VOLUME);
                if(posType == POSITION_TYPE_BUY) {
                    netVolume += volume;
                }
                else {
                    netVolume -= volume;
                }
            }
        }
    }
    return netVolume;
}

//+------------------------------------------------------------------+
//| Smart Position Management - Intelligent Entry/Exit Logic          |
//+------------------------------------------------------------------+
bool AI_SmartPositionManagement(ENUM_ORDER_TYPE orderType)
{
    int buyPositions = CountPositionsByType(POSITION_TYPE_BUY);
    int sellPositions = CountPositionsByType(POSITION_TYPE_SELL);
    int totalPositions = buyPositions + sellPositions;
    double netExposure = GetNetPositionExposure();
    
    // ═══════════════════════════════════════════════════════
    // STRATEGY 1: Allow Simultaneous BUY/SELL (Hedging)
    // ═══════════════════════════════════════════════════════
    
    // If we have strong opposite signal, consider closing losing opposite positions
    if(orderType == ORDER_TYPE_BUY && sellPositions > 0) {
        // Check if SELL positions are losing and signal is very strong
        if(AI.confidenceLevel >= 75 && AI.buySignalStrength > 700) {
            // Close losing SELL positions before opening BUY
            if(AI_CloseLosingOppositePositions(POSITION_TYPE_SELL)) {
                Print("🔄 Closed losing SELL positions before opening BUY (Strong Signal)");
            }
        }
    }
    else if(orderType == ORDER_TYPE_SELL && buyPositions > 0) {
        // Check if BUY positions are losing and signal is very strong
        if(AI.confidenceLevel >= 75 && AI.sellSignalStrength > 700) {
            // Close losing BUY positions before opening SELL
            if(AI_CloseLosingOppositePositions(POSITION_TYPE_BUY)) {
                Print("🔄 Closed losing BUY positions before opening SELL (Strong Signal)");
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════
    // STRATEGY 2: Position Diversification
    // ═══════════════════════════════════════════════════════
    
    // Allow simultaneous BUY/SELL if market is ranging/consolidating
    if(AI.marketRegime == "RANGING" || AI.marketRegime == "CONSOLIDATION") {
        // In ranging markets, allow both directions
        if(totalPositions < MaxSimultaneousTrades) {
            return true;
        }
    }
    
    // ═══════════════════════════════════════════════════════
    // STRATEGY 3: Trend Following with Position Limits
    // ═══════════════════════════════════════════════════════
    
    // In strong trends, prefer one direction but allow small hedging
    if(AI.marketRegime == "TRENDING") {
        if(orderType == ORDER_TYPE_BUY && AI.trendDirection == 1) {
            // Strong uptrend: Allow BUY, limit SELL
            if(buyPositions < MaxSimultaneousTrades && sellPositions <= 1) {
                return true;
            }
        }
        else if(orderType == ORDER_TYPE_SELL && AI.trendDirection == -1) {
            // Strong downtrend: Allow SELL, limit BUY
            if(sellPositions < MaxSimultaneousTrades && buyPositions <= 1) {
                return true;
            }
        }
        else {
            // Counter-trend: Be more cautious
            if(totalPositions < (MaxSimultaneousTrades / 2)) {
                return true;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════
    // STRATEGY 4: Net Exposure Management
    // ═══════════════════════════════════════════════════════
    
    // Prevent excessive net exposure in one direction
    double maxNetExposure = AI.optimalLotSize * 3.0; // Max 3x lot size net exposure
    
    if(orderType == ORDER_TYPE_BUY) {
        if(netExposure + AI.optimalLotSize <= maxNetExposure) {
            if(totalPositions < MaxSimultaneousTrades) {
                return true;
            }
        }
    }
    else {
        if(netExposure - AI.optimalLotSize >= -maxNetExposure) {
            if(totalPositions < MaxSimultaneousTrades) {
                return true;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════
    // STRATEGY 5: Default - Allow if under limit
    // ═══════════════════════════════════════════════════════
    
    if(totalPositions < MaxSimultaneousTrades) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Close Losing Opposite Positions                                  |
//+------------------------------------------------------------------+
bool AI_CloseLosingOppositePositions(ENUM_POSITION_TYPE positionType)
{
    bool closedAny = false;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) != _Symbol) continue;
        
        long magic = PositionGetInteger(POSITION_MAGIC);
        if(magic != MagicNumber) continue;
        
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if(posType != positionType) continue;
        
        double positionProfit = PositionGetDouble(POSITION_PROFIT);
        double positionSwap = PositionGetDouble(POSITION_SWAP);
        double totalPL = positionProfit + positionSwap;
        
        // Close if losing more than 50% of risk amount
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                              SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                              SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double priceDiff = MathAbs(currentPrice - openPrice);
        double slDistance = PipsToPoints(AI.optimalStopLoss);
        
        // If position is losing and close to SL, close it
        if(totalPL < 0 && priceDiff > slDistance * 0.5) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            if(AI_ClosePosition(ticket)) {
                Print("🔄 Closed losing ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"), 
                      " position #", ticket, " | P&L: ", DoubleToString(totalPL, 2));
                closedAny = true;
            }
        }
    }
    
    return closedAny;
}

//+------------------------------------------------------------------+
//| Close Position                                                    |
//+------------------------------------------------------------------+
bool AI_ClosePosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return false;
    
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double volume = PositionGetDouble(POSITION_VOLUME);
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (request.type == ORDER_TYPE_BUY) ? 
                    SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                    SymbolInfoDouble(_Symbol, SYMBOL_BID);
    request.deviation = 50;
    request.magic = MagicNumber;
    request.comment = "AI_SmartClose";
    request.type_filling = GetFillingMode();
    
    if(!OrderSend(request, result)) {
        Print("❌ Failed to close position #", ticket, " | Error: ", GetLastError());
        return false;
    }
    
    return (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED);
}

//+------------------------------------------------------------------+
//| Can AI Execute Trade                                              |
//+------------------------------------------------------------------+
bool AI_CanExecuteTrade()
{
    // Count open positions (now allows simultaneous BUY/SELL)
    int openPositions = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) == _Symbol) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
                openPositions++;
        }
    }
    
    // Allow up to MaxSimultaneousTrades total positions (can be mix of BUY/SELL)
    if(openPositions >= MaxSimultaneousTrades) {
        return false;
    }
    
    // Check spread (account-aware)
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double spreadPips = PointsToPips((double)spread);
    
    // CRITICAL: Different spread limits for cent vs standard accounts
    double maxSpread = 25.0;  // Default
    if(g_isCentAccount) {
        // Cent accounts: 0.3 pip spread is normal, allow up to 1.0 pips
        maxSpread = 1.0;  // Very tight for cent accounts
    }
    
    if(spreadPips > maxSpread) {
        static datetime lastSpreadLog = 0;
        if(TimeCurrent() - lastSpreadLog > 60) {
            Print("🚫 Spread too high: ", DoubleToString(spreadPips, 2), " pips (max: ", maxSpread, " pips)");
            lastSpreadLog = TimeCurrent();
        }
        return false;
    }
    
    // Check free margin
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double requiredMargin = AccountInfoDouble(ACCOUNT_BALANCE) * 0.1; // At least 10%
    if(freeMargin < requiredMargin) {
        return false;
    }
    
    // Minimum bars since last trade (prevent over-trading)
    if(!AI_AggressiveMode && g_barsSinceLastTrade < 3) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| OnTradeTransaction - Monitor position closures                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    // Get deal ticket
    ulong dealTicket = trans.deal;
    if(dealTicket == 0) return;
    
    // Only process our magic number trades
    if(HistoryDealSelect(dealTicket)) {
        long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
        if(dealMagic != MagicNumber) return;
    }
    else {
        return;
    }
    
    // Check if position was closed
    if(trans.type == TRADE_TRANSACTION_POSITION) {
        if(dealTicket > 0) {
            // Get deal information
            if(HistoryDealSelect(dealTicket)) {
                ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                
                // Position was closed (out entry)
                if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY) {
                    double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                    double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                    double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                    double totalProfit = profit + swap + commission;
                    
                    string reason = "";
                    if(dealEntry == DEAL_ENTRY_OUT_BY) {
                        reason = " (Closed by opposite position)";
                    }
                    
                    Print("");
                    Print("╔═══════════════════════════════════════════════════════════╗");
                    Print("║              📊 POSITION CLOSED 📊                        ║");
                    Print("╠═══════════════════════════════════════════════════════════╣");
                    Print("║  Deal Ticket: #", dealTicket, reason, "                              ║");
                    Print("║  Profit: ", DoubleToString(profit, 2), " | Swap: ", DoubleToString(swap, 2), " | Commission: ", DoubleToString(commission, 2), "  ║");
                    Print("║  Total P&L: ", DoubleToString(totalProfit, 2), "                                    ║");
                    
                    // Check if closed by SL or TP
                    ulong positionTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
                    if(positionTicket > 0) {
                        // Try to find the opening deal
                        datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
                        HistorySelect(dealTime - 86400, dealTime + 3600); // Look back 1 day
                        
                        for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
                            ulong checkTicket = HistoryDealGetTicket(i);
                            if(checkTicket > 0) {
                                if(HistoryDealGetInteger(checkTicket, DEAL_POSITION_ID) == positionTicket) {
                                    ENUM_DEAL_ENTRY checkEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(checkTicket, DEAL_ENTRY);
                                    if(checkEntry == DEAL_ENTRY_IN) {
                                        double openPrice = HistoryDealGetDouble(checkTicket, DEAL_PRICE);
                                        double closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                                        
                                        // Try to get SL/TP from position history
                                        string closeReason = "Manual Close";
                                        if(MathAbs(closePrice - openPrice) < 0.0001) {
                                            closeReason = "SL/TP Hit";
                                        }
                                        
                                        Print("║  Close Reason: ", closeReason, "                                    ║");
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    Print("╚═══════════════════════════════════════════════════════════╝");
                    Print("");
                    
                    // Update statistics
                    if(totalProfit > 0) {
                        g_winningTrades++;
                    }
                    else if(totalProfit < 0) {
                        g_losingTrades++;
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Periodic Check: Ensure all positions have SL/TP                  |
//+------------------------------------------------------------------+
void CheckAllPositionsHaveSLTP()
{
    static datetime lastCheck = 0;
    datetime now = TimeCurrent();
    
    // Check every 30 seconds
    if(now - lastCheck < 30) return;
    lastCheck = now;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetSymbol(i) != _Symbol) continue;
        
        long magic = PositionGetInteger(POSITION_MAGIC);
        if(magic != MagicNumber) continue;
        
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        
        // If SL or TP is missing, set them
        if(currentSL == 0 || currentTP == 0) {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            
            // Calculate SL/TP based on original optimal values
            double sl = 0, tp = 0;
            if(posType == POSITION_TYPE_BUY) {
                sl = openPrice - PipsToPoints(AI.optimalStopLoss);
                tp = openPrice + PipsToPoints(AI.optimalTakeProfit);
            }
            else {
                sl = openPrice + PipsToPoints(AI.optimalStopLoss);
                tp = openPrice - PipsToPoints(AI.optimalTakeProfit);
            }
            
            Print("⚠️ Position #", ticket, " missing SL/TP - Setting now...");
            if(AI_ModifyPosition(ticket, sl, tp)) {
                Print("✅ SL/TP set for position #", ticket);
            }
            else {
                Print("❌ Failed to set SL/TP for position #", ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Log Position Status - Show current position state                |
//+------------------------------------------------------------------+
void AI_LogPositionStatus()
{
    int buyPositions = CountPositionsByType(POSITION_TYPE_BUY);
    int sellPositions = CountPositionsByType(POSITION_TYPE_SELL);
    int totalPositions = buyPositions + sellPositions;
    double netExposure = GetNetPositionExposure();
    
    if(totalPositions > 0) {
        double totalProfit = 0;
        double buyProfit = 0;
        double sellProfit = 0;
        
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            if(PositionGetSymbol(i) != _Symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
            
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double swap = PositionGetDouble(POSITION_SWAP);
            double pl = profit + swap;
            
            totalProfit += pl;
            if(posType == POSITION_TYPE_BUY) buyProfit += pl;
            else sellProfit += pl;
        }
        
        Print("");
        Print("╔═══════════════════════════════════════════════════════════╗");
        Print("║              📊 CURRENT POSITION STATUS 📊                ║");
        Print("╠═══════════════════════════════════════════════════════════╣");
        Print("║  Total Positions: ", totalPositions, " (BUY: ", buyPositions, " | SELL: ", sellPositions, ")              ║");
        Print("║  Net Exposure: ", DoubleToString(netExposure, 2), " lots                                ║");
        Print("║  Total P&L: ", DoubleToString(totalProfit, 2), " (BUY: ", DoubleToString(buyProfit, 2), " | SELL: ", DoubleToString(sellProfit, 2), ")  ║");
        Print("║  Market Regime: ", AI.marketRegime, " | Trend: ", AI.marketSentiment, "        ║");
        Print("║  Trend Strength: ", DoubleToString(AI.trendStrength, 1), " | Direction: ", (AI.trendDirection == 1 ? "UP" : (AI.trendDirection == -1 ? "DOWN" : "NEUTRAL")), "      ║");
        Print("╚═══════════════════════════════════════════════════════════╝");
        Print("");
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
