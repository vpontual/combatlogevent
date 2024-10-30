-- Import WeakAuras library
local weakaura = LibStub("AceAddon-3.0"):GetAddon("WeakAuras")

-- Companion namespace
local addonName, addon = ...


-- Define the icon settings for each message type
local icons = {
    rangeError = {
        name = "Range Error",
        texture = "Interface\\AddOns\\CombatLogEvent\\media\\range_error_icon",
        color = { 1, 0, 0 },
        size = 32,
        scale = 1.5,
        show = true,
        hide = false,
    },
    facingError = {
        name = "Facing Error",
        texture = "Interface\\AddOns\\CombatLogEvent\\media\\facing_error_icon",
        color = { 0, 1, 0 },
        size = 32,
        scale = 1.5,
        show = true,
        hide = false,
    },
    interrupted = {
        name = "Interrupted",
        texture = "Interface\\AddOns\\CombatLogEvent\\media\\interrupted_icon",
        color = { 0, 0, 1 },
        size = 32,
        scale = 1.5,
        show = true,
        hide = false,
    }
}

-- Store WeakAuras display objects
local displays = {}

-- Create WeakAuras displays for each message type
local function CreateWeakAurasDisplay(msgType, config)
    local display = {
        id = string.format("CLE_%s", msgType),
        regionType = "icon",
        trigger = {
            type = "custom",
            custom = string.format([[
                function(trigger)
                    if trigger.msgType == "%s" then
                        return true
                    end
                    return false
                end
            ]], msgType),
            events = {"CLE_MESSAGE"}
        },
        load = {
            class = {multi = {}}
        },
        animation = {
            start = {
                type = "custom",
                duration = 0.2,
                alpha = 0,
                scale = 0.1
            },
            main = {
                type = "custom",
                duration = config.displayDuration,
                alpha = 1,
                scale = config.scale
            },
            finish = {
                type = "custom",
                duration = 0.2,
                alpha = 0,
                scale = 0.1
            }
        },
        icon = config.texture,
        iconColor = config.color,
        desaturate = false,
        frameStrata = "HIGH",
        width = config.size,
        height = config.size,
        xOffset = config.position.x,
        yOffset = config.position.y,
        anchorPoint = config.position.relativeTo,
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        cooldown = false,
        conditions = {},
        config = {},
        authorOptions = {},
        information = {
            forceEvents = true
        }
    }
    
    return display
end

-- Initialize WeakAuras integration
local function InitializeWeakAuras()
    -- Ensure WeakAuras exists
    if not WeakAuras then
        print(string.format("|cFFFF0000%s:|r WeakAuras addon not found!", addonName))
        return false
    end
    
    -- Create displays for each message type
    for msgType, config in pairs(icons) do
        if addon.messageTypes[msgType] then
            local display = CreateWeakAurasDisplay(msgType, config)
            displays[msgType] = display
            
            -- Register display with WeakAuras
            if WeakAuras.Add then
                WeakAuras.Add(display)
            else
                print(string.format("|cFFFF0000%s:|r Error registering WeakAuras display for %s", 
                    addonName, msgType))
            end
        end
    end
    
    return true
end

-- Update WeakAuras display when a message is processed
local function UpdateDisplay(msgType)
    if displays[msgType] and WeakAuras.ScanEvents then
        WeakAuras.ScanEvents("CLE_MESSAGE", {msgType = msgType})
    end
end

-- Hook into the main addon's message processors
local originalProcessErrorMessage = ProcessErrorMessage
function ProcessErrorMessage(errorType, message)
    local result = originalProcessErrorMessage(errorType, message)
    
    -- Check if any patterns matched and update corresponding display
    for msgType, data in pairs(addon.messageTypes) do
        if data.eventType == "error" then
            for _, pattern in ipairs(data.patterns) do
                if message:lower():find(pattern, 1, true) then
                    UpdateDisplay(msgType)
                    break
                end
            end
        end
    end
    
    return result
end

local originalProcessCombatLogEvent = ProcessCombatLogEvent
function ProcessCombatLogEvent(...)
    local result = originalProcessCombatLogEvent(...)
    
    local timestamp, eventType = ...
    
    -- Check if any patterns matched and update corresponding display
    for msgType, data in pairs(addon.messageTypes) do
        if data.eventType == "combat" then
            for _, pattern in ipairs(data.patterns) do
                if eventType == pattern then
                    UpdateDisplay(msgType)
                    break
                end
            end
        end
    end
    
    return result
end

-- Function to load WeakAuras integration
function LoadWeakAurasCompanion()
    local loaded = InitializeWeakAuras()
    if loaded then
        print(string.format("|cFF00FF00%s:|r WeakAuras integration loaded successfully!", addonName))
    end
end

-- Export functions for use in main addon
addon.LoadWeakAurasCompanion = LoadWeakAurasCompanion
addon.UpdateWeakAurasDisplay = UpdateDisplay