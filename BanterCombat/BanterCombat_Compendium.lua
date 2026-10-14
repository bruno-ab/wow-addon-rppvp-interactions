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
  frame:SetSize(540, 320)
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
  frame.Totals:SetPoint("TOPRIGHT", -16, -42)

  frame.Hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.Hint:SetPoint("BOTTOM", 0, 36)
  frame.Hint:SetWidth(500)
  frame.Hint:SetJustifyH("CENTER")

  local function header(parent, x)
    local race = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    race:SetPoint("TOPLEFT", x, -80)
    local kills = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kills:SetPoint("TOPLEFT", x + 132, -80)
    local deaths = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deaths:SetPoint("TOPLEFT", x + 184, -80)
    return race, kills, deaths
  end

  frame.RaceHeader, frame.RaceKillsHeader, frame.RaceDeathsHeader = header(frame, 22)
  frame.ClassHeader, frame.ClassKillsHeader, frame.ClassDeathsHeader = header(frame, 286)

  frame.rows = {}
  for i = 1, 9 do
    local y = -98 - (i - 1) * 16
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

  local function tab(text, x, page)
    local button = makeButton(frame, text, 78)
    button:SetPoint("TOPLEFT", x, -36)
    button:SetScript("OnClick", function()
      frame.page = page
      frame.listPage = 1
      Compendium.Refresh()
    end)
    return button
  end
  frame.TabCounts = tab("", 12, "counts")
  frame.TabRivals = tab("", 94, "rivals")
  frame.TabFeats = tab("", 176, "feats")
  frame.TabStory = tab("", 258, "story")
  frame.page = "counts"
  frame.listPage = 1

  frame.Back = makeButton(frame, "", 80)
  frame.Back:SetPoint("BOTTOMLEFT", 16, 12)
  frame.Back:SetScript("OnClick", function()
    frame.listPage = math.max(1, (frame.listPage or 1) - 1)
    Compendium.Refresh()
  end)
  frame.More = makeButton(frame, "", 80)
  frame.More:SetPoint("BOTTOMRIGHT", -16, 12)
  frame.More:SetScript("OnClick", function()
    frame.listPage = (frame.listPage or 1) + 1
    Compendium.Refresh()
  end)

  frame.Story = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Story:SetPoint("TOPLEFT", 24, -78)
  frame.Story:SetWidth(492)
  frame.Story:SetHeight(190)
  frame.Story:SetJustifyH("LEFT")
  frame.Story:SetJustifyV("TOP")
  if frame.Story.SetWordWrap then
    frame.Story:SetWordWrap(true)
  end
  frame.Story:Hide()
  frame:Hide()
end

function Compendium.Refresh()
  if not frame then
    return
  end
  local db = ns.Stats and ns.Stats.GetDB and ns.Stats.GetDB() or {}
  local page = frame.page or "counts"
  frame.Title:SetText(L.COMP_TITLE)
  frame.Totals:SetText(L.COMP_TOTAL_KILLS:format(db.totalKills or 0) .. "    " .. L.COMP_TOTAL_DEATHS:format(db.totalDeaths or 0))
  frame.Close:SetText(L.COMP_CLOSE)
  frame.TabCounts:SetText(L.COMP_COUNTS)
  frame.TabRivals:SetText(L.COMP_RIVALS)
  frame.TabFeats:SetText(L.COMP_FEATS)
  if frame.TabStory then
    frame.TabStory:SetText(L.COMP_STORY)
  end
  frame.Back:SetText(L.COMP_BACK)
  frame.More:SetText(L.COMP_MORE)
  if frame.Story then
    frame.Story:Hide()
  end

  local function widen(wide)
    for i = 1, 9 do
      local row = frame.rows[i]
      row.race:SetWidth(wide and 230 or 128)
      row.class:SetWidth(wide and 230 or 128)
      if wide then
        row.raceKills:Hide()
        row.raceDeaths:Hide()
        row.classKills:Hide()
        row.classDeaths:Hide()
      else
        row.raceKills:Show()
        row.raceDeaths:Show()
        row.classKills:Show()
        row.classDeaths:Show()
      end
    end
    if wide then
      frame.RaceKillsHeader:Hide()
      frame.RaceDeathsHeader:Hide()
      frame.ClassKillsHeader:Hide()
      frame.ClassDeathsHeader:Hide()
    else
      frame.RaceKillsHeader:Show()
      frame.RaceDeathsHeader:Show()
      frame.ClassKillsHeader:Show()
      frame.ClassDeathsHeader:Show()
    end
  end

  local function clearRows()
    for i = 1, 9 do
      local row = frame.rows[i]
      row.race:SetText("")
      row.class:SetText("")
      row.raceKills:SetText("")
      row.raceDeaths:SetText("")
      row.classKills:SetText("")
      row.classDeaths:SetText("")
    end
  end

  local function formatWhen(ts)
    ts = tonumber(ts) or 0
    if ts <= 0 or not date then
      return L.COMP_LOCKED
    end
    return date("%d/%m/%Y", ts)
  end

  if page == "story" then
    widen(true)
    clearRows()
    frame.RaceHeader:SetText("")
    frame.ClassHeader:SetText("")
    frame.Story:Show()
    local chapters = ns.Chronicle and ns.Chronicle.Chapters and ns.Chronicle.Chapters() or {}
    local index = frame.listPage or 1
    if #chapters == 0 then
      frame.Story:SetText(L.NARR_EMPTY)
      frame.Hint:SetText(L.NARR_HINT)
      frame.Back:Hide()
      frame.More:Hide()
      return
    end
    if index > #chapters then
      index = #chapters
    end
    if index < 1 then
      index = 1
    end
    frame.listPage = index
    local chapter = chapters[index]
    frame.Story:SetText(chapter.title .. "\n\n" .. chapter.text)
    frame.Hint:SetText(L.NARR_PAGE:format(index, #chapters))
    if index > 1 then
      frame.Back:Show()
    else
      frame.Back:Hide()
    end
    if index < #chapters then
      frame.More:Show()
    else
      frame.More:Hide()
    end
    return
  end

  if page == "counts" then
    widen(false)
    frame.Hint:SetText(L.COMP_HINT)
    frame.RaceHeader:SetText(L.COMP_RACE)
    frame.ClassHeader:SetText(L.COMP_CLASS)
    frame.RaceKillsHeader:SetText(L.COMP_KILLS)
    frame.RaceDeathsHeader:SetText(L.COMP_DEATHS)
    frame.ClassKillsHeader:SetText(L.COMP_KILLS)
    frame.ClassDeathsHeader:SetText(L.COMP_DEATHS)
    frame.Back:Hide()
    frame.More:Hide()
    local kills = db.kills or {}
    local deaths = db.deaths or {}
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
    return
  end

  widen(true)
  clearRows()
  local items = {}
  if page == "rivals" then
    frame.Hint:SetText(L.COMP_SCORE .. "  ·  " .. L.COMP_LAST)
    frame.RaceHeader:SetText(L.COMP_RIVALS)
    frame.ClassHeader:SetText("")
    local list = ns.Stats and ns.Stats.RivalList and ns.Stats.RivalList() or {}
    for i = 1, #list do
      local row = list[i]
      local score = L.RIVAL_SCORE:format(row.kills or 0, row.deaths or 0)
      items[#items + 1] = (row.name or "?") .. "   " .. score .. "   " .. formatWhen(row.last)
    end
  else
    frame.Hint:SetText(L.COMP_FEATS)
    frame.RaceHeader:SetText(L.COMP_FEATS)
    frame.ClassHeader:SetText("")
    local specials = {
      { "revenge", L.FEAT_REVENGE },
      { "legendary", L.FEAT_LEGENDARY },
      { "milestone100", L.FEAT_MILESTONE100 },
      { "streak3", L.FEAT_STREAK3 },
      { "streak5", L.FEAT_STREAK5 },
      { "streak10", L.FEAT_STREAK10 },
    }
    for i = 1, #specials do
      items[#items + 1] = { specials[i][1], specials[i][2] }
    end
    for i = 1, #RACES do
      items[#items + 1] = { "race:" .. RACES[i], L.FEAT_RACE:format(Data.RaceLabel(RACES[i])) }
    end
    local classes = Data.CLASSES
    for i = 1, #classes do
      items[#items + 1] = { "class:" .. classes[i], L.FEAT_CLASS:format(Data.ClassLabel(classes[i])) }
    end
    for i = 1, #items do
      local id, label = items[i][1], items[i][2]
      local when = ns.Stats and ns.Stats.FeatTime and ns.Stats.FeatTime(id)
      if when then
        items[i] = label .. "   |cFF9D9D9D" .. formatWhen(when) .. "|r"
      else
        items[i] = "|cFF666666" .. label .. "|r   " .. L.COMP_LOCKED
      end
    end
  end

  local pageIndex = frame.listPage or 1
  local start = (pageIndex - 1) * 18
  for i = 1, 9 do
    local row = frame.rows[i]
    row.race:SetText(items[start + i] or "")
    row.class:SetText(items[start + 9 + i] or "")
  end
  if pageIndex > 1 then
    frame.Back:Show()
  else
    frame.Back:Hide()
  end
  if start + 18 < #items then
    frame.More:Show()
  else
    frame.More:Hide()
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
