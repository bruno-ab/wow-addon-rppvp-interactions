local addonName, ns = ...
ns = ns or {}
ns.Options = ns.Options or {}

local Options = ns.Options
local L = ns.L

local DEFAULTS = {
  enabled = true,
  syncWhisper = true,
  syncGroup = true,
  sound = true,
  useModel = true,
  duration = 4.0,
  pvpOnly = false,
  point = "BOTTOM",
  relPoint = "BOTTOM",
  x = 0,
  y = 160,
}

local function copyDefaults()
  local t = {}
  for k, v in pairs(DEFAULTS) do
    t[k] = v
  end
  return t
end

function Options.Get()
  local db = ns.Stats and ns.Stats.GetDB and ns.Stats.GetDB()
  if not db then
    return copyDefaults()
  end
  db.settings = db.settings or {}
  for k, v in pairs(DEFAULTS) do
    if db.settings[k] == nil then
      db.settings[k] = v
    end
  end
  return db.settings
end

function Options.Set(key, value)
  local s = Options.Get()
  s[key] = value
end

function Options.ResetPosition()
  local s = Options.Get()
  s.point, s.relPoint, s.x, s.y = DEFAULTS.point, DEFAULTS.relPoint, DEFAULTS.x, DEFAULTS.y
  if ns.UI and ns.UI.ApplySavedPosition then
    ns.UI.ApplySavedPosition()
  end
end

------------------------------------------------------------
-- Simple options frame
------------------------------------------------------------
local panel

local function makeCheck(parent, label, key, y)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", 16, y)
  cb:SetChecked(Options.Get()[key])
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  text:SetText(label)
  cb:SetScript("OnClick", function(self)
    Options.Set(key, self:GetChecked() and true or false)
  end)
  return cb
end

function Options.TogglePanel()
  if panel and panel:IsShown() then
    panel:Hide()
    return
  end
  if not panel then
    panel = CreateFrame("Frame", "BanterCombatOptions", UIParent)
    panel:SetSize(360, 280)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    if panel.SetBackdrop then
      panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
      })
    end
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(L.OPT_TITLE)

    makeCheck(panel, L.OPT_ENABLE, "enabled", -44)
    makeCheck(panel, L.OPT_SYNC, "syncWhisper", -72)
    makeCheck(panel, L.OPT_GROUP, "syncGroup", -100)
    makeCheck(panel, L.OPT_SOUND, "sound", -128)
    makeCheck(panel, L.OPT_MODEL, "useModel", -156)
    makeCheck(panel, L.OPT_PVP_ONLY, "pvpOnly", -184)

    local durLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    durLabel:SetPoint("TOPLEFT", 24, -218)
    durLabel:SetText(L.OPT_DURATION)
    local slider = CreateFrame("Slider", "BanterCombatDurSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 160, -220)
    slider:SetMinMaxValues(2, 8)
    slider:SetValueStep(0.5)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(160)
    slider:SetValue(Options.Get().duration or 4)
    _G[slider:GetName() .. "Low"]:SetText("2")
    _G[slider:GetName() .. "High"]:SetText("8")
    _G[slider:GetName() .. "Text"]:SetText(string.format("%.1f", Options.Get().duration or 4))
    slider:SetScript("OnValueChanged", function(self, value)
      value = math.floor(value * 2 + 0.5) / 2
      Options.Set("duration", value)
      _G[self:GetName() .. "Text"]:SetText(string.format("%.1f", value))
    end)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(140, 22)
    reset:SetPoint("BOTTOMLEFT", 16, 16)
    reset:SetText(L.OPT_RESET_POS)
    reset:SetScript("OnClick", function()
      Options.ResetPosition()
    end)

    local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    close:SetSize(80, 22)
    close:SetPoint("BOTTOMRIGHT", -16, 16)
    close:SetText(L.OPT_CLOSE)
    close:SetScript("OnClick", function()
      panel:Hide()
    end)

    panel:Hide()
  end
  -- refresh checks
  panel:Show()
end

_G[addonName] = ns
