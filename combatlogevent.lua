-- Create addon frame and register events
local frame = CreateFrame("Frame")
local addonName = "RangeCounter"

-- Initialize variables
local outOfRangeCount = 0

-- Table of possible out of range messages (lowercase for comparison)
local rangeMessages = {
    "out of range",
    "is too far away",
    "no line of sight",
    "must be closer",
    "not close enough",
}

-- Register slash commands
SLASH_RANGECOUNTER1 = "/rangecount"
SLASH_RANGERESET1 = "/rangereset"

-- Event handling
frame:RegisterEvent("UI_ERROR_MESSAGE")

-- Main event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UI_ERROR_MESSAGE" then
        local _, message = ...
        -- Convert message to lowercase for comparison
        local lowerMessage = message:lower()
        
        -- Check against all possible range messages
        for _, rangeMsg in ipairs(rangeMessages) do
            if lowerMessage:find(rangeMsg) then
                outOfRangeCount = outOfRangeCount + 1
                break  -- Exit loop once we've found a match
            end
        end
    end
end)

-- Slash command handlers
SlashCmdList["RANGECOUNTER"] = function(msg)
    print("|cFF00FF00Range Counter:|r Out of range messages: " .. outOfRangeCount)
end

SlashCmdList["RANGERESET"] = function(msg)
    outOfRangeCount = 0
    print("|cFF00FF00Range Counter:|r Counter reset to 0")
end

-- Print loaded message
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00Range Counter loaded!|r Use /rangecount to see total and /rangereset to reset")
    end
end)
