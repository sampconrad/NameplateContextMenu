---@diagnostic disable: undefined-field
-- Localize globals
local _G = _G
local CreateFrame, UIParent, InCombatLockdown, C_NamePlate, UnitCanAttack, C_Timer = _G.CreateFrame,
  _G.UIParent, _G.InCombatLockdown, _G.C_NamePlate, _G.UnitCanAttack, _G.C_Timer
local GetNamePlateForUnit, GetNamePlates = C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates

-- Create the main frame for event handling
local NameplateContextFrame = CreateFrame("Frame", "NameplateContextFrame", UIParent)
NameplateContextFrame:Hide()
NameplateContextFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
NameplateContextFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
NameplateContextFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
NameplateContextFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

-- Create buttons for the player's and enemy/target nameplates
local function CreatePlateButton(name)
  local button = CreateFrame("BUTTON", name, UIParent, "SecureUnitButtonTemplate")
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetSize(300, 70)
  button:Hide()
  return button
end

local PersonalPlate_Btn = CreatePlateButton("NameplateContextMenu_PERSONAL")
local EnemyPlate_Btn = CreatePlateButton("NameplateContextMenu_ENEMY")

-- Helper function to anchor a button to a frame
local function AnchorBtn(Button, frame, unit)
  Button:ClearAllPoints()
  Button:SetPoint("CENTER", frame, "CENTER", -20, -10)
  Button:SetAttribute('unit', unit)
  Button:SetAttribute('type1', 'target') -- Left-click to target the unit
  Button:SetAttribute('type2', 'togglemenu') -- Right-click for context menu
  Button:Show()
end

-- Update button positions for all nameplates
local function UpdateBtnPosition()
  if InCombatLockdown() then
    return
  end

  -- Update personal nameplate button
  local playerFrame = GetNamePlateForUnit("player")
  if playerFrame and playerFrame:IsShown() then
    AnchorBtn(PersonalPlate_Btn, playerFrame, "player")
  else
    PersonalPlate_Btn:Hide()
  end

  -- Update enemy nameplate buttons
  for _, nameplate in ipairs(GetNamePlates()) do
    local nameplateUnit = nameplate.namePlateUnitToken
    if nameplateUnit and UnitCanAttack("player", nameplateUnit) then
      AnchorBtn(EnemyPlate_Btn, nameplate, nameplateUnit)
    end
  end
end

-- Event handler
local function OnEvent_Callback(_, event)
  if event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
    C_Timer.After(0.1, UpdateBtnPosition)
  else
    C_Timer.After(1, UpdateBtnPosition)
  end
end

-- Register the callback function
NameplateContextFrame:SetScript("OnEvent", OnEvent_Callback)