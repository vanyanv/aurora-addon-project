local NewSpell = Aurora.SpellHandler.NewSpell
local player = Aurora.UnitManager:Get("player")

local function isSpellKnown(spellId)
    return IsSpellKnown(spellId) or false
end

local function registerSpellIfKnown(spellId, payload)
    if isSpellKnown(spellId) then
        return NewSpell(spellId, payload)
    end
    return nil
end

local spells = {}
local auras = {}
local talents = {}

-- Core abilities available at all levels
spells.AutoAttack = NewSpell(6603)

-- Level-based ability registration
if player.level >= 1 then
    spells.SinisterStrike = registerSpellIfKnown(1752)
    spells.Eviscerate = registerSpellIfKnown(2098)
end

if player.level >= 4 then
    spells.Stealth = registerSpellIfKnown(1784)
end

if player.level >= 6 then
    spells.Gouge = registerSpellIfKnown(1776)
    spells.Backstab = registerSpellIfKnown(53)
end

if player.level >= 8 then
    spells.Evasion = registerSpellIfKnown(5277)
end

if player.level >= 10 then
    spells.Sprint = registerSpellIfKnown(2983)
    spells.Sap = registerSpellIfKnown(6770)
end

if player.level >= 12 then
    spells.Kick = registerSpellIfKnown(1766)
end

if player.level >= 14 then
    spells.Garrote = registerSpellIfKnown(703)
    spells.Slice_and_Dice = registerSpellIfKnown(5171)
    spells.Expose_Armor = registerSpellIfKnown(8647)
end

if player.level >= 16 then
    spells.Vanish = registerSpellIfKnown(1856)
end

if player.level >= 18 then
    spells.Ambush = registerSpellIfKnown(8676)
end

if player.level >= 20 then
    spells.Blind = registerSpellIfKnown(2094)
    spells.Detect_Traps = registerSpellIfKnown(2836)
    spells.Disarm_Trap = registerSpellIfKnown(1842)
    
    -- Poisons available at 20 after quest
    spells.Instant_Poison = registerSpellIfKnown(8679)
    spells.Crippling_Poison = registerSpellIfKnown(3408)
end

if player.level >= 22 then
    spells.Rupture = registerSpellIfKnown(1943)
end

if player.level >= 24 then
    spells.Deadly_Poison = registerSpellIfKnown(2823)
end

if player.level >= 26 then
    spells.Cheap_Shot = registerSpellIfKnown(1833)
end

if player.level >= 30 then
    spells.Kidney_Shot = registerSpellIfKnown(408)
    spells.Mind_numbing_Poison = registerSpellIfKnown(5761)
end

-- Talent-based abilities
talents.Improved_Sinister_Strike = registerSpellIfKnown(13732)
talents.Riposte = registerSpellIfKnown(14251)
talents.Blade_Flurry = registerSpellIfKnown(13877)
talents.Adrenaline_Rush = registerSpellIfKnown(13750)
talents.Cold_Blood = registerSpellIfKnown(14177)
talents.Preparation = registerSpellIfKnown(14185)
talents.Hemorrhage = registerSpellIfKnown(16511)
talents.Ghostly_Strike = registerSpellIfKnown(14278)
talents.Improved_Gouge = registerSpellIfKnown(13741)
talents.Lethality = registerSpellIfKnown(14128)
talents.Improved_Expose_Armor = registerSpellIfKnown(14168)
talents.Seal_Fate = registerSpellIfKnown(14190)
talents.Vigor = registerSpellIfKnown(14983)

-- Auras to track
auras.Stealth = NewSpell(1784)
auras.Slice_and_Dice = NewSpell(5171)
auras.Evasion = NewSpell(5277)
auras.Sprint = NewSpell(2983)
auras.Blade_Flurry = NewSpell(13877)
auras.Adrenaline_Rush = NewSpell(13750)
auras.Cold_Blood = NewSpell(14177)
auras.Gouge = NewSpell(1776)
auras.Cheap_Shot = NewSpell(1833)
auras.Kidney_Shot = NewSpell(408)
auras.Blind = NewSpell(2094)
auras.Rupture = NewSpell(1943)
auras.Garrote = NewSpell(703)
auras.Instant_Poison = NewSpell(8679)
auras.Deadly_Poison = NewSpell(2823)
auras.Crippling_Poison = NewSpell(3408)
auras.Mind_numbing_Poison = NewSpell(5761)

-- Enemy Abilities Database for Strategic Tracking
local EnemyAbilities = {
    WARRIOR = {
        Charge = { id = 100, cooldown = 15, canUseInCombat = false, range = 25 },
        Intercept = { id = 20252, cooldown = 30, canUseInCombat = true, range = 25 },
        Berserker_Rage = { id = 18499, cooldown = 30, duration = 10, breaksCC = true },
        Retaliation = { id = 20230, cooldown = 1800, duration = 15, reflectsMelee = true },
        Shield_Wall = { id = 871, cooldown = 1800, duration = 10, damageReduction = 75 },
        Pummel = { id = 6552, cooldown = 10, interrupt = true, silence = 4 },
        Intimidating_Shout = { id = 5246, cooldown = 180, duration = 8, fear = true }
    },
    MAGE = {
        Blink = { id = 1953, cooldown = 15, range = 20, escape = true },
        Ice_Block = { id = 45438, cooldown = 300, duration = 10, immunity = true },
        Counterspell = { id = 2139, cooldown = 30, silence = 4, interrupt = true },
        Frost_Nova = { id = 122, cooldown = 25, duration = 8, root = true },
        Cold_Snap = { id = 11958, cooldown = 600, resetsCooldowns = true },
        Polymorph = { id = 118, cooldown = 0, duration = 8, incapacitate = true },
        Ice_Barrier = { id = 11426, cooldown = 30, duration = 60, absorb = true }
    },
    PALADIN = {
        Divine_Shield = { id = 642, cooldown = 300, duration = 10, immunity = true, causesForbearance = true },
        Blessing_of_Protection = { id = 1022, cooldown = 300, duration = 10, physicalImmunity = true, causesForbearance = true },
        Hammer_of_Justice = { id = 853, cooldown = 60, duration = 6, stun = true },
        Consecration = { id = 26573, cooldown = 8, duration = 8, aoe = true },
        Flash_of_Light = { id = 19750, castTime = 1.5, heal = true },
        Holy_Light = { id = 635, castTime = 2.5, heal = true }
    },
    PRIEST = {
        Psychic_Scream = { id = 8122, cooldown = 30, duration = 8, fear = true, range = 8 },
        Fade = { id = 586, cooldown = 30, duration = 10, threatReduce = true },
        Power_Word_Shield = { id = 17, cooldown = 4, duration = 30, absorb = true },
        Mind_Control = { id = 605, cooldown = 0, duration = 8, control = true },
        Greater_Heal = { id = 2060, castTime = 3, heal = true },
        Flash_Heal = { id = 2061, castTime = 1.5, heal = true }
    },
    WARLOCK = {
        Fear = { id = 5782, cooldown = 0, duration = 10, fear = true },
        Howl_of_Terror = { id = 5484, cooldown = 40, duration = 8, aoe = true, fear = true },
        Death_Coil = { id = 6789, cooldown = 120, duration = 3, heal = true, horror = true },
        Shadow_Bolt = { id = 686, castTime = 3, damage = true },
        Drain_Life = { id = 689, channel = true, heal = true }
    },
    HUNTER = {
        Disengage = { id = 781, cooldown = 5, exitsCombat = true, range = true },
        Feign_Death = { id = 5384, cooldown = 30, duration = 6, feign = true },
        Intimidation = { id = 19577, cooldown = 60, duration = 5, stun = true, requiresPet = true },
        Flare = { id = 1543, cooldown = 20, detectsStealth = true, range = 30 },
        Aimed_Shot = { id = 19434, castTime = 3, damage = true },
        Multi_Shot = { id = 2643, cooldown = 10, aoe = true }
    },
    DRUID = {
        Bear_Form = { id = 5487, cooldown = 0, shapeshift = true, armor = true },
        Cat_Form = { id = 768, cooldown = 0, shapeshift = true, stealth = true },
        Travel_Form = { id = 783, cooldown = 0, shapeshift = true, speed = true },
        Aquatic_Form = { id = 1066, cooldown = 0, shapeshift = true, underwater = true },
        Nature_Swiftness = { id = 17116, cooldown = 180, instantCast = true },
        Barkskin = { id = 22812, cooldown = 30, duration = 12, damageReduction = 20 },
        Healing_Touch = { id = 5185, castTime = 3.5, heal = true },
        Regrowth = { id = 8936, castTime = 2, heal = true, hot = true },
        Rejuvenation = { id = 774, cooldown = 0, duration = 12, hot = true },
        Bash = { id = 5211, cooldown = 60, duration = 4, stun = true, requiresBearForm = true },
        Feral_Charge = { id = 16979, cooldown = 15, range = 25, requiresBearForm = true },
        Prowl = { id = 5215, cooldown = 10, stealth = true, requiresCatForm = true },
        Pounce = { id = 9005, cooldown = 0, duration = 2, stun = true, requiresCatForm = true, requiresStealth = true },
        Rake = { id = 1822, cooldown = 0, dot = true, requiresCatForm = true },
        Rip = { id = 1079, cooldown = 0, dot = true, requiresCatForm = true },
        Ferocious_Bite = { id = 22568, cooldown = 0, finisher = true, requiresCatForm = true },
        Shred = { id = 5221, cooldown = 0, requiresCatForm = true, requiresBehind = true },
        Claw = { id = 1082, cooldown = 0, requiresCatForm = true },
        Faerie_Fire = { id = 770, cooldown = 0, armorReduction = true },
        Moonfire = { id = 8921, cooldown = 0, dot = true },
        Entangling_Roots = { id = 339, cooldown = 0, duration = 12, root = true },
        Nature_Grasp = { id = 16689, cooldown = 60, duration = 45, root = true },
        Abolish_Poison = { id = 2893, cooldown = 0, dispel = true },
        Remove_Curse = { id = 2782, cooldown = 0, dispel = true }
    },
    SHAMAN = {
        Earth_Shock = { id = 8042, cooldown = 6, interrupt = true, silence = 2 },
        Grounding_Totem = { id = 8177, cooldown = 15, duration = 45, spellAbsorb = true },
        Tremor_Totem = { id = 8143, cooldown = 0, duration = 120, fearImmunity = true },
        Healing_Wave = { id = 331, castTime = 3, heal = true },
        Chain_Lightning = { id = 421, castTime = 2.5, aoe = true }
    }
}

-- Strategic threat patterns for each class
local ThreatPatterns = {
    WARRIOR = {
        highThreat = { "lowRage", "chargeRange", "interceptReady" },
        mediumThreat = { "inMelee", "hasRage" },
        lowThreat = { "noRage", "outOfRange", "weaponsBroken" }
    },
    MAGE = {
        highThreat = { "blinkReady", "iceBarrierUp", "castingDamage" },
        mediumThreat = { "inCastRange", "hasShield" },
        lowThreat = { "blinkDown", "silenced", "outOfMana" }
    },
    PALADIN = {
        highThreat = { "divineShieldReady", "lowHealth", "casting" },
        mediumThreat = { "inMelee", "hasShield" },
        lowThreat = { "forbearance", "outOfMana", "silenced" }
    }
}

-- Make databases accessible globally
MyNamespace = MyNamespace or {}
MyNamespace.EnemyAbilities = EnemyAbilities
MyNamespace.ThreatPatterns = ThreatPatterns

-- Clean up nil entries
local function cleanTable(tbl)
    local cleaned = {}
    for k, v in pairs(tbl) do
        if v ~= nil then
            cleaned[k] = v
        end
    end
    return cleaned
end

spells = cleanTable(spells)
talents = cleanTable(talents)

Aurora.SpellHandler.PopulateSpellbook({
    spells = spells,
    auras = auras,
    talents = talents,
}, "ROGUE", player.level >= 10 and 8 or 7, "AdaptivePvP")