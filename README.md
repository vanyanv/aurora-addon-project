# Aurora WoW Addon Project

A World of Warcraft addon development project using the Aurora Framework for creating advanced combat rotations and automation.

## Getting Started

### Prerequisites
- World of Warcraft with Aurora Framework installed
- Text editor with Lua support (recommended: VS Code)
- Git for version control

### Installation
1. Clone this repository to your WoW addons folder
2. Copy the `scripts` folder content to your Aurora scripts directory
3. Reload your UI in-game (`/reload`)

### Project Structure
```
aurora-addon-project/
├── docs/                               # Documentation
│   └── aurora-framework-reference.md   # Complete API reference
├── scripts/                            # Aurora scripts
│   └── AuroraRoutines/
│       ├── loadorder.json             # Loading configuration
│       └── Routines/                  # Class rotations
├── CLAUDE.md                          # AI assistant context
└── README.md                          # This file
```

## Development

### Creating a New Rotation

1. Create your class/spec folder:
```
scripts/AuroraRoutines/Routines/[Class]/[Specialization]/
```

2. Create three core files:
- `Spellbook.lua` - Define all spells, auras, and talents
- `Interface.lua` - Create GUI settings
- `Rotation.lua` - Implement combat logic

3. Update `loadorder.json` to include your files

### Example Rotation Structure

```lua
-- Spellbook.lua
local NewSpell = Aurora.SpellHandler.NewSpell
Aurora.SpellHandler.PopulateSpellbook({
    spells = {
        Strike = NewSpell(12345),
        -- More spells...
    },
    auras = {
        Buff = NewSpell(67890),
        -- More auras...
    }
}, "WARRIOR", 1, "MyRoutine")

-- Rotation.lua
local function combat()
    local target = Aurora.UnitManager:Get("target")
    if not target.exists then return end
    
    -- Combat logic here
    if spells.Strike:cast(target) then return end
end
```

## Testing

### In-Game Testing
1. Load into game with `/reload`
2. Enable your routine in Aurora settings
3. Test on training dummies first
4. Verify in dungeons/raids

### Debugging
- Enable debug mode: `Aurora.debug = true`
- Use `/aurora` commands for testing
- Check the in-game console for errors

## Recommended Addons

For development, install these helpful addons:
- **idTip** - Shows spell/item IDs in tooltips
- **DevTool** - In-game Lua debugging console
- **Instance Spell Collector** - Logs encounter spells
- **WowLua** - In-game Lua editor

## API Documentation

Complete API documentation is available in:
- `docs/aurora-framework-reference.md` - Full API reference
- https://docs.aurora-wow.wtf/ - Official Aurora documentation

### Quick API Reference

#### Units
```lua
local player = Aurora.UnitManager:Get("player")
local target = Aurora.UnitManager:Get("target")
```

#### Spells
```lua
local spell = Aurora.SpellHandler.NewSpell(spellId)
spell:cast(target)
```

#### Lists
```lua
Aurora.enemies:each(function(unit)
    -- Process each enemy
end)
```

## Contributing

1. Test your changes thoroughly
2. Follow existing code patterns
3. Document complex logic
4. Update loadorder.json when adding files

## Support

- Aurora Documentation: https://docs.aurora-wow.wtf/
- Discord: [Aurora Discord Server]
- Issues: Create an issue in this repository

## License

This project is for educational purposes. Respect World of Warcraft's Terms of Service.