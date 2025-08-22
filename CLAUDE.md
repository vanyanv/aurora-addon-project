# Aurora WoW Addon Development Project

## Project Overview
This is a World of Warcraft addon development project using the Aurora Framework. Aurora is a comprehensive framework for creating combat rotation addons and automation tools for WoW.

## IMPORTANT: Always Reference Documentation
**ALWAYS consult `/docs/aurora-framework-reference.md` before writing any code or answering questions about the Aurora framework.** This file contains the complete API reference and should be your primary source of truth.

## Project Structure
```
aurora-addon-project/
├── CLAUDE.md                           # This file (project context)
├── docs/
│   └── aurora-framework-reference.md   # Complete Aurora API reference
├── scripts/
│   └── AuroraRoutines/
│       ├── loadorder.json             # File loading configuration
│       └── Routines/                  # Class/spec rotation implementations
└── README.md                           # User-facing documentation
```

## Key Development Guidelines

### 1. Before Starting Any Task
- Read the aurora-framework-reference.md file
- Understand the specific Aurora APIs needed
- Check existing code patterns in the project

### 2. File Organization
- Each class/spec gets its own folder under `Routines/`
- Standard files per spec: `Spellbook.lua`, `Interface.lua`, `Rotation.lua`
- Use loadorder.json to control file loading sequence

### 3. Namespace Management
```lua
-- Always use the provided namespace
local Routine = Aurora.Routine
local MyNamespace = Routine.Namespace
```

### 4. Spell Registration Pattern
```lua
-- Always register spells in Spellbook.lua
Aurora.SpellHandler.PopulateSpellbook({
    spells = { ... },
    auras = { ... },
    talents = { ... }
}, "CLASS", specId, "Namespace")
```

### 5. Common Tasks

#### Creating a New Rotation
1. Create folder structure: `Routines/[Class]/[Spec]/`
2. Create Spellbook.lua with spell definitions
3. Create Interface.lua with GUI configuration
4. Create Rotation.lua with combat logic
5. Update loadorder.json

#### Adding Spells
1. Find spell IDs using idTip addon
2. Add to appropriate section in Spellbook.lua
3. Configure payload options if needed

#### Debugging
1. Use Aurora.debug flag for debug output
2. Test with DevTool addon in-game
3. Check spell IDs with Instance Spell Collector

### 6. Testing Requirements
- Test all rotations in various scenarios (single target, AOE, movement)
- Verify defensive cooldowns trigger correctly
- Check resource management (don't overcap/starve)
- Ensure interrupts work properly

### 7. Code Standards
- Use descriptive variable names
- Comment complex logic
- Follow existing patterns in the codebase
- Keep functions focused and small
- Handle edge cases (unit doesn't exist, spell on cooldown, etc.)

### 8. Performance Considerations
- Cache frequently accessed values
- Use Aurora's list filtering methods
- Avoid nested loops where possible
- Break early from iterations when possible

### 9. Common Patterns to Follow

#### Unit Checking
```lua
if unit and unit.exists and unit.enemy and unit.alive then
    -- Safe to interact with unit
end
```

#### Spell Casting
```lua
if spell:ready() and spell:cast(target) then
    return true
end
```

#### AOE Decision Making
```lua
local enemyCount = enemies:filter(function(u) return u.distance < 8 end):count()
if enemyCount >= 3 then
    -- Use AOE rotation
end
```

## Aurora Framework Quick Reference

### Most Used APIs
- `Aurora.UnitManager:Get("target")` - Get unit reference
- `Aurora.SpellHandler.NewSpell(id, payload)` - Create spell
- `Aurora.enemies` - Enemy unit list
- `unit.hp` - Unit health percentage
- `spell:cast(target)` - Cast spell on target
- `unit.aura(spellId)` - Check for buff/debuff

### Key Concepts
1. **Virtual Units**: Dynamic unit references (tank, healer)
2. **Lists**: Managed collections of units with filtering
3. **Spell Payload**: Configuration for spell behavior
4. **Hidden Auras**: Non-visible buffs like tier sets

## Resources
- Aurora Documentation: https://docs.aurora-wow.wtf/
- Complete API Reference: `/docs/aurora-framework-reference.md`
- WoW API: https://wowpedia.fandom.com/wiki/World_of_Warcraft_API

## Important Notes
- Never modify the aurora-framework-reference.md unless updating from official docs
- Always test changes in-game before committing
- Keep user settings and preferences in Interface.lua
- Use the macro system for testing individual functions

Remember: When in doubt, check the documentation first!