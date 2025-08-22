local NewSpell = Aurora.SpellHandler.NewSpell

Aurora.SpellHandler.PopulateSpellbook({
    spells = {
        -- Auto Attack
        AutoAttack = NewSpell(6603),
        AutoShot = NewSpell(75),
        
        -- Core Abilities (Classic)
        ArcaneShot = NewSpell(3044),           -- Rank 1
        ArcaneShotR2 = NewSpell(14281),        -- Rank 2
        ArcaneShotR3 = NewSpell(14282),        -- Rank 3
        ArcaneShotR4 = NewSpell(14283),        -- Rank 4
        ArcaneShotR5 = NewSpell(14284),        -- Rank 5
        ArcaneShotR6 = NewSpell(14285),        -- Rank 6
        ArcaneShotR7 = NewSpell(14286),        -- Rank 7
        ArcaneShotR8 = NewSpell(14287),        -- Rank 8
        
        MultiShot = NewSpell(2643, { radius = 8 }),     -- Rank 1
        MultiShotR2 = NewSpell(14288, { radius = 8 }),   -- Rank 2
        MultiShotR3 = NewSpell(14289, { radius = 8 }),   -- Rank 3
        MultiShotR4 = NewSpell(14290, { radius = 8 }),   -- Rank 4
        
        -- Classic Hunter Specific
        RaptorStrike = NewSpell(2973),         -- Melee ability
        RaptorStrikeR2 = NewSpell(14260),      -- Rank 2
        RaptorStrikeR3 = NewSpell(14261),      -- Rank 3
        RaptorStrikeR4 = NewSpell(14262),      -- Rank 4
        RaptorStrikeR5 = NewSpell(14263),      -- Rank 5
        RaptorStrikeR6 = NewSpell(14264),      -- Rank 6
        RaptorStrikeR7 = NewSpell(14265),      -- Rank 7
        RaptorStrikeR8 = NewSpell(14266),      -- Rank 8
        
        WingClip = NewSpell(2974),            -- Melee snare
        
        -- Pet Commands
        CallPet = NewSpell(883),
        DismissPet = NewSpell(2641),
        MendPet = NewSpell(136),
        FeedPet = NewSpell(6991),             -- Classic pet feeding
        RevivePet = NewSpell(982),            -- Classic pet revival
        TameBeast = NewSpell(1515),           -- Beast taming
        
        -- Pet Abilities
        PetAttack = NewSpell(16827),
        PetFollow = NewSpell(33663),
        PetStay = NewSpell(3144),
        PetMove = NewSpell(33664),
        
        -- Aspects (Classic)
        AspectOfTheMonkey = NewSpell(13163),   -- Dodge bonus
        AspectOfTheHawk = NewSpell(13165),     -- Ranged AP bonus
        AspectOfTheCheetah = NewSpell(5118),   -- Movement speed
        AspectOfThePack = NewSpell(13159),     -- Group movement
        AspectOfTheWild = NewSpell(20043),     -- Nature resistance
        AspectOfTheBeast = NewSpell(13161),    -- Melee AP bonus
        
        -- Defensive
        FeignDeath = NewSpell(5384),
        
        -- Utility
        HuntersMark = NewSpell(1130),          -- Classic Hunter's Mark
        HuntersMarkR2 = NewSpell(14323),       -- Rank 2
        HuntersMarkR3 = NewSpell(14324),       -- Rank 3
        HuntersMarkR4 = NewSpell(14325),       -- Rank 4
        
        ConcussiveShot = NewSpell(5116),
        
        -- Tracking
        TrackBeasts = NewSpell(1494),
        TrackHumanoids = NewSpell(5225),
        TrackUndead = NewSpell(19884),
        TrackDemons = NewSpell(19878),
        TrackDragonkin = NewSpell(19879),
        TrackGiants = NewSpell(19882),
        TrackElementals = NewSpell(19880),
        
        -- Traps (Classic)
        FreezingTrap = NewSpell(1499, { isSkillshot = true }),
        ImmolationTrap = NewSpell(13795, { isSkillshot = true }),
        ExplosiveTrap = NewSpell(13813, { isSkillshot = true }),
        
        -- DOTs
        SerpentSting = NewSpell(1978),         -- Rank 1
        SerpentStingR2 = NewSpell(13549),      -- Rank 2
        SerpentStingR3 = NewSpell(13550),      -- Rank 3
        SerpentStingR4 = NewSpell(13551),      -- Rank 4
        SerpentStingR5 = NewSpell(13552),      -- Rank 5
        SerpentStingR6 = NewSpell(13553),      -- Rank 6
        SerpentStingR7 = NewSpell(13554),      -- Rank 7
        SerpentStingR8 = NewSpell(13555),      -- Rank 8
        SerpentStingR9 = NewSpell(25295),      -- Rank 9
    },
    auras = {
        -- Buffs (Classic)
        AspectOfTheHawk = NewSpell(13165),
        AspectOfTheMonkey = NewSpell(13163),
        AspectOfTheCheetah = NewSpell(5118),
        AspectOfThePack = NewSpell(13159),
        AspectOfTheWild = NewSpell(20043),
        AspectOfTheBeast = NewSpell(13161),
        HuntersMark = NewSpell(1130),
        FeignDeath = NewSpell(5384),
        RapidFire = NewSpell(3045),
        
        -- Debuffs (Classic)
        SerpentSting = NewSpell(1978),
        ConcussiveShot = NewSpell(5116),
        WingClip = NewSpell(2974),
        
        -- Pet Buffs (Classic)
        -- Pet auras would be tracked separately
    },
    talents = {
        -- Beast Mastery Tree (Classic)
        BestialWrath = NewSpell(19574),        -- 31-point talent
        Intimidation = NewSpell(19577),        -- Mid-tier talent
        
        -- Marksmanship Tree (Classic)
        AimedShot = NewSpell(19434),           -- 31-point talent
        TrueshotAura = NewSpell(19506),        -- Mid-tier talent
        
        -- Survival Tree (Classic)
        Deterrence = NewSpell(19263),          -- Mid-tier talent
        Counterattack = NewSpell(19306),       -- Mid-tier talent
        WyvernSting = NewSpell(19386),         -- 31-point talent
        
        -- Other talents
        RapidFire = NewSpell(3045),            -- Available to all specs
        ScatterShot = NewSpell(19503),         -- Marksmanship talent
    }
}, "HUNTER", 253, "BeastMasteryLeveling")