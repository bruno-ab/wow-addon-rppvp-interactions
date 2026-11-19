local addonName, ns = ...
ns = ns or {}
ns.Compendium = ns.Compendium or {}

local Compendium = ns.Compendium
local L = ns.L
local Data = ns.Data

local RACES = { "Human", "Dwarf", "NightElf", "Gnome", "Orc", "Scourge", "Tauren", "Troll" }
local CHALLENGE_ROWS = 8
local frame
local minimapButton

local function shortName(name)
  if ns.Stats and ns.Stats.DisplayName then
    return ns.Stats.DisplayName(name) or name or "?"
  end
  if type(name) ~= "string" or name == "" then
    return "?"
  end
  local bare = name:match("^([^%-]+)")
  return (bare and bare ~= "" and bare) or name
end

local NAV = {
  { id = "overview", labelKey = "COMP_OVERVIEW" },
  { id = "challenges", labelKey = "COMP_CHALLENGES" },
  { id = "counts", labelKey = "COMP_COUNTS" },
  { id = "rivals", labelKey = "COMP_RIVALS" },
  { id = "story", labelKey = "COMP_STORY" },
  { id = "diary", labelKey = "COMP_DIARY" },
}

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

local function formatWhen(ts)
  ts = tonumber(ts) or 0
  if ts <= 0 or not date then
    return L.COMP_LOCKED or "—"
  end
  return date("%d.%m.%Y", ts)
end

local function solidTex(parent, layer, r, g, b, a)
  local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
  tex:SetTexture("Interface\\Buttons\\WHITE8X8")
  tex:SetVertexColor(r or 0.05, g or 0.05, b or 0.06, a or 0.98)
  return tex
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

local function applyWowDialogBackdrop(parent)
  if ns.Options and ns.Options.ApplyWowDialogBackdrop then
    ns.Options.ApplyWowDialogBackdrop(parent)
    return
  end
  if not parent then
    return
  end
  if not parent._banterSolidBg then
    local bg = solidTex(parent, "BACKGROUND", 0.05, 0.05, 0.06, 0.98)
    bg:SetAllPoints(parent)
    parent._banterSolidBg = bg
  end
  parent._banterSolidBg:Show()
end

local function ink(fs, r, g, b)
  if fs and fs.SetTextColor then
    fs:SetTextColor(r or 0.92, g or 0.86, b or 0.70)
  end
end

local function hideFilterBar()
  if frame and frame.filterBar then
    frame.filterBar:Hide()
  end
end

local function hideAllContent()
  if not frame then
    return
  end
  hideFilterBar()
  if frame.heroBox then
    frame.heroBox:Hide()
  end
  if frame.sideBox then
    frame.sideBox:Hide()
  end
  if frame.StoryScroll then
    frame.StoryScroll:Hide()
  elseif frame.Story then
    frame.Story:Hide()
  end
  if frame.challengeRows then
    for i = 1, #frame.challengeRows do
      frame.challengeRows[i]:Hide()
    end
  end
  if frame.subTabs then
    for i = 1, #frame.subTabs do
      frame.subTabs[i]:Hide()
    end
  end
  if frame.listRows then
    for i = 1, #frame.listRows do
      frame.listRows[i]:Hide()
    end
  end
  if frame.countRows then
    for i = 1, #frame.countRows do
      local row = frame.countRows[i]
      row.race:Hide()
      row.raceStats:Hide()
      row.class:Hide()
      row.classStats:Hide()
    end
  end
  if frame.countHeaderL then
    frame.countHeaderL:Hide()
  end
  if frame.countHeaderR then
    frame.countHeaderR:Hide()
  end
end

local CTX_CYCLE = { "all", "world", "bg", "duel" }

local function ctxLabel(ctx)
  if ctx == "world" then
    return L.COMP_LOG_CTX_world or "mundo"
  end
  if ctx == "bg" then
    return L.COMP_LOG_CTX_bg or "CB"
  end
  if ctx == "duel" then
    return L.COMP_LOG_CTX_duel or "duelo"
  end
  return L.COMP_FILTER_ALL or "todos"
end

local function queryLower()
  local q = frame and frame.filterQuery or ""
  if type(q) ~= "string" then
    return ""
  end
  return q:lower():match("^%s*(.-)%s*$") or ""
end

local function nameMatches(name, q)
  if q == "" then
    return true
  end
  local short = shortName(name):lower()
  return short:find(q, 1, true) and true or false
end

local function rivalMatchesContext(row, ctx)
  if not ctx or ctx == "all" then
    return true
  end
  local meetings = row.meetings
  if type(meetings) == "table" then
    for i = 1, #meetings do
      if meetings[i].context == ctx then
        return true
      end
    end
  end
  if ctx == "world" then
    return ((row.worldKills or 0) + (row.worldDeaths or 0)) > 0
  end
  if ctx == "bg" then
    return ((row.bgKills or 0) + (row.bgDeaths or 0)) > 0
  end
  if ctx == "duel" then
    return ((row.duelKills or 0) + (row.duelDeaths or 0)) > 0
  end
  return false
end

local function diaryDays(log)
  local seen, days = {}, {}
  for i = 1, #log do
    local day = formatWhen(log[i].t)
    if day and day ~= (L.COMP_LOCKED or "—") and not seen[day] then
      seen[day] = true
      days[#days + 1] = day
    end
  end
  return days
end

local function sideColor(side)
  if side == "kill" then
    return "|cff6ecf6e"
  end
  if side == "death" then
    return "|cffcf6e6e"
  end
  if side == "duel_win" then
    return "|cff6eb0cf"
  end
  if side == "duel_loss" then
    return "|cffcf9a6e"
  end
  return "|cffcfcfcf"
end

local function formatPvpLogEntry(e, withDate)
  if type(e) ~= "table" then
    return ""
  end
  local side = e.side or "?"
  local label = side
  if side == "kill" then
    label = L.COMP_LOG_KILL or "Abate"
  elseif side == "death" then
    label = L.COMP_LOG_DEATH or "Morte"
  elseif side == "duel_win" then
    label = L.COMP_LOG_DUEL_WIN or "Duelo +"
  elseif side == "duel_loss" then
    label = L.COMP_LOG_DUEL_LOSS or "Duelo −"
  end
  local colored = sideColor(side) .. label .. "|r"
  local bits = { colored, "|cffffffff" .. shortName(e.name) .. "|r" }
  if e.level then
    bits[#bits + 1] = (L.COMP_LEVEL_SHORT or "nv%d"):format(e.level)
  end
  if e.race and Data.RaceLabel then
    bits[#bits + 1] = Data.RaceLabel(e.race)
  elseif e.race then
    bits[#bits + 1] = e.race
  end
  if e.class and Data.ClassLabel then
    bits[#bits + 1] = Data.ClassLabel(e.class)
  elseif e.class then
    bits[#bits + 1] = e.class
  end
  if e.zone then
    bits[#bits + 1] = e.zone
  end
  if e.context then
    local ctxKey = "COMP_LOG_CTX_" .. tostring(e.context)
    bits[#bits + 1] = L[ctxKey] or e.context
  end
  if withDate then
    bits[#bits + 1] = "|cffaaaaaa" .. formatWhen(e.t) .. "|r"
  end
  return table.concat(bits, " · ")
end

local function buildFrame()
  local made
  if ns.Options and ns.Options.CreateDialogFrame then
    made = ns.Options.CreateDialogFrame("BanterCombatCompendium", UIParent)
  else
    local ok, created = pcall(CreateFrame, "Frame", "BanterCombatCompendium", UIParent, "BackdropTemplate")
    made = (ok and created) or CreateFrame("Frame", "BanterCombatCompendium", UIParent)
  end
  frame = made
  frame:SetSize(780, 520)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetClampedToScreen(true)
  applyWowDialogBackdrop(frame)

  local side = solidTex(frame, "BORDER", 0.08, 0.08, 0.10, 0.95)
  side:SetPoint("TOPLEFT", 14, -48)
  side:SetPoint("BOTTOMLEFT", 14, 14)
  side:SetWidth(150)

  local banner = frame:CreateTexture(nil, "ARTWORK")
  banner:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  banner:SetSize(360, 64)
  banner:SetPoint("TOP", 0, 12)

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.Title:SetPoint("TOP", banner, "TOP", 0, -14)
  ink(frame.Title, 1, 0.82, 0)

  frame.ProgressLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.ProgressLabel:SetPoint("TOPRIGHT", -40, -42)
  ink(frame.ProgressLabel, 0.85, 0.78, 0.55)

  frame.ProgressBar = CreateFrame("StatusBar", nil, frame)
  frame.ProgressBar:SetSize(180, 6)
  frame.ProgressBar:SetPoint("TOPRIGHT", -40, -58)
  frame.ProgressBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  frame.ProgressBar:SetStatusBarColor(0.78, 0.58, 0.18, 1)
  local pbg = frame.ProgressBar:CreateTexture(nil, "BACKGROUND")
  pbg:SetAllPoints()
  pbg:SetTexture("Interface\\Buttons\\WHITE8X8")
  pbg:SetVertexColor(0.15, 0.12, 0.08, 0.9)

  frame.Hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.Hint:SetPoint("BOTTOM", 80, 12)
  frame.Hint:SetWidth(520)
  frame.Hint:SetHeight(28)
  frame.Hint:SetJustifyH("CENTER")
  frame.Hint:SetJustifyV("TOP")
  if frame.Hint.SetWordWrap then
    frame.Hint:SetWordWrap(true)
  end

  local close = makeButton(frame, L.COMP_CLOSE or "Fechar", 80)
  close:SetPoint("TOPRIGHT", -18, -14)
  close:SetScript("OnClick", function()
    frame:Hide()
  end)
  frame.Close = close

  -- Left nav
  frame.nav = {}
  for i = 1, #NAV do
    local info = NAV[i]
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(138, 22)
    button:SetPoint("TOPLEFT", 20, -56 - (i - 1) * 26)
    local hi = solidTex(button, "BACKGROUND", 0.72, 0.55, 0.18, 0.45)
    hi:SetAllPoints()
    hi:Hide()
    button.hi = hi
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 8, 0)
    label:SetWidth(122)
    label:SetJustifyH("LEFT")
    button.label = label
    button.page = info.id
    button.labelKey = info.labelKey
    button:SetScript("OnClick", function()
      frame.page = info.id
      frame.listPage = 1
      frame.rivalFocus = nil
      if info.id ~= "challenges" then
        frame.challengeCat = nil
      end
      if info.id ~= "rivals" and info.id ~= "diary" then
        frame.filterQuery = ""
        frame.filterContext = "all"
        frame.filterDayKey = "all"
      end
      Compendium.Refresh()
    end)
    frame.nav[i] = button
  end

  -- Challenge sub-tabs (two rows under header)
  frame.subTabs = {}
  for i = 1, 12 do
    local tab = CreateFrame("Button", nil, frame)
    tab:SetSize(98, 20)
    local col = (i - 1) % 6
    local rowN = math.floor((i - 1) / 6)
    tab:SetPoint("TOPLEFT", 180 + col * 100, -50 - rowN * 20)
    local hi = solidTex(tab, "BACKGROUND", 0.72, 0.55, 0.18, 0.35)
    hi:SetAllPoints()
    hi:Hide()
    tab.hi = hi
    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 4, 0)
    label:SetWidth(90)
    label:SetJustifyH("LEFT")
    tab.label = label
    tab:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    tab:Hide()
    frame.subTabs[i] = tab
  end

  -- Challenge dense rows (title + condition + bar)
  frame.challengeRows = {}
  for i = 1, CHALLENGE_ROWS do
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(560, 42)
    row:SetPoint("TOPLEFT", 180, -100 - (i - 1) * 44)
    local bg = solidTex(row, "BACKGROUND", 0.12, 0.10, 0.07, 0.55)
    bg:SetAllPoints()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(30, 30)
    row.icon:SetPoint("LEFT", 6, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 42, -4)
    row.title:SetWidth(300)
    row.title:SetJustifyH("LEFT")
    row.cond = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.cond:SetPoint("TOPLEFT", 42, -18)
    row.cond:SetWidth(340)
    row.cond:SetJustifyH("LEFT")
    row.state = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.state:SetPoint("TOPRIGHT", -8, -4)
    row.state:SetWidth(160)
    row.state:SetJustifyH("RIGHT")
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetSize(500, 4)
    row.bar:SetPoint("BOTTOMLEFT", 42, 4)
    row.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local bbg = row.bar:CreateTexture(nil, "BACKGROUND")
    bbg:SetAllPoints()
    bbg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bbg:SetVertexColor(0.18, 0.16, 0.12, 0.9)
    row:Hide()
    frame.challengeRows[i] = row
  end

  -- Overview book panels
  frame.heroBox = CreateFrame("Frame", nil, frame)
  frame.heroBox:SetSize(260, 340)
  frame.heroBox:SetPoint("TOPLEFT", 180, -72)
  local hb = solidTex(frame.heroBox, "BACKGROUND", 0.10, 0.09, 0.07, 0.7)
  hb:SetAllPoints()
  frame.heroKills = frame.heroBox:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  frame.heroKills:SetPoint("TOP", 0, -24)
  ink(frame.heroKills, 1, 0.82, 0)
  frame.heroKillsLabel = frame.heroBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.heroKillsLabel:SetPoint("TOP", frame.heroKills, "BOTTOM", 0, -4)
  frame.heroStats = frame.heroBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.heroStats:SetPoint("TOPLEFT", 16, -100)
  frame.heroStats:SetWidth(228)
  frame.heroStats:SetJustifyH("LEFT")
  frame.heroStats:SetJustifyV("TOP")
  if frame.heroStats.SetWordWrap then
    frame.heroStats:SetWordWrap(true)
  end
  frame.heroBox:Hide()

  frame.sideBox = CreateFrame("Frame", nil, frame)
  frame.sideBox:SetSize(290, 340)
  frame.sideBox:SetPoint("TOPLEFT", 456, -72)
  local sb = solidTex(frame.sideBox, "BACKGROUND", 0.10, 0.09, 0.07, 0.7)
  sb:SetAllPoints()
  frame.sideTitle = frame.sideBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.sideTitle:SetPoint("TOPLEFT", 12, -12)
  ink(frame.sideTitle, 1, 0.82, 0)
  frame.sideBody = frame.sideBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.sideBody:SetPoint("TOPLEFT", 12, -34)
  frame.sideBody:SetWidth(266)
  frame.sideBody:SetHeight(290)
  frame.sideBody:SetJustifyH("LEFT")
  frame.sideBody:SetJustifyV("TOP")
  if frame.sideBody.SetWordWrap then
    frame.sideBody:SetWordWrap(true)
  end
  frame.sideBox:Hide()

  -- Filter bar (rivals / diary)
  frame.filterBar = CreateFrame("Frame", nil, frame)
  frame.filterBar:SetPoint("TOPLEFT", 180, -48)
  frame.filterBar:SetSize(560, 24)
  local search
  do
    local ok, box = pcall(CreateFrame, "EditBox", nil, frame.filterBar, "InputBoxTemplate")
    search = (ok and box) or CreateFrame("EditBox", nil, frame.filterBar)
    if not ok then
      local bg = solidTex(search, "BACKGROUND", 0.12, 0.11, 0.09, 0.9)
      bg:SetAllPoints()
      search:SetFontObject(GameFontHighlightSmall)
    end
  end
  search:SetAutoFocus(false)
  search:SetSize(150, 20)
  search:SetPoint("LEFT", 0, 0)
  search:SetMaxLetters(32)
  search:SetScript("OnTextChanged", function(self)
    if frame._filterQuiet then
      return
    end
    frame.filterQuery = self:GetText() or ""
    frame.listPage = 1
    if frame.page == "rivals" or frame.page == "diary" then
      Compendium.Refresh()
    end
  end)
  search:SetScript("OnEditFocusGained", function()
    if frame.filterSearchHint then
      frame.filterSearchHint:Hide()
    end
  end)
  search:SetScript("OnEditFocusLost", function(self)
    if frame.filterSearchHint and (self:GetText() or "") == "" then
      frame.filterSearchHint:Show()
    end
  end)
  search:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)
  search:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    frame.filterQuery = ""
    self:ClearFocus()
    Compendium.Refresh()
  end)
  frame.filterSearch = search
  frame.filterSearchHint = frame.filterBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.filterSearchHint:SetPoint("LEFT", search, "LEFT", 6, 0)
  frame.filterSearchHint:SetText(L.COMP_SEARCH or "Buscar nome…")

  frame.filterCtx = makeButton(frame.filterBar, "", 90)
  frame.filterCtx:SetPoint("LEFT", search, "RIGHT", 8, 0)
  frame.filterCtx:SetScript("OnClick", function()
    local cur = frame.filterContext or "all"
    local nextCtx = "all"
    for i = 1, #CTX_CYCLE do
      if CTX_CYCLE[i] == cur then
        nextCtx = CTX_CYCLE[(i % #CTX_CYCLE) + 1]
        break
      end
    end
    frame.filterContext = nextCtx
    frame.listPage = 1
    Compendium.Refresh()
  end)

  frame.filterDay = makeButton(frame.filterBar, "", 110)
  frame.filterDay:SetPoint("LEFT", frame.filterCtx, "RIGHT", 6, 0)
  frame.filterDay:SetScript("OnClick", function()
    local log = ns.Stats and ns.Stats.PvpLog and ns.Stats.PvpLog() or {}
    local days = diaryDays(log)
    local cur = frame.filterDayKey or "all"
    if cur == "all" then
      frame.filterDayKey = days[1] or "all"
    else
      local found
      for i = 1, #days do
        if days[i] == cur then
          frame.filterDayKey = days[i + 1] or "all"
          found = true
          break
        end
      end
      if not found then
        frame.filterDayKey = "all"
      end
    end
    frame.listPage = 1
    Compendium.Refresh()
  end)

  frame.filterBack = makeButton(frame.filterBar, L.COMP_BACK or "Voltar", 70)
  frame.filterBack:SetPoint("RIGHT", 0, 0)
  frame.filterBack:SetScript("OnClick", function()
    frame.rivalFocus = nil
    frame.listPage = 1
    Compendium.Refresh()
  end)
  frame.filterBar:Hide()

  -- Clickable list rows (rivals / diary)
  frame.listRows = {}
  for i = 1, 12 do
    local row = CreateFrame("Button", nil, frame)
    row:SetSize(560, 26)
    row:SetPoint("TOPLEFT", 180, -78 - (i - 1) * 28)
    local hi = solidTex(row, "HIGHLIGHT", 0.72, 0.55, 0.18, 0.25)
    hi:SetAllPoints()
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetWidth(552)
    row.label:SetJustifyH("LEFT")
    row:SetScript("OnClick", function(self)
      if self.onActivate then
        self.onActivate()
      end
    end)
    row:Hide()
    frame.listRows[i] = row
  end

  frame.filterQuery = ""
  frame.filterContext = "all"
  frame.filterDayKey = "all"
  frame.rivalFocus = nil

  -- Counts dual column
  frame.countRows = {}
  for i = 1, 9 do
    local row = {}
    row.race = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.race:SetPoint("TOPLEFT", 180, -90 - (i - 1) * 28)
    row.race:SetWidth(200)
    row.race:SetJustifyH("LEFT")
    row.raceStats = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raceStats:SetPoint("TOPLEFT", 390, -90 - (i - 1) * 28)
    row.raceStats:SetWidth(80)
    row.class = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.class:SetPoint("TOPLEFT", 480, -90 - (i - 1) * 28)
    row.class:SetWidth(160)
    row.class:SetJustifyH("LEFT")
    row.classStats = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.classStats:SetPoint("TOPLEFT", 650, -90 - (i - 1) * 28)
    row.classStats:SetWidth(80)
    row.race:Hide()
    row.raceStats:Hide()
    row.class:Hide()
    row.classStats:Hide()
    frame.countRows[i] = row
  end
  frame.countHeaderL = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.countHeaderL:SetPoint("TOPLEFT", 180, -70)
  frame.countHeaderR = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.countHeaderR:SetPoint("TOPLEFT", 480, -70)
  frame.countHeaderL:Hide()
  frame.countHeaderR:Hide()

  frame.StoryScroll = CreateFrame("ScrollFrame", nil, frame)
  frame.StoryScroll:SetPoint("TOPLEFT", 180, -72)
  frame.StoryScroll:SetSize(560, 360)
  frame.StoryScroll:EnableMouseWheel(true)
  frame.StoryScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll() or 0
    local max = self:GetVerticalScrollRange() or 0
    local next = math.min(max, math.max(0, cur - delta * 28))
    self:SetVerticalScroll(next)
  end)
  local storyChild = CreateFrame("Frame", nil, frame.StoryScroll)
  storyChild:SetSize(540, 360)
  frame.StoryScroll:SetScrollChild(storyChild)
  frame.Story = storyChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Story:SetPoint("TOPLEFT", 0, 0)
  frame.Story:SetWidth(540)
  frame.Story:SetJustifyH("LEFT")
  frame.Story:SetJustifyV("TOP")
  if frame.Story.SetWordWrap then
    frame.Story:SetWordWrap(true)
  end
  if frame.Story.SetNonSpaceWrap then
    frame.Story:SetNonSpaceWrap(true)
  end
  frame.StoryChild = storyChild
  frame.StoryScroll:Hide()

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
    return button
  end
  frame.Back = arrowButton("prev")
  frame.Back:SetPoint("BOTTOMLEFT", 180, 36)
  frame.Back:SetScript("OnClick", function()
    frame.listPage = math.max(1, (frame.listPage or 1) - 1)
    Compendium.Refresh()
  end)
  frame.More = arrowButton("next")
  frame.More:SetPoint("BOTTOMRIGHT", -24, 36)
  frame.More:SetScript("OnClick", function()
    frame.listPage = (frame.listPage or 1) + 1
    Compendium.Refresh()
  end)

  frame.page = "overview"
  frame.listPage = 1
  frame.challengeCat = nil
  frame:Hide()
end

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

local function refreshNav()
  local page = frame.page or "overview"
  for i = 1, #frame.nav do
    local button = frame.nav[i]
    local key = button.labelKey
    button.label:SetText((key and L[key]) or button.page)
    if button.page == page then
      button.label:SetTextColor(1, 0.82, 0)
      button.hi:Show()
    else
      button.label:SetTextColor(0.85, 0.75, 0.55)
      button.hi:Hide()
    end
  end
end

local function paintOverview(db)
  frame.heroBox:Show()
  frame.sideBox:Show()
  local kills = db.totalKills or 0
  local deaths = db.totalDeaths or 0
  local best = db.bestStreak or 0
  local streak = db.streak or 0
  local wins, losses = 0, 0
  if ns.Stats and ns.Stats.DuelStats then
    wins, losses = ns.Stats.DuelStats()
  end
  local sk, sd, ss = 0, 0, 0
  if ns.Stats and ns.Stats.Session then
    sk, sd, ss = ns.Stats.Session()
  end
  frame.heroKills:SetText(tostring(kills))
  frame.heroKillsLabel:SetText(L.COMP_KILLS or "Abates")
  frame.heroStats:SetText(table.concat({
    (L.COMP_TOTAL_DEATHS or "Mortes: %d"):format(deaths),
    (L.COMP_BEST_STREAK or "Melhor série: %d"):format(best),
    (L.COMP_STREAK_NOW or "Série atual: %d"):format(streak),
    (L.COMP_DUELS or "Duelos: %d–%d"):format(wins, losses),
    (L.MINIMAP_SESSION or "Sessão: %d / %d / %d"):format(sk, sd, ss),
  }, "\n"))

  frame.sideTitle:SetText(L.COMP_SPOTLIGHT or "Destaques")
  local lines = {}
  if ns.Stats and ns.Stats.Spotlight then
    local nemesis, prey, zone = ns.Stats.Spotlight()
    lines[#lines + 1] = nemesis and (L.SPOT_NEMESIS or "Nêmesis %s (%d)"):format(shortName(nemesis.name), nemesis.deaths or 0) or (L.SPOT_EMPTY or "—")
    lines[#lines + 1] = prey and (L.SPOT_PREY or "Presa %s (%d)"):format(shortName(prey.name), prey.kills or 0) or (L.SPOT_EMPTY or "—")
    lines[#lines + 1] = zone and (L.SPOT_ZONE or "Zona %s"):format(zone) or (L.SPOT_EMPTY or "—")
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "|cffffd100" .. (L.COMP_RECENT_LOG or "Diário recente") .. "|r"
  local log = ns.Stats and ns.Stats.PvpLog and ns.Stats.PvpLog() or {}
  for i = 1, math.min(4, #log) do
    lines[#lines + 1] = formatPvpLogEntry(log[i], true)
  end
  if #log == 0 then
    lines[#lines + 1] = L.COMP_DIARY_EMPTY or "Nenhum evento PvP ainda."
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "|cffffd100" .. (L.COMP_RECENT_FEATS or "Feitos recentes") .. "|r"
  local recent = ns.Achievements and ns.Achievements.RecentDone and ns.Achievements.RecentDone(4) or {}
  if #recent == 0 then
    lines[#lines + 1] = L.COMP_FEATS_EMPTY or "Nenhum feito recente."
  else
    for i = 1, #recent do
      local row = recent[i]
      lines[#lines + 1] = (row.title or "?") .. " · " .. formatWhen(row.when)
    end
  end
  frame.sideBody:SetText(table.concat(lines, "\n"))
  frame.Hint:SetText(L.COMP_OVERVIEW_HINT or "Resumo do livro PvP.")
  setPager(false, false)
end

local function paintChallenges()
  local cats = ns.Achievements and ns.Achievements.Categories and ns.Achievements.Categories() or {}
  local cat = frame.challengeCat
  local known = false
  for i = 1, #cats do
    if cats[i].id == cat then
      known = true
      break
    end
  end
  if (not cat or not known) and cats[1] then
    cat = cats[1].id
    frame.challengeCat = cat
  end
  for i = 1, #frame.subTabs do
    local tab = frame.subTabs[i]
    local info = cats[i]
    if not info then
      tab:Hide()
    else
      tab:Show()
      tab.label:SetText(info.label)
      if info.id == cat then
        tab.label:SetTextColor(1, 0.82, 0)
        if tab.hi then
          tab.hi:Show()
        end
      else
        tab.label:SetTextColor(0.75, 0.7, 0.55)
        if tab.hi then
          tab.hi:Hide()
        end
      end
      tab:SetScript("OnClick", function()
        frame.challengeCat = info.id
        frame.listPage = 1
        Compendium.Refresh()
      end)
    end
  end

  local list = ns.Achievements and ns.Achievements.List and ns.Achievements.List(cat or "challenges") or {}
  local index = frame.listPage or 1
  local pages = math.max(1, math.ceil(#list / CHALLENGE_ROWS))
  if index > pages then
    index = pages
  end
  if index < 1 then
    index = 1
  end
  frame.listPage = index
  local start = (index - 1) * CHALLENGE_ROWS
  for i = 1, CHALLENGE_ROWS do
    local item = list[start + i]
    local row = frame.challengeRows[i]
    if not item then
      row:Hide()
    else
      row:Show()
      row.icon:SetTexture(item.icon)
      row.title:SetText(item.title or "")
      local cond = item.desc or ""
      if type(item.detail) == "string" and item.detail ~= "" and not item.done then
        cond = cond ~= "" and (cond .. "  ·  " .. item.detail) or item.detail
      end
      row.cond:SetText(cond)
      row.cond:SetTextColor(0.72, 0.68, 0.58)
      if item.done then
        row.title:SetTextColor(1, 0.82, 0)
        row.state:SetText((L.COMP_DONE or "feito") .. " · " .. formatWhen(item.when))
        row.state:SetTextColor(0.85, 0.75, 0.4)
      else
        row.title:SetTextColor(0.95, 0.92, 0.85)
        local goal = item.goal or 1
        local progress = item.progress or 0
        if progress <= 0 then
          row.state:SetText(L.COMP_OPEN or "aberto")
          row.state:SetTextColor(0.65, 0.65, 0.6)
        else
          row.state:SetText(progress .. "/" .. goal)
          row.state:SetTextColor(0.85, 0.85, 0.75)
        end
      end
      local goal = math.max(1, item.goal or 1)
      local progress = math.min(goal, item.progress or 0)
      row.bar:SetMinMaxValues(0, goal)
      row.bar:SetValue(progress)
      if item.done then
        row.bar:SetStatusBarColor(0.95, 0.75, 0.15)
      else
        row.bar:SetStatusBarColor(0.35, 0.55, 0.22)
      end
    end
  end
  local last = math.min(#list, start + CHALLENGE_ROWS)
  if #list == 0 then
    frame.Hint:SetText(L.COMP_CHALLENGES_EMPTY or L.ACH_HINT or "")
  else
    frame.Hint:SetText((L.ACH_PAGE or "%d–%d de %d"):format(start + 1, last, #list))
  end
  setPager(index > 1, index < pages)
end

local function paintCounts(db)
  frame.countHeaderL:Show()
  frame.countHeaderR:Show()
  frame.countHeaderL:SetText((L.COMP_RACE or "Raça") .. "  ·  " .. (L.COMP_KILLS or "Abates") .. "/" .. (L.COMP_DEATHS or "Mortes"))
  frame.countHeaderR:SetText((L.COMP_CLASS or "Classe") .. "  ·  " .. (L.COMP_KILLS or "Abates") .. "/" .. (L.COMP_DEATHS or "Mortes"))
  ink(frame.countHeaderL, 1, 0.82, 0)
  ink(frame.countHeaderR, 1, 0.82, 0)
  local kills = db.kills or {}
  local deaths = db.deaths or {}
  local classes = Data.CLASSES or {}
  for i = 1, 9 do
    local row = frame.countRows[i]
    row.race:Show()
    row.raceStats:Show()
    row.class:Show()
    row.classStats:Show()
    local race = RACES[i]
    if race then
      local rk = countOf(kills.Race, race)
      row.race:SetText(featMark(rk) .. Data.RaceLabel(race))
      row.raceStats:SetText(rk .. "/" .. countOf(deaths.Race, race))
    else
      row.race:SetText("")
      row.raceStats:SetText("")
    end
    local class = classes[i]
    if class then
      local ck = countOf(kills.Class, class)
      row.class:SetText(featMark(ck) .. Data.ClassLabel(class))
      row.classStats:SetText(ck .. "/" .. countOf(deaths.Class, class))
    else
      row.class:SetText("")
      row.classStats:SetText("")
    end
  end
  frame.Hint:SetText(L.COMP_HINT or "")
  setPager(false, false)
end

local function showFilterBar(mode)
  -- mode: "rivals" | "diary" | "sheet"
  frame.filterBar:Show()
  local q = frame.filterQuery or ""
  if frame.filterSearch and frame.filterSearch.SetText then
    if (frame.filterSearch:GetText() or "") ~= q then
      frame._filterQuiet = true
      frame.filterSearch:SetText(q)
      frame._filterQuiet = nil
    end
  end
  if frame.filterSearchHint then
    if q == "" and not (frame.filterSearch and frame.filterSearch.HasFocus and frame.filterSearch:HasFocus()) then
      frame.filterSearchHint:Show()
    else
      frame.filterSearchHint:Hide()
    end
  end
  local ctx = frame.filterContext or "all"
  frame.filterCtx:SetText((L.COMP_FILTER_CTX or "Ctx: %s"):format(ctxLabel(ctx)))
  if mode == "sheet" then
    frame.filterSearch:Hide()
    frame.filterSearchHint:Hide()
    frame.filterCtx:Hide()
    frame.filterDay:Hide()
    frame.filterBack:Show()
    frame.filterBack:SetText(L.COMP_BACK or "Voltar")
  elseif mode == "diary" then
    frame.filterSearch:Show()
    frame.filterCtx:Show()
    frame.filterDay:Show()
    frame.filterBack:Hide()
    local day = frame.filterDayKey or "all"
    if day == "all" then
      frame.filterDay:SetText((L.COMP_FILTER_DAY or "Dia: %s"):format(L.COMP_FILTER_ALL or "todos"))
    else
      frame.filterDay:SetText((L.COMP_FILTER_DAY or "Dia: %s"):format(day))
    end
  else
    frame.filterSearch:Show()
    frame.filterCtx:Show()
    frame.filterDay:Hide()
    frame.filterBack:Hide()
  end
end

local function paintListPage(entries, emptyHint)
  local index = frame.listPage or 1
  local per = 12
  local pages = math.max(1, math.ceil(math.max(#entries, 1) / per))
  if #entries == 0 then
    for i = 1, per do
      frame.listRows[i]:Hide()
    end
    local row = frame.listRows[1]
    row:Show()
    row.label:SetText(emptyHint or "")
    row.label:SetTextColor(0.65, 0.62, 0.55)
    row.onActivate = nil
    frame.Hint:SetText("")
    setPager(false, false)
    return
  end
  if index > pages then
    index = pages
  end
  frame.listPage = index
  local start = (index - 1) * per
  for i = 1, per do
    local row = frame.listRows[i]
    local entry = entries[start + i]
    if entry then
      row:Show()
      row.label:SetText(entry.text or "")
      row.label:SetTextColor(entry.colorR or 0.92, entry.colorG or 0.90, entry.colorB or 0.84)
      row.onActivate = entry.onActivate
      if entry.onActivate then
        row:EnableMouse(true)
      else
        row:EnableMouse(false)
      end
    else
      row:Hide()
      row.onActivate = nil
    end
  end
  frame.Hint:SetText((L.ACH_PAGE or "%d–%d de %d"):format(start + 1, math.min(#entries, start + per), #entries))
  setPager(index > 1, index < pages)
end

local function openRivalSheet(rival)
  frame.rivalFocus = rival
  frame.listPage = 1
  Compendium.Refresh()
end

local function paintRivalSheet(rival)
  showFilterBar("sheet")
  for i = 1, #frame.listRows do
    frame.listRows[i]:Hide()
  end
  if frame.StoryScroll then
    frame.StoryScroll:Show()
    frame.StoryScroll:SetVerticalScroll(0)
  end
  frame.Story:Show()
  local who = shortName(rival.name)
  local score = (L.RIVAL_SCORE or "%d–%d"):format(rival.kills or 0, rival.deaths or 0)
  local lines = {
    "|cffffd100" .. who .. "|r",
    "|cffaaaaaa" .. (L.COMP_RIVAL_SHEET or "Ficha do rival") .. " · " .. score .. "|r",
  }
  local meta = {}
  if rival.race and Data.RaceLabel then
    meta[#meta + 1] = Data.RaceLabel(rival.race)
  end
  if rival.class and Data.ClassLabel then
    meta[#meta + 1] = Data.ClassLabel(rival.class)
  end
  if #meta > 0 then
    lines[#lines + 1] = table.concat(meta, " · ")
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "|cffffd100" .. (L.COMP_RIVAL_BREAKDOWN or "Por contexto") .. "|r"
  lines[#lines + 1] = (L.COMP_LOG_CTX_world or "mundo") .. ": "
    .. (rival.worldKills or 0) .. "–" .. (rival.worldDeaths or 0)
  lines[#lines + 1] = (L.COMP_LOG_CTX_bg or "CB") .. ": "
    .. (rival.bgKills or 0) .. "–" .. (rival.bgDeaths or 0)
  lines[#lines + 1] = (L.COMP_LOG_CTX_duel or "duelo") .. ": "
    .. (rival.duelKills or 0) .. "–" .. (rival.duelDeaths or 0)
  lines[#lines + 1] = ""
  lines[#lines + 1] = "|cffffd100" .. (L.COMP_RIVAL_TIMELINE or "Linha do tempo") .. "|r"

  local meetings = type(rival.meetings) == "table" and rival.meetings or {}
  if #meetings == 0 then
    lines[#lines + 1] = "|cff888888" .. (L.COMP_RIVAL_NO_MEET or "Nenhum encontro detalhado ainda.") .. "|r"
  else
    for i = #meetings, 1, -1 do
      local m = meetings[i]
      local side = m.side == "deaths" and (L.MEET_DEATH or "queda") or (L.MEET_KILL or "abate")
      local color = m.side == "deaths" and "|cffcf6e6e" or "|cff6ecf6e"
      local bits = {
        color .. side .. "|r",
        "|cffaaaaaa" .. formatWhen(m.time) .. "|r",
      }
      if type(m.zone) == "string" and m.zone ~= "" then
        bits[#bits + 1] = m.zone
      end
      if m.context then
        bits[#bits + 1] = ctxLabel(m.context)
      end
      lines[#lines + 1] = "  " .. table.concat(bits, " · ")
    end
  end

  local body = table.concat(lines, "\n")
  frame.Story:SetText(body)
  local height = 360
  if frame.Story.GetStringHeight then
    height = math.max(360, (frame.Story:GetStringHeight() or 360) + 24)
  end
  if frame.StoryChild then
    frame.StoryChild:SetHeight(height)
  end
  frame.Hint:SetText((L.COMP_RIVAL_HINT or "Clique em Voltar para a lista. · %d encontros"):format(#meetings))
  setPager(false, false)
end

local function paintRivals()
  if frame.rivalFocus then
    paintRivalSheet(frame.rivalFocus)
    return
  end
  showFilterBar("rivals")
  local q = queryLower()
  local ctx = frame.filterContext or "all"
  local entries = {}
  local list = ns.Stats and ns.Stats.RivalList and ns.Stats.RivalList() or {}
  for i = 1, #list do
    local row = list[i]
    if nameMatches(row.name, q) and rivalMatchesContext(row, ctx) then
      local score = (L.RIVAL_SCORE or "%d–%d"):format(row.kills or 0, row.deaths or 0)
      local who = "|cffffffff" .. shortName(row.name) .. "|r"
      local bits = { who, "|cffffd100" .. score .. "|r", "|cffaaaaaa" .. formatWhen(row.last) .. "|r" }
      if row.race and Data.RaceLabel then
        bits[#bits + 1] = Data.RaceLabel(row.race)
      end
      if row.class and Data.ClassLabel then
        bits[#bits + 1] = Data.ClassLabel(row.class)
      end
      local meetings = row.meetings
      if type(meetings) == "table" and #meetings > 0 then
        local last = meetings[#meetings]
        local side = last.side == "deaths" and (L.MEET_DEATH or "queda") or (L.MEET_KILL or "abate")
        if type(last.zone) == "string" and last.zone ~= "" then
          bits[#bits + 1] = side .. " · " .. last.zone
        else
          bits[#bits + 1] = side
        end
      end
      entries[#entries + 1] = {
        text = table.concat(bits, "   "),
        onActivate = function()
          openRivalSheet(row)
        end,
      }
    end
  end
  local empty = L.COMP_RIVALS_EMPTY or "Nenhum rival ainda."
  if #list > 0 and #entries == 0 then
    empty = L.COMP_FILTER_EMPTY or "Nada com este filtro."
  end
  paintListPage(entries, empty)
  if #entries > 0 then
    frame.Hint:SetText((frame.Hint:GetText() or "") .. "  ·  " .. (L.COMP_RIVAL_CLICK or "Clique para abrir a ficha"))
  end
end

local function paintDiary()
  showFilterBar("diary")
  local q = queryLower()
  local ctx = frame.filterContext or "all"
  local dayKey = frame.filterDayKey or "all"
  local entries = {}
  local log = ns.Stats and ns.Stats.PvpLog and ns.Stats.PvpLog() or {}
  local matched = 0
  local lastDay = nil
  for i = 1, #log do
    local e = log[i]
    local day = formatWhen(e.t)
    local ctxOk = (ctx == "all") or (e.context == ctx)
    local dayOk = (dayKey == "all") or (day == dayKey)
    local nameOk = nameMatches(e.name, q)
    if ctxOk and dayOk and nameOk then
      matched = matched + 1
      if day ~= lastDay then
        entries[#entries + 1] = {
          text = "|cffffd100— " .. day .. " —|r",
          colorR = 1, colorG = 0.82, colorB = 0,
        }
        lastDay = day
      end
      local rival = ns.Stats and ns.Stats.RivalByName and ns.Stats.RivalByName(e.name)
      entries[#entries + 1] = {
        text = "  " .. formatPvpLogEntry(e, false),
        onActivate = rival and function()
          openRivalSheet(rival)
        end or nil,
      }
    end
  end
  local empty = L.COMP_DIARY_EMPTY or "Nenhum evento PvP ainda."
  if #log > 0 and matched == 0 then
    empty = L.COMP_FILTER_EMPTY or "Nada com este filtro."
  end
  paintListPage(entries, empty)
  if matched > 0 and frame.Hint then
    local pageHint = frame.Hint:GetText() or ""
    local tally = (L.COMP_DIARY_HINT or "Abates, mortes e duelos · %d eventos"):format(matched)
    if pageHint ~= "" then
      frame.Hint:SetText(pageHint .. "  ·  " .. tally)
    else
      frame.Hint:SetText(tally)
    end
  end
end

local function paintStory()
  if frame.StoryScroll then
    frame.StoryScroll:Show()
    frame.StoryScroll:SetVerticalScroll(0)
  end
  frame.Story:Show()
  local chapters = ns.Chronicle and ns.Chronicle.Chapters and ns.Chronicle.Chapters() or {}
  local index = frame.listPage or 1
  if #chapters == 0 then
    frame.Story:SetText("|cffc9b896" .. (L.NARR_EMPTY or "") .. "|r")
    if frame.StoryChild then
      frame.StoryChild:SetHeight(80)
    end
    frame.Hint:SetText(L.NARR_HINT or "")
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
  local parts = {
    "|cffffd100" .. (chapter.title or "") .. "|r",
  }
  if type(chapter.meta) == "string" and chapter.meta ~= "" then
    parts[#parts + 1] = "|cffaaaaaa" .. chapter.meta .. "|r"
  end
  parts[#parts + 1] = ""
  parts[#parts + 1] = "|cffe8dcc8" .. (chapter.text or "") .. "|r"
  local body = table.concat(parts, "\n")
  frame.Story:SetText(body)
  local height = 360
  if frame.Story.GetStringHeight then
    height = math.max(360, (frame.Story:GetStringHeight() or 360) + 24)
  end
  if frame.StoryChild then
    frame.StoryChild:SetHeight(height)
  end
  local dayHint = chapter.meta and (" · " .. chapter.meta) or ""
  frame.Hint:SetText((L.NARR_PAGE or "Capítulo %d de %d"):format(index, #chapters) .. dayHint)
  setPager(index > 1, index < #chapters)
end

function Compendium.Refresh()
  if not frame then
    return
  end
  local db = ns.Stats and ns.Stats.GetDB and ns.Stats.GetDB() or {}
  frame.Title:SetText(L.COMP_TITLE or "Compêndio de PvP")
  frame.Close:SetText(L.COMP_CLOSE or "Fechar")
  hideAllContent()
  refreshNav()

  local done, total = 0, 0
  if ns.Achievements and ns.Achievements.Counts then
    done, total = ns.Achievements.Counts()
  end
  frame.ProgressLabel:SetText((L.ACH_TOTAL or "Conquistas: %d/%d"):format(done, total))
  frame.ProgressBar:SetMinMaxValues(0, math.max(1, total))
  frame.ProgressBar:SetValue(done)

  local page = frame.page or "overview"
  if page == "overview" then
    paintOverview(db)
  elseif page == "challenges" then
    paintChallenges()
  elseif page == "counts" then
    paintCounts(db)
  elseif page == "rivals" then
    paintRivals()
  elseif page == "story" then
    paintStory()
  elseif page == "diary" then
    paintDiary()
  else
    frame.page = "overview"
    paintOverview(db)
  end
end

function Compendium.ShowPage(page)
  if not frame then
    buildFrame()
  end
  if page == "summary" then
    page = "overview"
  end
  frame.page = page or frame.page or "overview"
  frame.listPage = 1
  frame.rivalFocus = nil
  Compendium.Refresh()
  frame:Show()
end

function Compendium.Toggle()
  if not frame then
    buildFrame()
  else
    applyWowDialogBackdrop(frame)
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
  button.Icon = icon

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
    if ns.Stats and ns.Stats.Session then
      local kills, deaths, streak = ns.Stats.Session()
      GameTooltip:AddLine(L.MINIMAP_SESSION:format(kills or 0, deaths or 0, streak or 0), 1, 0.82, 0)
    end
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
