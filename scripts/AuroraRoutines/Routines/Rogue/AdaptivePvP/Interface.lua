local Routine = Aurora.Routine
local MyNamespace = Routine.Namespace
local player = Aurora.UnitManager:Get("player")

local gui = Aurora.GuiBuilder:New()

local function hasSpell(spellName)
    local spells = Aurora.SpellHandler.Spellbooks.rogue
    if not spells then return false end
    
    local specId = tostring(player.level >= 10 and 8 or 7)
    local namespace = spells[specId] and spells[specId].AdaptivePvP
    if not namespace then return false end
    
    return (namespace.spells and namespace.spells[spellName]) or 
           (namespace.talents and namespace.talents[spellName])
end

gui:Category("Adaptive PvP Settings")
   :Tab("General")
   :Header({ text = "PvP Strategy" })
   :Dropdown({
       text = "Combat Mode",
       var = "combatMode",
       options = {"Aggressive", "Balanced", "Defensive"},
       default = "Balanced",
       tooltip = "Overall combat approach - adapts to your playstyle"
   })
   :Checkbox({
       text = "Auto Class Detection",
       var = "autoClassDetection",
       default = true,
       tooltip = "Automatically detect enemy class and adapt rotation"
   })

-- Level-based settings
if player.level >= 4 then
    gui:Header({ text = "Stealth & Positioning" })
       :Checkbox({
           text = "Use Stealth Openers",
           var = "useStealthOpeners",
           default = true,
           tooltip = "Open fights from stealth when possible"
       })
end

if player.level >= 20 then
    gui:Checkbox({
           text = "Auto Apply Poisons",
           var = "autoApplyPoisons",
           default = true,
           tooltip = "Automatically suggest optimal poisons for target class"
       })
       :Dropdown({
           text = "Primary Poison",
           var = "primaryPoison",
           options = {"Instant", "Deadly", "Auto"},
           default = "Auto",
           tooltip = "Main hand poison preference"
       })
end

if player.level >= 26 then
    gui:Header({ text = "Crowd Control" })
       :Checkbox({
           text = "Use Cheap Shot Openers",
           var = "useCheapShotOpeners",
           default = true,
           tooltip = "Open with Cheap Shot from stealth for 4-second stun"
       })
       :Slider({
           text = "CC Chain Length",
           var = "ccChainLength",
           min = 1,
           max = 5,
           default = 3,
           step = 1,
           tooltip = "How many CC abilities to chain together"
       })
end

if player.level >= 30 then
    gui:Checkbox({
           text = "Use Kidney Shot Chains",
           var = "useKidneyShotChains",
           default = true,
           tooltip = "Chain stuns with Kidney Shot for extended lockdown"
       })
end

-- Talent-specific settings
if hasSpell("Riposte") then
    gui:Tab("Combat Talents")
       :Header({ text = "Combat Specialization" })
       :Checkbox({
           text = "Prioritize Riposte",
           var = "prioritizeRiposte",
           default = true,
           tooltip = "Use Riposte immediately when available"
       })
end

if hasSpell("Blade_Flurry") then
    gui:Checkbox({
           text = "Auto Blade Flurry",
           var = "autoBladeFlurry",
           default = false,
           tooltip = "Automatically use Blade Flurry for burst (player controlled by default)"
       })
end

if hasSpell("Adrenaline_Rush") then
    gui:Checkbox({
           text = "Auto Adrenaline Rush",
           var = "autoAdrenalineRush",
           default = false,
           tooltip = "Automatically use Adrenaline Rush for energy (player controlled by default)"
       })
end

if hasSpell("Cold_Blood") then
    gui:Tab("Subtlety Talents")
       :Header({ text = "Subtlety Specialization" })
       :Checkbox({
           text = "Cold Blood Combos",
           var = "coldBloodCombos",
           default = true,
           tooltip = "Use Cold Blood + Eviscerate for guaranteed crits"
       })
       :Slider({
           text = "Cold Blood CP Threshold",
           var = "coldBloodCPThreshold",
           min = 3,
           max = 5,
           default = 5,
           step = 1,
           tooltip = "Minimum combo points for Cold Blood combo"
       })
end

if hasSpell("Preparation") then
    gui:Checkbox({
           text = "Preparation Double Burst",
           var = "preparationDoubleBurst",
           default = true,
           tooltip = "Use Preparation to reset cooldowns for second burst"
       })
end

if hasSpell("Hemorrhage") then
    gui:Tab("Assassination Talents")
       :Header({ text = "Assassination Specialization" })
       :Checkbox({
           text = "Use Hemorrhage",
           var = "useHemorrhage",
           default = true,
           tooltip = "Use Hemorrhage as combo point builder in PvP"
       })
end

-- Class-specific strategies
gui:Tab("Class Strategies")
   :Header({ text = "Warrior Strategy" })
   :Dropdown({
       text = "vs Warrior",
       var = "vsWarrior",
       options = {"Kite Heavy", "Stun Lock", "Burst Rush", "Auto"},
       default = "Auto",
       tooltip = "Strategy against Warriors"
   })
   :Header({ text = "Mage Strategy" })
   :Dropdown({
       text = "vs Mage",
       var = "vsMage",
       options = {"Stick Close", "Interrupt Focus", "Burst Rush", "Auto"},
       default = "Auto",
       tooltip = "Strategy against Mages"
   })
   :Header({ text = "Hunter Strategy" })
   :Dropdown({
       text = "vs Hunter",
       var = "vsHunter",
       options = {"Kill Pet First", "Ignore Pet", "Stay Close", "Auto"},
       default = "Auto",
       tooltip = "Strategy against Hunters"
   })

-- Advisory system settings
gui:Tab("Advisory")
   :Header({ text = "Tactical Notifications" })
   :Checkbox({
       text = "Kiting Alerts",
       var = "kitingAlerts",
       default = true,
       tooltip = "Show alerts when you should kite or re-engage"
   })
   :Checkbox({
       text = "Burst Window Alerts",
       var = "burstWindowAlerts",
       default = true,
       tooltip = "Alert when enemy cooldowns are down for burst"
   })
   :Checkbox({
       text = "Escape Alerts",
       var = "escapeAlerts",
       default = true,
       tooltip = "Alert when you should use escape abilities"
   })
   :Slider({
       text = "Alert Frequency",
       var = "alertFrequency",
       min = 1,
       max = 10,
       default = 5,
       step = 1,
       tooltip = "How often to show alerts (1=rare, 10=frequent)"
   })

-- Strategic Prediction Settings
gui:Tab("Predictions")
   :Header({ text = "Predictive Intelligence" })
   :Checkbox({
       text = "Enable Predictions",
       var = "enablePredictions",
       default = true,
       tooltip = "Use AI to predict enemy actions and suggest counters"
   })
   :Checkbox({
       text = "Cooldown Tracking",
       var = "cooldownTracking",
       default = true,
       tooltip = "Track enemy ability cooldowns for strategic planning"
   })
   :Checkbox({
       text = "Threat Assessment",
       var = "threatAssessment",
       default = true,
       tooltip = "Continuously assess strategic threat levels"
   })
   :Slider({
       text = "Prediction Confidence",
       var = "predictionConfidence",
       min = 1,
       max = 10,
       default = 7,
       step = 1,
       tooltip = "Minimum confidence level for predictions (1=low, 10=high)"
   })

gui:Header({ text = "Opportunity Windows" })
   :Checkbox({
       text = "Burst Window Detection",
       var = "burstWindowDetection",
       default = true,
       tooltip = "Detect optimal moments for burst damage"
   })
   :Checkbox({
       text = "Escape Window Alerts",
       var = "escapeWindowAlerts",
       default = true,
       tooltip = "Alert when enemy abilities create escape opportunities"
   })
   :Checkbox({
       text = "Counter-Strategy Hints",
       var = "counterStrategyHints",
       default = true,
       tooltip = "Suggest specific counters to enemy actions"
   })

gui:Header({ text = "Class-Specific Predictions" })
   :Checkbox({
       text = "Warrior Intercept Warnings",
       var = "warriorInterceptWarnings",
       default = true,
       tooltip = "Warn before Warriors can use Intercept"
   })
   :Checkbox({
       text = "Mage Blink Predictions",
       var = "mageBlinkPredictions",
       default = true,
       tooltip = "Predict when Mages will use Blink/Nova"
   })
   :Checkbox({
       text = "Paladin Bubble Timing",
       var = "paladinBubbleTiming",
       default = true,
       tooltip = "Predict Divine Shield usage timing"
   })
   :Checkbox({
       text = "Priest Fear Warnings",
       var = "priestFearWarnings",
       default = true,
       tooltip = "Warn about incoming Psychic Scream"
   })

gui:Tab("Strategy Engine")
   :Header({ text = "Adaptive Strategy" })
   :Dropdown({
       text = "Strategy Aggressiveness",
       var = "strategyAggressiveness",
       options = {"Conservative", "Balanced", "Aggressive", "Adaptive"},
       default = "Adaptive",
       tooltip = "How aggressive the strategic recommendations should be"
   })
   :Checkbox({
       text = "Auto-Adapt to Enemy",
       var = "autoAdaptToEnemy",
       default = true,
       tooltip = "Automatically adjust strategy based on enemy behavior"
   })
   :Checkbox({
       text = "Learn from Fights",
       var = "learnFromFights",
       default = false,
       tooltip = "Remember successful strategies against specific players"
   })

gui:Header({ text = "Timing Predictions" })
   :Slider({
       text = "Warning Lead Time",
       var = "warningLeadTime",
       min = 1,
       max = 5,
       default = 3,
       step = 1,
       tooltip = "Seconds of warning before predicted enemy actions"
   })
   :Slider({
       text = "Opportunity Window",
       var = "opportunityWindow",
       min = 2,
       max = 10,
       default = 5,
       step = 1,
       tooltip = "Duration to highlight tactical opportunities"
   })

gui:Header({ text = "Advanced Features" })
   :Checkbox({
       text = "Resource Prediction",
       var = "resourcePrediction",
       default = true,
       tooltip = "Predict enemy mana/rage/energy states"
   })
   :Checkbox({
       text = "Multi-Target Analysis",
       var = "multiTargetAnalysis",
       default = false,
       tooltip = "Analyze multiple enemies in group fights"
   })
   :Checkbox({
       text = "Positioning Suggestions",
       var = "positioningSuggestions",
       default = true,
       tooltip = "Suggest optimal positioning based on predictions"
   })

-- Enhanced Combat Flow Settings
gui:Tab("Combat Flow")
   :Header({ text = "Combat State Machine" })
   :Checkbox({
       text = "Enable Combat States",
       var = "enableCombatStates",
       default = true,
       tooltip = "Use advanced state-driven combat flow"
   })
   :Checkbox({
       text = "Energy Pooling",
       var = "energyPooling",
       default = true,
       tooltip = "Pool energy before burst windows and important sequences"
   })
   :Slider({
       text = "Pool Energy Threshold",
       var = "poolEnergyThreshold",
       min = 60,
       max = 100,
       default = 80,
       step = 5,
       tooltip = "Energy level to pool before burst (60-100)"
   })
   :Checkbox({
       text = "State Notifications",
       var = "stateNotifications",
       default = true,
       tooltip = "Show notifications when combat state changes"
   })

gui:Header({ text = "Druid Mastery" })
   :Checkbox({
       text = "Druid Form Tracking",
       var = "druidFormTracking",
       default = true,
       tooltip = "Track and predict Druid shapeshifts"
   })
   :Checkbox({
       text = "Form-Specific Strategies",
       var = "formSpecificStrategies",
       default = true,
       tooltip = "Use different tactics based on Druid form"
   })
   :Checkbox({
       text = "Shapeshift Predictions",
       var = "shapeshiftPredictions",
       default = true,
       tooltip = "Predict when Druids will change forms"
   })
   :Checkbox({
       text = "Healing Interrupt Priority",
       var = "healingInterruptPriority",
       default = true,
       tooltip = "Prioritize interrupting Druid heals"
   })

gui:Header({ text = "Priest Mastery" })
   :Checkbox({
       text = "Fear Positioning",
       var = "fearPositioning",
       default = true,
       tooltip = "Automatic positioning to avoid Psychic Scream"
   })
   :Checkbox({
       text = "Heal Interrupt Chains",
       var = "healInterruptChains",
       default = true,
       tooltip = "Chain interrupts to lock down Priest healing"
   })
   :Checkbox({
       text = "Mind Control Predictions",
       var = "mindControlPredictions",
       default = true,
       tooltip = "Predict and counter Mind Control attempts"
   })
   :Checkbox({
       text = "Shield Breaking Priority",
       var = "shieldBreakingPriority",
       default = true,
       tooltip = "Optimize damage for breaking Power Word Shield"
   })

gui:Tab("Cooldown Mastery")
   :Header({ text = "Cooldown Manipulation" })
   :Checkbox({
       text = "Enable Cooldown Baiting",
       var = "enableCooldownBaiting",
       default = true,
       tooltip = "Strategically force enemies to use cooldowns early"
   })
   :Dropdown({
       text = "Baiting Aggressiveness",
       var = "baitingAggressiveness",
       options = {"Conservative", "Moderate", "Aggressive"},
       default = "Moderate",
       tooltip = "How aggressively to bait enemy cooldowns"
   })
   :Checkbox({
       text = "Opportunity Exploitation",
       var = "opportunityExploitation",
       default = true,
       tooltip = "Exploit windows when enemy cooldowns are down"
   })

gui:Header({ text = "Burst Coordination" })
   :Checkbox({
       text = "Cold Blood Optimization",
       var = "coldBloodOptimization",
       default = true,
       tooltip = "Optimize Cold Blood usage with energy pooling"
   })
   :Checkbox({
       text = "Preparation Double Burst",
       var = "preparationDoubleBurst",
       default = true,
       tooltip = "Use Preparation for coordinated double burst sequences"
   })
   :Slider({
       text = "Burst Window Duration",
       var = "burstWindowDuration",
       min = 3,
       max = 10,
       default = 6,
       step = 1,
       tooltip = "Duration of burst windows in seconds"
   })

gui:Header({ text = "Energy Optimization" })
   :Checkbox({
       text = "Smart Energy Management",
       var = "smartEnergyManagement",
       default = true,
       tooltip = "Intelligent energy pooling and spending"
   })
   :Slider({
       text = "Emergency Reserve",
       var = "emergencyReserve",
       min = 30,
       max = 80,
       default = 60,
       step = 10,
       tooltip = "Energy to reserve for emergency escapes"
   })
   :Checkbox({
       text = "Efficiency Tracking",
       var = "efficiencyTracking",
       default = false,
       tooltip = "Track and optimize energy efficiency over time"
   })