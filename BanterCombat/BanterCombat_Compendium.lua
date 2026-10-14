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

local function paintSheet(parent)
  local plate = parent:CreateTexture(nil, "BACKGROUND")
  plate:SetAllPoints()
  plate:SetTexture("Interface\\AddOns\\BanterCombat\\Art\\Plate.tga")

  local dark = type(DialogueUI_DB) == "table" and DialogueUI_DB.Theme == 2
  local folder = dark and "Theme_Dark" or "Theme_Brown"
  local file = "Interface\\AddOns\\DialogueUI\\Art\\" .. folder .. "\\Parchment.png"
  local frameWidth = parent:GetWidth()
  if not frameWidth or frameWidth < 64 then
    frameWidth = 780
  end
  -- The sheet art has empty margins. Crop to the paper and place it on the
  -- feat column so the roll does not sit on the category menu.
  local sheetLeft, sheetRight = 176, 12
  local texLeft, texRight = 156, 867
  local sheetWidth = frameWidth - sheetLeft - sheetRight
  local cap = math.floor(sheetWidth * (256 / (texRight - texLeft)))
  local u0, u1 = texLeft / 1024, texRight / 1024
  local top = parent:CreateTexture(nil, "BORDER")
  local mid = parent:CreateTexture(nil, "BORDER")
  local bot = parent:CreateTexture(nil, "BORDER")
  top:SetTexture(file)
  mid:SetTexture(file)
  bot:SetTexture(file)
  top:SetTexCoord(u0, u1, 0, 256 / 2048)
  mid:SetTexCoord(u0, u1, 256 / 2048, 896 / 2048)
  bot:SetTexCoord(u0, u1, 896 / 2048, 1152 / 2048)
  top:SetSize(sheetWidth, cap)
  bot:SetSize(sheetWidth, cap)
  top:SetPoint("TOPLEFT", parent, "TOPLEFT", sheetLeft, 8)
  bot:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", sheetLeft, -6)
  mid:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0)
  mid:SetPoint("BOTTOMRIGHT", bot, "TOPRIGHT", 0, 0)
end

local function buildFrame()
  local made
  local ok, created = pcall(CreateFrame, "Frame", "BanterCombatCompendium", UIParent, "BackdropTemplate")
  if ok and created then
    made = created
  else
    made = CreateFrame("Frame", "BanterCombatCompendium", UIParent)
  end
  frame = made
  frame:SetSize(780, 512)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetClampedToScreen(true)
  paintSheet(frame)
  if frame.SetBackdrop then
    pcall(frame.SetBackdrop, frame, {
      bgFile = "Interface\\AddOns\\BanterCombat\\Art\\Plate.tga",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = false, edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    if frame.SetBackdropColor then
      frame:SetBackdropColor(1, 1, 1, 1)
    end
  end

  local side = frame:CreateTexture(nil, "BORDER")
  side:SetPoint("TOPLEFT", 14, -36)
  side:SetPoint("BOTTOMLEFT", 14, 12)
  side:SetWidth(162)
  side:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  side:SetVertexColor(0.22, 0.14, 0.07, 0.92)

  local banner = frame:CreateTexture(nil, "ARTWORK")
  banner:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  banner:SetSize(320, 64)
  banner:SetPoint("TOP", 0, 12)

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.Title:SetPoint("TOP", banner, "TOP", 0, -14)

  frame.Totals = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Totals:SetPoint("TOPRIGHT", -40, -36)

  frame.Hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.Hint:SetPoint("BOTTOM", 80, 40)
  frame.Hint:SetWidth(520)
  frame.Hint:SetHeight(28)
  frame.Hint:SetJustifyH("CENTER")
  frame.Hint:SetJustifyV("TOP")
  if frame.Hint.SetWordWrap then
    frame.Hint:SetWordWrap(true)
  end

  local function header(parent, x)
    local race = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    race:SetPoint("TOPLEFT", x, -80)
    local kills = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kills:SetPoint("TOPLEFT", x + 132, -80)
    local deaths = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deaths:SetPoint("TOPLEFT", x + 184, -80)
    return race, kills, deaths
  end

  frame.RaceHeader, frame.RaceKillsHeader, frame.RaceDeathsHeader = header(frame, 210)
  frame.ClassHeader, frame.ClassKillsHeader, frame.ClassDeathsHeader = header(frame, 470)

  frame.rows = {}
  for i = 1, 9 do
    local y = -98 - (i - 1) * 16
    local row = {}
    row.race = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.race:SetPoint("TOPLEFT", 210, y)
    row.race:SetWidth(128)
    row.race:SetJustifyH("LEFT")
    row.raceKills = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raceKills:SetPoint("TOPLEFT", 342, y)
    row.raceKills:SetWidth(28)
    row.raceKills:SetJustifyH("RIGHT")
    row.raceDeaths = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raceDeaths:SetPoint("TOPLEFT", 394, y)
    row.raceDeaths:SetWidth(28)
    row.raceDeaths:SetJustifyH("RIGHT")

    row.class = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.class:SetPoint("TOPLEFT", 470, y)
    row.class:SetWidth(140)
    row.class:SetJustifyH("LEFT")
    row.classKills = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.classKills:SetPoint("TOPLEFT", 602, y)
    row.classKills:SetWidth(28)
    row.classKills:SetJustifyH("RIGHT")
    row.classDeaths = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.classDeaths:SetPoint("TOPLEFT", 654, y)
    row.classDeaths:SetWidth(28)
    row.classDeaths:SetJustifyH("RIGHT")
    frame.rows[i] = row
  end

  local close = makeButton(frame, "", 90)
  close:SetPoint("BOTTOM", 80, 12)
  close:SetScript("OnClick", function()
    frame:Hide()
  end)
  frame.Close = close

  frame.nav = {}
  local categories = ns.Achievements and ns.Achievements.Categories and ns.Achievements.Categories() or {}
  for i = 1, #categories do
    local page = categories[i].id
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(148, 20)
    button:SetPoint("TOPLEFT", 22, -54 - (i - 1) * 22)
    local hi = button:CreateTexture(nil, "BACKGROUND")
    hi:SetAllPoints()
    hi:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    hi:SetVertexColor(0.72, 0.55, 0.18, 0.55)
    hi:Hide()
    button.hi = hi
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 8, 0)
    label:SetJustifyH("LEFT")
    label:SetWidth(132)
    label:SetText(categories[i].label)
    button.label = label
    button.page = page
    button:SetScript("OnClick", function()
      frame.page = page
      frame.listPage = 1
      Compendium.Refresh()
    end)
    button:SetScript("OnEnter", function()
      if frame.page ~= page then
        label:SetTextColor(1, 0.95, 0.7)
      end
    end)
    button:SetScript("OnLeave", function()
      Compendium.Refresh()
    end)
    frame.nav[i] = button
  end
  frame.page = "summary"
  frame.listPage = 1

  local function arrowButton(direction)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(32, 32)
    local prefix = direction == "prev"
      and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-"
      or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
    button:SetNormalTexture(prefix .. "Up")
    button:SetPushedTexture(prefix .. "Down")
    button:SetDisabledTexture(prefix .. "Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetScript("OnEnter", function(self)
      if not GameTooltip then
        return
      end
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(direction == "prev" and L.COMP_BACK or L.COMP_MORE, 1, 0.82, 0)
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
      if GameTooltip then
        GameTooltip:Hide()
      end
    end)
    return button
  end
  frame.Back = arrowButton("prev")
  frame.Back:SetPoint("BOTTOMLEFT", 188, 8)
  frame.Back:SetScript("OnClick", function()
    frame.listPage = math.max(1, (frame.listPage or 1) - 1)
    Compendium.Refresh()
  end)
  frame.More = arrowButton("next")
  frame.More:SetPoint("BOTTOMRIGHT", -24, 8)
  frame.More:SetScript("OnClick", function()
    frame.listPage = (frame.listPage or 1) + 1
    Compendium.Refresh()
  end)

  frame.achRows = {}
  for i = 1, 6 do
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(520, 56)
    row:SetPoint("TOPLEFT", 206, -58 - (i - 1) * 60)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bg:SetVertexColor(0.16, 0.11, 0.05, 0.55)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(40, 40)
    row.icon:SetPoint("LEFT", 8, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 56, -6)
    row.title:SetWidth(300)
    row.title:SetJustifyH("LEFT")
    row.desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.desc:SetPoint("TOPLEFT", 56, -24)
    row.desc:SetWidth(300)
    row.desc:SetHeight(30)
    row.desc:SetJustifyH("LEFT")
    row.desc:SetJustifyV("TOP")
    if row.desc.SetWordWrap then
      row.desc:SetWordWrap(true)
    end
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetSize(140, 14)
    row.bar:SetPoint("BOTTOMRIGHT", -10, 8)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(0)
    local barBg = row.bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    barBg:SetVertexColor(0, 0, 0, 0.65)
    row.barText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.barText:SetPoint("CENTER", row.bar, "CENTER", 0, 0)
    row:Hide()
    frame.achRows[i] = row
  end

  frame.Story = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Story:SetPoint("TOPLEFT", 210, -78)
  frame.Story:SetWidth(500)
  frame.Story:SetHeight(340)
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
  frame.Close:SetText(L.COMP_CLOSE)
  local function setPager(canBack, canMore)
    if not canBack and not canMore then
      frame.Back:Hide()
      frame.More:Hide()
      return
    end
    frame.Back:Show()
    frame.More:Show()
    if frame.Back.SetEnabled then
      frame.Back:SetEnabled(canBack and true or false)
    end
    if frame.More.SetEnabled then
      frame.More:SetEnabled(canMore and true or false)
    end
  end
  if frame.Story then
    frame.Story:Hide()
  end
  if frame.nav and ns.Achievements and ns.Achievements.Categories then
    local categories = ns.Achievements.Categories()
    for i = 1, #frame.nav do
      local button = frame.nav[i]
      local label = categories[i] and categories[i].label or ""
      button.label:SetText(label)
      if button.page == page then
        button.label:SetTextColor(1, 0.82, 0)
        button.hi:Show()
      else
        button.label:SetTextColor(0.85, 0.75, 0.55)
        button.hi:Hide()
      end
    end
  end

  local function ledger(show)
    local headers = {
      frame.RaceHeader, frame.RaceKillsHeader, frame.RaceDeathsHeader,
      frame.ClassHeader, frame.ClassKillsHeader, frame.ClassDeathsHeader,
    }
    for i = 1, #headers do
      if show then
        headers[i]:Show()
      else
        headers[i]:Hide()
      end
    end
    for i = 1, 9 do
      local row = frame.rows[i]
      local cells = { row.race, row.raceKills, row.raceDeaths, row.class, row.classKills, row.classDeaths }
      for c = 1, #cells do
        if show then
          cells[c]:Show()
        else
          cells[c]:Hide()
        end
      end
    end
  end

  local function hideAch()
    if not frame.achRows then
      return
    end
    for i = 1, #frame.achRows do
      frame.achRows[i]:Hide()
    end
  end

  local ledgerPage = page == "counts" or page == "rivals" or page == "feats" or page == "story"
  if not ledgerPage and ns.Achievements and ns.Achievements.List then
    ledger(false)
    hideAch()
    local list = ns.Achievements.List(page)
    local done, total = ns.Achievements.Counts()
    frame.Totals:SetText(L.ACH_TOTAL:format(done, total))
    local index = frame.listPage or 1
    local pages = math.max(1, math.ceil(#list / 6))
    if index > pages then
      index = pages
    end
    if index < 1 then
      index = 1
    end
    frame.listPage = index
    local start = (index - 1) * 6
    for i = 1, 6 do
      local item = list[start + i]
      local row = frame.achRows[i]
      if not item then
        row:Hide()
      else
        row:Show()
        local title = item.title or ""
        if item.done and item.when and item.when > 0 and date then
          title = title .. "   |cFF9D9D9D" .. date("%d/%m/%Y", item.when) .. "|r"
        end
        row.title:SetText(title)
        if item.blocked then
          row.title:SetTextColor(0.55, 0.55, 0.55)
        elseif item.done then
          row.title:SetTextColor(1, 0.82, 0)
        else
          row.title:SetTextColor(1, 1, 1)
        end
        local desc = item.desc or ""
        if item.detail and item.detail ~= "" then
          desc = desc .. "\n" .. item.detail
        end
        if item.blocked then
          desc = "|cFF888888" .. item.blocked .. "|r\n" .. desc
        end
        row.desc:SetText(desc)
        row.icon:SetTexture(item.icon)
        if row.icon.SetDesaturated then
          row.icon:SetDesaturated(item.blocked and true or false)
        end
        local goal = item.goal or 1
        if goal < 1 then
          goal = 1
        end
        local progress = item.progress or 0
        if progress > goal then
          progress = goal
        end
        row.bar:SetMinMaxValues(0, goal)
        row.bar:SetValue(progress)
        row.barText:SetText(progress .. "/" .. goal)
        if item.done then
          row.bar:SetStatusBarColor(0.95, 0.75, 0.15)
        elseif item.blocked then
          row.bar:SetStatusBarColor(0.35, 0.35, 0.35)
        else
          row.bar:SetStatusBarColor(0.2, 0.55, 0.15)
        end
      end
    end
    local last = math.min(#list, start + 6)
    if #list == 0 then
      frame.Hint:SetText(L.ACH_HINT)
    else
      frame.Hint:SetText(L.ACH_PAGE:format(start + 1, last, #list))
    end
    setPager(index > 1, index < pages)
    return
  end

  hideAch()
  ledger(true)
  frame.Totals:SetText(L.COMP_TOTAL_KILLS:format(db.totalKills or 0) .. "    " .. L.COMP_TOTAL_DEATHS:format(db.totalDeaths or 0))

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
      setPager(false, false)
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
    setPager(index > 1, index < #chapters)
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
    setPager(false, false)
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
  setPager(pageIndex > 1, start + 18 < #items)
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

  button:SetScript("OnClick", function(self, mouse)
    if mouse == "RightButton" then
      if ns.Options and ns.Options.ToggleMinimapMenu then
        ns.Options.ToggleMinimapMenu(self)
      end
      return
    end
    if ns.Options and ns.Options.HideMinimapMenu then
      ns.Options.HideMinimapMenu()
    end
    Compendium.Toggle()
  end)
  button:SetScript("OnDragStart", function(self)
    if ns.Options and ns.Options.HideMinimapMenu then
      ns.Options.HideMinimapMenu()
    end
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
