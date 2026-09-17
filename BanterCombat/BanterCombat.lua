local addonName, ns = ...
ns = ns or {}

local Data = ns.Data
local Stats = ns.Stats
local UI = ns.UI
local Options = ns.Options
local L = ns.L

local PREFIX = "BANTER_MSG"
local PROTOCOL = "v2"
local PROTOCOL_MIN = 1
local MSG_TEXT_MAX = 180
local MSG_BADGE_MAX = 48
local HISTORY_MAX = 20

local playerGUID
local eventFrame
local pruneCounter = 0
local history = {}

-- Hot-path locals
local band = bit.band
local strsplit = strsplit
local Ambiguate = Ambiguate
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitClass = UnitClass
local UnitRace = UnitRace
local UnitExists = UnitExists
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local find = string.find
local sub = string.sub
local len = string.len

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x00000010
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040

local recentEvents = {} -- key -> GetTime()
local DEDUP_WINDOW = 1.5
local ignoredNames = {} -- Ambiguate(name) -> true

------------------------------------------------------------
-- Debug / history
------------------------------------------------------------
local function Debug(...)
  local s = Options.Get()
  if not s or not s.debug then
    return
  end
  local parts = { ... }
  for i = 1, #parts do
    parts[i] = tostring(parts[i])
  end
  print("|cFF66CCFFBanterCombat|r " .. table.concat(parts, " "))
end

local function PushHistory(kind, text, speaker)
  history[#history + 1] = {
    t = time(),
    kind = kind or "?",
    speaker = speaker or "?",
    text = text or "",
  }
  while #history > HISTORY_MAX do
    table.remove(history, 1)
  end
end

local function Truncate(str, maxLen)
  str = tostring(str or "")
  if len(str) <= maxLen then
    return str
  end
  return sub(str, 1, maxLen - 3) .. "..."
end

local function SanitizeField(str, maxLen)
  str = tostring(str or "")
  -- Strip WoW escape sequences that could break chat/UI, and pipe (protocol sep)
  str = str:gsub("|", "/")
  str = str:gsub("[\001-\031]", " ")
  str = str:gsub("%s+", " ")
  str = str:match("^%s*(.-)%s*$") or str
  return Truncate(str, maxLen)
end

------------------------------------------------------------
-- Compat messaging
------------------------------------------------------------
local function RegisterPrefix(prefix)
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(prefix)
  end
end

local function SendAddon(msg, channel, target)
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    if channel == "WHISPER" then
      C_ChatInfo.SendAddonMessage(PREFIX, msg, "WHISPER", target)
    else
      C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
    end
  elseif SendAddonMessage then
    if channel == "WHISPER" then
      SendAddonMessage(PREFIX, msg, "WHISPER", target)
    else
      SendAddonMessage(PREFIX, msg, channel)
    end
  end
end

local function BroadcastPayload(encoded, whisperTarget)
  local s = Options.Get()
  if s.syncWhisper and whisperTarget and whisperTarget ~= "" then
    SendAddon(encoded, "WHISPER", Ambiguate(whisperTarget, "none"))
  end
  if s.syncGroup then
    local sent = false
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
      SendAddon(encoded, "INSTANCE_CHAT")
      sent = true
    end
    if not sent and IsInRaid and IsInRaid() then
      SendAddon(encoded, "RAID")
    elseif not sent and IsInGroup and IsInGroup() then
      SendAddon(encoded, "PARTY")
    end
  end
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function IsPlayerFlags(flags)
  return flags and band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
end

local function IsHostileFlags(flags)
  if not flags then
    return true
  end
  if band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
    return true
  end
  if band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
    return false
  end
  return true
end

local function IsIgnored(name)
  if not name or name == "" then
    return false
  end
  return ignoredNames[Ambiguate(name, "none")] == true
end

local function SeenRecently(key)
  local now = GetTime()
  local last = recentEvents[key]
  if last and (now - last) < DEDUP_WINDOW then
    return true
  end
  recentEvents[key] = now
  pruneCounter = pruneCounter + 1
  if pruneCounter >= 32 then
    pruneCounter = 0
    for k, t in pairs(recentEvents) do
      if now - t > 10 then
        recentEvents[k] = nil
      end
    end
  end
  return false
end

local function IsPvPContextAllowed()
  local s = Options.Get()
  if not s.pvpOnly then
    return true
  end
  if UnitIsPVP and UnitIsPVP("player") then
    return true
  end
  if UnitInBattleground and UnitInBattleground("player") then
    return true
  end
  return false
end

local function InfoFromGUID(guid)
  if not guid or not GetPlayerInfoByGUID then
    return nil
  end
  local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
  if not name then
    return nil
  end
  if realm and realm ~= "" and not find(name, "-", 1, true) then
    name = name .. "-" .. realm
  end
  return {
    name = name,
    class = englishClass,
    race = englishRace,
    guid = guid,
    localizedClass = localizedClass,
    localizedRace = localizedRace,
    sex = sex,
  }
end

local function PlayerSelfInfo()
  local _, class = UnitClass("player")
  local _, race = UnitRace("player")
  return {
    name = UnitName("player"),
    class = class,
    race = race,
    guid = UnitGUID("player"),
  }
end

local function Pick(list)
  if not list or #list == 0 then
    return nil
  end
  return list[math.random(1, #list)]
end

local function RollRarity()
  local roll = math.random(1, 100)
  local acc = 0
  for _, row in ipairs(Data.RARITY_WEIGHTS) do
    acc = acc + row.weight
    if roll <= acc then
      return row.key
    end
  end
  return "common"
end

local function FormatTemplate(text, ctx)
  if not text then
    return ""
  end
  ctx = ctx or {}
  local raceLabel = (ctx.race and Data.RACE_LABEL[ctx.race]) or ctx.race or "?"
  local classLabel = (ctx.class and Data.CLASS_LABEL[ctx.class]) or ctx.class or "?"
  text = text:gsub("{race}", raceLabel)
  text = text:gsub("{class}", classLabel)
  text = text:gsub("{name}", ctx.name or "?")
  return text
end

local function MaybeChatAnnounce(text)
  local s = Options.Get()
  if not s.chatAnnounce or not text or text == "" then
    return
  end
  if SendChatMessage then
    pcall(SendChatMessage, Truncate(text, 240), "EMOTE")
  end
end

------------------------------------------------------------
-- Speech
------------------------------------------------------------
local function SelectKillSpeech(victim, isRevenge, milestoneKind, milestoneValue, milestoneKey)
  if isRevenge then
    return Pick(Data.Speech.revenge), "revenge", L.REVENGE
  end

  if milestoneKind and milestoneValue and milestoneKey then
    local special = Stats.GetMilestoneSpeech(milestoneKind, milestoneValue, milestoneKey)
    if special then
      local label = milestoneKind == "race"
        and (Data.RACE_LABEL[milestoneKey] or milestoneKey)
        or (Data.CLASS_LABEL[milestoneKey] or milestoneKey)
      local badge = L.MILESTONE:format(milestoneValue, label)
      return special, "milestone", badge
    end
  end

  local rarity = RollRarity()
  local speech = Data.Speech.kill
  local text

  if rarity == "legendary" then
    local candidates = {}
    local _, myClass = UnitClass("player")
    local _, myRace = UnitRace("player")
    for _, row in ipairs(speech.legendary) do
      local ok = true
      if row.class and row.class ~= myClass then ok = false end
      if row.vsClass and victim.class and row.vsClass ~= victim.class then ok = false end
      if row.race and row.race ~= myRace then ok = false end
      if row.vsRace and victim.race and row.vsRace ~= victim.race then ok = false end
      if ok and row.text then
        candidates[#candidates + 1] = row.text
      end
    end
    text = Pick(candidates) or Pick(speech.common)
  elseif rarity == "epic" then
    local _, myClass = UnitClass("player")
    local byMe = speech.epic[myClass]
    if byMe and victim.class and byMe[victim.class] then
      text = Pick(byMe[victim.class])
    end
    text = text or Pick(speech.common)
  elseif rarity == "rare" then
    if math.random(1, 2) == 1 and victim.race and speech.rare_race[victim.race] then
      text = Pick(speech.rare_race[victim.race])
    elseif victim.class and speech.rare_class[victim.class] then
      text = Pick(speech.rare_class[victim.class])
    else
      text = Pick(speech.common)
    end
  else
    text = Pick(speech.common)
  end

  return FormatTemplate(text, victim), rarity, nil
end

local function SelectDeathSpeech(killer)
  local rarity = RollRarity()
  local speech = Data.Speech.death
  local text
  if rarity == "legendary" then
    local row = Pick(speech.legendary)
    text = row and row.text
  elseif rarity == "epic" and killer and killer.class then
    local _, myClass = UnitClass("player")
    local pack = speech.epic[killer.class]
    if pack and pack[myClass] then
      text = Pick(pack[myClass])
    end
  elseif rarity == "rare" and killer then
    if killer.race and speech.rare_race[killer.race] then
      text = Pick(speech.rare_race[killer.race])
    elseif killer.class and speech.rare_class[killer.class] then
      text = Pick(speech.rare_class[killer.class])
    end
  end
  text = text or Pick(speech.common)
  return FormatTemplate(text, killer or {}), rarity, nil
end

------------------------------------------------------------
-- Protocol v2: v2|SHOW|proto|speaker|race|class|kind|rarity|badge|text
-- Also accepts v1 for older clients
------------------------------------------------------------
local function EncodeMessage(speaker, race, class, kind, rarity, badge, text)
  return table.concat({
    PROTOCOL,
    "SHOW",
    "2",
    SanitizeField(speaker or "?", 48),
    SanitizeField(race or "", 24),
    SanitizeField(class or "", 24),
    SanitizeField(kind or "kill", 16),
    SanitizeField(rarity or "common", 16),
    SanitizeField(badge, MSG_BADGE_MAX),
    SanitizeField(text, MSG_TEXT_MAX),
  }, "\031")
end

local function DecodeMessage(msg)
  if not msg or msg == "" then
    return nil
  end
  local parts = { strsplit("\031", msg) }
  local ver = parts[1]
  if parts[2] ~= "SHOW" then
    return nil
  end
  if ver == "v2" then
    local proto = tonumber(parts[3]) or 0
    if proto < PROTOCOL_MIN then
      return nil
    end
    return {
      speaker = parts[4],
      race = parts[5],
      class = parts[6],
      kind = parts[7],
      rarity = parts[8],
      badge = parts[9],
      text = parts[10],
    }
  elseif ver == "v1" then
    return {
      speaker = parts[3],
      race = parts[4],
      class = parts[5],
      kind = parts[6],
      rarity = parts[7],
      badge = parts[8],
      text = parts[9],
    }
  end
  return nil
end

local function Present(payload, unit)
  PushHistory(payload.kind, payload.text, payload.speaker)
  UI.Enqueue({
    speaker = payload.speaker,
    text = payload.text,
    badge = payload.badge,
    class = payload.class,
    race = payload.race,
    kind = payload.kind,
    rarity = payload.rarity,
    unit = unit,
  })
end

------------------------------------------------------------
-- Combat resolution
------------------------------------------------------------
local function OnPlayerKill(victim, destFlags)
  if not victim or not victim.name then
    return
  end
  local s = Options.Get()
  if not s.enabled then
    return
  end
  if IsIgnored(victim.name) then
    Debug("skip kill: ignored", victim.name)
    return
  end
  if s.hostileOnly and not IsHostileFlags(destFlags) then
    Debug("skip kill: not hostile", victim.name)
    return
  end
  local dedupKey = "kill:" .. (victim.guid or victim.name)
  if SeenRecently(dedupKey) then
    return
  end

  local isRevenge = Stats.IsRevenge(victim.name)
  local _, _, mKind, mValue, mKey = Stats.RecordKill(victim)
  if isRevenge then
    Stats.ClearRevenge()
  end

  local text, rarity, badge = SelectKillSpeech(victim, isRevenge, mKind, mValue, mKey)
  local selfInfo = PlayerSelfInfo()
  local payload = {
    speaker = selfInfo.name,
    race = selfInfo.race,
    class = selfInfo.class,
    kind = isRevenge and "revenge" or (badge and "milestone" or "kill"),
    rarity = rarity,
    badge = badge,
    text = text,
  }

  Debug("kill", victim.name, payload.kind, rarity)
  Present(payload, "player")
  MaybeChatAnnounce(text)
  BroadcastPayload(EncodeMessage(
    payload.speaker, payload.race, payload.class, payload.kind, payload.rarity, payload.badge, payload.text
  ), victim.name)
end

local function OnPlayerDeath(killer)
  local s = Options.Get()
  if not s.enabled then
    return
  end
  if s.showDeaths == false then
    if killer then
      Stats.RecordDeathBy(killer)
    end
    return
  end
  if SeenRecently("death:" .. (playerGUID or "self")) then
    return
  end
  if killer and IsIgnored(killer.name) then
    Stats.RecordDeathBy(killer)
    Debug("death recorded, popup skipped (ignored)", killer.name)
    return
  end
  Stats.RecordDeathBy(killer)
  local text, rarity = SelectDeathSpeech(killer)
  local selfInfo = PlayerSelfInfo()
  local payload = {
    speaker = selfInfo.name,
    race = selfInfo.race,
    class = selfInfo.class,
    kind = "death",
    rarity = rarity,
    badge = nil,
    text = text,
  }
  Debug("death", killer and killer.name or "?", rarity)
  Present(payload, "player")
  MaybeChatAnnounce(text)
  if killer and killer.name then
    BroadcastPayload(EncodeMessage(
      payload.speaker, payload.race, payload.class, payload.kind, payload.rarity, "", payload.text
    ), killer.name)
  end
end

local function HandleCombatLog()
  local s = Options.Get()
  if not s.enabled then
    return
  end
  if not IsPvPContextAllowed() then
    return
  end

  local _, subevent, _,
    sourceGUID, sourceName, sourceFlags, _,
    destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()

  if not playerGUID then
    playerGUID = UnitGUID("player")
  end

  if subevent == "PARTY_KILL" then
    if sourceGUID == playerGUID and IsPlayerFlags(destFlags) then
      local victim = InfoFromGUID(destGUID) or {
        name = destName,
        guid = destGUID,
      }
      if UnitExists("target") and UnitGUID("target") == destGUID then
        local _, class = UnitClass("target")
        local _, race = UnitRace("target")
        victim.class = victim.class or class
        victim.race = victim.race or race
        victim.name = victim.name or UnitName("target")
      end
      OnPlayerKill(victim, destFlags)
    end
    return
  end

  if subevent == "UNIT_DIED" and destGUID == playerGUID then
    local killer = ns._lastHostileAttacker
    if killer and killer.guid == playerGUID then
      killer = nil
    end
    OnPlayerDeath(killer)
    ns._lastHostileAttacker = nil
    return
  end

  if sourceGUID and sourceGUID ~= playerGUID and destGUID == playerGUID and IsPlayerFlags(sourceFlags) then
    if subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE"
      or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE"
      or (type(subevent) == "string" and find(subevent, "_DAMAGE", 1, true)) then
      if s.hostileOnly and not IsHostileFlags(sourceFlags) then
        return
      end
      ns._lastHostileAttacker = InfoFromGUID(sourceGUID) or {
        name = sourceName,
        guid = sourceGUID,
      }
    end
  end
end

------------------------------------------------------------
-- Events / slash
------------------------------------------------------------
local function OnAddonMessage(prefix, message, channel, sender)
  if prefix ~= PREFIX then
    return
  end
  local s = Options.Get()
  if not s.enabled then
    return
  end
  local data = DecodeMessage(message)
  if not data then
    return
  end
  if sender and Ambiguate(sender, "none") == Ambiguate(UnitName("player"), "none") then
    return
  end
  if IsIgnored(sender) or IsIgnored(data.speaker) then
    Debug("remote skipped (ignored)", sender)
    return
  end
  -- Group channel filter
  if channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT" then
    if s.showGroupBanter == false then
      Debug("remote group skipped")
      return
    end
  end
  if data.kind == "death" and s.showDeaths == false then
    return
  end
  local key = "remote:" .. (sender or "?") .. ":" .. (data.text or "")
  if SeenRecently(key) then
    return
  end
  Debug("remote", channel, sender, data.kind)
  Present({
    speaker = data.speaker,
    text = data.text,
    badge = (data.badge ~= "" and data.badge) or nil,
    class = data.class,
    race = data.race,
    kind = data.kind,
    rarity = data.rarity,
  }, nil)
end

local function PrintTopMap(title, map, labelLookup, limit)
  if type(map) ~= "table" then
    return
  end
  local rows = {}
  for k, v in pairs(map) do
    rows[#rows + 1] = { key = k, n = v }
  end
  table.sort(rows, function(a, b)
    if a.n == b.n then
      return a.key < b.key
    end
    return a.n > b.n
  end)
  if #rows == 0 then
    return
  end
  print("  " .. title)
  for i = 1, math.min(limit or 5, #rows) do
    local row = rows[i]
    local label = (labelLookup and labelLookup[row.key]) or row.key
    print(string.format("    %d. %s — %d", i, label, row.n))
  end
end

local function OnEvent(_, event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name ~= addonName then
      return
    end
    Stats.GetDB()
    Options.Get()
    RegisterPrefix(PREFIX)
  elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    playerGUID = UnitGUID("player")
    if event == "PLAYER_LOGIN" then
      math.randomseed(time() + (playerGUID and tonumber(playerGUID:sub(-6), 16) or 0))
      if UI.ApplySavedPosition then
        UI.ApplySavedPosition()
      end
      print("|cFFFFD100BanterCombat|r " .. L.LOADED)
    end
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    HandleCombatLog()
  elseif event == "CHAT_MSG_ADDON" then
    OnAddonMessage(...)
  end
end

eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", OnEvent)

SLASH_BANTERCOMBAT1 = "/banter"
SLASH_BANTERCOMBAT2 = "/bantercombat"
SlashCmdList.BANTERCOMBAT = function(msg)
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = (cmd or ""):lower()
  rest = rest or ""

  if cmd == "test" or cmd == "kill" then
    local victim = { name = "AlvoTeste", race = "Orc", class = "MAGE" }
    local text, rarity, badge = SelectKillSpeech(victim, false, nil, nil, nil)
    Present({
      speaker = UnitName("player"),
      text = text,
      badge = badge,
      class = select(2, UnitClass("player")),
      kind = badge and "milestone" or "kill",
      rarity = rarity,
    }, "player")
  elseif cmd == "revenge" then
    Present({
      speaker = UnitName("player"),
      text = Pick(Data.Speech.revenge),
      badge = L.REVENGE,
      class = select(2, UnitClass("player")),
      kind = "revenge",
      rarity = "revenge",
    }, "player")
  elseif cmd == "milestone" then
    Present({
      speaker = UnitName("player"),
      text = Stats.GetMilestoneSpeech("race", 50, "Orc") or "Marco de teste",
      badge = L.MILESTONE:format(50, Data.RACE_LABEL.Orc or "Orc"),
      class = select(2, UnitClass("player")),
      kind = "milestone",
      rarity = "milestone",
    }, "player")
  elseif cmd == "stats" then
    local db = Stats.GetDB()
    print("|cFFFFD100BanterCombat|r " .. L.STATS:format(db.totalKills or 0, db.totalDeaths or 0))
    if db.lastKiller then
      print("  " .. L.LAST_KILLER:format(
        db.lastKiller.name or "?",
        db.lastKiller.race or "?",
        db.lastKiller.class or "?"
      ))
    end
    PrintTopMap(L.TOP_RACE, db.kills and db.kills.Race, Data.RACE_LABEL, 5)
    PrintTopMap(L.TOP_CLASS, db.kills and db.kills.Class, Data.CLASS_LABEL, 5)
  elseif cmd == "config" or cmd == "options" then
    Options.TogglePanel()
  elseif cmd == "queue" then
    print("|cFFFFD100BanterCombat|r " .. L.QUEUE:format(UI.QueueSize()))
  elseif cmd == "hide" then
    UI.HideNow()
  elseif cmd == "debug" then
    local s = Options.Get()
    if rest == "on" then
      Options.Set("debug", true)
    elseif rest == "off" then
      Options.Set("debug", false)
    else
      Options.Set("debug", not s.debug)
    end
    print("|cFFFFD100BanterCombat|r debug=" .. tostring(Options.Get().debug))
  elseif cmd == "history" then
    if #history == 0 then
      print("|cFFFFD100BanterCombat|r (empty)")
      return
    end
    for i = #history, math.max(1, #history - 9), -1 do
      local h = history[i]
      print(string.format("  [%s] %s: %s", h.kind, h.speaker, Truncate(h.text, 80)))
    end
  elseif cmd == "ignore" then
    local name = rest:match("^%s*(.-)%s*$")
    if name == "" then
      print("|cFFFFD100BanterCombat|r ignore <name> | ignore list | ignore clear")
      return
    end
    if name:lower() == "list" then
      local any = false
      for n in pairs(ignoredNames) do
        print("  " .. n)
        any = true
      end
      if not any then
        print("|cFFFFD100BanterCombat|r (none)")
      end
      return
    end
    if name:lower() == "clear" then
      wipe(ignoredNames)
      print("|cFFFFD100BanterCombat|r ignore cleared")
      return
    end
    local key = Ambiguate(name, "none")
    ignoredNames[key] = true
    print("|cFFFFD100BanterCombat|r ignore +" .. key)
  elseif cmd == "unignore" then
    local name = rest:match("^%s*(.-)%s*$")
    if name == "" then
      return
    end
    local key = Ambiguate(name, "none")
    ignoredNames[key] = nil
    print("|cFFFFD100BanterCombat|r ignore -" .. key)
  else
    print("|cFFFFD100BanterCombat|r " .. L.HELP)
  end
end

_G[addonName] = ns
