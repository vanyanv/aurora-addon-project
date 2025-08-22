# Aurora Framework Complete API Reference

## Table of Contents
1. [Framework Overview](#framework-overview)
2. [Project Setup](#project-setup)
3. [Unit System](#unit-system)
4. [Lists and Virtual Units](#lists-and-virtual-units)
5. [Spell System](#spell-system)
6. [Missiles System](#missiles-system)
7. [Utility Functions](#utility-functions)
8. [Interface System](#interface-system)
9. [Macro System](#macro-system)
10. [Enumerations](#enumerations)
11. [Development Tools](#development-tools)

## Framework Overview

Aurora is a comprehensive World of Warcraft addon development framework focused on combat rotation automation and spell management. It provides:

- **Namespace Management**: Avoid conflicts and organize code
- **Modular Architecture**: Structured file loading with `loadorder.json`
- **Spell-Centric Design**: Robust spell handling and intelligent casting
- **Unit Management**: Comprehensive unit tracking and interaction
- **Development Tools**: Integrated debugging and testing utilities

## Project Setup

### Directory Structure
```
📂 scripts/
└── 📂 AuroraRoutines/
    ├── 📄 loadorder.json
    ├── 📄 Main.lua
    └── 📂 Routines/
        └── 📂 [Class]/
            └── 📂 [Specialization]/
                ├── 📄 Spellbook.lua
                ├── 📄 Interface.lua
                └── 📄 Rotation.lua
```

### Initial Setup
```bash
# Create directories
mkdir -p scripts/AuroraRoutines/Routines

# Create loadorder.json
echo '{"files": ["Main.lua"]}' > scripts/AuroraRoutines/loadorder.json
```

### Namespace Configuration
```lua
-- Namespace is automatically passed when routines are loaded
local Routine = Aurora.Routine
local Unlocker = Aurora.Unlocker

-- Access your namespace
local MyNamespace = Routine.Namespace
```

### Loading System
1. Framework checks for routines directory
2. Reads `loadorder.json` for file load order
3. Loads files in specified sequence
4. Passes namespace to each file

## Unit System

### Unit Properties

#### Identification Properties
- `unit.guid` - Unique identifier
- `unit.name` - Unit's name  
- `unit.id` - Unit's ID
- `unit.class` - Class name
- `unit.race` - Race name
- `unit.level` - Unit level

#### Health & Status
- `unit.health` - Current health value
- `unit.healthmax` - Maximum health
- `unit.healthpercent` or `unit.hp` - Health percentage (0-100)
- `unit.dead` - Boolean death status
- `unit.alive` - Boolean alive status
- `unit.exists` - Unit exists check

#### Combat Properties
- `unit.combat` - In combat status
- `unit.enemy` - Is enemy
- `unit.aggro` - Has aggro
- `unit.threat` - Threat level
- `unit.aggrotowards(target)` - Aggro towards specific target

#### Movement & Position
- `unit.position` - 3D space location
- `unit.speed` - Movement speed
- `unit.moving` - Movement status
- `unit.distance` or `unit.distanceto(target)` - Distance to target

#### Casting Information
- `unit.casting` - Current cast name
- `unit.castinginterruptible` - Can interrupt cast
- `unit.channelingremains` - Channel time remaining percentage
- `unit.castingpercent` - Cast progress percentage

### Unit Methods

#### Position & Movement Methods
```lua
-- Check positioning
unit.behind(target)           -- Unit is behind target
unit.infront(target)          -- Unit is in front of target
unit.melee(target)           -- Unit in melee range
unit.distanceto(target)      -- Distance in yards

-- Movement prediction
unit.movingtoward(target, {angle = 45, duration = 1})
unit.movingawayfrom(target, {angle = 45, duration = 1})
unit.predictposition(1.5)    -- Predict position after 1.5 seconds
```

#### Combat Methods
```lua
-- Area checks
unit.inarcof(target, size, arc, rotation)
unit.inrectangleof(target, width, length, rotation)
unit.enemiesaround(radius)   -- Count enemies within radius
unit.friendsaround(radius)   -- Count friends within radius

-- Line of sight
unit.haslos(target)          -- Check line of sight
unit.predictlos(target, 2)   -- Predict LoS in 2 seconds
```

#### Interaction Methods
```lua
unit.settarget(target)       -- Set unit's target
unit.isunit(target)          -- Check if same unit
unit.interact()              -- Interact with unit
unit.friendof(otherUnit)     -- Check friendly status
```

### Power Types

#### Resource Types (with IDs)
```lua
-- Primary Resources
unit.mana        -- ID 0: Caster resource
unit.rage        -- ID 1: Warrior/Druid
unit.focus       -- ID 2: Hunter
unit.energy      -- ID 3: Rogue/Druid/Monk

-- Secondary Resources
unit.combopoints -- ID 4: Rogue/Druid
unit.runes       -- ID 5: Death Knight
unit.runicpower  -- ID 6: Death Knight
unit.soulshards  -- ID 7: Warlock
unit.astralpower -- ID 8: Balance Druid
unit.holypower   -- ID 9: Paladin
unit.maelstrom   -- ID 11: Shaman
unit.chi         -- ID 12: Monk
unit.insanity    -- ID 13: Shadow Priest
unit.arcanecharges -- ID 16: Arcane Mage
unit.fury        -- ID 17: Demon Hunter
unit.pain        -- ID 18: Vengeance DH
unit.essence     -- ID 19: Evoker
```

#### Power Properties
```lua
-- For each power type:
unit.<type>              -- Current value
unit.<type>max          -- Maximum value
unit.<type>pct          -- Percentage (0-100)
unit.<type>deficit      -- Missing from max
unit.<type>regen        -- Regen per second
unit.timeto(<type>, value) -- Time to reach value
```

### Aura System

#### Aura Properties
```lua
local aura = unit.aura(spellId)
if aura then
    aura.name              -- Aura name
    aura.icon              -- Texture path
    aura.count            -- Stack count
    aura.duration         -- Total duration
    aura.expirationTime   -- Expiration time
    aura.spellId          -- Spell ID
    aura.isStealable      -- Can be stolen
    aura.isHarmful        -- Is debuff
    aura.isHelpful        -- Is buff
    aura.remaining        -- Time remaining
    aura.charges          -- Charge count
end
```

#### Aura Methods
```lua
-- Collection methods
unit.allauras           -- Get all auras
unit.alldispelauras    -- Get dispellable auras

-- Check methods
unit.aura(id, source)          -- Get specific aura
unit.aurauptime(id, source)    -- Total uptime
unit.auraremains(id, source)   -- Remaining time
unit.auracount(id, source)     -- Stack count
unit.aurafrom({id1, id2}, source) -- Has any from list
```

#### Hidden Auras
```lua
-- Access hidden auras (tier sets, etc.)
local hiddenAura = Aurora.hiddenauras[spellId]
if hiddenAura then
    print("Hidden aura active:", hiddenAura.name)
    print("Stacks:", hiddenAura.stacks)
end
```

## Lists and Virtual Units

### Lists

#### Available Lists
```lua
Aurora.enemies         -- Enemy units
Aurora.friends         -- Friendly units
Aurora.group          -- Group members (excluding player)
Aurora.fgroup         -- Full group (including player)
Aurora.activeenemies  -- Enemies in combat with threat
Aurora.dead           -- Dead units
Aurora.units          -- All units
Aurora.objects        -- Game objects
Aurora.missiles       -- All missiles
Aurora.areatriggers   -- Area triggers
```

#### List Methods
```lua
-- Iteration
enemies:each(function(unit, index, uptime)
    print(unit.name .. " visible for " .. uptime .. " seconds")
    return false  -- Continue iteration
end)

-- Filtering
local lowHealth = enemies:filter(function(unit)
    return unit.hp < 50
end)

-- Finding
local firstLowHealth = enemies:first(function(unit)
    return unit.hp < 30
end)

-- Random selection
local randomEnemy = enemies:random()

-- Sorting
enemies:sort(function(a, b)
    return a.hp < b.hp  -- Sort by health ascending
end)

-- Chaining
local nearbyLowHealth = enemies
    :filter(function(u) return u.distance < 10 end)
    :filter(function(u) return u.hp < 50 end)
    :sort(function(a, b) return a.hp < b.hp end)
```

### Virtual Units

#### Built-in Virtual Units
```lua
Aurora.UnitManager.tank    -- Resolves to tank
Aurora.UnitManager.healer  -- Resolves to healer
Aurora.UnitManager.target  -- Target references
```

#### Creating Custom Virtual Units
```lua
-- Register custom virtual unit
Aurora.UnitManager:RegisterVirtualUnit("lowestHealth", function(self)
    local lowest = nil
    local lowestHP = 100
    
    Aurora.fgroup:each(function(unit)
        if unit.alive and unit.hp < lowestHP then
            lowest = unit
            lowestHP = unit.hp
        end
    end)
    
    return lowest or self:Get("none")
end)

-- Use custom virtual unit
local needsHealing = Aurora.UnitManager.lowestHealth
if needsHealing.exists and needsHealing.hp < 50 then
    -- Heal lowest health member
end
```

## Spell System

### Creating Spells
```lua
-- Basic spell creation
local spell = Aurora.SpellHandler.NewSpell(spellId)

-- With configuration payload
local spell = Aurora.SpellHandler.NewSpell(spellId, {
    ignoreFacing = true,
    ignoreMoving = true,
    isSkillshot = true,
    radius = 8,
    queued = false,
    facehack = true
})

-- Multiple spell IDs (for ranks/versions)
local spell = Aurora.SpellHandler.NewSpell({id1, id2, id3}, payload)
```

### Spell Registration
```lua
-- Register spells for class/spec
local NewSpell = Aurora.SpellHandler.NewSpell
Aurora.SpellHandler.PopulateSpellbook({
    spells = {
        -- Basic abilities
        AutoAttack = NewSpell(6603),
        Charge = NewSpell(100),
        ShieldSlam = NewSpell(23922),
        
        -- AOE with radius
        Ravager = NewSpell(228920, { radius = 8 }),
        Whirlwind = NewSpell(1680, { radius = 8 }),
        
        -- Skillshots
        HeroicLeap = NewSpell(6544, { isSkillshot = true }),
    },
    auras = {
        -- Buffs/debuffs to track
        ShieldBlock = NewSpell(132404),
        LastStand = NewSpell(12975),
    },
    talents = {
        -- Talent spells
        Avatar = NewSpell(401150),
        Devastator = NewSpell(236279),
    },
}, "WARRIOR", 3, "YourNamespace")

-- Access registered spells
local spells = Aurora.SpellHandler.Spellbooks.warrior["3"].YourNamespace.spells
```

### Spell Methods

#### Casting Methods
```lua
-- Basic casting
spell:cast(target)           -- Attempt cast on target
spell:castable(target)       -- Check if castable
spell:ready()               -- Check if ready

-- Smart AOE
spell:smartaoe(target, {
    maxOffset = 30,          -- Max position offset
    minUnits = 3,           -- Min units to hit
})

spell:smartaoeposition(target) -- Get optimal position
```

#### Cooldown Methods
```lua
spell:getcd()               -- Remaining cooldown
spell:charges()             -- Current charges
spell:maxcharges()          -- Maximum charges
spell:chargesleft()         -- Fractional charges
spell:timetofull()          -- Time to full charges
spell:timetonextcharge()    -- Time to next charge
```

#### Cast History
```lua
spell:waslastcast(2)        -- Cast within 2 seconds
spell:wasSecondLastCast()   -- Was second-to-last
spell:timeSinceLastCast()   -- Time since cast
```

#### Utility Methods
```lua
spell:inrange(target)       -- Target in range
spell:rank()               -- Talent rank
spell:overlayed()          -- Is glowing
spell:getcasttime()        -- Cast time
spell:isknown()           -- Spell known
spell:isusable()          -- Can use spell
```

#### Angle Callbacks
```lua
-- Set custom facing angle
spell:setanglecallback(function()
    return math.rad(45)  -- Face 45 degrees
end)

-- Face specific position
spell:createangletoposition(x, y)

-- Face specific unit
spell:createangletounit(unit)

-- Face with offset
spell:createanglewithoffset(math.rad(90))
```

### Payload Configuration Options
```lua
{
    ignoreCasting = false,      -- Ignore casting state
    ignoreChanneling = false,   -- Ignore channeling
    ignoreCost = false,         -- Ignore resource cost
    ignoreFacing = false,       -- Ignore facing requirement
    ignoreMoving = false,       -- Ignore movement
    isSkillshot = false,        -- Is ground-targeted
    radius = 0,                 -- Effect radius
    queued = false,             -- Allow queueing
    facehack = false,           -- Auto-face target
    maxOffset = 0,              -- Max position offset for AOE
}
```

## Missiles System

### Accessing Missiles
```lua
-- Iterate all missiles
Aurora.missiles:each(function(missile)
    -- Process each missile
end)

-- Filter player missiles
local player = Aurora.UnitManager:Get("player")
Aurora.missiles:each(function(missile)
    if missile.creator == player then
        -- Player's missile
    end
end)
```

### Missile Properties
```lua
missile.spellid           -- Spell ID that created it
missile.creator           -- Unit that created it
missile.target            -- Target unit
missile.progress          -- Journey percentage (0-100)
missile.distancetraveled  -- Distance traveled
missile.position          -- Current position
missile.velocity          -- Movement velocity
```

## Utility Functions

### Texture Handling
```lua
-- Create texture string for UI
local texture = Aurora.texture(spellId, size)
local texture = Aurora.texture("path/to/texture", 16)
```

### Map & Location
```lua
local mapId = Aurora.mapid  -- Current map/instance ID
```

### Group Analysis
```lua
-- Average time-to-die for enemies
local avgTTD = Aurora.groupttd()

-- Average group health
local avgHealth = Aurora.grouphp(40)  -- Within 40 yards

-- Count above health threshold
local healthyCount = Aurora.grouphpcount(40, 80)  -- 80% health
```

### Combat Utilities
```lua
-- Global cooldown with haste
local gcd = Aurora.gcd()

-- Cached random (prevents erratic behavior)
local rand = Aurora.random(1, 100)

-- Boolean to binary
local binary = Aurora.bin(true)  -- Returns 1
```

### Control Functions
```lua
-- Block movement temporarily
Aurora.blockmovement(2)  -- Block for 2 seconds

-- Check player control
if Aurora.hascontrol then
    -- Player not CC'd
end
```

## Interface System

### GUI Builder
```lua
-- Create GUI instance
local gui = Aurora.GuiBuilder:New()

-- Build interface with chaining
gui:Category("General Settings")
   :Tab("Combat")
   :Header({ text = "Rotation Settings" })
   :Checkbox({ 
       text = "Enable Burst Mode",
       var = "burstMode",
       default = false
   })
   :Slider({
       text = "Health Threshold",
       var = "healthThreshold",
       min = 0,
       max = 100,
       default = 30,
       step = 5
   })
   :Dropdown({
       text = "Priority Target",
       var = "priorityTarget",
       options = {"Nearest", "Lowest Health", "Highest Threat"},
       default = "Nearest"
   })
   :Tab("Defensives")
   :Header({ text = "Defensive Options" })
   :Checkbox({
       text = "Auto Shield Wall",
       var = "autoShieldWall",
       default = true
   })
```

### Frame Callbacks
```lua
-- Update callback (every 0.1 seconds)
local updateId = Aurora:OnUpdate(function(elapsed)
    -- Update logic
end, true)  -- enabled

-- Tick callback (precise timing)
local tickId = Aurora:OnTick(function(elapsed)
    if player.casting then
        -- Track cast progress
    end
end, true)

-- Disable/enable callbacks
Aurora:SetUpdateCallback(updateId, false)  -- Disable
Aurora:SetTickCallback(tickId, true)       -- Enable
```

## Macro System

### Command Registration
```lua
-- Register basic command
Macro:RegisterCommand("test", function()
    print("Test command executed!")
end, "Test command description")

-- Command with arguments
Macro:RegisterCommand("cast", function(spell, target)
    if spell then
        local spellObj = Aurora.SpellHandler.NewSpell(spell)
        spellObj:cast(target or "target")
    end
end, "Cast spell on target")

-- Complex command
Macro:RegisterCommand("burst", function(duration)
    local dur = tonumber(duration) or 10
    Aurora.burstMode = true
    C_Timer.After(dur, function()
        Aurora.burstMode = false
        print("Burst mode ended")
    end)
    print("Burst mode active for " .. dur .. " seconds")
end, "Activate burst mode for X seconds")
```

### Using Commands
```lua
-- In-game chat
/aurora test
/aurora cast 100 target
/aurora burst 15
/aurora help  -- Show all commands
```

## Enumerations

### Classes
```lua
Aurora.Enums.Class = {
    DEATHKNIGHT = 1,
    DEMONHUNTER = 2,
    DRUID = 3,
    HUNTER = 4,
    MAGE = 5,
    MONK = 6,
    PALADIN = 7,
    PRIEST = 8,
    ROGUE = 9,
    SHAMAN = 10,
    WARLOCK = 11,
    WARRIOR = 12,
    EVOKER = 13
}
```

### Specializations
```lua
-- Death Knight
BLOOD = 250
FROST_DK = 251
UNHOLY = 252

-- Demon Hunter
HAVOC = 577
VENGEANCE = 581

-- Druid
BALANCE = 102
FERAL = 103
GUARDIAN = 104
RESTORATION_DRUID = 105

-- Check roles
Aurora.Enums.IsHealer(specId)
Aurora.Enums.IsTank(specId)
```

### Equipment
```lua
-- Item Classes
Aurora.Enums.ItemClass = {
    Consumable = 0,
    Container = 1,
    Weapon = 2,
    Armor = 4,
    -- etc.
}

-- Weapon Subclasses
Aurora.Enums.WeaponSubclass = {
    Axe1H = 0,
    Axe2H = 1,
    Bow = 2,
    Gun = 3,
    Mace1H = 4,
    Mace2H = 5,
    Polearm = 6,
    Sword1H = 7,
    Sword2H = 8,
    Staff = 10,
    -- etc.
}

-- Inventory Slots
Aurora.Enums.InventorySlot = {
    INVSLOT_HEAD = 1,
    INVSLOT_NECK = 2,
    INVSLOT_SHOULDER = 3,
    INVSLOT_SHIRT = 4,
    INVSLOT_CHEST = 5,
    INVSLOT_WAIST = 6,
    -- etc.
}
```

## Development Tools

### Recommended Addons

1. **idTip** - Shows IDs in tooltips
   - Spell IDs
   - Item IDs
   - NPC IDs
   - Achievement IDs

2. **DevTool** - In-game Lua console
   - Inspect variables
   - Execute Lua code
   - Debug runtime issues

3. **Instance Spell Collector (ISC)** - Auto-logs encounter spells
   - Tracks all spells during encounters
   - Exports to file for analysis
   - Essential for raid/dungeon development

4. **WowLua** - In-game Lua editor
   - Syntax highlighting
   - Code execution
   - Script saving

### Debugging Tips

```lua
-- Print debugging
local function debug(...)
    if Aurora.debug then
        print("DEBUG:", ...)
    end
end

-- Timing analysis
local startTime = debugprofilestop()
-- Code to measure
local elapsed = debugprofilestop() - startTime
debug("Operation took:", elapsed, "ms")

-- Unit inspection
local function inspectUnit(unit)
    debug("Unit:", unit.name)
    debug("Health:", unit.hp .. "%")
    debug("Distance:", unit.distance)
    debug("Combat:", unit.combat)
end

-- Spell tracking
local function trackSpell(spell)
    debug("Spell:", spell.name)
    debug("CD:", spell:getcd())
    debug("Charges:", spell:charges())
    debug("Castable:", spell:castable("target"))
end
```

## Common Patterns

### Basic Rotation Structure
```lua
local function combat()
    local target = Aurora.UnitManager:Get("target")
    if not target.exists or not target.enemy then return end
    
    -- Defensive checks
    if player.hp < 30 then
        if spells.ShieldWall:cast(player) then return end
    end
    
    -- AOE rotation
    if enemies:filter(function(u) return u.distance < 8 end):count() >= 3 then
        if spells.Whirlwind:cast(player) then return end
    end
    
    -- Single target rotation
    if spells.ShieldSlam:cast(target) then return end
    if spells.Devastate:cast(target) then return end
end
```

### Priority System
```lua
local priorities = {
    {
        name = "Interrupts",
        condition = function() return target.castinginterruptible end,
        action = function() return spells.Pummel:cast(target) end
    },
    {
        name = "Defensives",
        condition = function() return player.hp < 40 end,
        action = function() return spells.ShieldWall:cast(player) end
    },
    {
        name = "AOE",
        condition = function() return enemies:around(8) >= 3 end,
        action = function() return spells.Whirlwind:cast(player) end
    }
}

local function executePriorities()
    for _, priority in ipairs(priorities) do
        if priority.condition() and priority.action() then
            return true
        end
    end
end
```

### Resource Management
```lua
local function manageResources()
    -- Rage management
    if player.rage > 80 then
        -- Dump rage
        if spells.RampageOrExecute:cast(target) then return end
    end
    
    -- Combo points
    if player.combopoints >= 5 then
        -- Use finisher
        if spells.Finisher:cast(target) then return end
    end
    
    -- Energy pooling
    if player.energy < 50 then
        return false  -- Wait for energy
    end
end
```

### Target Selection
```lua
local function selectTarget()
    -- Priority: Lowest health enemy in range
    local bestTarget = enemies
        :filter(function(u) return u.distance < 30 end)
        :sort(function(a, b) return a.hp < b.hp end)
        :first()
    
    if bestTarget and bestTarget.guid ~= target.guid then
        bestTarget:settarget()
    end
end
```

## Best Practices

1. **Always Check Unit Existence**
   ```lua
   if unit and unit.exists then
       -- Safe to use unit
   end
   ```

2. **Use Appropriate Lists**
   ```lua
   -- Good: Use filtered list
   local nearEnemies = enemies:filter(function(u) 
       return u.distance < 10 
   end)
   
   -- Bad: Manual iteration
   for i = 1, #enemies do
       if enemies[i].distance < 10 then
           -- Process
       end
   end
   ```

3. **Cache Expensive Operations**
   ```lua
   local enemyCount = enemies:around(8)
   if enemyCount >= 3 then
       -- Use AOE abilities
   end
   ```

4. **Handle Spell Failures**
   ```lua
   if not spell:cast(target) then
       -- Try alternative
       if alternativeSpell:cast(target) then
           return
       end
   end
   ```

5. **Profile-Specific Settings**
   ```lua
   local settings = {
       burst = Aurora.config.burst or false,
       defensiveThreshold = Aurora.config.defensiveHP or 40,
       aoeTargets = Aurora.config.aoeCount or 3
   }
   ```

This comprehensive reference covers all major systems and APIs available in the Aurora Framework for World of Warcraft addon development.