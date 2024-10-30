-- Create addon namespace
local addonName, addon = ...
addon.version = "1.2.0"

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
        soundFile = "Interface\\AddOns\\ComabtLogEvent\\media\\range_error_sound.wav"  
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

-- Initialize saved variables
local function InitializeSavedVars()
    if not ConditionCounterDB then
        ConditionCounterDB = {
            conditionTypes = {},
            settings = {
                enableSound = true,
                enableWarnings = true,
            }
        }
    end
    
    -- Initialize counters from saved data
    for msgType, data in pairs(addon.messageTypes) do
        if not ConditionCounterDB.conditionTypes[msgType] then
            ConditionCounterDB.conditionTypes[msgType] = {
                count = 0,
            }
        end
        data.count = ConditionCounterDB.conditionTypes[msgType].count
    end
end

-- Debug print function
local function DebugPrint(...)
    if addon.debug then
        print(string.format("|cFF00FF00%s Debug:|r", addonName), ...)
    end
end

-- Generic message handler for UI errors
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
                    
                    -- Play the sound file for this category
                    if data.soundFile then
                        PlaySoundFile(data.soundFile)
                    end
                    
                    if data.threshold and data.count >= data.threshold then
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

-- Combat log processor
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
                    ConditionCounterDB.messageTypes[msgType].count = data.count
                    
                    if data.threshold and data.count >= data.threshold then
                        print(string.format("|cFF00FF00%s:|r Threshold reached for %s! Count: %d", 
                            addonName, msgType, data.count))
                    end
                    
                    return
                end
            end
        end
    end
end

-- Create main addon frame
local frame = CreateFrame("Frame")

-- Event handlers
function frame:PLAYER_LOGIN(event)
    InitializeSavedVars()
    print(string.format("|cFF00FF00%s v%s loaded!|r Use /cle to see totals and /cle reset to reset", 
        addonName, addon.version))
end

-- Handle both arguments from UI_ERROR_MESSAGE
function frame:UI_ERROR_MESSAGE(event, errorType, message)
    ProcessErrorMessage(errorType, message)
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
end

-- Main event handler
function frame:OnEvent(event, ...)
    if self[event] then
        self[event](self, event, ...)
    end
end

-- Register events properly for both types of error messages
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", frame.OnEvent)

-- Command handling
local function ShowCounts()
    for msgType, data in pairs(addon.messageTypes) do
        print(string.format("|cFF00FF00%s:|r %s messages: %d", 
            addonName, msgType, data.count))
    end
end

local function ResetCounts()
    for msgType, data in pairs(addon.messageTypes) do
        data.count = 0
        ConditionCounterDB.messageTypes[msgType].count = 0
    end
    print(string.format("|cFF00FF00%s:|r Counters reset to 0", addonName))
end

-- Debug command handler
local function ToggleDebug()
    addon.debug = not addon.debug
    print(string.format("|cFF00FF00%s:|r Debug mode %s", 
        addonName, addon.debug and "enabled" or "disabled"))
end

-- Slash command handler
local function SlashCommandHandler(msg)
    msg = msg and msg:lower() or ""
    if msg == "reset" then
        ResetCounts()
    elseif msg == "debug" then
        ToggleDebug()
    else
        ShowCounts()
    end
end

-- Register slash commands
SLASH_CLE1 = "/cle"
SlashCmdList["CLE"] = SlashCommandHandler