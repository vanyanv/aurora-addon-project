local Routine = Aurora.Routine
local MyNamespace = Routine.Namespace
local player = Aurora.UnitManager:Get("player")
local target = Aurora.UnitManager:Get("target")
local enemies = Aurora.enemies

local spells = Aurora.SpellHandler.Spellbooks.rogue["9"].Combat.spells
local auras = Aurora.SpellHandler.Spellbooks.rogue["9"].Combat.auras

local function combat()
    if not target.exists or not target.enemy or not target.alive then
        return
    end

    local config = Aurora.config or {}
    local smartCPSpending = config.smartCPSpending ~= false
    local emergencyCPThreshold = config.emergencyCPThreshold or 25
    local mediumCPThreshold = config.mediumCPThreshold or 50
    local maintainSliceAndDice = config.maintainSliceAndDice ~= false
    local use1CPSliceAndDice = config.use1CPSliceAndDice ~= false

    local currentCP = player.combopoints or 0
    local targetHP = target.hp or 100

    -- Priority 1: Riposte (reactive DPS ability)
    if spells.Riposte and spells.Riposte:ready() and spells.Riposte:cast(target) then
        return true
    end

    -- Priority 2: Maintain Slice and Dice
    if maintainSliceAndDice and not player.aura(5171) then
        if use1CPSliceAndDice and currentCP >= 1 then
            if spells.SliceAndDice:cast(player) then
                return true
            end
        elseif currentCP >= 5 then
            if spells.SliceAndDice:cast(player) then
                return true
            end
        end
    end

    -- Priority 3: Smart Combo Point Spending
    if smartCPSpending then
        local shouldSpend = false
        local requiredCP = 5

        if targetHP <= emergencyCPThreshold and currentCP >= 2 then
            shouldSpend = true
            requiredCP = 2
        elseif targetHP <= mediumCPThreshold and currentCP >= 3 then
            shouldSpend = true
            requiredCP = 3
        elseif currentCP >= 5 then
            shouldSpend = true
            requiredCP = 5
        end

        if shouldSpend and currentCP >= requiredCP then
            if spells.Eviscerate:cast(target) then
                return true
            end
        end
    else
        -- Simple 5 CP spending if smart spending is disabled
        if currentCP >= 5 then
            if spells.Eviscerate:cast(target) then
                return true
            end
        end
    end

    -- Priority 4: Build Combo Points with Sinister Strike
    if currentCP < 5 then
        if spells.SinisterStrike:cast(target) then
            return true
        end
    end

    return false
end

Aurora:OnUpdate(function()
    if player.combat and not player.channeling and not player.casting then
        combat()
    end
end, true)