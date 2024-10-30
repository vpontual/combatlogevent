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
local defaultConfig = {
    displayDuration = 3,
    scale = 1,
    position = {
        x = 0,
        y = 0,
        relativeTo = "CENTER"
    }
}

local function CreateWeakAurasDisplay(msgType, config)
    -- Merge with defaults
    config = config or {}
    for k, v in pairs(defaultConfig) do
        if config[k] == nil then
            config[k] = v
        end
    end

    local display = {
        id = format("CLE_%s", msgType),
        regionType = "icon",
        trigger = {
            type = "custom",
            custom = format([[
                function(trigger)
                    return trigger.msgType == %q
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

-- Error handling and validation
local function SafeWeakAurasAdd(display)
    if type(WeakAuras.Add) ~= "function" then
        print(format("|cFFFF0000%s:|r WeakAuras.Add is not available", addonName))
        return false
    end
    
    local success, err = pcall(WeakAuras.Add, display)
    if not success then
        print(format("|cFFFF0000%s:|r Error adding WeakAura: %s", addonName, err))
        return false
    end
    return true
end

-- Initialize WeakAuras integration
local function InitializeWeakAuras()
    if not WeakAuras then
        print(format("|cFFFF0000%s:|r WeakAuras addon not found!", addonName))
        return false
    end
    
    for msgType, config in pairs(icons) do
        if addon.messageTypes[msgType] then
            local display = CreateWeakAurasDisplay(msgType, config)
            if display then
                displays[msgType] = display
                if not SafeWeakAurasAdd(display) then
                    return false
                end
            end
        end
    end
    
    return true
end

-- Update WeakAuras display when a message is processed
local function UpdateDisplay(msgType)
    if not displays[msgType] then return end
    if type(WeakAuras.ScanEvents) ~= "function" then
        print(format("|cFFFF0000%s:|r WeakAuras.ScanEvents is not available", addonName))
        return
    end
    
    WeakAuras.ScanEvents("CLE_MESSAGE", {msgType = msgType})
end

-- Cleanup function
local function CleanupWeakAuras()
    for msgType, display in pairs(displays) do
        if WeakAuras.Delete then
            WeakAuras.Delete(display.id)
        end
    end
    displays = {}
end

-- Hook into the main addon's message processors
ProcessErrorMessage = function(errorType, message)
    if type(originalProcessErrorMessage) ~= "function" then return end
    
    local result = originalProcessErrorMessage(errorType, message)
    
    if message then
        local lowerMessage = message:lower()
        for msgType, data in pairs(addon.messageTypes) do
            if data.eventType == "error" then
                for _, pattern in ipairs(data.patterns) do
                    if lowerMessage:find(pattern, 1, true) then
                        UpdateDisplay(msgType)
                        break
                    end
                end
            end
        end
    end
    
    return result
end

ProcessCombatLogEvent = function(...)
    if type(originalProcessCombatLogEvent) ~= "function" then return end
    
    local result = originalProcessCombatLogEvent(...)
    local timestamp, eventType = ...
    
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
addon.LoadWeakAurasCompanion = function()
    local loaded = InitializeWeakAuras()
    if loaded then
        print(format("|cFF00FF00%s:|r WeakAuras integration loaded successfully!", addonName))
    end
end

-- Export functions for use in main addon
addon.LoadWeakAurasCompanion = LoadWeakAurasCompanion
addon.UpdateWeakAurasDisplay = UpdateDisplay
addon.CleanupWeakAuras = CleanupWeakAuras