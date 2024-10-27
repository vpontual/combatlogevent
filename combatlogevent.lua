local addonName = "RangeCounter"

-- Message categories and their patterns
local messageTypes = {
    -- Range messages using UI error events
    range = {
        patterns = {
            "out of range",
            "is too far away",
            "no line of sight",
            "must be closer",
            "not close enough",
        },
        count = 0,
        threshold = 10,
        eventType = "error" -- Marks this as using UI error system
    },
    -- Example combat log message type
    interrupted = {
        patterns = {
            "SPELL_INTERRUPT",   -- Combat log event type to match
            "SPELL_STOLEN"       -- Could add multiple event types to track
        },
        count = 0,
        threshold = 5,
        eventType = "combat",   -- Marks this as using combat log
        -- Optional: Add specific spell IDs to track
        spellIds = {
            -- Example: Counterspell
            2139,
            -- Add more spell IDs as needed
        }
    }
    -- Template for adding new combat log categories:
    --[[
    newtype = {
        patterns = {}, -- COMBAT_LOG_EVENT types or error messages
        count = 0,
        threshold = 0,
        eventType = "combat", -- or "error"
        spellIds = {}, -- optional, for specific spells
        sourceOnly = true, -- optional, only count if player is source
        destOnly = true, -- optional, only count if player is target
    }
    ]]
}

-- Initialize saved variables with a structure ready for expansion
local function InitializeSavedVars()
    if not RangeCounterDB then
        RangeCounterDB = {
            messageTypes = {},
            settings = {
                enableSound = true,
                enableWarnings = true,
                -- Add new settings here as needed
            }
        }
    end
    
    -- Initialize counters from saved data
    for msgType, data in pairs(messageTypes) do
        if not RangeCounterDB.messageTypes[msgType] then
            RangeCounterDB.messageTypes[msgType] = {
                count = 0,
            }
        end
        data.count = RangeCounterDB.messageTypes[msgType].count
    end
end

-- Generic message handler for UI errors
local function ProcessErrorMessage(message)
    if not message then return end
    local lowerMessage = message:lower()
    
    -- Check each message type that uses error events
    for msgType, data in pairs(messageTypes) do
        if data.eventType == "error" then
            for _, pattern in ipairs(data.patterns) do
                if lowerMessage:find(pattern) then
                    data.count = data.count + 1
                    RangeCounterDB.messageTypes[msgType].count = data.count
                    
                    if data.threshold and data.count >= data.threshold then
                        print(string.format("|cFF00FF00%s:|r Threshold reached for %s! Count: %d", 
                            addonName, msgType, data.count))
                    end
                    
                    return -- Exit after first match
                end
            end
        end
    end
end

-- Combat log processor
local function ProcessCombatLogEvent(...)
    -- Combat log parameters
    local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
          spellId, spellName = ...
    
    -- Get player GUID for comparison if needed
    local playerGUID = UnitGUID("player")
    
    -- Check each message type that uses combat log
    for msgType, data in pairs(messageTypes) do
        if data.eventType == "combat" then
            -- Check if this event type matches our patterns
            for _, pattern in ipairs(data.patterns) do
                if eventType == pattern then
                    -- Optional: Check if it's a specific spell we're tracking
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
                    
                    -- Optional: Check source/dest restrictions
                    if (data.sourceOnly and sourceGUID ~= playerGUID) or
                       (data.destOnly and destGUID ~= playerGUID) then
                        return
                    end
                    
                    -- Increment counter
                    data.count = data.count + 1
                    RangeCounterDB.messageTypes[msgType].count = data.count
                    
                    -- Handle threshold notification
                    if data.threshold and data.count >= data.threshold then
                        print(string.format("|cFF00FF00%s:|r Threshold reached for %s! Count: %d", 
                            addonName, msgType, data.count))
                    end
                    
                    return -- Exit after first match
                end
            end
        end
    end
end

-- Event handlers
local function OnErrorMessage(self, event, message)
    ProcessErrorMessage(message)
end

local function OnCombatLogEvent(self, event, ...)
    ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
end

local function OnPlayerLogin(self, event)
    InitializeSavedVars()
    print(string.format("|cFF00FF00%s loaded!|r Use /range to see totals and /range reset to reset", 
        addonName))
end

local function OnEvent(self, event, ...)
    if event == "UI_ERROR_MESSAGE" then
        OnErrorMessage(self, event, ...)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent(self, event, ...)
    elseif event == "PLAYER_LOGIN" then
        OnPlayerLogin(self, event)
    end
end

-- Command handling
local function ShowCounts()
    for msgType, data in pairs(messageTypes) do
        print(string.format("|cFF00FF00%s:|r %s messages: %d", 
            addonName, msgType, data.count))
    end
end

local function ResetCounts()
    for msgType, data in pairs(messageTypes) do
        data.count = 0
        RangeCounterDB.messageTypes[msgType].count = 0
    end
    print(string.format("|cFF00FF00%s:|r Counters reset to 0", addonName))
end

local function SlashCommandHandler(msg)
    msg = msg and msg:lower() or ""
    if msg == "reset" then
        ResetCounts()
    else
        ShowCounts()
    end
end

-- Frame setup
local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")  -- Added combat log event
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", OnEvent)

-- Register slash commands
SLASH_RANGECOUNTER1 = "/range"
SlashCmdList["RANGECOUNTER"] = SlashCommandHandler