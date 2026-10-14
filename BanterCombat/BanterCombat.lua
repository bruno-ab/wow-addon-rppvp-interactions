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
local EnsureTestButton

-- Hot-path locals. bit exists on 1.15 and on the Forever 1.60 beta; keep a fallback.
local band = bit and bit.band
if not band then
  band = function(a, b)
    local result, place = 0, 1
    a, b = tonumber(a) or 0, tonumber(b) or 0
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then
        result = result + place
      end
      a = math.floor(a / 2)
      b = math.floor(b / 2)
      place = place * 2
    end
    return result
  end
end
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

local function SpeechPack()
  if Data.ActiveSpeech then
    return Data.ActiveSpeech()
  end
  return Data.Speech
end

local function RarityBadge(rarity)
  if rarity == "common" then
    return L.RARITY_COMMON
  end
  if rarity == "rare" then
    return L.RARITY_UNCOMMON
  end
  if rarity == "epic" then
    return L.RARITY_EPIC
  end
  if rarity == "legendary" then
    return L.RARITY_LEGENDARY
  end
  return nil
end

local function FormatTemplate(text, ctx)
  if not text then
    return ""
  end
  ctx = ctx or {}
  local raceLabel = (ctx.race and Data.RaceLabel(ctx.race)) or ctx.race or "?"
  local classLabel = (ctx.class and Data.ClassLabel(ctx.class)) or ctx.class or "?"
  text = text:gsub("{race}", raceLabel)
  text = text:gsub("{class}", classLabel)
  text = text:gsub("{name}", ctx.name or "?")
  text = text:gsub("{kills}", tostring(ctx.kills or 0))
  text = text:gsub("{deaths}", tostring(ctx.deaths or 0))
  text = text:gsub("{streak}", tostring(ctx.streak or 0))
  local female = ctx.sex == 3
  text = text:gsub("{g:([^|}]+)|([^}]+)}", function(masc, fem)
    if female then
      return fem
    end
    return masc
  end)
  if ns.Genderize then
    text = ns.Genderize(text, ctx.sex)
  end
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
local function CustomLine(bucket)
  local settings = Options.Get()
  local list = bucket == "epic" and settings.customEpic or settings.customCommon
  if type(list) ~= "table" or #list == 0 or math.random(1, 2) ~= 1 then
    return nil
  end
  return Pick(list)
end

local function CurrentTitle()
  local tier = Stats.TitleTier and Stats.TitleTier()
  local titles = tier and SpeechPack().titles
  if titles and type(titles[tier]) == "string" and titles[tier] ~= "" then
    return titles[tier]
  end
  return nil
end

local function SelectKillSpeech(victim, isRevenge, milestoneKind, milestoneValue, milestoneKey, forcedRarity, rival, streakHit)
  local pack = SpeechPack()
  if isRevenge then
    local badge = L.REVENGE
    if rival and ((rival.kills or 0) > 0 or (rival.deaths or 0) > 0) then
      badge = badge .. " " .. L.RIVAL_SCORE:format(rival.kills or 0, rival.deaths or 0)
    end
    return FormatTemplate(Pick(pack.revenge), victim), "revenge", badge, "revenge"
  end

  if milestoneKind and milestoneValue and milestoneKey then
    local special = Stats.GetMilestoneSpeech(milestoneKind, milestoneValue, milestoneKey)
    if special then
      local label = milestoneKind == "race"
        and Data.RaceLabel(milestoneKey)
        or Data.ClassLabel(milestoneKey)
      local badge = L.MILESTONE:format(milestoneValue, label)
      return FormatTemplate(special, victim), "milestone", badge, "milestone"
    end
  end

  if not forcedRarity and streakHit and pack.streak and pack.streak[streakHit] then
    local streakRarity = "rare"
    if streakHit >= 10 then
      streakRarity = "legendary"
    elseif streakHit >= 5 then
      streakRarity = "epic"
    end
    return FormatTemplate(Pick(pack.streak[streakHit]), victim), streakRarity, L.STREAK:format(streakHit), "streak"
  end

  if not forcedRarity and rival and ((rival.deaths or 0) >= 1 or (rival.kills or 0) >= 2) and pack.rival then
    local ctx = {
      name = victim.name,
      race = victim.race,
      class = victim.class,
      sex = victim.sex,
      kills = rival.kills or 0,
      deaths = rival.deaths or 0,
    }
    return FormatTemplate(Pick(pack.rival), ctx), "rare", L.RIVAL_SCORE:format(ctx.kills, ctx.deaths), "rival"
  end

  local rarity = forcedRarity or RollRarity()
  local speech = pack.kill
  local text
  local usedCustom = false

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
    text = Pick(candidates)
    if not text and forcedRarity == "legendary" then
      local any = {}
      for _, row in ipairs(speech.legendary) do
        if row.text then
          any[#any + 1] = row.text
        end
      end
      text = Pick(any)
    end
    text = text or Pick(speech.common)
  elseif rarity == "epic" then
    if not forcedRarity then
      text = CustomLine("epic")
      usedCustom = text ~= nil
    end
    local _, myClass = UnitClass("player")
    local byMe = speech.epic[myClass]
    if not text and byMe and victim.class and byMe[victim.class] then
      text = Pick(byMe[victim.class])
    end
    if not text and forcedRarity == "epic" and byMe then
      for _, lines in pairs(byMe) do
        text = Pick(lines)
        if text then
          break
        end
      end
    end
    if not text and forcedRarity == "epic" then
      for _, byClass in pairs(speech.epic) do
        if type(byClass) == "table" then
          for _, lines in pairs(byClass) do
            text = Pick(lines)
            if text then
              break
            end
          end
        end
        if text then
          break
        end
      end
    end
    text = text or Pick(speech.common)
  elseif rarity == "rare" then
    if math.random(1, 2) == 1 and victim.race and speech.rare_race[victim.race] then
      text = Pick(speech.rare_race[victim.race])
    elseif victim.class and speech.rare_class[victim.class] then
      text = Pick(speech.rare_class[victim.class])
    elseif victim.race and speech.rare_race[victim.race] then
      text = Pick(speech.rare_race[victim.race])
    end
    if not text and forcedRarity == "rare" then
      for _, lines in pairs(speech.rare_race) do
        text = Pick(lines)
        if text then
          break
        end
      end
    end
    text = text or Pick(speech.common)
  else
    if not forcedRarity then
      text = CustomLine("common")
      usedCustom = text ~= nil
    end
    text = text or Pick(speech.common)
  end

  if not forcedRarity and not usedCustom and rarity == "common" and ns.CurrentZone and pack.zone then
    local zone = ns.CurrentZone()
    local lines = zone and pack.zone[zone]
    if lines then
      local zoneBadge = L.ZONE_ASHENVALE
      if zone == "warsong" then
        zoneBadge = L.ZONE_WARSONG
      elseif zone == "arathi" then
        zoneBadge = L.ZONE_ARATHI
      end
      return FormatTemplate(Pick(lines), victim), "common", zoneBadge, "kill"
    end
  end

  return FormatTemplate(text, victim), rarity, RarityBadge(rarity), "kill"
end

local function SelectDeathSpeech(killer)
  local rarity = RollRarity()
  local speech = SpeechPack().death
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
  return FormatTemplate(text, killer or {}), rarity, RarityBadge(rarity)
end

------------------------------------------------------------
-- Protocol v2: v2|SHOW|proto|speaker|race|class|kind|rarity|badge|text
-- Also accepts v1 for older clients
------------------------------------------------------------
local function EncodeMessage(speaker, race, class, kind, rarity, badge, text, title)
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
    SanitizeField(title or "", 48),
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
      title = parts[11],
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
    title = payload.title,
    announcer = payload.announcer,
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
  local _, _, mKind, mValue, mKey, rival, streakHit = Stats.RecordKill(victim)
  if isRevenge then
    Stats.ClearRevenge()
    Stats.UnlockFeat("revenge")
  end

  local text, rarity, badge, kind = SelectKillSpeech(victim, isRevenge, mKind, mValue, mKey, nil, rival, streakHit)
  kind = kind or "kill"
  if kind == "kill" and rarity == "legendary" then
    Stats.UnlockFeat("legendary")
  end
  local selfInfo = PlayerSelfInfo()
  local payload = {
    speaker = selfInfo.name,
    race = selfInfo.race,
    class = selfInfo.class,
    kind = kind,
    rarity = rarity,
    badge = badge,
    text = text,
    title = CurrentTitle(),
    announcer = Stats.AnnouncerCue and Stats.AnnouncerCue(),
  }

  local zoneName = ""
  if GetRealZoneText then
    zoneName = GetRealZoneText() or ""
  end
  if zoneName == "" and GetZoneText then
    zoneName = GetZoneText() or ""
  end
  local spellName
  local blow = ns._lastBlow
  if blow and victim.guid and blow.guid == victim.guid and type(blow.spell) == "string" then
    spellName = blow.spell
  end
  local _, myClass = UnitClass("player")
  if Stats.RememberChronicle then
    Stats.RememberChronicle({
      name = victim.name,
      race = victim.race,
      class = victim.class,
      zone = zoneName,
      spell = spellName,
      level = UnitLevel and UnitLevel("player") or 0,
      myClass = myClass,
      mySex = UnitSex and UnitSex("player") or nil,
      sex = victim.sex,
    })
  end

  Debug("kill", victim.name, payload.kind, rarity)
  Present(payload, "player")
  MaybeChatAnnounce(text)
  BroadcastPayload(EncodeMessage(
    payload.speaker, payload.race, payload.class, payload.kind, payload.rarity, payload.badge, payload.text, payload.title
  ), victim.name)
  if ns.Achievements and ns.Achievements.OnKill then
    ns.Achievements.OnKill(victim, isRevenge)
  end
end

local function OnPlayerDeath(killer)
  if ns.Achievements and ns.Achievements.OnDeath then
    ns.Achievements.OnDeath()
  end
  local s = Options.Get()
  if not s.enabled then
    return
  end
  if s.showDeaths == false then
    Stats.RecordDeathBy(killer)
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
  local broken = Stats.RecordDeathBy(killer)
  local playerSex = UnitSex and UnitSex("player") or nil
  local ctx = {
    name = killer and killer.name,
    race = killer and killer.race,
    class = killer and killer.class,
    sex = playerSex,
  }
  local text, rarity, badge
  if broken then
    ctx.streak = broken
    text = FormatTemplate(Pick(SpeechPack().streakBreak), ctx)
    rarity = "rare"
    badge = L.STREAK_BREAK
  else
    text, rarity, badge = SelectDeathSpeech(ctx)
  end
  local selfInfo = PlayerSelfInfo()
  local payload = {
    speaker = selfInfo.name,
    race = selfInfo.race,
    class = selfInfo.class,
    kind = "death",
    rarity = rarity,
    badge = badge,
    text = text,
  }
  Debug("death", killer and killer.name or "?", rarity)
  Present(payload, "player")
  MaybeChatAnnounce(text)
  if killer and killer.name then
    BroadcastPayload(EncodeMessage(
      payload.speaker, payload.race, payload.class, payload.kind, payload.rarity, payload.badge, payload.text, nil
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

  if ns.Achievements and ns.Achievements.OnLog then
    local spellId, spellName = select(12, CombatLogGetCurrentEventInfo())
    ns.Achievements.OnLog(subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
  end

  if sourceGUID == playerGUID and destGUID and IsPlayerFlags(destFlags) then
    if subevent == "SWING_DAMAGE" then
      ns._lastBlow = { guid = destGUID }
    elseif subevent == "RANGE_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
      local spellName = select(13, CombatLogGetCurrentEventInfo())
      if type(spellName) == "string" and spellName ~= "" then
        ns._lastBlow = { guid = destGUID, spell = spellName }
      end
    end
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
        if UnitSex then
          victim.sex = victim.sex or UnitSex("target")
        end
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
    title = (data.title ~= "" and data.title) or nil,
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
    local label = row.key
    if type(labelLookup) == "function" then
      label = labelLookup(row.key) or row.key
    elseif labelLookup and labelLookup[row.key] then
      label = labelLookup[row.key]
    end
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
    if ns.ApplySavedLocale then
      ns.ApplySavedLocale()
    end
    RegisterPrefix(PREFIX)
  elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    playerGUID = UnitGUID("player")
    if event == "PLAYER_LOGIN" then
      if math.randomseed then
        math.randomseed(time() + (playerGUID and tonumber(playerGUID:sub(-6), 16) or 0))
      end
      if UI.ApplySavedPosition then
        UI.ApplySavedPosition()
      end
      print("|cFFFFD100BanterCombat|r " .. L.LOADED)
      EnsureTestButton()
      if ns.Compendium and ns.Compendium.Init then
        ns.Compendium.Init()
      end
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

local PREVIEW_ORDER = { "kill", "common", "rare", "epic", "legendary", "revenge", "milestone", "death" }
local previewIndex = 0
local testStreak = 0
local testMulti = 0
local testAnnounceAt = 0

local function resetTestAnnouncer()
  testStreak = 0
  testMulti = 0
  testAnnounceAt = 0
end

local function nextTestAnnouncer()
  local now = GetTime and GetTime() or 0
  testStreak = testStreak + 1
  if testAnnounceAt > 0 and (now - testAnnounceAt) <= 12 then
    testMulti = testMulti + 1
  else
    testMulti = 1
  end
  testAnnounceAt = now
  if Stats.CueFor then
    return Stats.CueFor(testStreak, testMulti)
  end
  return "FirstBlood"
end

function ns.Preview(kind)
  local classToken = select(2, UnitClass("player"))
  local speaker = UnitName("player") or "?"
  local sex = UnitSex and UnitSex("player") or nil
  if kind == "revenge" then
    Present({
      speaker = speaker,
      text = Pick(SpeechPack().revenge),
      badge = L.REVENGE,
      class = classToken,
      kind = "revenge",
      rarity = "revenge",
    }, "player")
  elseif kind == "milestone" then
    Present({
      speaker = speaker,
      text = Stats.GetMilestoneSpeech("race", 50, "Orc") or "Marco de teste",
      badge = L.MILESTONE:format(50, Data.RaceLabel("Orc")),
      class = classToken,
      kind = "milestone",
      rarity = "milestone",
    }, "player")
  elseif kind == "rival" then
    local ctx = { name = "AlvoTeste", race = "Orc", class = "MAGE", sex = 3, kills = 4, deaths = 2 }
    Present({
      speaker = speaker,
      text = FormatTemplate(Pick(SpeechPack().rival), ctx),
      badge = L.RIVAL_SCORE:format(4, 2),
      class = classToken,
      kind = "rival",
      rarity = "rare",
      title = SpeechPack().titles and SpeechPack().titles[3],
    }, "player")
  elseif kind == "streak" then
    Present({
      speaker = speaker,
      text = FormatTemplate(Pick(SpeechPack().streak[5]), { sex = UnitSex and UnitSex("player") }),
      badge = L.STREAK:format(5),
      class = classToken,
      kind = "streak",
      rarity = "epic",
      title = SpeechPack().titles and SpeechPack().titles[5],
    }, "player")
  elseif kind == "zone" then
    local zone = (ns.CurrentZone and ns.CurrentZone()) or "warsong"
    local lines = SpeechPack().zone and SpeechPack().zone[zone] or SpeechPack().zone.warsong
    local zoneBadge = L.ZONE_WARSONG
    if zone == "arathi" then
      zoneBadge = L.ZONE_ARATHI
    elseif zone == "ashenvale" then
      zoneBadge = L.ZONE_ASHENVALE
    end
    Present({
      speaker = speaker,
      text = FormatTemplate(Pick(lines), { name = "AlvoTeste", race = "Orc", class = "MAGE" }),
      badge = zoneBadge,
      class = classToken,
      kind = "kill",
      rarity = "common",
    }, "player")
  elseif kind == "death" then
    resetTestAnnouncer()
    local killer = { name = "AlvoTeste", race = "Orc", class = "MAGE", sex = sex }
    local text, rarity, badge = SelectDeathSpeech(killer)
    Present({
      speaker = killer.name,
      text = text,
      badge = badge,
      class = killer.class,
      kind = "death",
      rarity = rarity,
    }, "player")
  elseif kind == "common" or kind == "rare" or kind == "epic" or kind == "legendary" then
    local victim = { name = "AlvoTeste", race = "Orc", class = "MAGE", sex = sex }
    local text, rarity, badge = SelectKillSpeech(victim, false, nil, nil, nil, kind)
    Present({
      speaker = speaker,
      text = text,
      badge = badge,
      class = classToken,
      kind = "kill",
      rarity = rarity,
    }, "player")
  else
    local victim = { name = "AlvoTeste", race = "Orc", class = "MAGE", sex = sex }
    local text, rarity, badge = SelectKillSpeech(victim, false, nil, nil, nil)
    Present({
      speaker = speaker,
      text = text,
      badge = badge,
      class = classToken,
      kind = "kill",
      rarity = rarity,
      announcer = nextTestAnnouncer(),
    }, "player")
  end
end

local function PreviewLabel(kind)
  if kind == "common" then
    return L.TEST_COMMON
  end
  if kind == "rare" then
    return L.TEST_UNCOMMON
  end
  if kind == "epic" then
    return L.TEST_EPIC
  end
  if kind == "legendary" then
    return L.TEST_LEGENDARY
  end
  if kind == "revenge" then
    return L.TEST_REVENGE
  end
  if kind == "milestone" then
    return L.TEST_MILESTONE
  end
  if kind == "death" then
    return L.TEST_DEATH
  end
  return L.TEST_KILL
end

local testButton

function EnsureTestButton()
  if testButton then
    return
  end
  local ok, button = pcall(CreateFrame, "Button", "BanterCombatTestButton", UIParent, "UIPanelButtonTemplate")
  if not ok or not button then
    button = CreateFrame("Button", "BanterCombatTestButton", UIParent)
  end
  if not button.SetText then
    local font = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    font:SetPoint("CENTER")
    button.SetText = function(self, text)
      font:SetText(text)
    end
  end
  button:SetSize(148, 26)
  button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -180)
  button:SetFrameStrata("HIGH")
  button:SetClampedToScreen(true)
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForDrag("RightButton")
  button:SetScript("OnDragStart", function(self)
    if InCombatLockdown and InCombatLockdown() then
      return
    end
    self:StartMoving()
  end)
  button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)
  button:SetText(L.TEST_BUTTON)
  button:SetScript("OnClick", function(self)
    previewIndex = (previewIndex % #PREVIEW_ORDER) + 1
    local kind = PREVIEW_ORDER[previewIndex]
    self:SetText(PreviewLabel(kind))
    ns.Preview(kind)
  end)
  button:SetScript("OnEnter", function(self)
    if not GameTooltip then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.TEST_BUTTON, 1, 0.82, 0)
    GameTooltip:AddLine(L.TEST_TOOLTIP, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)
  testButton = button
end

local announcePreview = 0
local ANNOUNCE_PREVIEW = {
  { id = "FirstBlood", label = "FIRST BLOOD" },
  { id = "DoubleKill", label = "DOUBLE KILL" },
  { id = "TripleKill", label = "TRIPLE KILL" },
  { id = "Rampage", label = "RAMPAGE" },
  { id = "Massacre", label = "MASSACRE" },
  { id = "KillingSpree", label = "KILLING SPREE" },
  { id = "Dominating", label = "DOMINATING" },
  { id = "MegaKill", label = "MEGA KILL" },
  { id = "Ownage", label = "OWNAGE" },
  { id = "Mayhem", label = "MAYHEM" },
  { id = "Carnage", label = "CARNAGE" },
  { id = "Godlike", label = "GODLIKE" },
}

function ns.PreviewAnnouncer()
  announcePreview = (announcePreview % #ANNOUNCE_PREVIEW) + 1
  local row = ANNOUNCE_PREVIEW[announcePreview]
  local classToken = select(2, UnitClass("player"))
  Present({
    speaker = UnitName("player") or "?",
    text = row.label,
    badge = row.label,
    class = classToken,
    kind = "kill",
    rarity = "common",
    announcer = row.id,
  }, "player")
end

SLASH_BANTERCOMBAT1 = "/banter"
SLASH_BANTERCOMBAT2 = "/bantercombat"
SlashCmdList.BANTERCOMBAT = function(msg)
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = (cmd or ""):lower()
  rest = rest or ""

  if cmd == "test" or cmd == "kill" or cmd == "common" or cmd == "rare" or cmd == "uncommon" or cmd == "epic" or cmd == "legendary" then
    local sub = rest:lower()
    if cmd == "uncommon" or sub == "uncommon" or sub == "incomum" then
      ns.Preview("rare")
    elseif cmd == "common" or cmd == "rare" or cmd == "epic" or cmd == "legendary" then
      ns.Preview(cmd)
    elseif sub == "common" or sub == "rare" or sub == "epic" or sub == "legendary" or sub == "revenge" or sub == "milestone" or sub == "death" or sub == "kill" then
      ns.Preview(sub)
    else
      ns.Preview("kill")
    end
  elseif cmd == "revenge" then
    ns.Preview("revenge")
  elseif cmd == "rival" then
    ns.Preview("rival")
  elseif cmd == "streak" then
    ns.Preview("streak")
  elseif cmd == "zone" then
    ns.Preview("zone")
  elseif cmd == "lines" then
    if Options.ToggleLines then
      Options.ToggleLines()
    end
  elseif cmd == "announce" or cmd == "blood" then
    ns.PreviewAnnouncer()
  elseif cmd == "milestone" then
    ns.Preview("milestone")
  elseif cmd == "death" then
    ns.Preview("death")
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
    PrintTopMap(L.TOP_RACE, db.kills and db.kills.Race, Data.RaceLabel, 5)
    PrintTopMap(L.TOP_CLASS, db.kills and db.kills.Class, Data.ClassLabel, 5)
  elseif cmd == "compendium" or cmd == "comp" or cmd == "book" then
    if ns.Compendium and ns.Compendium.Toggle then
      ns.Compendium.Toggle()
    end
  elseif cmd == "locale" then
    local code = rest:match("^(%S+)") or ""
    if code == "" then
      print("|cFFFFD100BanterCombat|r " .. L.LOCALE_CURRENT:format(ns.LocaleCode or "?"))
    else
      Options.Set("locale", code)
      if ns.ApplySavedLocale then
        ns.ApplySavedLocale()
      end
      print("|cFFFFD100BanterCombat|r " .. L.LOCALE_CURRENT:format(ns.LocaleCode or "?"))
    end
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
