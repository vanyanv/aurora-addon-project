local Routine = Aurora.Routine
local MyNamespace = Routine.Namespace
local player = Aurora.UnitManager:Get("player")
local target = Aurora.UnitManager:Get("target")
local enemies = Aurora.enemies

local specId = tostring(player.level >= 10 and 8 or 7)
local spells = Aurora.SpellHandler.Spellbooks.rogue[specId].AdaptivePvP.spells
local talents = Aurora.SpellHandler.Spellbooks.rogue[specId].AdaptivePvP.talents
local auras = Aurora.SpellHandler.Spellbooks.rogue[specId].AdaptivePvP.auras

local lastNotification = 0
local notificationCooldown = 3

-- Import enemy abilities database
local EnemyAbilities = MyNamespace.EnemyAbilities
local ThreatPatterns = MyNamespace.ThreatPatterns

-- Cooldown tracking system
local enemyCooldowns = {}
local lastSeenAbilities = {}
local combatHistory = {}

-- Unified Combat State Machine
local CombatStates = {
    ANALYZE = "analyze",         -- Assess situation & plan ahead
    OPENER = "opener",           -- Strategic engagement
    PRESSURE = "pressure",       -- Build advantage
    BURST = "burst",            -- Execute damage windows
    CONTROL = "control",        -- Crowd control phases
    BAIT = "bait",             -- Force enemy cooldowns
    SUSTAIN = "sustain",       -- Energy pooling/recovery
    ADAPT = "adapt",           -- Counter enemy actions
    ESCAPE = "escape"          -- Emergency disengagement
}

-- Energy Management System
local EnergyStates = {
    STARVED = "starved",     -- <30 energy, wait/pool
    LIMITED = "limited",     -- 30-60, basic abilities only
    READY = "ready",         -- 60-90, execute plans
    ABUNDANT = "abundant"    -- 90+, aggressive actions
}

-- Combat State Tracking
local combatState = {
    current = CombatStates.ANALYZE,
    previous = nil,
    transitionTime = 0,
    stateData = {},
    plannedActions = {},
    energyState = EnergyStates.LIMITED
}

-- Druid Form Tracking
local DruidForms = {
    HUMAN = "human",     -- Caster form (healing/roots)
    CAT = "cat",         -- Stealth/DPS form  
    BEAR = "bear",       -- Tank form (high armor)
    TRAVEL = "travel",   -- Movement form
    UNKNOWN = "unknown"
}

local druidState = {
    currentForm = DruidForms.UNKNOWN,
    lastFormChange = 0,
    predictedNextForm = nil,
    formHistory = {}
}

-- Prediction state tracking
local predictionState = {
    lastPrediction = 0,
    confidence = 0,
    nextExpectedAction = nil,
    timeWindow = 0
}

local function notify(message)
    local now = GetTime()
    if now - lastNotification > notificationCooldown then
        print("🗡️ " .. message)
        lastNotification = now
    end
end

local function getConfig()
    return Aurora.config or {}
end

local function hasSpell(spellTable, spellName)
    return spellTable and spellTable[spellName] and spellTable[spellName]:isknown()
end

local function canCast(spell, target)
    if not spell then return false end
    if not spell:isknown() then return false end
    if not spell:ready() then return false end
    if target and (not target.exists or not target.alive) then return false end
    return true
end

local function safeCast(spell, target, successMessage)
    if not canCast(spell, target) then return false end
    if spell:cast(target) then
        if successMessage then
            notify(successMessage)
        end
        return true
    end
    return false
end

local function getEnemyClass()
    if not target or not target.exists then return "UNKNOWN" end
    local success, class = pcall(function() return target.class end)
    return success and class or "UNKNOWN"
end

-- Energy Management Functions
local function assessEnergyState()
    local currentEnergy = player.energy or 0
    
    if currentEnergy < 30 then
        return EnergyStates.STARVED
    elseif currentEnergy < 60 then
        return EnergyStates.LIMITED
    elseif currentEnergy < 90 then
        return EnergyStates.READY
    else
        return EnergyStates.ABUNDANT
    end
end

local function shouldPoolEnergy(plannedAction, targetState)
    local currentEnergy = player.energy or 0
    local energyState = assessEnergyState()
    local config = getConfig()
    local poolThreshold = config.poolEnergyThreshold or 80
    
    -- Pool before burst windows
    if targetState == CombatStates.BURST and energyState ~= EnergyStates.ABUNDANT then
        return true
    end
    
    -- Pool before important combo sequences
    if plannedAction == "COLD_BLOOD_COMBO" and currentEnergy < poolThreshold then
        return true
    end
    
    -- Pool for energy optimization setting
    if config.smartEnergyManagement and currentEnergy < poolThreshold then
        local enemyClass = getEnemyClass()
        local predictions = predictEnemyActions(enemyClass)
        
        -- Pool before predicted opportunities
        if predictions and predictions.timeWindow <= 3 then
            return true
        end
    end
    
    -- Pool before enemy vulnerability windows
    local enemyClass = getEnemyClass()
    if enemyClass == "PALADIN" and isEnemyAbilityReady(642, target.guid) and currentEnergy < 70 then
        return true -- Pool before Divine Shield ends
    end
    
    -- Pool before Druid form shifts (if enabled)
    if enemyClass == "DRUID" and config.druidFormTracking then
        local prediction = predictDruidShapeshift()
        if prediction and prediction.confidence >= 7 and currentEnergy < poolThreshold then
            return true
        end
    end
    
    -- Pool before Priest fear if close
    if enemyClass == "PRIEST" and config.fearPositioning and target.distance < 10 and 
       isEnemyAbilityReady(8122, target.guid) and currentEnergy < poolThreshold then
        return true
    end
    
    -- Emergency energy reserve
    local emergencyReserve = config.emergencyReserve or 60
    local threat = assessStrategicThreat(enemyClass)
    if threat == "CRITICAL" and currentEnergy < emergencyReserve then
        return true
    end
    
    return false
end

-- Druid Form Detection & Tracking
local function detectDruidForm()
    if not target or not target.exists then return DruidForms.UNKNOWN end
    
    local enemyClass = getEnemyClass()
    if enemyClass ~= "DRUID" then return DruidForms.UNKNOWN end
    
    -- Safely check for form auras
    local function hasAura(spellId)
        if not target.aura then return false end
        local success, result = pcall(target.aura, spellId)
        return success and result
    end
    
    -- Check for form auras
    if hasAura(768) then -- Cat Form
        return DruidForms.CAT
    elseif hasAura(5487) then -- Bear Form
        return DruidForms.BEAR
    elseif hasAura(783) then -- Travel Form
        return DruidForms.TRAVEL
    else
        return DruidForms.HUMAN -- Default/caster form
    end
end

local function updateDruidState()
    local success, currentForm = pcall(detectDruidForm)
    if not success then
        currentForm = DruidForms.UNKNOWN
    end
    
    if currentForm ~= druidState.currentForm then
        -- Form change detected
        druidState.previous = druidState.currentForm
        druidState.currentForm = currentForm
        druidState.lastFormChange = GetTime()
        
        -- Safely get target health
        local targetHP = 100
        if target and target.exists then
            local hpSuccess, hp = pcall(function() return target.hp end)
            if hpSuccess and hp then
                targetHP = hp
            end
        end
        
        -- Add to history
        druidState.formHistory[#druidState.formHistory + 1] = {
            form = currentForm,
            time = GetTime(),
            health = targetHP
        }
        
        -- Keep only last 10 form changes
        if #druidState.formHistory > 10 then
            table.remove(druidState.formHistory, 1)
        end
        
        if currentForm ~= DruidForms.UNKNOWN then
            notify("🔄 Druid shifted to " .. currentForm .. " form!")
        end
    end
end

local function predictDruidShapeshift()
    if getEnemyClass() ~= "DRUID" then return nil end
    
    local currentForm = druidState.currentForm
    local druidHP = target.hp or 100
    local underPressure = assessStrategicThreat("DRUID") == "HIGH"
    
    local prediction = {
        nextForm = nil,
        confidence = 0,
        reason = nil
    }
    
    if currentForm == DruidForms.CAT and druidHP < 40 then
        prediction.nextForm = DruidForms.BEAR
        prediction.confidence = 8
        prediction.reason = "LOW_HEALTH_NEED_ARMOR"
    elseif currentForm == DruidForms.BEAR and druidHP < 30 then
        prediction.nextForm = DruidForms.HUMAN
        prediction.confidence = 9
        prediction.reason = "CRITICAL_NEED_HEAL"
    elseif currentForm == DruidForms.HUMAN and underPressure then
        prediction.nextForm = DruidForms.CAT
        prediction.confidence = 7
        prediction.reason = "PRESSURE_ESCAPE_STEALTH"
    end
    
    if prediction.confidence >= 7 then
        druidState.predictedNextForm = prediction.nextForm
        return prediction
    end
    
    return nil
end

-- Cooldown tracking functions
local function trackEnemyCooldown(spellId, enemyGUID, enemyClass)
    if not enemyGUID or not enemyClass then return end
    
    local abilities = EnemyAbilities[enemyClass]
    if not abilities then return end
    
    -- Find the ability by spell ID
    local ability = nil
    for name, data in pairs(abilities) do
        if data.id == spellId then
            ability = data
            break
        end
    end
    
    if ability then
        enemyCooldowns[enemyGUID] = enemyCooldowns[enemyGUID] or {}
        enemyCooldowns[enemyGUID][spellId] = {
            usedAt = GetTime(),
            availableAt = GetTime() + ability.cooldown,
            cooldown = ability.cooldown,
            abilityName = name
        }
        
        -- Record in combat history
        combatHistory[#combatHistory + 1] = {
            time = GetTime(),
            enemyClass = enemyClass,
            spellId = spellId,
            playerHealth = player.hp,
            enemyHealth = target.hp
        }
    end
end

local function isEnemyAbilityReady(spellId, enemyGUID)
    if not enemyGUID or not enemyCooldowns[enemyGUID] then return true end
    
    local tracked = enemyCooldowns[enemyGUID][spellId]
    if not tracked then return true end
    
    return GetTime() >= tracked.availableAt
end

local function getEnemyAbilityCooldown(spellId, enemyGUID)
    if not enemyGUID or not enemyCooldowns[enemyGUID] then return 0 end
    
    local tracked = enemyCooldowns[enemyGUID][spellId]
    if not tracked then return 0 end
    
    local remaining = tracked.availableAt - GetTime()
    return math.max(0, remaining)
end

-- Threat assessment functions
local function assessStrategicThreat(enemyClass)
    if not target.exists then return "SAFE" end
    
    local playerHP = player.hp or 100
    local targetHP = target.hp or 100
    local distance = target.distance or 100
    local threat = "NEUTRAL"
    
    if enemyClass == "WARRIOR" then
        local interceptReady = isEnemyAbilityReady(20252, target.guid)
        local chargeReady = isEnemyAbilityReady(100, target.guid)
        
        if distance > 15 and (interceptReady or chargeReady) then
            threat = "HIGH"
        elseif distance < 5 and playerHP < 40 then
            threat = "CRITICAL"
        elseif distance > 20 then
            threat = "LOW"
        end
    elseif enemyClass == "MAGE" then
        local blinkReady = isEnemyAbilityReady(1953, target.guid)
        local iceBlockReady = isEnemyAbilityReady(45438, target.guid)
        
        if target.casting and distance < 30 then
            threat = "HIGH"
        elseif blinkReady and targetHP < 50 then
            threat = "HIGH"
        elseif not blinkReady and distance < 8 then
            threat = "LOW"
        end
    elseif enemyClass == "PALADIN" then
        local divineShieldReady = isEnemyAbilityReady(642, target.guid)
        local hammerReady = isEnemyAbilityReady(853, target.guid)
        
        if divineShieldReady and targetHP < 30 then
            threat = "MEDIUM"
        elseif hammerReady and distance < 10 then
            threat = "MEDIUM"
        elseif target.aura(25771) then -- Forbearance
            threat = "LOW"
        end
    end
    
    return threat
end

-- Enhanced Prediction Engine with Druid/Priest Support
local function predictEnemyActions(enemyClass)
    if not target.exists then return nil end
    
    local config = getConfig()
    if not config.enablePredictions then return nil end
    
    local predictions = {
        action = nil,
        confidence = 0,
        timeWindow = 0,
        counterStrategy = nil
    }
    
    local distance = target.distance or 100
    local targetHP = target.hp or 100
    local playerHP = player.hp or 100
    
    if enemyClass == "WARRIOR" then
        -- Predict Intercept usage
        if distance > 10 and distance < 25 and isEnemyAbilityReady(20252, target.guid) then
            predictions.action = "INTERCEPT"
            predictions.confidence = 8
            predictions.timeWindow = 3
            predictions.counterStrategy = "PREEMPTIVE_STUN"
        end
        -- Predict charge when out of combat
        if not player.combat and distance > 8 and distance < 25 and isEnemyAbilityReady(100, target.guid) then
            predictions.action = "CHARGE"
            predictions.confidence = 9
            predictions.timeWindow = 2
            predictions.counterStrategy = "DODGE_OR_STEALTH"
        end
    elseif enemyClass == "MAGE" then
        -- Predict Frost Nova + Blink combo
        if distance < 8 and isEnemyAbilityReady(122, target.guid) and isEnemyAbilityReady(1953, target.guid) then
            predictions.action = "FROST_NOVA_BLINK"
            predictions.confidence = 7
            predictions.timeWindow = 2
            predictions.counterStrategy = "INTERRUPT_OR_STUN"
        end
        -- Predict Ice Block usage
        if targetHP < 40 and isEnemyAbilityReady(45438, target.guid) then
            predictions.action = "ICE_BLOCK"
            predictions.confidence = 6
            predictions.timeWindow = 5
            predictions.counterStrategy = "POSITION_BEHIND"
        end
    elseif enemyClass == "PALADIN" then
        -- Predict Divine Shield usage
        if targetHP < 50 and isEnemyAbilityReady(642, target.guid) then
            predictions.action = "DIVINE_SHIELD"
            predictions.confidence = 7
            predictions.timeWindow = 4
            predictions.counterStrategy = "FORCE_EARLY_OR_WAIT"
        end
    elseif enemyClass == "DRUID" then
        -- Predict shapeshift based on form and health
        local currentForm = druidState.currentForm
        if currentForm == DruidForms.CAT and targetHP < 40 then
            predictions.action = "BEAR_FORM_SHIFT"
            predictions.confidence = 8
            predictions.timeWindow = 2
            predictions.counterStrategy = "STUN_DURING_SHIFT"
        elseif currentForm == DruidForms.BEAR and targetHP < 30 then
            predictions.action = "HEAL_FORM_SHIFT"
            predictions.confidence = 9
            predictions.timeWindow = 2
            predictions.counterStrategy = "INTERRUPT_HEAL"
        elseif currentForm == DruidForms.HUMAN and target.casting then
            if target.casting == "Healing Touch" then
                predictions.action = "HEALING_TOUCH"
                predictions.confidence = 9
                predictions.timeWindow = 1
                predictions.counterStrategy = "INTERRUPT_IMMEDIATELY"
            end
        elseif currentForm == DruidForms.HUMAN and isEnemyAbilityReady(17116, target.guid) and targetHP < 40 then
            predictions.action = "NATURE_SWIFTNESS_HEAL"
            predictions.confidence = 8
            predictions.timeWindow = 3
            predictions.counterStrategy = "BURST_BEFORE_HEAL"
        end
    elseif enemyClass == "PRIEST" then
        -- Predict Psychic Scream
        if distance < 8 and targetHP < 40 and isEnemyAbilityReady(8122, target.guid) then
            predictions.action = "PSYCHIC_SCREAM"
            predictions.confidence = 9
            predictions.timeWindow = 2
            predictions.counterStrategy = "GET_BEHIND_OR_STUN"
        end
        -- Predict Mind Control
        if targetHP < 25 and isEnemyAbilityReady(605, target.guid) then
            predictions.action = "MIND_CONTROL"
            predictions.confidence = 8
            predictions.timeWindow = 3
            predictions.counterStrategy = "LOS_OR_TRINKET"
        end
        -- Predict healing based on casting
        if target.casting then
            if target.casting == "Greater Heal" then
                predictions.action = "GREATER_HEAL"
                predictions.confidence = 9
                predictions.timeWindow = 1
                predictions.counterStrategy = "INTERRUPT_IMMEDIATELY"
            elseif target.casting == "Flash Heal" then
                predictions.action = "FLASH_HEAL"
                predictions.confidence = 8
                predictions.timeWindow = 0.5
                predictions.counterStrategy = "INTERRUPT_QUICKLY"
            end
        end
    end
    
    -- Only return high-confidence predictions
    local minConfidence = config.predictionConfidence or 7
    if predictions.confidence >= minConfidence then
        predictionState.lastPrediction = GetTime()
        predictionState.confidence = predictions.confidence
        predictionState.nextExpectedAction = predictions.action
        predictionState.timeWindow = predictions.timeWindow
        return predictions
    end
    
    return nil
end

-- Druid-Specific Strategy Functions
local function getDruidStrategy(currentForm)
    local strategy = {
        opener = nil,
        pressure = nil,
        burst = nil,
        control = nil
    }
    
    if currentForm == DruidForms.CAT then
        strategy.opener = "CHEAP_SHOT_BEFORE_STEALTH"
        strategy.pressure = "PREVENT_STEALTH_REGEN"
        strategy.burst = "BEFORE_THEY_SHIFT"
        strategy.control = "STUN_LOCK_IN_CAT"
    elseif currentForm == DruidForms.BEAR then
        strategy.opener = "EXPOSE_ARMOR_FIRST"
        strategy.pressure = "POISON_DOT_DAMAGE"
        strategy.burst = "WAIT_FOR_HUMAN_FORM"
        strategy.control = "FORCE_FORM_SHIFT"
    elseif currentForm == DruidForms.HUMAN then
        strategy.opener = "INTERRUPT_HEALS"
        strategy.pressure = "HEAL_LOCK_COMBO"
        strategy.burst = "BEFORE_BEAR_SHIFT" 
        strategy.control = "SILENCE_CHAIN"
    else
        strategy.opener = "CHEAP_SHOT_SCOUT"
        strategy.pressure = "FORCE_FORM_REVEAL"
        strategy.burst = "REACT_TO_FORM"
        strategy.control = "ADAPTABLE"
    end
    
    return strategy
end

-- Priest-Specific Strategy Functions  
local function getPriestStrategy()
    local distance = target.distance or 100
    local priestHP = target.hp or 100
    
    local strategy = {
        positioning = nil,
        interrupt = nil,
        burst = nil,
        control = nil
    }
    
    if distance < 8 then
        strategy.positioning = "PSYCHIC_SCREAM_RANGE"
        strategy.control = "GET_BEHIND_IMMEDIATELY"
    end
    
    if target.casting then
        strategy.interrupt = "HIGH_PRIORITY"
    end
    
    if priestHP < 40 then
        strategy.burst = "BEFORE_FEAR_PANIC"
        strategy.control = "INTERRUPT_HEAL_CHAIN"
    end
    
    return strategy
end

local function shouldUseAlerts()
    local config = getConfig()
    return config.kitingAlerts ~= false or 
           config.burstWindowAlerts ~= false or 
           config.escapeAlerts ~= false
end

local function assessThreat()
    if not target.exists then return "SAFE" end
    
    local playerHP = player.hp or 100
    local targetHP = target.hp or 100
    
    if playerHP < 25 then
        return "CRITICAL"
    elseif playerHP < 50 and targetHP > 70 then
        return "DANGER"
    elseif playerHP > 70 and targetHP < 30 then
        return "ADVANTAGE"
    else
        return "NEUTRAL"
    end
end

local function getOptimalOpener()
    local config = getConfig()
    
    if player.level < 4 then
        return "basic_attack"
    elseif player.level >= 26 and hasSpell(spells, "Cheap_Shot") and config.useCheapShotOpeners ~= false then
        return "cheap_shot"
    elseif player.level >= 18 and hasSpell(spells, "Ambush") then
        return "ambush"
    elseif player.level >= 14 and hasSpell(spells, "Garrote") then
        return "garrote"
    else
        return "basic_stealth"
    end
end

local function getClassStrategy(enemyClass)
    local config = getConfig()
    local strategy = config["vs" .. enemyClass] or "Auto"
    
    if strategy == "Auto" then
        if enemyClass == "WARRIOR" then
            return player.level >= 26 and "stun_lock" or "kite_heavy"
        elseif enemyClass == "MAGE" then
            return "stick_close"
        elseif enemyClass == "HUNTER" then
            return "stay_close"
        elseif enemyClass == "PRIEST" then
            return "interrupt_focus"
        else
            return "balanced"
        end
    end
    
    return strategy:lower():gsub(" ", "_")
end

local function executeStealthOpener()
    if not player.aura(1784) then return false end
    
    local opener = getOptimalOpener()
    local config = getConfig()
    
    if opener == "cheap_shot" and spells.Cheap_Shot then
        return safeCast(spells.Cheap_Shot, target, "Cheap Shot opener - 4 second stun!")
    elseif opener == "ambush" and spells.Ambush then
        return safeCast(spells.Ambush, target, "Ambush opener - high damage!")
    elseif opener == "garrote" and spells.Garrote then
        return safeCast(spells.Garrote, target, "Garrote opener - DOT + combo point")
    end
    
    return false
end

local function manageCrowdControl()
    local currentCP = player.combopoints or 0
    local config = getConfig()
    
    -- Kidney Shot chain (if available and enough CPs)
    if player.level >= 30 and hasSpell(spells, "Kidney_Shot") and 
       config.useKidneyShotChains ~= false and currentCP >= 1 then
        
        local threat = assessThreat()
        local minCP = (threat == "CRITICAL") and 1 or 3
        
        if currentCP >= minCP then
            return safeCast(spells.Kidney_Shot, target, "Kidney Shot - " .. currentCP .. "CP stun!")
        end
    end
    
    -- Gouge for breathing room
    if player.level >= 6 and hasSpell(spells, "Gouge") and 
       assessThreat() == "CRITICAL" then
        return safeCast(spells.Gouge, target, "Gouge - get behind and restealth!")
    end
    
    return false
end

local function executeFinisher()
    local currentCP = player.combopoints or 0
    local config = getConfig()
    local threat = assessThreat()
    
    if currentCP == 0 then return false end
    
    -- Cold Blood combo (if available)
    if hasSpell(talents, "Cold_Blood") and config.coldBloodCombos ~= false then
        local minCP = config.coldBloodCPThreshold or 5
        if currentCP >= minCP and talents.Cold_Blood:ready() then
            return safeCast(talents.Cold_Blood, player, "Cold Blood active - guaranteed crit!")
        end
    end
    
    -- Emergency finisher on low CP if target is low
    if target.hp <= 25 and currentCP >= 2 then
        return safeCast(spells.Eviscerate, target, "Emergency Eviscerate - finish them!")
    end
    
    -- Standard finisher thresholds
    local finisherCP = 5
    if threat == "CRITICAL" then
        finisherCP = 3
    elseif threat == "DANGER" then
        finisherCP = 4
    end
    
    if currentCP >= finisherCP then
        return safeCast(spells.Eviscerate, target, "Eviscerate - " .. currentCP .. " combo points!")
    end
    
    return false
end

local function buildComboPoints()
    local enemyClass = getEnemyClass()
    local strategy = getClassStrategy(enemyClass)
    
    -- Riposte priority (if available)
    if hasSpell(talents, "Riposte") and talents.Riposte:ready() then
        return safeCast(talents.Riposte, target, "Riposte - reactive strike!")
    end
    
    -- Hemorrhage for PvP (if available)
    if hasSpell(talents, "Hemorrhage") and getConfig().useHemorrhage ~= false then
        return safeCast(talents.Hemorrhage, target)
    end
    
    -- Standard Sinister Strike
    if hasSpell(spells, "SinisterStrike") then
        return safeCast(spells.SinisterStrike, target)
    end
    
    return false
end

-- Strategic opportunity detection
local function detectOpportunityWindows(enemyClass)
    local config = getConfig()
    if not config.burstWindowDetection then return false end
    
    local opportunities = {}
    
    if enemyClass == "WARRIOR" then
        -- Intercept on cooldown = safe window
        if not isEnemyAbilityReady(20252, target.guid) then
            local remaining = getEnemyAbilityCooldown(20252, target.guid)
            opportunities[#opportunities + 1] = {
                type = "SAFE_WINDOW",
                duration = remaining,
                suggestion = "Intercept on CD - Safe to pressure!"
            }
        end
    elseif enemyClass == "MAGE" then
        -- Blink on cooldown = stick close
        if not isEnemyAbilityReady(1953, target.guid) then
            local remaining = getEnemyAbilityCooldown(1953, target.guid)
            opportunities[#opportunities + 1] = {
                type = "MOBILITY_DOWN",
                duration = remaining,
                suggestion = "Blink on CD - Stick close!"
            }
        end
    elseif enemyClass == "PALADIN" then
        -- Forbearance = no bubble
        if target.aura(25771) then
            local remaining = target.auraremains(25771)
            opportunities[#opportunities + 1] = {
                type = "IMMUNITY_DOWN",
                duration = remaining,
                suggestion = "Forbearance active - No Divine Shield!"
            }
        end
    end
    
    return opportunities
end

-- Enhanced tactical advice with predictions
local function provideTacticalAdvice()
    if not shouldUseAlerts() then return end
    
    local enemyClass = getEnemyClass()
    local threat = assessStrategicThreat(enemyClass)
    local predictions = predictEnemyActions(enemyClass)
    local opportunities = detectOpportunityWindows(enemyClass)
    local config = getConfig()
    
    -- Predictive warnings
    if predictions and config.enablePredictions then
        local leadTime = config.warningLeadTime or 3
        local timeSincePrediction = GetTime() - predictionState.lastPrediction
        
        if timeSincePrediction <= leadTime then
            if predictions.action == "INTERCEPT" and config.warriorInterceptWarnings then
                notify("⚡ INTERCEPT INCOMING - " .. predictions.counterStrategy .. "!")
            elseif predictions.action == "FROST_NOVA_BLINK" and config.mageBlinkPredictions then
                notify("🧊 FROST NOVA + BLINK COMBO - " .. predictions.counterStrategy .. "!")
            elseif predictions.action == "DIVINE_SHIELD" and config.paladinBubbleTiming then
                notify("🛡️ DIVINE SHIELD EXPECTED - " .. predictions.counterStrategy .. "!")
            elseif predictions.action == "ICE_BLOCK" then
                notify("🧊 ICE BLOCK INCOMING - " .. predictions.counterStrategy .. "!")
            end
        end
    end
    
    -- Opportunity window alerts
    for _, opportunity in ipairs(opportunities) do
        if config.burstWindowDetection then
            notify("✅ " .. opportunity.suggestion .. " (" .. math.floor(opportunity.duration) .. "s)")
        end
    end
    
    -- Threat-based advice
    if threat == "CRITICAL" and config.escapeAlerts ~= false then
        if hasSpell(spells, "Vanish") and spells.Vanish:ready() then
            notify("⚠️ CRITICAL - Use Vanish to escape!")
        elseif hasSpell(spells, "Sprint") and spells.Sprint:ready() then
            notify("⚠️ CRITICAL - Use Sprint to kite!")
        else
            notify("⚠️ CRITICAL - Need to kite manually!")
        end
    elseif threat == "HIGH" and config.kitingAlerts ~= false then
        notify("⚠️ HIGH THREAT - Consider defensive actions")
    elseif threat == "LOW" and config.burstWindowAlerts ~= false then
        if hasSpell(talents, "Cold_Blood") and talents.Cold_Blood:ready() then
            notify("✅ LOW THREAT - Cold Blood burst available!")
        else
            notify("✅ LOW THREAT - Press the attack!")
        end
    end
    
    -- Counter-strategy hints
    if config.counterStrategyHints then
        if enemyClass == "WARRIOR" and target.distance > 15 then
            notify("🏃 vs Warrior - Kite and use poisons")
        elseif enemyClass == "MAGE" and target.casting then
            notify("🚫 vs Mage - Interrupt or get behind!")
        elseif enemyClass == "PRIEST" and target.distance < 8 then
            notify("😱 vs Priest - Psychic Scream range!")
        end
    end
end

-- Cooldown Baiting Decision Logic
local function shouldBaitCooldowns(enemyClass)
    local config = getConfig()
    if not config.enableCooldownBaiting then return false end
    
    local threat = assessStrategicThreat(enemyClass)
    local baitStrategy = config.baitingAggressiveness or "Moderate"
    
    -- Only bait if we're not in immediate danger
    if threat == "CRITICAL" then return false end
    
    if enemyClass == "MAGE" then
        -- Bait Ice Block if they're low health and have it ready
        return target.hp < 40 and isEnemyAbilityReady(45438, target.guid)
    elseif enemyClass == "PRIEST" then
        -- Bait Psychic Scream by getting close
        return target.distance > 8 and isEnemyAbilityReady(8122, target.guid) and baitStrategy ~= "Conservative"
    elseif enemyClass == "PALADIN" then
        -- Bait Divine Shield with burst threat
        return target.hp < 60 and isEnemyAbilityReady(642, target.guid) and baitStrategy == "Aggressive"
    elseif enemyClass == "WARRIOR" then
        -- Bait Berserker Rage with CC
        return isEnemyAbilityReady(18499, target.guid) and hasSpell(spells, "Cheap_Shot") and player.aura(1784)
    end
    
    return false
end

-- Cooldown Baiting & Manipulation System
local function executeCooldownBait(enemyClass, targetCooldown)
    local config = getConfig()
    
    if enemyClass == "MAGE" and targetCooldown == "ICE_BLOCK" then
        -- Apply pressure to force early Ice Block
        return {
            action = "PRESSURE_SEQUENCE",
            goal = "FORCE_ICE_BLOCK",
            followUp = "POSITION_FOR_POST_BLOCK",
            execute = function()
                if hasSpell(spells, "Cheap_Shot") and player.aura(1784) then
                    notify("🧊 Forcing Ice Block with pressure!")
                    return safeCast(spells.Cheap_Shot, target)
                end
            end
        }
    elseif enemyClass == "WARRIOR" and targetCooldown == "BERSERKER_RAGE" then
        return {
            action = "CHEAP_SHOT",
            goal = "FORCE_BERSERKER_RAGE",
            followUp = "SAVE_STUNS_FOR_AFTER",
            execute = function()
                if hasSpell(spells, "Cheap_Shot") and player.aura(1784) then
                    notify("⚡ Forcing Berserker Rage with stun!")
                    return safeCast(spells.Cheap_Shot, target)
                end
            end
        }
    elseif enemyClass == "DRUID" and targetCooldown == "FORM_SHIFT" then
        local currentForm = druidState.currentForm
        if currentForm == DruidForms.CAT then
            return {
                action = "PRESSURE_TO_FORCE_BEAR",
                goal = "FORCE_DEFENSIVE_SHIFT",
                followUp = "WAIT_FOR_HEAL_FORM",
                execute = function()
                    notify("🐻 Forcing Bear Form with pressure!")
                    -- Apply sustained pressure to force defensive form
                    return false -- Continue with normal rotation but increase pressure
                end
            }
        end
    elseif enemyClass == "PRIEST" and targetCooldown == "PSYCHIC_SCREAM" then
        return {
            action = "FAKE_PRESSURE",
            goal = "FORCE_EARLY_FEAR", 
            followUp = "POSITION_BEHIND",
            execute = function()
                notify("😱 Baiting Psychic Scream!")
                -- Get close to trigger fear, then get behind
                return false
            end
        }
    end
    
    return nil
end

-- Strategic decision making with predictions and baiting
local function executeStrategicAction(enemyClass, predictions)
    if not predictions then return false end
    
    local config = getConfig()
    
    -- Pre-emptive actions based on predictions
    if predictions.action == "INTERCEPT" and predictions.counterStrategy == "PREEMPTIVE_STUN" then
        if hasSpell(spells, "Cheap_Shot") and player.aura(1784) then
            return safeCast(spells.Cheap_Shot, target, "🎯 Pre-emptive Cheap Shot before Intercept!")
        elseif hasSpell(spells, "Kidney_Shot") and player.combopoints >= 1 then
            return safeCast(spells.Kidney_Shot, target, "🎯 Pre-emptive Kidney Shot before Intercept!")
        end
    elseif predictions.action == "FROST_NOVA_BLINK" and predictions.counterStrategy == "INTERRUPT_OR_STUN" then
        if hasSpell(spells, "Kick") and target.casting then
            return safeCast(spells.Kick, target, "🚫 Interrupted before Nova+Blink!")
        end
    elseif predictions.action == "DIVINE_SHIELD" and predictions.counterStrategy == "FORCE_EARLY_OR_WAIT" then
        local strategy = config.strategyAggressiveness or "Adaptive"
        if strategy == "Aggressive" then
            -- Try to force early bubble with burst
            if hasSpell(talents, "Cold_Blood") and player.combopoints >= 4 then
                return safeCast(talents.Cold_Blood, player, "🔥 Forcing early Divine Shield with burst!")
            end
        end
    elseif predictions.action == "BEAR_FORM_SHIFT" and predictions.counterStrategy == "STUN_DURING_SHIFT" then
        if hasSpell(spells, "Cheap_Shot") and player.aura(1784) then
            return safeCast(spells.Cheap_Shot, target, "🔄 Stunning during form shift!")
        end
    elseif predictions.action == "HEAL_FORM_SHIFT" and config.formSpecificStrategies then
        -- Druid shifting to heal form - interrupt immediately
        if hasSpell(spells, "Kick") then
            return safeCast(spells.Kick, target, "🚫 Interrupting form shift to heal!")
        elseif hasSpell(spells, "Kidney_Shot") and player.combopoints >= 1 then
            return safeCast(spells.Kidney_Shot, target, "🔄 Stunning during heal form shift!")
        end
    elseif predictions.action == "HEALING_TOUCH" and predictions.counterStrategy == "INTERRUPT_IMMEDIATELY" then
        if hasSpell(spells, "Kick") and config.healingInterruptPriority then
            return safeCast(spells.Kick, target, "🚫 Interrupted Healing Touch!")
        end
    elseif predictions.action == "NATURE_SWIFTNESS_HEAL" and config.formSpecificStrategies then
        -- High priority - instant heal incoming
        if hasSpell(spells, "Kidney_Shot") and player.combopoints >= 1 then
            return safeCast(spells.Kidney_Shot, target, "⚡ Stopping Nature's Swiftness heal!")
        end
    elseif predictions.action == "PSYCHIC_SCREAM" and predictions.counterStrategy == "GET_BEHIND_OR_STUN" then
        if hasSpell(spells, "Cheap_Shot") and player.aura(1784) and config.fearPositioning then
            return safeCast(spells.Cheap_Shot, target, "😱 Prevented Psychic Scream with stun!")
        end
    elseif predictions.action == "MIND_CONTROL" and config.mindControlPredictions then
        -- Try to break line of sight or stun before MC
        if hasSpell(spells, "Kidney_Shot") and player.combopoints >= 1 then
            return safeCast(spells.Kidney_Shot, target, "🧠 Stopping Mind Control!")
        end
    elseif predictions.action == "GREATER_HEAL" and config.healInterruptChains then
        if hasSpell(spells, "Kick") then
            return safeCast(spells.Kick, target, "🚫 Interrupted Greater Heal!")
        end
    elseif predictions.action == "FLASH_HEAL" and predictions.counterStrategy == "INTERRUPT_QUICKLY" then
        if hasSpell(spells, "Kick") and config.healInterruptChains then
            return safeCast(spells.Kick, target, "🚫 Interrupted Flash Heal!")
        end
    end
    
    -- Cooldown baiting logic
    if config.enableCooldownBaiting then
        local baitStrategy = config.baitingAggressiveness or "Moderate"
        
        if enemyClass == "PRIEST" and target.distance < 8 and not isEnemyAbilityReady(8122, target.guid) then
            -- Psychic Scream is down, apply pressure
            if baitStrategy == "Aggressive" and hasSpell(spells, "Cheap_Shot") and player.aura(1784) then
                return safeCast(spells.Cheap_Shot, target, "💀 Pressure while Psychic Scream down!")
            end
        elseif enemyClass == "MAGE" and not isEnemyAbilityReady(1953, target.guid) then
            -- Blink is down, stick close
            if baitStrategy ~= "Conservative" and hasSpell(spells, "Kidney_Shot") and player.combopoints >= 1 then
                return safeCast(spells.Kidney_Shot, target, "❄️ Locking down while Blink down!")
            end
        end
    end
    
    return false
end

-- Combat State Management Functions
local function determineOptimalCombatState(situation)
    local currentState = combatState.current
    local energyState = situation.energyState
    local threat = situation.threat
    local predictions = situation.predictions
    local enemyClass = situation.enemyClass
    
    -- State transition logic
    if currentState == CombatStates.ANALYZE then
        if player.aura(1784) then -- In stealth
            return CombatStates.OPENER
        elseif energyState == EnergyStates.STARVED then
            return CombatStates.SUSTAIN
        else
            return CombatStates.PRESSURE
        end
    elseif currentState == CombatStates.OPENER then
        if not player.aura(1784) then -- No longer in stealth
            if predictions and predictions.confidence > 8 then
                return CombatStates.BURST
            elseif predictions and predictions.timeWindow <= 2 then
                return CombatStates.ADAPT
            else
                return CombatStates.PRESSURE
            end
        end
    elseif currentState == CombatStates.PRESSURE then
        if threat == "CRITICAL" then
            return CombatStates.ESCAPE
        elseif energyState == EnergyStates.ABUNDANT and detectOpportunityWindows(enemyClass) then
            return CombatStates.BURST
        elseif predictions and predictions.timeWindow < 3 then
            return CombatStates.ADAPT
        elseif shouldBaitCooldowns(enemyClass) then
            return CombatStates.BAIT
        end
    elseif currentState == CombatStates.BURST then
        if energyState == EnergyStates.STARVED then
            return CombatStates.SUSTAIN
        elseif threat == "HIGH" then
            return CombatStates.CONTROL
        else
            return CombatStates.PRESSURE
        end
    elseif currentState == CombatStates.CONTROL then
        if threat == "LOW" then
            return CombatStates.PRESSURE
        elseif energyState == EnergyStates.STARVED then
            return CombatStates.SUSTAIN
        end
    elseif currentState == CombatStates.SUSTAIN then
        if energyState == EnergyStates.READY or energyState == EnergyStates.ABUNDANT then
            if predictions and predictions.timeWindow <= 3 then
                return CombatStates.ADAPT
            elseif shouldBaitCooldowns(enemyClass) then
                return CombatStates.BAIT
            else
                return CombatStates.PRESSURE
            end
        end
    elseif currentState == CombatStates.ADAPT then
        if predictions and predictions.timeWindow > 3 then
            if shouldBaitCooldowns(enemyClass) then
                return CombatStates.BAIT
            else
                return CombatStates.PRESSURE
            end
        elseif energyState == EnergyStates.ABUNDANT and not predictions then
            return CombatStates.BURST
        elseif energyState == EnergyStates.STARVED then
            return CombatStates.SUSTAIN
        end
    elseif currentState == CombatStates.BAIT then
        if threat == "CRITICAL" then
            return CombatStates.ESCAPE
        elseif not shouldBaitCooldowns(enemyClass) then
            return CombatStates.PRESSURE
        elseif energyState == EnergyStates.STARVED then
            return CombatStates.SUSTAIN
        end
    elseif currentState == CombatStates.ESCAPE then
        if threat ~= "CRITICAL" then
            return CombatStates.ANALYZE
        end
    end
    
    return currentState -- Stay in current state if no transition needed
end

local function executeStateAction(state, situation)
    local enemyClass = situation.enemyClass
    local predictions = situation.predictions
    local config = getConfig()
    
    if state == CombatStates.ANALYZE then
        -- Update Druid form tracking
        if enemyClass == "DRUID" then
            updateDruidState()
        end
        return false
        
    elseif state == CombatStates.OPENER then
        if player.aura(1784) and config.useStealthOpeners ~= false then
            return executeStealthOpener()
        end
        
    elseif state == CombatStates.PRESSURE then
        -- Sustained damage and pressure
        if buildComboPoints() then
            return true
        end
        
    elseif state == CombatStates.BURST then
        -- Execute burst sequence
        if executeFinisher() then
            return true
        end
        
    elseif state == CombatStates.CONTROL then
        -- Crowd control management
        if manageCrowdControl() then
            return true
        end
        
    elseif state == CombatStates.SUSTAIN then
        -- Energy pooling - don't execute abilities, just wait
        local config = getConfig()
        if config.stateNotifications then
            notify("⚡ Pooling energy for next opportunity...")
        end
        return false
        
    elseif state == CombatStates.ADAPT then
        -- React to predictions
        if config.enablePredictions and executeStrategicAction(enemyClass, predictions) then
            return true
        end
        
    elseif state == CombatStates.BAIT then
        -- Execute cooldown baiting strategy
        local baitResult = executeCooldownBait(enemyClass, "STRATEGIC")
        if baitResult and baitResult.execute then
            return baitResult.execute()
        end
        -- Default baiting behavior - apply moderate pressure
        return buildComboPoints()
        
    elseif state == CombatStates.ESCAPE then
        -- Emergency escape logic (handled by player manually)
        notify("🚨 ESCAPE STATE - Use defensive abilities!")
        return false
    end
    
    return false
end

local function updateCombatState(newState, actionResult)
    if newState ~= combatState.current then
        combatState.previous = combatState.current
        combatState.current = newState
        combatState.transitionTime = GetTime()
        
        -- Clear state-specific data on transition
        combatState.stateData = {}
        
        -- Update energy state
        combatState.energyState = assessEnergyState()
        
        local config = getConfig()
        
        -- State change notifications
        if config.stateNotifications then
            local stateMessages = {
                [CombatStates.ANALYZE] = "🔍 ANALYZING situation...",
                [CombatStates.OPENER] = "⚔️ OPENER phase - engaging!",
                [CombatStates.PRESSURE] = "💪 PRESSURE phase - building advantage",
                [CombatStates.BURST] = "🔥 BURST phase - maximum damage!",
                [CombatStates.CONTROL] = "🛡️ CONTROL phase - crowd control",
                [CombatStates.BAIT] = "🎣 BAIT phase - forcing cooldowns",
                [CombatStates.SUSTAIN] = "⚡ SUSTAIN phase - energy recovery",
                [CombatStates.ADAPT] = "🎯 ADAPT phase - reactive strategy",
                [CombatStates.ESCAPE] = "🚨 ESCAPE phase - emergency!"
            }
            
            local message = stateMessages[newState] or ("🔄 Combat State: " .. newState)
            notify(message)
        else
            -- Minimal notification for critical states
            if newState == CombatStates.ESCAPE then
                notify("🚨 ESCAPE STATE - Use defensive abilities!")
            elseif newState == CombatStates.BURST then
                notify("🔥 BURST WINDOW!")
            end
        end
    end
end

-- Unified Cohesive Rotation Controller
local function executeCohesiveRotation()
    -- Comprehensive safety checks
    if not target or not target.exists then
        combatState.current = CombatStates.ANALYZE
        return false
    end
    
    local targetAlive = true
    local targetEnemy = true
    
    -- Safe target state checks
    local success, alive = pcall(function() return target.alive end)
    if success then targetAlive = alive else targetAlive = false end
    
    local success2, enemy = pcall(function() return target.enemy end)
    if success2 then targetEnemy = enemy else targetEnemy = false end
    
    if not targetAlive or not targetEnemy then
        combatState.current = CombatStates.ANALYZE
        return false
    end
    
    -- 1. Analyze complete situation with safe value extraction
    local enemyClass = getEnemyClass()
    local situation = {
        energyState = assessEnergyState(),
        threat = "NEUTRAL",
        enemyClass = enemyClass,
        predictions = nil,
        currentCP = 0,
        playerHP = 100,
        targetHP = 100,
        distance = 100
    }
    
    -- Safe value extraction with error handling
    local function safeGet(obj, prop, default)
        local success, value = pcall(function() return obj[prop] end)
        return success and value or default
    end
    
    situation.currentCP = safeGet(player, "combopoints", 0)
    situation.playerHP = safeGet(player, "hp", 100)
    situation.targetHP = safeGet(target, "hp", 100) 
    situation.distance = safeGet(target, "distance", 100)
    
    -- Safe threat assessment and predictions
    local threatSuccess, threat = pcall(assessStrategicThreat, enemyClass)
    if threatSuccess then situation.threat = threat end
    
    local predSuccess, predictions = pcall(predictEnemyActions, enemyClass)
    if predSuccess then situation.predictions = predictions end
    
    -- Update Druid state if fighting druid (with error handling)
    if situation.enemyClass == "DRUID" then
        local druidSuccess, druidError = pcall(updateDruidState)
        if not druidSuccess then
            -- Reset druid state on error
            druidState.currentForm = DruidForms.UNKNOWN
        end
    end
    
    -- 2. Determine optimal combat state (with error handling)
    local optimalState = combatState.current
    local stateSuccess, newState = pcall(determineOptimalCombatState, situation)
    if stateSuccess and newState then
        optimalState = newState
    end
    
    -- 3. Check if we should pool energy before action
    local poolSuccess, shouldPool = pcall(shouldPoolEnergy, combatState.plannedActions and combatState.plannedActions[1], optimalState)
    if poolSuccess and shouldPool then
        local config = getConfig()
        if config.stateNotifications then
            notify("⚡ Pooling energy for optimal action...")
        end
        return false
    end
    
    -- 4. Execute state-specific logic (with error handling)
    local actionTaken = false
    local actionSuccess, result = pcall(executeStateAction, optimalState, situation)
    if actionSuccess then
        actionTaken = result
    end
    
    -- 5. Update combat state
    updateCombatState(optimalState, actionTaken)
    
    -- 6. Provide tactical advice (with error handling)
    local adviceSuccess = pcall(provideTacticalAdvice)
    -- Continue even if advice fails
    
    return actionTaken
end

-- Legacy function maintained for compatibility
local function adaptiveRotation()
    return executeCohesiveRotation()
end

-- Combat log event handler for tracking enemy abilities
local function onCombatLogEvent(...)
    local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags, spellId, spellName = ...
    
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == target.guid then
        local enemyClass = getEnemyClass()
        trackEnemyCooldown(spellId, sourceGUID, enemyClass)
    end
end

-- Register combat log event handler
local combatLogFrame = CreateFrame("Frame")
combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatLogFrame:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLogEvent(CombatLogGetCurrentEventInfo())
    end
end)

-- Main combat loop
Aurora:OnUpdate(function()
    if player.combat and not player.channeling and not player.casting then
        adaptiveRotation()
    end
end, true)

-- Strategic analysis update (less frequent)
local lastAnalysisUpdate = 0
Aurora:OnUpdate(function()
    local now = GetTime()
    if now - lastAnalysisUpdate > 1 then -- Update every second
        lastAnalysisUpdate = now
        
        local config = getConfig()
        if config.cooldownTracking and target.exists then
            -- Cleanup old cooldown data (older than 10 minutes)
            for guid, cooldowns in pairs(enemyCooldowns) do
                for spellId, data in pairs(cooldowns) do
                    if now - data.usedAt > 600 then
                        cooldowns[spellId] = nil
                    end
                end
            end
        end
    end
end, true)

-- Level-up notification with strategic advice
local lastLevel = player.level
Aurora:OnUpdate(function()
    if player.level > lastLevel then
        notify("🎉 Level " .. player.level .. " - New abilities may be available!")
        
        -- Provide level milestone advice
        if player.level == 26 then
            notify("🎯 Level 26 - Cheap Shot unlocked! Game-changing PvP ability!")
        elseif player.level == 30 then
            notify("🎯 Level 30 - Kidney Shot unlocked! Stun chain combos available!")
        elseif player.level == 40 then
            notify("🎯 Level 40 - Major talent tier! Check for Cold Blood/Preparation!")
        end
        
        lastLevel = player.level
    end
end, true)

-- Strategic intelligence summary on target change
local lastTargetGUID = nil
Aurora:OnUpdate(function()
    if target.exists and target.guid ~= lastTargetGUID then
        lastTargetGUID = target.guid
        
        local enemyClass = getEnemyClass()
        local config = getConfig()
        
        if config.autoClassDetection and enemyClass ~= "UNKNOWN" then
            notify("🎯 " .. enemyClass .. " detected - Adapting strategy...")
            
            -- Provide class-specific strategic overview
            if enemyClass == "WARRIOR" then
                notify("⚔️ Warrior Strategy: Kite, use poisons, avoid Intercept")
            elseif enemyClass == "MAGE" then
                notify("🔮 Mage Strategy: Stick close, interrupt, counter Blink")
            elseif enemyClass == "PALADIN" then
                notify("🛡️ Paladin Strategy: Force bubble early, wait out immunity")
            end
        end
    elseif not target.exists then
        lastTargetGUID = nil
    end
end, true)