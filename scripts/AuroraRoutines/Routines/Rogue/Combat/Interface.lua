local Routine = Aurora.Routine
local MyNamespace = Routine.Namespace

local gui = Aurora.GuiBuilder:New()

gui:Category("Combat Settings")
   :Tab("DPS")
   :Header({ text = "Combo Point Management" })
   :Checkbox({ 
       text = "Smart CP Spending",
       var = "smartCPSpending",
       default = true,
       tooltip = "Spend combo points early on low health targets to avoid losing them when target dies"
   })
   :Slider({
       text = "Emergency CP Threshold",
       var = "emergencyCPThreshold",
       min = 10,
       max = 40,
       default = 25,
       step = 5,
       tooltip = "Spend 2+ combo points when target health is below this percentage"
   })
   :Slider({
       text = "Medium CP Threshold", 
       var = "mediumCPThreshold",
       min = 30,
       max = 70,
       default = 50,
       step = 5,
       tooltip = "Spend 3+ combo points when target health is below this percentage"
   })
   :Header({ text = "Slice and Dice" })
   :Checkbox({
       text = "Maintain Slice and Dice",
       var = "maintainSliceAndDice",
       default = true,
       tooltip = "Always keep Slice and Dice active for increased attack speed"
   })
   :Checkbox({
       text = "Use 1 CP Slice and Dice",
       var = "use1CPSliceAndDice",
       default = true,
       tooltip = "Use 1 combo point Slice and Dice to maintain uptime efficiently"
   })