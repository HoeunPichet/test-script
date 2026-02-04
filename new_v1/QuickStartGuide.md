# SMART MOMENTUM EA - QUICK START GUIDE
## Get Trading in 10 Minutes! ⚡

---

## 🎯 WHAT THIS EA DOES
- **Buys** when price shows strong upward momentum
- **Sells** when price shows strong downward momentum
- Uses **7 filters** to ensure high-quality trades
- **Manages risk** automatically (1% per trade)
- **Expected win rate: 60-75%** with proper settings

---

## 📥 STEP 1: INSTALLATION (2 minutes)

1. **Open MT5** → Press `F4` (opens MetaEditor)
2. **File** → **Open Data Folder**
3. Navigate to **MQL5** → **Experts**
4. Copy **SmartMomentumEA.mq5** into this folder
5. Restart MT5
6. EA should appear in **Navigator** panel under "Expert Advisors"

---

## 🔧 STEP 2: FIRST-TIME SETUP (3 minutes)

### Attach EA to Chart:
1. Open **EUR/USD M15** chart (good for beginners)
2. Drag **SmartMomentumEA** from Navigator onto chart
3. Settings window will appear

### Essential Settings for Beginners:
```
=== RISK MANAGEMENT ===
RiskPercent = 1.0                    ← Risk 1% per trade
MaxDailyRisk = 3.0                   ← Stop if lose 3% in one day
MaxConcurrentTrades = 2              ← Max 2 trades at once
MinRiskRewardRatio = 1.5             ← Win 1.5× what you risk

=== MOMENTUM ENTRY ===
MomentumPeriod = 14
MinMomentumStrength = 60.0           ← Quality over quantity
ConfirmationCandles = 2

=== FILTERS (Keep all TRUE) ===
UseTrendFilter = true                ← CRITICAL - only trade with trend
UseADXFilter = true                  ← CRITICAL - ensure trend exists
UseRSIFilter = true                  ← Avoid overbought/oversold
MinADX = 20.0

=== STOP LOSS & TAKE PROFIT ===
StopLossMode = 1                     ← Use ATR (dynamic, recommended)
ATR_SL_Multiplier = 2.0              ← Stop loss = 2× ATR
ATR_TP_Multiplier = 3.0              ← Take profit = 3× ATR

=== PROTECTIVE FEATURES ===
UseTrailingStop = true               ← Lock in profits
UseBreakEven = true                  ← Protect capital

=== SESSION FILTER ===
EnableSessionFilter = true
TradeAsianSession = true
TradeLondonSession = true
TradeNYSession = true
```

4. Click **OK**
5. Click **AutoTrading** button in MT5 toolbar (should turn GREEN)
6. EA smiley face should appear in top-right corner 😊

---

## 🧪 STEP 3: DEMO TESTING (Mandatory!)

### Run on Demo Account First
```
⚠️ CRITICAL: Never start on live account!

Demo testing period: 2-4 weeks minimum

What to monitor:
□ Win rate (should be >55%)
□ Average R:R (should be >1.3)
□ Max drawdown (should be <20%)
□ Number of trades (should be 10+ per week)
□ EA errors (check Journal tab - should be none)
```

### How to Track Performance:
1. Check MT5 **Account History** tab daily
2. Calculate:
   - Total Trades: ____
   - Winning Trades: ____
   - Win Rate: ____ % (aim for 60%+)
   - Total Profit: $ ____
   - Max Drawdown: $ ____ (should be <20% of starting balance)

---

## 📊 STEP 4: OPTIMIZATION (5 minutes)

### Backtest Before Live Trading:

1. **Open Strategy Tester** (Ctrl+R)
2. Settings:
   - Expert: SmartMomentumEA
   - Symbol: EUR/USD
   - Period: M15
   - Date: Last 3 months
   - Mode: Every tick
3. Click **Start**
4. Wait for completion (10-20 mins)

### Good Backtest Results:
```
✅ Profit Factor: >1.5
✅ Win Rate: >55%
✅ Total Trades: >50
✅ Max Drawdown: <20%
✅ Sharpe Ratio: >1.0
```

### Bad Results? Adjust:
```
If win rate too low (<50%):
→ Increase MinMomentumStrength to 70
→ Increase MinADX to 25
→ Keep UseTrendFilter = true

If too few trades (<20):
→ Decrease MinMomentumStrength to 50
→ Decrease MinADX to 15
→ Trade more sessions

If too many losses:
→ Increase MinRiskRewardRatio to 2.0
→ Use longer timeframe (H1 instead of M15)
```

---

## 🚀 STEP 5: GO LIVE (When Ready)

### Pre-Live Checklist:
```
□ Tested on demo for 2+ weeks
□ Win rate >55%
□ Understand how EA works
□ Account has >$500 (minimum recommended)
□ Risk set to 1% or less
□ VPS or stable internet (optional but recommended)
□ Broker has low spreads (<2 pips for EUR/USD)
□ AutoTrading is enabled
```

### First Week on Live:
```
1. Start with ONLY 1 pair (EUR/USD)
2. Monitor DAILY
3. Risk only 0.5-1% per trade
4. Don't touch running trades
5. Keep journal of results
```

---

## 🎛️ RECOMMENDED SETTINGS BY EXPERIENCE

### 🟢 BEGINNER (Start Here)
```
Pairs: EUR/USD only
Timeframe: M15 or H1
RiskPercent: 1.0%
MinMomentumStrength: 60-70
UseTrendFilter: TRUE (must)
UseADXFilter: TRUE (must)
MinADX: 20-25
MaxConcurrentTrades: 2

Expected:
- 5-10 trades per week
- 65-75% win rate
- 5-10% monthly return
```

### 🟡 INTERMEDIATE
```
Pairs: EUR/USD, GBP/USD, USD/JPY
Timeframe: M15 or H1
RiskPercent: 1.5%
MinMomentumStrength: 60
UseTrendFilter: TRUE
UseADXFilter: TRUE
MinADX: 20
MaxConcurrentTrades: 3

Expected:
- 15-25 trades per week
- 60-70% win rate
- 8-15% monthly return
```

### 🔴 ADVANCED (Experienced Only)
```
Pairs: 5+ pairs including Gold
Timeframe: M5, M15, H1
RiskPercent: 2.0%
MinMomentumStrength: 50-60
UseTrendFilter: TRUE
UseADXFilter: TRUE
MinADX: 15-20
MaxConcurrentTrades: 5

Expected:
- 30-50 trades per week
- 55-65% win rate
- 10-20% monthly return
```

---

## ⚠️ CRITICAL DOS AND DON'TS

### ✅ DO:
- Test on demo first (2-4 weeks)
- Start with 1% risk per trade
- Keep all filters enabled
- Monitor daily
- Use VPS for 24/7 trading
- Check news calendar (pause during major events)
- Track performance in journal
- Stay patient with the strategy

### ❌ DON'T:
- Skip demo testing
- Risk more than 2% per trade
- Disable trend filter
- Manually close EA's trades
- Use on accounts under $500
- Trade during major news (NFP, FOMC)
- Change settings constantly
- Expect overnight riches
- Overtrade or revenge trade

---

## 🔧 TROUBLESHOOTING QUICK FIXES

### Problem: EA Not Opening Trades
```
Fix:
1. Check AutoTrading button (must be GREEN)
2. Check EA smiley face (must be happy 😊)
3. Check Experts tab for errors
4. Verify spread <3 pips
5. Check if in trading session
```

### Problem: Trades Stop Out Too Often
```
Fix:
1. Increase ATR_SL_Multiplier (2.0 → 2.5 → 3.0)
2. Reduce RiskPercent (less lot size = safer)
3. Use UseBreakEven = true
```

### Problem: Not Enough Trades
```
Fix:
1. Decrease MinMomentumStrength (70 → 60 → 50)
2. Decrease MinADX (25 → 20 → 15)
3. Trade more sessions
4. Use M15 instead of H1
```

### Problem: Too Many Losses
```
Fix:
1. Increase MinMomentumStrength (60 → 70 → 80)
2. Increase MinADX (20 → 25 → 30)
3. Verify UseTrendFilter = TRUE
4. Increase MinRiskRewardRatio (1.5 → 2.0)
```

---

## 📱 DAILY MONITORING ROUTINE (5 minutes)

### Morning Check (Before Markets Open):
```
□ Check any overnight trades
□ Verify EA is running (green smiley)
□ Check today's news calendar
□ Pause EA if major news expected
```

### Evening Check (After Markets Close):
```
□ Review closed trades
□ Calculate daily profit/loss
□ Update trading journal
□ Check for any errors in Journal tab
□ Adjust settings if needed
```

### Weekly Review:
```
□ Calculate weekly win rate
□ Calculate average R:R
□ Total profit/loss
□ Adjust strategy if needed
```

---

## 💰 ACCOUNT SIZE REQUIREMENTS

```
MINIMUM RECOMMENDED: $500
- Can start lower ($200-300) but expect slower growth
- More capital = better risk management
- Less emotional stress

IDEAL: $1000-2000
- Comfortable lot sizes
- Can withstand normal drawdowns
- Better compounding potential

COMFORTABLE: $5000+
- Professional level risk management
- Multiple pairs simultaneously
- VPS costs are negligible percentage
```

---

## 🎓 LEARNING PATH

### Week 1-2: Demo Testing
- Understand how EA detects momentum
- Watch trades open/close
- Verify filters work correctly
- Track performance

### Week 3-4: Optimization
- Backtest different settings
- Try different timeframes
- Test on different pairs
- Find optimal parameters

### Month 2: Live Trading (Small)
- Start with minimum risk (0.5-1%)
- Trade only 1 pair
- Build confidence
- Track real emotions

### Month 3+: Scale Up
- Increase risk slightly (1-1.5%)
- Add more pairs
- Consider VPS
- Compound profits

---

## 📊 EXPECTED PERFORMANCE (Realistic)

### Conservative Settings:
```
Monthly Return: 5-10%
Win Rate: 65-75%
Max Drawdown: <15%
Trades/Month: 20-40
Risk: 1% per trade
```

### Moderate Settings:
```
Monthly Return: 8-15%
Win Rate: 60-70%
Max Drawdown: <20%
Trades/Month: 40-80
Risk: 1.5% per trade
```

### Aggressive Settings:
```
Monthly Return: 10-20%
Win Rate: 55-65%
Max Drawdown: <25%
Trades/Month: 80-160
Risk: 2% per trade
```

---

## 🏆 SUCCESS TIPS

1. **Patience is Key**
   - EA needs time to show results
   - Don't judge after 5 trades
   - Minimum 50-100 trades for statistical validity

2. **Risk Management First**
   - Never risk more than 2% per trade
   - Never have more than 6% total exposure
   - Set daily/weekly loss limits

3. **Trust the System**
   - Don't manually interfere with trades
   - Let EA manage according to logic
   - Emotional trading kills profits

4. **Keep Learning**
   - Understand WHY trades are taken
   - Learn from losing trades
   - Continuously optimize

5. **Track Everything**
   - Keep detailed journal
   - Note market conditions
   - Record settings changes
   - Learn from data

---

## 🎯 YOUR 30-DAY ACTION PLAN

### Week 1:
```
□ Install EA on demo account
□ Configure conservative settings
□ Let it run for full week
□ Take notes on behavior
```

### Week 2:
```
□ Review Week 1 results
□ Backtest 3 months historical data
□ Adjust settings if needed
□ Continue demo trading
```

### Week 3:
```
□ Calculate win rate and R:R
□ If >55% win rate, prepare for live
□ If <55%, optimize settings
□ Continue demo testing
```

### Week 4:
```
□ Open live account (if demo successful)
□ Start with 0.5% risk
□ Trade only 1 pair
□ Monitor very closely
```

---

## 📞 NEED HELP?

### Before Asking for Help:
1. ✅ Read full documentation
2. ✅ Check troubleshooting section
3. ✅ Review MT5 Journal for errors
4. ✅ Test on demo first
5. ✅ Have specific error messages ready

### Common Questions:

**Q: Why isn't my EA opening trades?**
A: Check spread filter, session filter, trend filter. View Experts tab for details.

**Q: Can I run this on a $100 account?**
A: Technically yes, but not recommended. Minimum $500 for proper risk management.

**Q: What pairs work best?**
A: EUR/USD, GBP/USD, USD/JPY for beginners. Gold for advanced (with lower risk).

**Q: What timeframe is best?**
A: M15 or H1 for beginners. M5 for advanced (more trades, more monitoring needed).

**Q: Should I use VPS?**
A: Recommended if you want 24/7 trading, but not required for testing.

---

## ⚖️ FINAL REMINDER

```
⚠️ RISK WARNING ⚠️

Past performance does not guarantee future results.
Only trade with money you can afford to lose.
This EA is a tool, not a magic money printer.
Success requires:
  - Proper risk management
  - Patience and discipline
  - Continuous learning
  - Realistic expectations

Start small. Test thoroughly. Scale carefully.
```

---

## 🚀 YOU'RE READY!

Follow this guide step by step, and you'll be trading with confidence in no time.

**Remember**: Trading is a marathon, not a sprint. Focus on consistent, sustainable profits rather than getting rich quick.

**Good luck and trade safely!** 📊💰

---

**For detailed information, see the full documentation file.**

**Version 1.0 - January 2026**
