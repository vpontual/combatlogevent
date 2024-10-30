-- Create addon namespace
local addonName, addon = ...
addon.version = "1.2.0"

-- Create frames
local frame = CreateFrame("Frame")
local combatFrame = CreateFrame("Frame")

-- Message categories and their patterns
addon.messageTypes = {
    -- Range messages using UI error events
    rangeError = {
        patterns = {
            "out of range",
            "is too far away",
            "no line of sight",
            "must be closer",
            "not close enough",
            "cannot reach",
            "out of range.",
            "too far away"
        },
        count = 0,
        threshold = 10,
        eventType = "error",
        soundFile = "Interface\\AddOns\\CombatLogEvent\\media\\range_error_sound.wav"  
    },
    facingError = {
        patterns = {
            "not facing the target"
        },
        count = 0,
        threshold = 10,
        eventType = "error",
        soundFile = "Interface\\AddOns\\CombatLogEvent\\media\\facing_error_sound.wav"  
    },
    interrupted = {
        patterns = {
            "SPELL_INTERRUPT",
            "SPELL_STOLEN"
        },
        count = 0,
        threshold = 5,
        eventType = "combat",
        spellIds = {
            2139, -- Counterspell
        }
    }
}

-- Utility Functions
local function DebugPrint(...)
    if addon.debug then
        print(string.format("|cFF00FF00%s Debug:|r", addonName), ...)
    end
end

local function PlaySoundWithCheck(soundFile)
    if soundFile and ConditionCounterDB.settings.enableSound then
        -- pcall to safely handle missing sound files
        local success = pcall(PlaySoundFile, soundFile, "Master")
        if not success and addon.debug then
            DebugPrint("Failed to play sound file:", soundFile)
        end
    end
end

local function UpdateSetting(setting, value)
    if ConditionCounterDB.settings[setting] ~= nil then
        ConditionCounterDB.settings[setting] = value
        print(string.format("|cFF00FF00%s:|r %s %s", 
            addonName, setting, value and "enabled" or "disabled"))
            
        -- Special handling for combat-only mode
        if setting == "inCombatOnly" then
            if value then
                if not InCombatLockdown() then
                    frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                end
            else
                frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
    end
end

local function ShowHelp()
    print(string.format("|cFF00FF00%s commands:|r", addonName))
    print("  /cle - Show current counts")
    print("  /cle reset - Reset all counters to 0")
    print("  /cle debug - Toggle debug mode")
    print("  /cle sound on|off - Toggle sound")
    print("  /cle warnings on|off - Toggle warnings")
    print("  /cle combatonly on|off - Toggle combat-only mode")
    print("  /cle help - Show this help message")
end

local function ShowCounts()
    for msgType, data in pairs(addon.messageTypes) do
        print(string.format("|cFF00FF00%s:|r %s messages: %d", 
            addonName, msgType, data.count))
    end
end

local function ResetCounts()
    for msgType, data in pairs(addon.messageTypes) do
        data.count = 0
        ConditionCounterDB.conditionTypes[msgType].count = 0
    end
    print(string.format("|cFF00FF00%s:|r Counters reset to 0", addonName))
end

-- Event Processing Functions
local function ProcessErrorMessage(errorType, message)
    if not message then return end
    local lowerMessage = message:lower()
    
    DebugPrint("Received UI error:", errorType, message)
    
    -- Check each message type that uses error events
    for msgType, data in pairs(addon.messageTypes) do
        if data.eventType == "error" then
            for _, pattern in ipairs(data.patterns) do
                if lowerMessage:find(pattern, 1, true) then
                    data.count = data.count + 1
                    ConditionCounterDB.conditionTypes[msgType].count = data.count
                    
                    DebugPrint("Matched pattern:", pattern, "New count:", data.count)
                    
                    -- Play sound using safe function
                    if data.soundFile then
                        PlaySoundWithCheck(data.soundFile)
                    end
                    
                    if ConditionCounterDB.settings.enableWarnings and
                       data.threshold and data.count >= data.threshold then
                        print(string.format("|cFF00FF00%s:|r Threshold reached for %s! Count: %d", 
                            addonName, msgType, data.count))
                    end

                    return
                end
            end
        end
    end

    DebugPrint("No pattern match found")
end

local function ProcessCombatLogEvent(...)
    local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
          spellId, spellName = ...
    
    local playerGUID = UnitGUID("player")
    
    for msgType, data in pairs(addon.messageTypes) do
        if data.eventType == "combat" then
            for _, pattern in ipairs(data.patterns) do
                if eventType == pattern then
                    if data.spellIds and #data.spellIds > 0 then
                        local spellMatch = false
                        for _, trackedSpellId in ipairs(data.spellIds) do
                            if spellId == trackedSpellId then
                                spellMatch = true
                                break
                            end
                        end
                        if not spellMatch then
                            return
                        end
                    end
                    
                    if (data.sourceOnly and sourceGUID ~= playerGUID) or
                       (data.destOnly and destGUID ~= playerGUID) then
                        return
                    end
                    
                    data.count = data.count + 1
                    ConditionCounterDB.conditionTypes[msgType].count = data.count
                    
                    if ConditionCounterDB.settings.enableWarnings and
                       data.threshold and data.count >= data.threshold then
                        print(string.format("|cFF00FF00%s:|r Threshold reached for %s! Count: %d", 
                            addonName, msgType, data.count))
                    end

                    return
                end
            end
        end
    end
end

-- Initialization Functions
local function InitializeSavedVars()
    ConditionCounterDB = ConditionCounterDB or {
        conditionTypes = {},
        settings = {
            enableSound = true,
            enableWarnings = true,
            debug = false,
            inCombatOnly = true
        }
    }
    
    -- Ensure all settings exist
    for key, value in pairs({
        enableSound = true,
        enableWarnings = true,
        debug = false,
        inCombatOnly = true
    }) do
        if ConditionCounterDB.settings[key] == nil then
            ConditionCounterDB.settings[key] = value
        end
    end
    
    -- Initialize counters from saved data
    for msgType, data in pairs(addon.messageTypes) do
        ConditionCounterDB.conditionTypes[msgType] = ConditionCounterDB.conditionTypes[msgType] or {
            count = 0
        }
        data.count = ConditionCounterDB.conditionTypes[msgType].count
    end
    
    -- Restore debug state
    addon.debug = ConditionCounterDB.settings.debug
end

-- Event Handlers
function frame:PLAYER_LOGIN(event)
    InitializeSavedVars()
    print(string.format("|cFF00FF00%s v%s loaded!|r Use /cle to see totals and /cle help for commands", 
        addonName, addon.version))

    local name, _, _, _, loadable = GetAddOnInfo("WeakAuras")
    if name and loadable then
        LoadWeakAurasCompanion()
    end
end

function frame:UI_ERROR_MESSAGE(event, errorType, message)
    ProcessErrorMessage(errorType, message)
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
end

function frame:OnEvent(event, ...)
    if self[event] then
        self[event](self, event, ...)
    end
end

-- Slash Command Handler
local function SlashCommandHandler(msg)
    msg = msg and msg:lower() or ""
    
    if msg == "reset" then
        ResetCounts()
    elseif msg == "debug" then
        UpdateSetting("debug", not ConditionCounterDB.settings.debug)
        addon.debug = ConditionCounterDB.settings.debug
    elseif msg == "help" then
        ShowHelp()
    elseif msg:match("^sound%s+(%w+)") then
        local state = msg:match("^sound%s+(%w+)")
        UpdateSetting("enableSound", state == "on")
    elseif msg:match("^warnings%s+(%w+)") then
        local state = msg:match("^warnings%s+(%w+)")
        UpdateSetting("enableWarnings", state == "on")
    elseif msg:match("^combatonly%s+(%w+)") then
        local state = msg:match("^combatonly%s+(%w+)")
        UpdateSetting("inCombatOnly", state == "on")
    else
        ShowCounts()
    end
end

-- Register Events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UI_ERROR_MESSAGE")
if not ConditionCounterDB or not ConditionCounterDB.settings.inCombatOnly then
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
frame:SetScript("OnEvent", frame.OnEvent)

-- Combat state handling
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if ConditionCounterDB.settings.inCombatOnly then
        if event == "PLAYER_REGEN_DISABLED" then
            frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end
end)

-- Register slash commands
SLASH_CLE1 = "/cle"
SlashCmdList["CLE"] = SlashCommandHandler