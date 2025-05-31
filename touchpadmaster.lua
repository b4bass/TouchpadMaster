local _, Addon = ...
Addon.Public = Addon.Public or {}
_G["TouchpadMaster"] = Addon

local GetTime = GetTime
local IsMouseButtonDown = IsMouseButtonDown
local UnitExists = UnitExists
local GetMouseFoci = GetMouseFoci
local CursorHasItem = CursorHasItem
local SpellIsTargeting = SpellIsTargeting
local MouselookStart = MouselookStart
local MouselookStop = MouselookStop

local config = {
    isMonitoring = true,
    heldTime = 0.2,
}

local isMouseLookActive = false
local mouseDownStartTime, wasOverUnit, wasMouseDown = nil, false, false

-- Check if mouse over 3D world
local function IsMouseInWorld()
    local region = (GetMouseFoci() or {})[1]
    return (not region) or (region == WorldFrame)
end

local function ResetState()
    wasMouseDown = false
    mouseDownStartTime = nil
    wasOverUnit = false
end

local function StartTouchpadMouselook()
    MouselookStart()
    isMouseLookActive = true
end

local function StopTouchpadMouselook()
    MouselookStop()
    isMouseLookActive = false
end

local function SetCameraAxis(axis, value)
    value = tonumber(value)
    if not value or value < 1 or value > 360 then
        print("TouchpadMaster: Invalid " .. axis .. " value (".. tostring(value) .."), must be between 1 and 360.")
        return false
    end
    if axis == "x" then
        SetCVar("cameraYawMoveSpeed", value)
        print("TouchpadMaster: x-axis (yaw) speed set to " .. value)
    elseif axis == "y" then
        SetCVar("cameraPitchMoveSpeed", value)
        print("TouchpadMaster: y-axis (pitch) speed set to " .. value)
    end
    return true
end

local function SetInvert(axis)
    if axis == "x" then
        local new = GetCVar("mouseInvertYaw") == "1" and "0" or "1"
        SetCVar("mouseInvertYaw", new)
        print("TouchpadMaster: x-axis (yaw) invert " .. (new == "1" and "ON" or "OFF"))
    elseif axis == "y" then
        local new = GetCVar("mouseInvertPitch") == "1" and "0" or "1"
        SetCVar("mouseInvertPitch", new)
        print("TouchpadMaster: y-axis (pitch) invert " .. (new == "1" and "ON" or "OFF"))
    end
end

-- Main logic frame
local mouseLookFrame = CreateFrame("Frame", "TouchpadMasterFrame")
mouseLookFrame:SetScript("OnUpdate", function()
    if not config.isMonitoring then return end

    local now = GetTime()
    local mouseDown = IsMouseButtonDown("LeftButton")
    local inWorld = IsMouseInWorld()
    local overUnit = UnitExists("mouseover")
    local hasItem = CursorHasItem()
    local isTargeting = SpellIsTargeting()

    if hasItem or isTargeting then
        if isMouseLookActive then StopTouchpadMouselook() end
        ResetState()
        return
    end

    -- LeftMouseButton just pressed
    if mouseDown and not wasMouseDown then
        mouseDownStartTime = now
        wasOverUnit = overUnit
        wasMouseDown = true

    -- LeftMouseButton held
    elseif mouseDown and wasMouseDown then
        if wasOverUnit and not overUnit then
            return
        end
        local heldTime = now - (mouseDownStartTime or now)
        if wasOverUnit then
            if heldTime > config.heldTime then
                if not isMouseLookActive and inWorld then
                    StartTouchpadMouselook()
                end
            end
            return
        else
            if not isMouseLookActive and inWorld then
                StartTouchpadMouselook()
            end
        end

    -- LeftMouseButton just released
    elseif not mouseDown and wasMouseDown then
        if isMouseLookActive then
            StopTouchpadMouselook()
        end
        ResetState()
    end
end)

function Addon:ToggleTouchpadMaster()
    config.isMonitoring = not config.isMonitoring
    if config.isMonitoring then
        print("TouchpadMaster: |cff00ff00ENABLED|r")
        print("Type /touchpad help for options.")
    else
        if isMouseLookActive then StopTouchpadMouselook() end
        print("TouchpadMaster: |cffff0000DISABLED|r")
    end
end

-- Startup message
local startup = CreateFrame("Frame")
startup:RegisterEvent("PLAYER_ENTERING_WORLD")
startup:SetScript("OnEvent", function()
    if config.isMonitoring then
        print("TouchpadMaster: |cff00ff00ENABLED|r  /touchpad help")
    end
end)

local function HandleSlashCommand(args)
    if not args or args == "" then
        Addon:ToggleTouchpadMaster()
        return
    end

    local cmd, value = string.match(args, "^(%S+)%s*(.*)$")
    -- Convert the command to lowercase to ensure case-insensitivity for command handling
    cmd = string.lower(cmd or "")

    if cmd == "time" or cmd == "delay" then
        local time = tonumber(value)
        if time and time > 0 and time <= 2 then
            config.heldTime = time
            print("TouchpadMaster: Hold time set to " .. time .. "s")
        else
            print("TouchpadMaster: Invalid time (0.1-2.0 seconds)")
        end
    elseif cmd == "yaw" then
        SetCameraAxis("x", value)
    elseif cmd == "pitch" then
        SetCameraAxis("y", value)
    elseif cmd == "invertpitch" then
        SetInvert("y")
    elseif cmd == "invertyaw" then
        SetInvert("x")
    elseif cmd == "help" then
        print("TouchpadMaster Commands:")
        print("/touchpad - Toggle Touchpad on/off")
        print("/touchpad time <0.1-2.0> - Set LeftMouseButton-click timeframe to select units")
        print("/touchpad yaw <1-360> - Set x-axis camera speed")
        print("/touchpad pitch <1-360> - Set y-axis camera speed")
        print("/touchpad invertpitch - Toggle y-axis invert")
        print("/touchpad invertyaw - Toggle x-axis invert")
        print(" ")
        print("Set your keybind to toggle TouchpadMaster in the WoW Keybindings interface (default: CTRL-SHIFT-M)")

    else
        print("TouchpadMaster: Unknown command. Use '/touchpad help'")
    end
end

SLASH_TOUCHPADMASTER1 = "/touchpad"
SlashCmdList["TOUCHPADMASTER"] = HandleSlashCommand