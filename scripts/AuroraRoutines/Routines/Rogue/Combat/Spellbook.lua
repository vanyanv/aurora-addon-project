local NewSpell = Aurora.SpellHandler.NewSpell

Aurora.SpellHandler.PopulateSpellbook({
    spells = {
        AutoAttack = NewSpell(6603),
        SinisterStrike = NewSpell(1752),
        Eviscerate = NewSpell(2098),
        SliceAndDice = NewSpell(5171),
        Riposte = NewSpell(14251),
    },
    auras = {
        SliceAndDice = NewSpell(5171),
    },
    talents = {
    },
}, "ROGUE", 9, "Combat")