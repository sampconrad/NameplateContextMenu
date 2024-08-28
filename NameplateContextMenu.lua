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

-- Create buttons for the player's and enemy/target nameplates
local function CreatePlateButton(name)
    local button = CreateFrame("BUTTON", name, UIParent, "SecureActionButtonTemplate")
    button:SetSize(200, 50)
    button:RegisterForClicks('RightButtonUp', 'RightButtonDown')
    button:SetAttribute('*type2', 'togglemenu')
    if name == "PersonalPlate_Btn" then
        button:SetAttribute('unit', 'player')
    end
    return button
end

local PersonalPlate_Btn = CreatePlateButton("PersonalPlate_Btn")
local EnemyPlate_Btn = CreatePlateButton("EnemyPlate_Btn")

-- Helper functions
local function AnchorBtn(Button, frame, unit)
    Button:Show()
    Button:SetPoint("CENTER", frame, "CENTER", 0, 0)
    Button:SetAttribute('unit', unit)
end

local function HandlePlate_Added(unit)
    local frame = GetNamePlateForUnit(unit)
    if not frame then return end

    if UnitIsUnit(unit, "player") then
        AnchorBtn(PersonalPlate_Btn, frame, unit)
    elseif UnitCanAttack("player", unit) then
        AnchorBtn(EnemyPlate_Btn, frame, unit)
    end
end

local function HandlePlate_Removed(unit)
    if UnitIsUnit(unit, "player") then
        PersonalPlate_Btn:Hide()
    elseif UnitCanAttack("player", unit) then
        EnemyPlate_Btn:Hide()
    end
end

local function UpdateBtnPosition()
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
    if InCombatLockdown() then return end

    if event == "NAME_PLATE_UNIT_ADDED" then
        HandlePlate_Added(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        HandlePlate_Removed(unit)
    end

    UpdateBtnPosition()
end

-- Register the callback function
NameplateContextFrame:SetScript("OnEvent", OnEvent_Callback)
