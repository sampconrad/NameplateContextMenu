---@diagnostic disable: undefined-field
-- Localize globals
local _G = _G
local CreateFrame, UIParent, InCombatLockdown, C_NamePlate, UnitCanAttack, UnitIsUnit, Plater = _G.CreateFrame,
    _G.UIParent, _G.InCombatLockdown, _G.C_NamePlate, _G.UnitCanAttack, _G.UnitIsUnit, _G.Plater
local GetNamePlateForUnit, GetNamePlates = C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates

-- Create the main frame for event handling
local NameplateContextFrame = CreateFrame("Frame", "NameplateContextFrame", UIParent)
NameplateContextFrame:Hide()
NameplateContextFrame.attachedVisibleFrames = {}
NameplateContextFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
NameplateContextFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
NameplateContextFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Create buttons for the player's and enemy/target nameplates
local function CreatePlateButton(name)
    local button = CreateFrame("BUTTON", name, UIParent, "SecureActionButtonTemplate")
    button:SetSize(300, 70)
    button:RegisterForClicks('LeftButtonUp', 'LeftButtonDown', 'RightButtonUp', 'RightButtonDown')
    button:Hide()
    return button
end

local PersonalPlate_Btn = CreatePlateButton("PersonalPlate_Btn")
local EnemyPlate_Btn = CreatePlateButton("EnemyPlate_Btn")

-- Helper functions
local function AnchorBtn(Button, frame, unit)
    Button:ClearAllPoints()
    Button:SetPoint("CENTER", frame, "CENTER", -20, -10)
    Button:SetAttribute('unit', unit)
    Button:SetAttribute('*type1', 'target')      -- Left-click to target the unit
    Button:SetAttribute('*type2', 'togglemenu')  -- Right-click for context menu
    Button:Show()
end

local function HandlePlate_Added(unit)
    local frame = GetNamePlateForUnit(unit)
    if not frame then return end

    if UnitIsUnit(unit, "player") then
        AnchorBtn(PersonalPlate_Btn, frame, "player")  -- Personal nameplate
    elseif UnitCanAttack("player", unit) then
        AnchorBtn(EnemyPlate_Btn, frame, unit)  -- Enemy nameplate
    end
end

local function HandlePlate_Removed(unit)
    if UnitIsUnit(unit, "player") then
        PersonalPlate_Btn:Hide()  -- Hide when personal plate is removed
    elseif UnitCanAttack("player", unit) then
        EnemyPlate_Btn:Hide()  -- Hide when enemy plate is removed
    end
end

local function UpdateBtnPosition()
    if InCombatLockdown() then return end

    local playerFrame = GetNamePlateForUnit("player")
    if playerFrame and Plater and playerFrame.unitFrame.PlaterOnScreen then
        AnchorBtn(PersonalPlate_Btn, playerFrame, "player")
    end

    for _, nameplate in ipairs(GetNamePlates()) do
        local nameplateUnit = nameplate.namePlateUnitToken
        if UnitCanAttack("player", nameplateUnit) then
            AnchorBtn(EnemyPlate_Btn, nameplate, nameplateUnit)
        end
    end
end

local function OnEvent_Callback(_, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Update buttons and positions after combat ends
        UpdateBtnPosition()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if not InCombatLockdown() then
            HandlePlate_Added(unit)
            UpdateBtnPosition()
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if not InCombatLockdown() then
            HandlePlate_Removed(unit)
            UpdateBtnPosition()
        end
    end
end

-- Register the callback function
NameplateContextFrame:SetScript("OnEvent", OnEvent_Callback)
