---@diagnostic disable: undefined-field
local _, NCM = ...

NCM.config = {
  buttonSize = {
    300,
    70
  }, -- size of the button on the nameplate
  updateDelay = {
    0.1,
    0.2
  }, -- first delay is for new nameplates, second delay is for nameplates that are already on the screen
  events = {
    "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED",
    "PLAYER_REGEN_ENABLED",
    "LOADING_SCREEN_DISABLED",
    "PLAYER_TARGET_CHANGED"
  }
}

local _G = _G

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local InCombatLockdown = _G.InCombatLockdown
local C_NamePlate = _G.C_NamePlate
local UnitIsUnit = _G.UnitIsUnit
local C_Timer = _G.C_Timer
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates

NCM.frame = CreateFrame("Frame", "NCMFrame", UIParent)
local NCMFrame = NCM.frame
NCMFrame:Hide()

for _, event in ipairs(NCM.config.events) do
  NCMFrame:RegisterEvent(event)
end

NCM.tempBtnTable = {}

NCM.ConfigureButton = function(button, frame, unit)
  if InCombatLockdown() then
    return
  end

  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetSize(NCM.config.buttonSize[1], NCM.config.buttonSize[2])

  button:SetAttribute('type1', 'target')
  button:SetAttribute('type2', 'togglemenu')

  button:ClearAllPoints()
  button:SetPoint("CENTER", frame, "CENTER", 0, 0)
  button:SetAttribute("unit", unit)
  button:Show()
end

NCM.CreatePlateButtonForFrame = function(frame, unit)
  if not frame or not unit then
    return
  end

  if NCM.tempBtnTable[frame] then
    NCM.tempBtnTable[frame]:SetAttribute("unit", unit)
    NCM.tempBtnTable[frame]:Show()
    return NCM.tempBtnTable[frame]
  end

  local button = CreateFrame("BUTTON", nil, UIParent, "SecureUnitButtonTemplate")
  NCM.ConfigureButton(button, frame, unit)

  NCM.tempBtnTable[frame] = button
  return button
end

NCM.CleanupInvalidButtons = function()
  for frame, button in pairs(NCM.tempBtnTable) do
    if not frame:IsShown() or not frame.namePlateUnitToken then
      button:Hide()
      NCM.tempBtnTable[frame] = nil
    end
  end
end

NCM.UpdateBtnPosition = function()
  if InCombatLockdown() then
    return
  end

  NCM.CleanupInvalidButtons()

  for _, nameplate in ipairs(GetNamePlates()) do
    local unit = nameplate.namePlateUnitToken
    if unit and not UnitIsUnit(unit, "player") then
      NCM.CreatePlateButtonForFrame(nameplate, unit)
    end
  end

  local playerFrame = GetNamePlateForUnit("player")
  if playerFrame then
    NCM.CreatePlateButtonForFrame(playerFrame, "player")
  end
end

NCM.HandleEvent = function(_, event)
  local delays = {
    ["NAME_PLATE_UNIT_ADDED"] = NCM.config.updateDelay[1],
    ["NAME_PLATE_UNIT_REMOVED"] = NCM.config.updateDelay[1],
    ["PLAYER_REGEN_ENABLED"] = NCM.config.updateDelay[2],
    ["LOADING_SCREEN_DISABLED"] = NCM.config.updateDelay[2],
    ["PLAYER_TARGET_CHANGED"] = 0
  }

  local delay = delays[event]
  if delay then
    C_Timer.After(delay, NCM.UpdateBtnPosition)
  else
    NCM.UpdateBtnPosition()
  end
end

NCMFrame:SetScript("OnEvent", NCM.HandleEvent)
