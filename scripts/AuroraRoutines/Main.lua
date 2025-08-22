-- Aurora Routines Main Entry Point
-- This file is loaded first according to loadorder.json

local Routine = Aurora.Routine
local Unlocker = Aurora.Unlocker

-- Initialize routine namespace
local AuroraRoutines = {}

-- Version information
AuroraRoutines.version = "1.0.0"
AuroraRoutines.author = "Your Name"

-- Debug flag
AuroraRoutines.debug = false

-- Utility function for debug output
function AuroraRoutines:Debug(...)
    if self.debug then
        print("[AuroraRoutines]", ...)
    end
end

-- Initialize the routine system
function AuroraRoutines:Initialize()
    self:Debug("Initializing Aurora Routines v" .. self.version)
    
    -- Register any global handlers here
    
    self:Debug("Initialization complete")
end

-- Called when routine is loaded
function AuroraRoutines:OnLoad()
    self:Debug("Aurora Routines loaded")
    self:Initialize()
end

-- Called when routine is unloaded
function AuroraRoutines:OnUnload()
    self:Debug("Aurora Routines unloaded")
end

-- Register the main routine
Aurora.AuroraRoutines = AuroraRoutines

-- Auto-initialize
AuroraRoutines:OnLoad()

return AuroraRoutines