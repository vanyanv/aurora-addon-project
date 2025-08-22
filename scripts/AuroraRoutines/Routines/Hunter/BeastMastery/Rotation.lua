local Routine = Aurora.Routine
local player = Aurora.UnitManager:Get("player")
local target = Aurora.UnitManager:Get("target")
local pet = Aurora.UnitManager:Get("pet")
local enemies = Aurora.enemies
local spells = Aurora.SpellHandler.Spellbooks.hunter["253"].BeastMasteryLeveling.spells
local auras = Aurora.SpellHandler.Spellbooks.hunter["253"].BeastMasteryLeveling.auras
local talents = Aurora.SpellHandler.Spellbooks.hunter["253"].BeastMasteryLeveling.talents

-- Level-based spell selection functions
local function getBestSpellByLevel(baseSpell, ranks)
    for i = #ranks, 1, -1 do
        if ranks[i].spell:isknown() then
            return ranks[i].spell
        end
    end
    return baseSpell:isknown() and baseSpell or nil
end

-- Define spell ranks for progression
local arcaneRanks = {
    {level = 6, spell = spells.ArcaneShot},
    {level = 12, spell = spells.ArcaneShotR2},
    {level = 20, spell = spells.ArcaneShotR3},
    {level = 28, spell = spells.ArcaneShotR4},
    {level = 36, spell = spells.ArcaneShotR5},
    {level = 44, spell = spells.ArcaneShotR6},
    {level = 52, spell = spells.ArcaneShotR7},
    {level = 60, spell = spells.ArcaneShotR8}
}

local serpentRanks = {
    {level = 4, spell = spells.SerpentSting},
    {level = 10, spell = spells.SerpentStingR2},
    {level = 18, spell = spells.SerpentStingR3},
    {level = 26, spell = spells.SerpentStingR4},
    {level = 34, spell = spells.SerpentStingR5},
    {level = 42, spell = spells.SerpentStingR6},
    {level = 50, spell = spells.SerpentStingR7},
    {level = 58, spell = spells.SerpentStingR8}
}

local markRanks = {
    {level = 6, spell = spells.HuntersMark},
    {level = 26, spell = spells.HuntersMarkR2},
    {level = 40, spell = spells.HuntersMarkR3},
    {level = 56, spell = spells.HuntersMarkR4}
}

local function getConfig(key, default)
    return Aurora.config[key] ~= nil and Aurora.config[key] or default
end

local function debug(...)
    if Aurora.debug then
        print("BM Hunter:", ...)
    end
end

-- Pet Management Functions (Classic)
local function managePet()
    if not getConfig("autoSummonPet", true) then return false end
    
    -- Tame a beast if no pet and player is level 10+
    if not pet.exists and player.level >= 10 then
        if spells.CallPet:ready() then
            debug("Summoning pet")
            return spells.CallPet:cast(player)
        end
    end
    
    -- Revive pet if dead
    if pet.exists and pet.dead and spells.RevivePet:ready() and not player.combat then
        debug("Reviving dead pet")
        return spells.RevivePet:cast(pet)
    end
    
    -- Mend pet if injured (Classic version)
    if pet.exists and pet.alive and getConfig("autoMendPet", true) then
        local petHealthThreshold = getConfig("petHealthThreshold", 50)
        if pet.hp < petHealthThreshold and spells.MendPet:ready() and not player.combat then
            debug("Mending pet at", pet.hp, "% health")
            return spells.MendPet:cast(pet)
        end
    end
    
    -- Send pet to attack target
    if pet.exists and pet.alive and target.exists and target.enemy and target.alive then
        if getConfig("petAttackTarget", true) and pet.target ~= target.guid then
            debug("Sending pet to attack target")
            spells.PetAttack:cast(target)
        end
    end
    
    return false
end

-- Auto Shot Management (Classic - Rotation Backbone)
local function manageAutoShot()
    if not getConfig("enableAutoShot", true) then return false end
    
    if target.exists and target.enemy and target.alive and target.distance <= 35 then
        -- Auto Shot is the backbone of Classic Hunter damage
        if not player.moving and not player.casting then
            if spells.AutoShot:ready() then
                debug("Maintaining Auto Shot")
                return spells.AutoShot:cast(target)
            end
        end
        
        -- If we're moving, we should stop to auto shot when possible
        if player.moving and getConfig("prioritizeAutoShot", true) then
            -- Don't interrupt movement if we just started moving or if in combat with multiple enemies
            local enemyCount = enemies:filter(function(u) return u.distance < 10 and u.combat end):count()
            if enemyCount <= 1 and not player.aura(auras.AspectOfTheCheetah.spellId) then
                debug("Consider stopping for Auto Shot")
                -- The framework will handle this automatically
            end
        end
    end
    
    return false
end

-- Enhanced Auto Shot - Always try to maintain
local function ensureAutoShot()
    if not target.exists or not target.enemy or not target.alive then return false end
    if target.distance > 35 or player.moving then return false end
    
    -- Auto Shot should always be active in Classic
    if spells.AutoShot:ready() then
        debug("Ensuring Auto Shot is active")
        return spells.AutoShot:cast(target)
    end
    
    return false
end

-- Defensive Functions (Classic)
local function checkDefensives()
    -- Feign Death for emergency situations
    if getConfig("autoFeignDeath", true) then
        local feignHealth = getConfig("feignDeathHealth", 20)
        if player.hp < feignHealth and spells.FeignDeath:ready() then
            debug("Using Feign Death at", player.hp, "% health")
            return spells.FeignDeath:cast(player)
        end
    end
    
    -- Wing Clip for melee enemies (Classic hunters don't have Disengage)
    if getConfig("autoWingClip", true) then
        local nearbyEnemies = enemies:filter(function(u) 
            return u.distance <= 5 and u.combat and not u.aura(auras.WingClip.spellId)
        end):first()
        
        if nearbyEnemies and spells.WingClip:ready() and hasSufficientMana(30) then
            debug("Using Wing Clip on nearby enemy")
            return spells.WingClip:cast(nearbyEnemies)
        end
    end
    
    -- Aspect switching for defense
    if not player.aura(auras.AspectOfTheMonkey.spellId) and player.hp < 50 then
        if spells.AspectOfTheMonkey:ready() then
            debug("Switching to Aspect of the Monkey for dodge")
            return spells.AspectOfTheMonkey:cast(player)
        end
    end
    
    return false
end

-- Utility Functions (Classic)
local function handleUtility()
    if not target.exists or not target.enemy then return false end
    
    -- Hunter's Mark (Classic - most important)
    if getConfig("autoHuntersMark", true) then
        local bestMark = getBestHuntersMark()
        if bestMark and not target.aura(auras.HuntersMark.spellId) and bestMark:ready() then
            debug("Applying Hunter's Mark")
            return bestMark:cast(target)
        end
    end
    
    -- Concussive Shot for kiting
    if getConfig("autoKiting", true) and target.distance > 8 and target.distance < 30 then
        if not target.aura(auras.ConcussiveShot.spellId) and spells.ConcussiveShot:ready() and hasSufficientMana(50) then
            debug("Using Concussive Shot for kiting")
            return spells.ConcussiveShot:cast(target)
        end
    end
    
    return false
end

-- AOE Detection and Handling
local function getAOETargetCount()
    local aoeRange = 8 -- Multi-Shot range
    return enemies:filter(function(u) 
        return u.distance < aoeRange and u.alive and u.enemy 
    end):count()
end

local function shouldUseAOE()
    if not getConfig("useMultiShot", true) then return false end
    local aoeCount = getConfig("aoeCount", 3)
    return getAOETargetCount() >= aoeCount
end

-- Mana Management (Classic) - Enhanced with tiers
local function getManaPercent()
    if player.manamax == 0 then return 0 end
    return (player.mana / player.manamax) * 100
end

local function getManaMode()
    local manaPercent = getManaPercent()
    if manaPercent >= 80 then
        return "HIGH" -- Full rotation available
    elseif manaPercent >= 30 then
        return "MEDIUM" -- Conservative rotation
    else
        return "LOW" -- Emergency mode - regen priority
    end
end

local function hasSufficientMana(spellCost, manaMode)
    local threshold = getConfig("manaThreshold", 200)
    local manaPercent = getManaPercent()
    manaMode = manaMode or getManaMode()
    
    -- Emergency threshold - always reserve mana
    if player.mana < threshold then
        return false
    end
    
    -- Mode-based mana management
    if manaMode == "HIGH" then
        return player.mana >= (spellCost or 0)
    elseif manaMode == "MEDIUM" then
        -- More conservative in medium mana
        return player.mana >= ((spellCost or 0) + 100)
    else -- LOW mode
        -- Only allow very cheap spells
        return player.mana >= ((spellCost or 0) + 300) and (spellCost or 0) <= 30
    end
end

-- Spell efficiency calculations (damage per mana)
local spellEfficiency = {
    AutoShot = 999, -- Free damage, highest priority
    SerpentSting = 8, -- Great DoT efficiency for leveling
    ArcaneShotR1 = 3, -- Lower rank for efficiency
    ArcaneShot = 2,   -- Expensive but good damage
    MultiShot = 1.5,  -- AOE only
    AimedShot = 1.2,  -- High damage but very expensive
    RaptorStrike = 10 -- Cheap melee emergency
}

local function shouldUseManaRegenMode()
    local manaPercent = getManaPercent()
    local waitThreshold = getConfig("manaWaitThreshold", 25)
    
    if manaPercent < waitThreshold then
        debug("Entering mana regeneration mode -", manaPercent, "% mana")
        return true
    end
    
    return false
end

-- Get the best available rank of a spell based on player level
local function getBestArcaneShot()
    return getBestSpellByLevel(spells.ArcaneShot, arcaneRanks)
end

local function getBestSerpentSting()
    return getBestSpellByLevel(spells.SerpentSting, serpentRanks)
end

local function getBestHuntersMark()
    return getBestSpellByLevel(spells.HuntersMark, markRanks)
end

-- Aspect management
local function manageAspects()
    if player.combat then
        -- Use Aspect of the Hawk in combat for damage
        if not player.aura(auras.AspectOfTheHawk.spellId) and spells.AspectOfTheHawk:ready() then
            debug("Switching to Aspect of the Hawk")
            return spells.AspectOfTheHawk:cast(player)
        end
    else
        -- Use Aspect of the Cheetah out of combat for movement
        if getConfig("useAspectCheetah", false) and player.moving then
            if not player.aura(auras.AspectOfTheCheetah.spellId) and spells.AspectOfTheCheetah:ready() then
                debug("Switching to Aspect of the Cheetah for movement")
                return spells.AspectOfTheCheetah:cast(player)
            end
        end
    end
    return false
end

-- Main Rotation Logic (Classic) - Mana-aware
local function singleTargetRotation()
    if not target.exists or not target.enemy or not target.alive then return false end
    
    local manaMode = getManaMode()
    local manaPercent = getManaPercent()
    
    debug("Single target rotation - Mana:", manaPercent, "% Mode:", manaMode)
    
    -- CRITICAL: Check if we should wait for mana regeneration
    if shouldUseManaRegenMode() then
        debug("Waiting for mana regeneration")
        -- Only allow Auto Shot and emergency abilities
        if ensureAutoShot() then return true end
        
        -- Emergency melee if forced into melee range
        if target.distance <= 5 and spells.RaptorStrike:ready() and player.mana >= 20 then
            debug("Emergency Raptor Strike while low mana")
            if spells.RaptorStrike:cast(target) then return true end
        end
        
        return false -- Wait for mana to regenerate
    end
    
    -- HIGH MANA MODE (80%+) - Full rotation
    if manaMode == "HIGH" then
        -- Bestial Wrath (if talented and conditions met)
        if getConfig("useBestialWrath", false) and talents.BestialWrath:isknown() then
            if target.hp > getConfig("burstHealthThreshold", 80) and talents.BestialWrath:ready() then
                debug("Using Bestial Wrath (HIGH mana)")
                if talents.BestialWrath:cast(player) then return true end
            end
        end
        
        -- Aimed Shot (if talented and have time to cast)
        if talents.AimedShot:isknown() and not player.moving then
            if talents.AimedShot:ready() and hasSufficientMana(100, manaMode) and target.hp > 30 then
                debug("Using Aimed Shot (HIGH mana)")
                if talents.AimedShot:cast(target) then return true end
            end
        end
        
        -- Serpent Sting DoT (Classic leveling priority)
        if getConfig("useSerpentSting", true) then
            local bestSting = getBestSerpentSting()
            if bestSting and not target.aura(auras.SerpentSting.spellId) and bestSting:ready() and hasSufficientMana(30, manaMode) then
                debug("Applying Serpent Sting (HIGH mana)")
                if bestSting:cast(target) then return true end
            end
        end
        
        -- Arcane Shot (primary damage dealer)
        local bestArcane = getBestArcaneShot()
        if bestArcane and bestArcane:ready() and hasSufficientMana(50, manaMode) then
            debug("Using Arcane Shot (HIGH mana)")
            if bestArcane:cast(target) then return true end
        end
    
    -- MEDIUM MANA MODE (30-80%) - Conservative rotation
    elseif manaMode == "MEDIUM" then
        debug("Conservative rotation - medium mana")
        
        -- Serpent Sting (most efficient DoT)
        if getConfig("useSerpentSting", true) then
            local bestSting = getBestSerpentSting()
            if bestSting and not target.aura(auras.SerpentSting.spellId) and bestSting:ready() and hasSufficientMana(30, manaMode) then
                debug("Applying Serpent Sting (MEDIUM mana)")
                if bestSting:cast(target) then return true end
            end
        end
        
        -- Only use Arcane Shot if target has high HP (worth the mana)
        if target.hp > 50 then
            local bestArcane = getBestArcaneShot()
            if bestArcane and bestArcane:ready() and hasSufficientMana(50, manaMode) then
                debug("Using Arcane Shot - high HP target (MEDIUM mana)")
                if bestArcane:cast(target) then return true end
            end
        end
    
    -- LOW MANA MODE (<30%) - Emergency only
    else
        debug("Emergency mode - low mana")
        
        -- Only Serpent Sting if target has very high HP and it's worth it
        if target.hp > 80 and getConfig("useSerpentSting", true) then
            local bestSting = getBestSerpentSting()
            if bestSting and not target.aura(auras.SerpentSting.spellId) and bestSting:ready() and hasSufficientMana(30, manaMode) then
                debug("Emergency Serpent Sting - high HP target (LOW mana)")
                if bestSting:cast(target) then return true end
            end
        end
    end
    
    -- Multi-Shot for AOE (all modes, but check mana)
    if shouldUseAOE() and manaMode ~= "LOW" then
        local bestMulti = spells.MultiShot
        if bestMulti:ready() and hasSufficientMana(80, manaMode) then
            debug("Using Multi-Shot for AOE")
            if bestMulti:cast(target) then return true end
        end
    end
    
    -- Raptor Strike if in melee range (all modes)
    if target.distance <= 5 and spells.RaptorStrike:ready() and hasSufficientMana(20, manaMode) then
        debug("Using Raptor Strike in melee")
        if spells.RaptorStrike:cast(target) then return true end
    end
    
    -- Always try to maintain Auto Shot last
    if ensureAutoShot() then return true end
    
    return false
end

local function aoeRotation()
    local aoeTargetCount = getAOETargetCount()
    if aoeTargetCount < getConfig("aoeCount", 3) then return false end
    
    debug("AOE rotation with", aoeTargetCount, "targets")
    
    -- Multi-Shot is the main AOE ability in Classic
    local bestMulti = spells.MultiShot
    if bestMulti:ready() and hasSufficientMana(80) then
        debug("Using Multi-Shot on", aoeTargetCount, "targets")
        if bestMulti:cast(target) then return true end
    end
    
    -- Explosive Trap if available and positioned well
    if spells.ExplosiveTrap:ready() and hasSufficientMana(50) and aoeTargetCount >= 4 then
        debug("Using Explosive Trap for AOE")
        if spells.ExplosiveTrap:cast(target) then return true end
    end
    
    -- Fall back to single target rotation
    return singleTargetRotation()
end

-- Out of Combat Functions (Classic)
local function outOfCombat()
    -- Aspect management
    if manageAspects() then return true end
    
    -- Pet management
    if managePet() then return true end
    
    -- Auto Shot management - ensure it's ready
    if manageAutoShot() then return true end
    
    return false
end

-- Main Combat Function (Classic) - Enhanced with mana priority
local function combat()
    if not player.combat then
        return outOfCombat()
    end
    
    local manaMode = getManaMode()
    local manaPercent = getManaPercent()
    
    -- PRIORITY 1: Auto Shot maintenance (backbone of Classic Hunter)
    if ensureAutoShot() then return true end
    
    -- PRIORITY 2: Emergency defensives (regardless of mana)
    if checkDefensives() then return true end
    
    -- PRIORITY 3: Critical mana management
    if shouldUseManaRegenMode() then
        debug("Critical mana mode - preserving mana for survival")
        -- Only essential abilities when critically low on mana
        
        -- Still manage pet (might be taking damage)
        if managePet() then return true end
        
        -- Essential utility only
        local bestMark = getBestHuntersMark()
        if bestMark and not target.aura(auras.HuntersMark.spellId) and bestMark:ready() and player.mana >= 30 then
            debug("Essential Hunter's Mark (critical mana)")
            if bestMark:cast(target) then return true end
        end
        
        -- Don't cast other spells - let mana regenerate
        return false
    end
    
    -- PRIORITY 4: Aspect management (low mana cost)
    if manageAspects() then return true end
    
    -- PRIORITY 5: Pet management 
    if managePet() then return true end
    
    -- PRIORITY 6: Essential utility (Hunter's Mark is critical)
    if handleUtility() then return true end
    
    -- PRIORITY 7: Mana-aware rotation
    debug("Combat rotation - Mana:", manaPercent, "% Mode:", manaMode)
    
    -- AOE vs Single Target decision (consider mana mode)
    if shouldUseAOE() and manaMode ~= "LOW" then
        if aoeRotation() then return true end
    end
    
    -- Single target rotation (mana-aware)
    if singleTargetRotation() then return true end
    
    -- PRIORITY 8: Auto Shot fallback (should always be maintained)
    if manageAutoShot() then return true end
    
    return false
end

-- Smart Target Selection
local function smartTargeting()
    if not getConfig("smartTargeting", true) then return end
    
    if not target.exists or not target.enemy or not target.alive then
        -- Find nearest enemy
        local nearestEnemy = enemies:filter(function(u) 
            return u.alive and u.distance < 40 
        end):sort(function(a, b) 
            return a.distance < b.distance 
        end):first()
        
        if nearestEnemy then
            debug("Auto-targeting nearest enemy:", nearestEnemy.name)
            nearestEnemy:settarget()
        end
    end
end

-- Main Execution
Routine:SetCombatFunc(function()
    smartTargeting()
    return combat()
end)

debug("Beast Mastery Hunter Leveling Rotation Loaded")