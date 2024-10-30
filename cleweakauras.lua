-- Companion namespace
local addonName, addon = ...

-- Define the icon settings for each message type
local icons = {
    rangeError = {
        name = "Range Error",
        texture = "Interface\\AddOns\\ConditionCounter\\media\\range_error_icon",
        color = { 1, 0, 0 },
        size = 32,
        scale = 1.5,
        show = true,
        hide = false,
    },
    facingError = {
        name = "Facing Error",
        texture = "Interface\\AddOns\\ConditionCounter\\media\\facing_error_icon",
        color = { 0, 1, 0 },
        size = 32,
        scale = 1.5,
        show = true,
        hide = false,
    },
    interrupted = {
        name = "Interrupted",
        texture = "Interface\\AddOns\\ConditionCounter\\media\\interrupted_icon",
        color = { 0, 0, 1 },
        size = 32,
        scale = 1.5,
        show = true,
        hide = false,
    }
}

-- Create a WeakAura module for each message type
for msgType, data in pairs(addon.messageTypes) do
    if icons[msgType] then
        weakaura:RegisterModule(msgType, {
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