-- MiniHonor: Displays current honor / max honor in a small draggable frame
-- For WoW Classic Anniversary Edition

local ADDON_NAME = "MiniHonor"

-- Currency ID for Classic Honor
local CLASSIC_HONOR_CURRENCY_ID = 1901

-- Format number with commas (17000 -> 17,000)
local function FormatNumber(num)
    if not num then return "0" end
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- Create the main frame
local frame = CreateFrame("Frame", "MiniHonorFrame", UIParent)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("HONOR_XP_UPDATE")

-- Create the display button
local honorButton = CreateFrame("Button", "MiniHonorButton", UIParent, "BackdropTemplate")
honorButton:SetSize(110, 20)
honorButton:EnableMouse(true)
honorButton:SetMovable(true)
honorButton:SetClampedToScreen(true)
honorButton:RegisterForDrag("LeftButton")
honorButton:RegisterForClicks("AnyUp")

-- Add semi-transparent background
honorButton:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
honorButton:SetBackdropColor(0, 0, 0, 0.7)
honorButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)

-- Create the text
local honorText = honorButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
honorText:SetPoint("CENTER", honorButton, "CENTER", 0, 0)
honorText:SetTextColor(1, 0.82, 0, 1)  -- Gold color for honor

-- Store reference
honorButton.text = honorText

-- Drag handlers
honorButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

honorButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, relPoint, x, y = self:GetPoint()
    MiniHonorDB = MiniHonorDB or {}
    MiniHonorDB.point = point
    MiniHonorDB.relPoint = relPoint
    MiniHonorDB.x = x
    MiniHonorDB.y = y
end)

-- Get honor info
local function GetHonorInfo()
    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(CLASSIC_HONOR_CURRENCY_ID)
    if currencyInfo then
        return currencyInfo.quantity, currencyInfo.maxQuantity
    end
    return 0, 0
end

-- Update honor display
local function UpdateHonor()
    local current, max = GetHonorInfo()
    local displayText
    if max and max > 0 then
        displayText = FormatNumber(current) .. "/" .. FormatNumber(max)
    else
        displayText = FormatNumber(current)
    end
    honorText:SetText(displayText)

    -- Adjust frame width based on text
    local textWidth = honorText:GetStringWidth()
    honorButton:SetWidth(math.max(textWidth + 20, 80))
end

-- Position the frame
local function PositionFrame()
    honorButton:ClearAllPoints()

    -- Load saved position if available
    if MiniHonorDB and MiniHonorDB.point then
        honorButton:SetPoint(MiniHonorDB.point, UIParent, MiniHonorDB.relPoint, MiniHonorDB.x, MiniHonorDB.y)
    else
        -- Default position
        honorButton:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -5, -230)
    end
    honorButton:Show()
end

-- Tooltip
honorButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("MiniHonor", 1, 1, 1)
    GameTooltip:AddLine(" ")

    local current, max = GetHonorInfo()
    GameTooltip:AddDoubleLine("Current Honor:", FormatNumber(current), 0.8, 0.8, 0.8, 1, 0.82, 0)
    if max and max > 0 then
        GameTooltip:AddDoubleLine("Maximum:", FormatNumber(max), 0.8, 0.8, 0.8, 1, 1, 1)
        local remaining = max - current
        if remaining > 0 then
            GameTooltip:AddDoubleLine("Until Cap:", FormatNumber(remaining), 0.8, 0.8, 0.8, 0.5, 1, 0.5)
        else
            GameTooltip:AddLine("Honor capped!", 1, 0.5, 0.5)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

honorButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Click handler - open PVP frame
honorButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        ToggleCharacter("PVPFrame")
    end
end)

-- Event handler
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            PositionFrame()
            UpdateHonor()
        end)
    elseif event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        print("|cffffd100MiniHonor|r loaded")
    elseif event == "CURRENCY_DISPLAY_UPDATE" or event == "HONOR_XP_UPDATE" then
        UpdateHonor()
    end
end)

-- Slash command
SLASH_MiniHonor1 = "/MiniHonor"
SlashCmdList["MiniHonor"] = function(msg)
    local current, max = GetHonorInfo()
    print("|cffffd100MiniHonor:|r " .. FormatNumber(current) .. "/" .. FormatNumber(max))
end
