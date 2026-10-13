local addonName, ns = ...
ns = ns or {}
ns.Compendium = ns.Compendium or {}

local Compendium = ns.Compendium
local L = ns.L
local Data = ns.Data

local RACES = { "Human", "Dwarf", "NightElf", "Gnome", "Orc", "Scourge", "Tauren", "Troll" }
local frame
local minimapButton

local function countOf(map, key)
  if type(map) ~= "table" then
    return 0
  end
  return tonumber(map[key]) or 0
end

local function featMark(n)
  if n >= 100 then
    return "|cFFFF8000*|r "
  end
  if n >= 50 then
    return "|cFFA335EE*|r "
  end
  if n >= 10 then
    return "|cFF1EFF00*|r "
  end
  return ""
end

local function makeButton(parent, text, width)
  local ok, button = pcall(CreateFrame, "Button", nil, parent, "UIPanelButtonTemplate")
  if not ok or not button then
    button = CreateFrame("Button", nil, parent)
    local font = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    font:SetPoint("CENTER")
    button.SetText = function(_, value)
      font:SetText(value)
    end
  end
  button:SetSize(width or 80, 22)
  button:SetText(text or "")
  return button
end

local function buildFrame()
  frame = CreateFrame("Frame", "BanterCombatCompendium", UIParent)
  frame:SetSize(540, 292)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetClampedToScreen(true)
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
  end

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.Title:SetPoint("TOP", 0, -14)

  frame.Totals = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Totals:SetPoint("TOP", 0, -38)

  frame.Hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.Hint:SetPoint("BOTTOM", 0, 36)
  frame.Hint:SetWidth(500)
  frame.Hint:SetJustifyH("CENTER")

  local function header(parent, x)
    local race = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    race:SetPoint("TOPLEFT", x, -62)
    local kills = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kills:SetPoint("TOPLEFT", x + 132, -62)
    local deaths = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deaths:SetPoint("TOPLEFT", x + 184, -62)
    return race, kills, deaths
  end

  frame.RaceHeader, frame.RaceKillsHeader, frame.RaceDeathsHeader = header(frame, 22)
  frame.ClassHeader, frame.ClassKillsHeader, frame.ClassDeathsHeader = header(frame, 286)

  frame.rows = {}
  for i = 1, 9 do
    local y = -80 - (i - 1) * 16
    local row = {}
    row.race = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.race:SetPoint("TOPLEFT", 22, y)
    row.race:SetWidth(128)
    row.race:SetJustifyH("LEFT")
    row.raceKills = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raceKills:SetPoint("TOPLEFT", 154, y)
    row.raceKills:SetWidth(28)
    row.raceKills:SetJustifyH("RIGHT")
    row.raceDeaths = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raceDeaths:SetPoint("TOPLEFT", 206, y)
    row.raceDeaths:SetWidth(28)
    row.raceDeaths:SetJustifyH("RIGHT")

    row.class = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.class:SetPoint("TOPLEFT", 286, y)
    row.class:SetWidth(128)
    row.class:SetJustifyH("LEFT")
    row.classKills = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.classKills:SetPoint("TOPLEFT", 418, y)
    row.classKills:SetWidth(28)
    row.classKills:SetJustifyH("RIGHT")
    row.classDeaths = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.classDeaths:SetPoint("TOPLEFT", 470, y)
    row.classDeaths:SetWidth(28)
    row.classDeaths:SetJustifyH("RIGHT")
    frame.rows[i] = row
  end

  local close = makeButton(frame, "", 90)
  close:SetPoint("BOTTOM", 0, 12)
  close:SetScript("OnClick", function()
    frame:Hide()
  end)
  frame.Close = close
  frame:Hide()
end

function Compendium.Refresh()
  if not frame then
    return
  end
  local db = ns.Stats and ns.Stats.GetDB and ns.Stats.GetDB() or {}
  local kills = db.kills or {}
  local deaths = db.deaths or {}
  frame.Title:SetText(L.COMP_TITLE)
  frame.Totals:SetText(L.COMP_TOTAL_KILLS:format(db.totalKills or 0) .. "    " .. L.COMP_TOTAL_DEATHS:format(db.totalDeaths or 0))
  frame.Hint:SetText(L.COMP_HINT)
  frame.RaceHeader:SetText(L.COMP_RACE)
  frame.ClassHeader:SetText(L.COMP_CLASS)
  frame.RaceKillsHeader:SetText(L.COMP_KILLS)
  frame.RaceDeathsHeader:SetText(L.COMP_DEATHS)
  frame.ClassKillsHeader:SetText(L.COMP_KILLS)
  frame.ClassDeathsHeader:SetText(L.COMP_DEATHS)
  frame.Close:SetText(L.COMP_CLOSE)

  local classes = Data.CLASSES
  for i = 1, 9 do
    local row = frame.rows[i]
    local race = RACES[i]
    if race then
      local rk = countOf(kills.Race, race)
      row.race:SetText(featMark(rk) .. Data.RaceLabel(race))
      row.raceKills:SetText(tostring(rk))
      row.raceDeaths:SetText(tostring(countOf(deaths.Race, race)))
    else
      row.race:SetText("")
      row.raceKills:SetText("")
      row.raceDeaths:SetText("")
    end
    local class = classes[i]
    if class then
      local ck = countOf(kills.Class, class)
      row.class:SetText(featMark(ck) .. Data.ClassLabel(class))
      row.classKills:SetText(tostring(ck))
      row.classDeaths:SetText(tostring(countOf(deaths.Class, class)))
    else
      row.class:SetText("")
      row.classKills:SetText("")
      row.classDeaths:SetText("")
    end
  end
end

function Compendium.Toggle()
  if not frame then
    buildFrame()
  end
  if frame:IsShown() then
    frame:Hide()
    return
  end
  Compendium.Refresh()
  frame:Show()
end

local function atan2(y, x)
  if math.atan2 then
    return math.atan2(y, x)
  end
  return math.atan(y, x)
end

local function placeMinimap(button)
  if not Minimap or not button then
    return
  end
  local settings = ns.Options and ns.Options.Get and ns.Options.Get() or {}
  local angle = tonumber(settings.minimapAngle) or 220
  local rad = math.rad(angle)
  local radius = (Minimap:GetWidth() / 2) + 5
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
end

function Compendium.Init()
  if minimapButton or not Minimap then
    return
  end
  local button = CreateFrame("Button", "BanterCombatMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 1)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  button:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      if ns.Options and ns.Options.TogglePanel then
        ns.Options.TogglePanel()
      end
      return
    end
    Compendium.Toggle()
  end)
  button:SetScript("OnDragStart", function(self)
    if InCombatLockdown and InCombatLockdown() then
      return
    end
    self:SetScript("OnUpdate", function(btn)
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cx, cy = cx / scale, cy / scale
      local angle = math.deg(atan2(cy - my, cx - mx))
      if ns.Options and ns.Options.Set then
        ns.Options.Set("minimapAngle", angle)
      end
      placeMinimap(btn)
    end)
  end)
  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)
  button:SetScript("OnEnter", function(self)
    if not GameTooltip then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.MINIMAP_TITLE, 1, 0.82, 0)
    GameTooltip:AddLine(L.MINIMAP_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_DRAG, 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)

  placeMinimap(button)
  minimapButton = button
end

_G[addonName] = ns
