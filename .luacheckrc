-- Standard WoW addon configuration
-- Using 'lua51' as the base because WoW uses a custom 5.1 implementation
std = "lua51"

-- Ignore certain common "false positive" warnings
-- 631: Line is too long (useful if you have long data tables)
-- 211: Unused local variable (often used for underscore placeholders like _, event)
ignore = { "631", "211" }

-- Define Blizzard-specific global variables so Luacheck doesn't flag them as "undefined"
read_globals = {
    -- Basic Frame & UI API
    "CreateFrame", "UIParent", "UnitName", "UnitClass", "print", "GetTime",
    "C_Timer", "C_PetJournal", "C_MountJournal", "PlaySound", "UIFrameFadeIn",
    
    -- Common Addon Libraries
    "LibStub", "AceLibrary", "CallbackHandler",

    -- Addon-specific global (Add your addon's main table name here)
    "jMap", 
}

-- Exclude folders you don't want to lint (like external libraries or release builds)
exclude_files = {
    "Libs/**",
    ".release/**",
}

-- Enable checking for unused arguments and variables
unused_args = true
unused_locals = true