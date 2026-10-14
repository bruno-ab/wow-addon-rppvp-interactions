local addonName, ns = ...
ns = ns or {}
ns.Options = ns.Options or {}

local Options = ns.Options
local L = ns.L

local DEFAULTS = {
  enabled = true,
  syncWhisper = true,
  syncGroup = true,
  showGroupBanter = true,
  showDeaths = true,
  sound = true,
  useModel = true,
  duration = 4.0,
  pvpOnly = false,
  hostileOnly = true,
  chatAnnounce = false,
  debug = false,
  point = "CENTER",
  relPoint = "CENTER",
  x = 0,
  y = 20,
  locale = "auto",
  minimapAngle = 220,
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
  Options.Get()[key] = value
end

function Options.ResetPosition()
  local s = Options.Get()
  s.point, s.relPoint, s.x, s.y = DEFAULTS.point, DEFAULTS.relPoint, DEFAULTS.x, DEFAULTS.y
  if ns.UI and ns.UI.ApplySavedPosition then
    ns.UI.ApplySavedPosition()
  end
end

local function customBucket(bucket)
  local settings = Options.Get()
  if bucket == "epic" then
    settings.customEpic = settings.customEpic or {}
    return settings.customEpic
  end
  settings.customCommon = settings.customCommon or {}
  return settings.customCommon
end

function Options.AddCustomLine(bucket, text)
  if type(text) ~= "string" then
    return false
  end
  text = text:gsub("|", ""):gsub("[\001-\031]", " ")
  text = text:match("^%s*(.-)%s*$") or ""
  if text == "" then
    return false
  end
  local list = customBucket(bucket)
  if #list >= 8 then
    return false
  end
  list[#list + 1] = text:sub(1, 120)
  if ns.Stats and ns.Stats.GetDB then
    ns.Stats.GetDB()
  end
  return true
end

function Options.ClearCustomLines()
  local settings = Options.Get()
  settings.customCommon = {}
  settings.customEpic = {}
end

local panel
local checks = {}

local function makeCheck(parent, label, key, y)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", 16, y)
  cb._banterKey = key
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  text:SetText(label)
  text:SetWidth(280)
  text:SetJustifyH("LEFT")
  cb:SetScript("OnClick", function(self)
    Options.Set(key, self:GetChecked() and true or false)
  end)
  checks[#checks + 1] = cb
  return cb
end

local function refreshChecks()
  local s = Options.Get()
  for _, cb in ipairs(checks) do
    if cb._banterKey then
      cb:SetChecked(s[cb._banterKey] and true or false)
    end
  end
end

function Options.TogglePanel()
  if panel and panel:IsShown() then
    panel:Hide()
    return
  end
  if not panel then
    panel = CreateFrame("Frame", "BanterCombatOptions", UIParent)
    panel:SetSize(380, 448)
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
    title:SetPoint("TOP", 0, -14)
    title:SetText(L.OPT_TITLE)

    makeCheck(panel, L.OPT_ENABLE, "enabled", -40)
    makeCheck(panel, L.OPT_SYNC, "syncWhisper", -64)
    makeCheck(panel, L.OPT_GROUP, "syncGroup", -88)
    makeCheck(panel, L.OPT_SHOW_GROUP, "showGroupBanter", -112)
    makeCheck(panel, L.OPT_SHOW_DEATHS, "showDeaths", -136)
    makeCheck(panel, L.OPT_SOUND, "sound", -160)
    makeCheck(panel, L.OPT_MODEL, "useModel", -184)
    makeCheck(panel, L.OPT_PVP_ONLY, "pvpOnly", -208)
    makeCheck(panel, L.OPT_HOSTILE, "hostileOnly", -232)
    makeCheck(panel, L.OPT_CHAT, "chatAnnounce", -256)
    makeCheck(panel, L.OPT_DEBUG, "debug", -280)

    local durLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    durLabel:SetPoint("TOPLEFT", 24, -318)
    durLabel:SetText(L.OPT_DURATION)
    local slider = CreateFrame("Slider", "BanterCombatDurSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 170, -320)
    slider:SetMinMaxValues(2, 8)
    slider:SetValueStep(0.5)
    if slider.SetObeyStepOnDrag then
      slider:SetObeyStepOnDrag(true)
    end
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

    local linesBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    linesBtn:SetSize(200, 22)
    linesBtn:SetPoint("BOTTOM", 0, 72)
    linesBtn:SetText(L.OPT_LINES)
    linesBtn:SetScript("OnClick", function()
      Options.ToggleLines()
    end)

    local localeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    localeBtn:SetSize(340, 22)
    localeBtn:SetPoint("BOTTOM", 0, 42)
    localeBtn:SetScript("OnClick", function()
      local order = ns.LOCALE_ORDER or { "auto" }
      local current = Options.Get().locale or "auto"
      local index = 1
      for i, code in ipairs(order) do
        if code == current then
          index = i
          break
        end
      end
      local nextCode = order[(index % #order) + 1]
      Options.Set("locale", nextCode)
      if ns.ApplySavedLocale then
        ns.ApplySavedLocale()
      end
      if localeBtn.SetText then
        localeBtn:SetText(L.OPT_LOCALE:format(ns.LocaleName and ns.LocaleName(nextCode) or nextCode))
      end
      if ns.Compendium and ns.Compendium.Refresh and panel then
        ns.Compendium.Refresh()
      end
    end)
    panel._localeBtn = localeBtn

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(140, 22)
    reset:SetPoint("BOTTOMLEFT", 16, 14)
    reset:SetText(L.OPT_RESET_POS)
    reset:SetScript("OnClick", function()
      Options.ResetPosition()
    end)

    local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    close:SetSize(80, 22)
    close:SetPoint("BOTTOMRIGHT", -16, 14)
    close:SetText(L.OPT_CLOSE)
    close:SetScript("OnClick", function()
      panel:Hide()
    end)

    panel:Hide()
  end
  refreshChecks()
  if panel._localeBtn then
    local code = Options.Get().locale or "auto"
    panel._localeBtn:SetText(L.OPT_LOCALE:format(ns.LocaleName and ns.LocaleName(code) or code))
  end
  local slider = _G.BanterCombatDurSlider
  if slider then
    local d = Options.Get().duration or 4
    slider:SetValue(d)
    if _G[slider:GetName() .. "Text"] then
      _G[slider:GetName() .. "Text"]:SetText(string.format("%.1f", d))
    end
  end
  panel:Show()
end

local linesFrame

local function fillLineList(font, list)
  if type(list) ~= "table" or #list == 0 then
    font:SetText(L.LINES_EMPTY)
    return
  end
  local lines = {}
  for i = 1, #list do
    lines[#lines + 1] = i .. ". " .. list[i]
  end
  font:SetText(table.concat(lines, "\n"))
end

local function refreshLines()
  if not linesFrame then
    return
  end
  local settings = Options.Get()
  linesFrame.Title:SetText(L.LINES_TITLE)
  linesFrame.Hint:SetText(L.LINES_HINT)
  linesFrame.CommonLabel:SetText(L.RARITY_COMMON)
  linesFrame.EpicLabel:SetText(L.RARITY_EPIC)
  fillLineList(linesFrame.CommonList, settings.customCommon)
  fillLineList(linesFrame.EpicList, settings.customEpic)
  linesFrame.AddCommon:SetText(L.LINES_ADD_COMMON)
  linesFrame.AddEpic:SetText(L.LINES_ADD_EPIC)
  linesFrame.Clear:SetText(L.LINES_CLEAR)
  linesFrame.Close:SetText(L.OPT_CLOSE)
end

function Options.ToggleLines()
  if linesFrame and linesFrame:IsShown() then
    linesFrame:Hide()
    return
  end
  if not linesFrame then
    linesFrame = CreateFrame("Frame", "BanterCombatLines", UIParent)
    linesFrame:SetSize(440, 360)
    linesFrame:SetPoint("CENTER", 40, 0)
    linesFrame:SetFrameStrata("DIALOG")
    linesFrame:EnableMouse(true)
    linesFrame:SetMovable(true)
    linesFrame:RegisterForDrag("LeftButton")
    linesFrame:SetScript("OnDragStart", linesFrame.StartMoving)
    linesFrame:SetScript("OnDragStop", linesFrame.StopMovingOrSizing)
    if linesFrame.SetBackdrop then
      linesFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
      })
    end
    linesFrame.Title = linesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    linesFrame.Title:SetPoint("TOP", 0, -14)
    linesFrame.Hint = linesFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    linesFrame.Hint:SetPoint("TOP", 0, -36)
    linesFrame.Hint:SetWidth(400)
    linesFrame.Hint:SetJustifyH("CENTER")

    linesFrame.CommonLabel = linesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    linesFrame.CommonLabel:SetPoint("TOPLEFT", 20, -62)
    linesFrame.CommonList = linesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    linesFrame.CommonList:SetPoint("TOPLEFT", 20, -78)
    linesFrame.CommonList:SetWidth(190)
    linesFrame.CommonList:SetJustifyH("LEFT")
    linesFrame.CommonList:SetJustifyV("TOP")

    linesFrame.EpicLabel = linesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    linesFrame.EpicLabel:SetPoint("TOPLEFT", 230, -62)
    linesFrame.EpicList = linesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    linesFrame.EpicList:SetPoint("TOPLEFT", 230, -78)
    linesFrame.EpicList:SetWidth(190)
    linesFrame.EpicList:SetJustifyH("LEFT")
    linesFrame.EpicList:SetJustifyV("TOP")

    local ok, edit = pcall(CreateFrame, "EditBox", "BanterCombatLineInput", linesFrame, "InputBoxTemplate")
    if not ok or not edit then
      edit = CreateFrame("EditBox", "BanterCombatLineInput", linesFrame)
      edit:SetFontObject("ChatFontNormal")
      edit:SetTextInsets(6, 6, 0, 0)
    end
    edit:SetSize(280, 20)
    edit:SetPoint("BOTTOM", 0, 72)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(120)
    linesFrame.Edit = edit

    local function makeBtn(text, width, x)
      local button = CreateFrame("Button", nil, linesFrame, "UIPanelButtonTemplate")
      button:SetSize(width, 22)
      button:SetPoint("BOTTOMLEFT", x, 40)
      button:SetText(text)
      return button
    end
    linesFrame.AddCommon = makeBtn(L.LINES_ADD_COMMON, 130, 16)
    linesFrame.AddEpic = makeBtn(L.LINES_ADD_EPIC, 130, 152)
    linesFrame.Clear = makeBtn(L.LINES_CLEAR, 80, 288)
    linesFrame.AddCommon:SetScript("OnClick", function()
      if Options.AddCustomLine("common", edit:GetText() or "") then
        edit:SetText("")
      end
      refreshLines()
    end)
    linesFrame.AddEpic:SetScript("OnClick", function()
      if Options.AddCustomLine("epic", edit:GetText() or "") then
        edit:SetText("")
      end
      refreshLines()
    end)
    linesFrame.Clear:SetScript("OnClick", function()
      Options.ClearCustomLines()
      refreshLines()
    end)
    edit:SetScript("OnEnterPressed", function(self)
      Options.AddCustomLine("common", self:GetText() or "")
      self:SetText("")
      self:ClearFocus()
      refreshLines()
    end)
    edit:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
    end)

    linesFrame.Close = CreateFrame("Button", nil, linesFrame, "UIPanelButtonTemplate")
    linesFrame.Close:SetSize(80, 22)
    linesFrame.Close:SetPoint("BOTTOM", 0, 12)
    linesFrame.Close:SetScript("OnClick", function()
      linesFrame:Hide()
    end)
    linesFrame:Hide()
  end
  refreshLines()
  linesFrame:Show()
end

_G[addonName] = ns
