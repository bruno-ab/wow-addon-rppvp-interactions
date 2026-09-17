local addonName, ns = ...
ns = ns or {}

local Data = ns.Data
local Stats = ns.Stats
local UI = ns.UI

local PREFIX = "BANTER_MSG"
local PROTOCOL = "v1"

local playerGUID
local playerName
local eventFrame

local bit_band = bit.band
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x00000010

------------------------------------------------------------
-- Compat messaging (Classic Era)
------------------------------------------------------------
local function RegisterPrefix(prefix)
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(prefix)
  end
end

local function SendWhisperAddon(msg, target)
  if not target or target == "" or not msg then
    return
  end
  target = Ambiguate(target, "none")
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    C_ChatInfo.SendAddonMessage(PREFIX, msg, "WHISPER", target)
  elseif SendAddonMessage then
    SendAddonMessage(PREFIX, msg, "WHISPER", target)
  end
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function IsPlayerFlags(flags)
  if not flags then
    return false
  end
  return bit_band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
end

local function IsHostileFlags(flags)
  if not flags then
    return false
  end
  return bit_band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
end

local function InfoFromGUID(guid)
  if not guid or not GetPlayerInfoByGUID then
    return nil
  end
  local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
  if not name then
    return nil
  end
  if realm and realm ~= "" and not name:find("-", 1, true) then
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
  local raceLabel = (ctx.race and Data.RACE_LABEL[ctx.race]) or ctx.race or "?"
  local classLabel = (ctx.class and Data.CLASS_LABEL[ctx.class]) or ctx.class or "?"
  text = text:gsub("{race}", raceLabel)
  text = text:gsub("{class}", classLabel)
  text = text:gsub("{name}", ctx.name or "?")
  return text
end

------------------------------------------------------------
-- Speech selection
------------------------------------------------------------
local function SelectKillSpeech(victim, isRevenge, milestoneKind, milestoneValue, milestoneKey)
  if isRevenge then
    return Pick(Data.Speech.revenge), "revenge", "VINGANÇA"
  end

  if milestoneKind and milestoneValue and milestoneKey then
    local special = Stats.GetMilestoneSpeech(milestoneKind, milestoneValue, milestoneKey)
    if special then
      local badge = ("CONQUISTA · %d %s"):format(
        milestoneValue,
        milestoneKind == "race" and (Data.RACE_LABEL[milestoneKey] or milestoneKey)
          or (Data.CLASS_LABEL[milestoneKey] or milestoneKey)
      )
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
      if row.class and row.class ~= myClass then
        ok = false
      end
      if row.vsClass and victim.class and row.vsClass ~= victim.class then
        ok = false
      end
      if row.race and row.race ~= myRace then
        ok = false
      end
      if row.vsRace and victim.race and row.vsRace ~= victim.race then
        ok = false
      end
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
-- Protocol: v1|SHOW|speaker|race|class|kind|rarity|badge|text
------------------------------------------------------------
local function EncodeMessage(speaker, race, class, kind, rarity, badge, text)
  -- Use \031 as field sep internally escaped from pipes in text
  local clean = tostring(text or ""):gsub("|", "/")
  badge = tostring(badge or ""):gsub("|", "/")
  return table.concat({
    PROTOCOL,
    "SHOW",
    speaker or "?",
    race or "",
    class or "",
    kind or "kill",
    rarity or "common",
    badge,
    clean,
  }, "\031")
end

local function DecodeMessage(msg)
  if not msg or msg == "" then
    return nil
  end
  local parts = { strsplit("\031", msg) }
  if parts[1] ~= PROTOCOL or parts[2] ~= "SHOW" then
    return nil
  end
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

local function Present(payload, unit)
  UI.Show({
    speaker = payload.speaker,
    text = payload.text,
    badge = payload.badge,
    class = payload.class,
    unit = unit,
  })
end

------------------------------------------------------------
-- Combat resolution
------------------------------------------------------------
local function OnPlayerKill(victim)
  if not victim or not victim.name then
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

  Present(payload, "player")
  SendWhisperAddon(EncodeMessage(
    payload.speaker, payload.race, payload.class, payload.kind, payload.rarity, payload.badge, payload.text
  ), victim.name)
end

local function OnPlayerDeath(killer)
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
  Present(payload, "player")
  if killer and killer.name then
    SendWhisperAddon(EncodeMessage(
      payload.speaker, payload.race, payload.class, payload.kind, payload.rarity, "", payload.text
    ), killer.name)
  end
end

local function HandleCombatLog()
  local timestamp, subevent, hideCaster,
    sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
    destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

  if not playerGUID then
    playerGUID = UnitGUID("player")
  end

  -- Vitória: PARTY_KILL (honor / player kill credit)
  if subevent == "PARTY_KILL" then
    if sourceGUID == playerGUID and IsPlayerFlags(destFlags) then
      local victim = InfoFromGUID(destGUID) or {
        name = destName,
        guid = destGUID,
      }
      -- Enriquecer se target atual for a vítima
      if UnitExists("target") and UnitGUID("target") == destGUID then
        local _, class = UnitClass("target")
        local _, race = UnitRace("target")
        victim.class = victim.class or class
        victim.race = victim.race or race
        victim.name = victim.name or UnitName("target")
      end
      OnPlayerKill(victim)
    end
    return
  end

  -- Morte do jogador local
  if subevent == "UNIT_DIED" and destGUID == playerGUID then
    -- Tenta achar o killer pelo source do evento anterior não está disponível;
    -- usa last damaging approach via sourceName se hostile player on CLEU FEIGN etc.
    -- Em UNIT_DIED source costuma ser nil; usamos ambiente: target se for quem nos matou é raro.
    -- Melhor esforço: GetPlayerInfo não ajuda. Guardamos last hostile attacker.
    local killer = ns._lastHostileAttacker
    if killer and killer.guid == playerGUID then
      killer = nil
    end
    OnPlayerDeath(killer)
    ns._lastHostileAttacker = nil
    return
  end

  -- Rastreia último atacante hostil jogador (para death attribution)
  if sourceGUID and sourceGUID ~= playerGUID and destGUID == playerGUID and IsPlayerFlags(sourceFlags) then
    if subevent:find("_DAMAGE") or subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
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
  local data = DecodeMessage(message)
  if not data then
    return
  end
  -- Evita eco da própria mensagem
  if sender and Ambiguate(sender, "none") == Ambiguate(UnitName("player"), "none") then
    return
  end
  Present({
    speaker = data.speaker,
    text = data.text,
    badge = (data.badge ~= "" and data.badge) or nil,
    class = data.class,
  }, nil)
end

local function OnEvent(self, event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name ~= addonName then
      return
    end
    Stats.GetDB()
    RegisterPrefix(PREFIX)
  elseif event == "PLAYER_LOGIN" then
    playerGUID = UnitGUID("player")
    playerName = UnitName("player")
    math.randomseed(time() + (playerGUID and tonumber(playerGUID:sub(-6), 16) or 0))
    print("|cFFFFD100BanterCombat|r carregado. /banter test | /banter stats")
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    HandleCombatLog()
  elseif event == "CHAT_MSG_ADDON" then
    OnAddonMessage(...)
  end
end

eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", OnEvent)

SLASH_BANTERCOMBAT1 = "/banter"
SLASH_BANTERCOMBAT2 = "/bantercombat"
SlashCmdList.BANTERCOMBAT = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  if msg == "test" or msg == "kill" then
    local victim = { name = "AlvoTeste", race = "Orc", class = "MAGE" }
    local text, rarity, badge = SelectKillSpeech(victim, false, nil, nil, nil)
    Present({
      speaker = UnitName("player"),
      text = text .. "  |cffaaaaaa(" .. rarity .. ")|r",
      badge = badge,
      class = select(2, UnitClass("player")),
    }, "player")
  elseif msg == "revenge" then
    Present({
      speaker = UnitName("player"),
      text = Pick(Data.Speech.revenge),
      badge = "VINGANÇA",
      class = select(2, UnitClass("player")),
    }, "player")
  elseif msg == "milestone" then
    Present({
      speaker = UnitName("player"),
      text = Stats.GetMilestoneSpeech("race", 50, "Orc") or "Marco de teste",
      badge = "CONQUISTA · 50 Orcs",
      class = select(2, UnitClass("player")),
    }, "player")
  elseif msg == "stats" then
    local db = Stats.GetDB()
    print(("|cFFFFD100BanterCombat|r Kills=%d Deaths=%d"):format(db.totalKills or 0, db.totalDeaths or 0))
    if db.lastKiller then
      print("  Último killer:", db.lastKiller.name, db.lastKiller.race, db.lastKiller.class)
    end
  elseif msg == "hide" then
    UI.HideNow()
  else
    print("|cFFFFD100BanterCombat|r comandos: test, revenge, milestone, stats, hide")
  end
end

_G[addonName] = ns
