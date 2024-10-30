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

-- Update the WeakAura module settings when a new message is caught
function ProcessErrorMessage(errorType, message)
    -- ...
    for msgType, data in pairs(addon.messageTypes) do
        if icons[msgType] then
            weakaura:SetModule(msgType, {
                name = icons[msgType].name,
                texture = icons[msgType].texture,
                color = icons[msgType].color,
                size = icons[msgType].size,
                scale = icons[msgType].scale,
                show = icons[msgType].show,
                hide = icons[msgType].hide,
            })
        end
    end
end

-- Update the WeakAura module settings when a new combat log event is caught
function ProcessCombatLogEvent(...)
    -- ...
    for msgType, data in pairs(addon.messageTypes) do
        if icons[msgType] then
            weakaura:SetModule(msgType, {
                name = icons[msgType].name,
                texture = icons[msgType].texture,
                color = icons[msgType].color,
                size = icons[msgType].size,
                scale = icons[msgType].scale,
                show = icons[msgType].show,
                hide = icons[msgType].hide,
            })
        end
    end
end

-- Load the WeakAuras companion file if it's available and enabled by the user
local function LoadWeakAurasCompanion()
    local weakaurasEnabled, _ = GetAddOnMetadata("WeakAuras", "Enabled")
    if weakaurasEnabled then
        dofile("ConditionCounterWeakAuras.lua")
    end
end

-- Call the load function when the addon is enabled
function frame:PLAYER_LOGIN(event)
    -- ...
    LoadWeakAurasCompanion()
end