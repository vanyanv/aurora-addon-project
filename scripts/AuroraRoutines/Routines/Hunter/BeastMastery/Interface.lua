local gui = Aurora.GuiBuilder:New()

gui:Category("Classic Hunter Leveling")
   :Tab("General")
   :Header({ text = "Classic Rotation Settings" })
   :Checkbox({ 
       text = "Enable Auto Shot Management",
       var = "enableAutoShot",
       default = true,
       tooltip = "Automatically manage Auto Shot (Classic WoW)"
   })
   :Checkbox({ 
       text = "Use Multi-Shot in AOE",
       var = "useMultiShot",
       default = true,
       tooltip = "Use Multi-Shot for AOE situations (Level 18+)"
   })
   :Slider({
       text = "AOE Enemy Count",
       var = "aoeCount",
       min = 2,
       max = 8,
       default = 3,
       step = 1,
       tooltip = "Minimum enemies to use AOE abilities"
   })
   :Slider({
       text = "Mana Reserve Threshold",
       var = "manaThreshold",
       min = 100,
       max = 500,
       default = 200,
       step = 25,
       tooltip = "Minimum mana to reserve for emergency abilities (Classic uses Mana)"
   })
   :Slider({
       text = "Mana Regeneration Wait %",
       var = "manaWaitThreshold",
       min = 15,
       max = 40,
       default = 25,
       step = 5,
       tooltip = "Mana percentage to enter regeneration mode (wait for mana)"
   })
   :Checkbox({ 
       text = "Auto Kiting with Concussive Shot",
       var = "autoKiting",
       default = true,
       tooltip = "Use Concussive Shot to slow enemies for kiting"
   })
   :Checkbox({ 
       text = "Prioritize Auto Shot",
       var = "prioritizeAutoShot",
       default = true,
       tooltip = "Always prioritize maintaining Auto Shot (Classic backbone)"
   })
   
   :Tab("Pet Control")
   :Header({ text = "Classic Pet Management" })
   :Checkbox({ 
       text = "Auto Summon Pet",
       var = "autoSummonPet",
       default = true,
       tooltip = "Automatically summon pet when not present (Level 10+)"
   })
   :Checkbox({ 
       text = "Auto Mend Pet",
       var = "autoMendPet",
       default = true,
       tooltip = "Automatically heal pet when low on health (out of combat)"
   })
   :Slider({
       text = "Pet Health Threshold",
       var = "petHealthThreshold",
       min = 20,
       max = 80,
       default = 50,
       step = 5,
       tooltip = "Pet health percentage to trigger Mend Pet"
   })
   :Checkbox({ 
       text = "Pet Attack on Target",
       var = "petAttackTarget",
       default = true,
       tooltip = "Send pet to attack current target"
   })
   :Checkbox({ 
       text = "Auto Revive Pet",
       var = "autoRevivePet",
       default = true,
       tooltip = "Automatically revive pet when dead (Classic)"
   })
   
   :Tab("Defensives")
   :Header({ text = "Classic Defensive Options" })
   :Checkbox({
       text = "Auto Feign Death",
       var = "autoFeignDeath",
       default = true,
       tooltip = "Use Feign Death when in danger (Level 30+)"
   })
   :Slider({
       text = "Feign Death Health %",
       var = "feignDeathHealth",
       min = 10,
       max = 50,
       default = 20,
       step = 5,
       tooltip = "Health percentage to trigger Feign Death"
   })
   :Checkbox({
       text = "Auto Wing Clip",
       var = "autoWingClip",
       default = true,
       tooltip = "Use Wing Clip to slow nearby enemies (Classic melee)"
   })
   :Checkbox({
       text = "Smart Aspect Switching",
       var = "smartAspects",
       default = true,
       tooltip = "Auto switch between Hawk (combat) and Cheetah (travel)"
   })
   
   :Tab("Utility")
   :Header({ text = "Classic Utility Spells" })
   :Checkbox({
       text = "Auto Hunter's Mark",
       var = "autoHuntersMark",
       default = true,
       tooltip = "Automatically apply Hunter's Mark to targets (Level 6+)"
   })
   :Checkbox({
       text = "Use Serpent Sting",
       var = "useSerpentSting",
       default = true,
       tooltip = "Apply Serpent Sting DoT to targets (Level 4+, great for leveling)"
   })
   :Checkbox({
       text = "Use Aspect of the Cheetah",
       var = "useAspectCheetah",
       default = true,
       tooltip = "Use Aspect of the Cheetah for movement (out of combat, Level 20+)"
   })
   :Header({ text = "Tracking Options" })
   :Checkbox({
       text = "Auto Track Beasts",
       var = "autoTrackBeasts",
       default = true,
       tooltip = "Automatically track beasts while leveling"
   })
   :Checkbox({
       text = "Auto Track Humanoids",
       var = "autoTrackHumanoids",
       default = false,
       tooltip = "Track humanoids in PvP areas (Level 10+)"
   })
   
   :Tab("Advanced")
   :Header({ text = "Classic Advanced Settings" })
   :Checkbox({
       text = "Use Bestial Wrath (Talent)",
       var = "useBestialWrath",
       default = false,
       tooltip = "Use Bestial Wrath if talented (31-point Beast Mastery)"
   })
   :Checkbox({
       text = "Use Aimed Shot (Talent)",
       var = "useAimedShot",
       default = true,
       tooltip = "Use Aimed Shot if talented (31-point Marksmanship)"
   })
   :Slider({
       text = "Enemy Health for Bursting",
       var = "burstHealthThreshold",
       min = 50,
       max = 100,
       default = 80,
       step = 5,
       tooltip = "Enemy health percentage to start using cooldowns"
   })
   :Checkbox({
       text = "Smart Target Selection",
       var = "smartTargeting",
       default = true,
       tooltip = "Automatically select best targets for abilities"
   })
   :Checkbox({
       text = "Melee Rotation (Emergency)",
       var = "useMeleeRotation",
       default = true,
       tooltip = "Use Raptor Strike and Wing Clip when enemies get too close"
   })
   :Header({ text = "Level Progression" })
   :Checkbox({
       text = "Auto-adjust spell ranks",
       var = "autoSpellRanks",
       default = true,
       tooltip = "Automatically use highest known rank of spells"
   })