local addonName, ns = ...
ns = ns or {}
ns.Stats = ns.Stats or {}

local Stats = ns.Stats
local Data = ns.Data

local DB_VERSION = 3

local VALID_RACE = {
  Human = true, Dwarf = true, NightElf = true, Gnome = true,
  Orc = true, Scourge = true, Tauren = true, Troll = true,
}
local VALID_CLASS = {
  WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
  SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}

local function scrubCounterMap(map, valid)
  if type(map) ~= "table" then
    return {}
  end
  local out = {}
  for k, v in pairs(map) do
    if type(k) == "string" and valid[k] and type(v) == "number" and v >= 0 then
      out[k] = math.floor(v)
    end
  end
  return out
end

local function nameKey(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  local key = name
  if Ambiguate then
    key = Ambiguate(name, "none") or name
  end
  key = key:lower()
  if key == "" then
    return nil
  end
  return key
end

local function displayName(name)
  if Ambiguate then
    return Ambiguate(name, "none") or name
  end
  return name
end

local function scrubLines(list)
  if type(list) ~= "table" then
    return {}
  end
  local out = {}
  for i = 1, math.min(#list, 8) do
    if type(list[i]) == "string" then
      local text = list[i]:gsub("|", ""):gsub("[\001-\031]", " ")
      text = text:match("^%s*(.-)%s*$") or ""
      if text ~= "" then
        out[#out + 1] = text:sub(1, 120)
      end
    end
  end
  return out
end

local function scrubRivals(map)
  if type(map) ~= "table" then
    return {}
  end
  local out = {}
  for k, v in pairs(map) do
    if type(k) == "string" and #k <= 64 and type(v) == "table" and type(v.name) == "string" and v.name ~= "" then
      local kills = math.max(0, math.floor(tonumber(v.kills) or 0))
      local deaths = math.max(0, math.floor(tonumber(v.deaths) or 0))
      if kills + deaths > 0 then
        out[k] = {
          name = v.name:sub(1, 48),
          kills = kills,
          deaths = deaths,
          last = math.max(0, math.floor(tonumber(v.last) or 0)),
          race = (type(v.race) == "string" and VALID_RACE[v.race]) and v.race or nil,
          class = (type(v.class) == "string" and VALID_CLASS[v.class]) and v.class or nil,
        }
      end
    end
  end
  return out
end

local function scrubFeats(map)
  if type(map) ~= "table" then
    return {}
  end
  local out = {}
  for k, v in pairs(map) do
    if type(k) == "string" and #k <= 40 and type(v) == "number" and v > 0 then
      out[k] = math.floor(v)
    end
  end
  return out
end

local function scrubLastKiller(lk)
  if type(lk) ~= "table" or type(lk.name) ~= "string" or lk.name == "" then
    return nil
  end
  return {
    name = tostring(lk.name),
    race = (type(lk.race) == "string" and VALID_RACE[lk.race]) and lk.race or nil,
    class = (type(lk.class) == "string" and VALID_CLASS[lk.class]) and lk.class or nil,
    guid = type(lk.guid) == "string" and lk.guid or nil,
    time = type(lk.time) == "number" and lk.time or time(),
  }
end

local function ensureDB()
  if type(BanterCombatDB) ~= "table" then
    BanterCombatDB = {}
  end
  local db = BanterCombatDB
  local from = tonumber(db.version) or 0

  db.kills = type(db.kills) == "table" and db.kills or {}
  db.kills.Race = scrubCounterMap(db.kills.Race, VALID_RACE)
  db.kills.Class = scrubCounterMap(db.kills.Class, VALID_CLASS)
  db.deaths = type(db.deaths) == "table" and db.deaths or {}
  db.deaths.Race = scrubCounterMap(db.deaths.Race, VALID_RACE)
  db.deaths.Class = scrubCounterMap(db.deaths.Class, VALID_CLASS)
  db.totalKills = math.max(0, math.floor(tonumber(db.totalKills) or 0))
  db.totalDeaths = math.max(0, math.floor(tonumber(db.totalDeaths) or 0))
  db.lastKiller = scrubLastKiller(db.lastKiller)
  db.settings = type(db.settings) == "table" and db.settings or {}
  db.settings.customCommon = scrubLines(db.settings.customCommon)
  db.settings.customEpic = scrubLines(db.settings.customEpic)
  db.rivals = scrubRivals(db.rivals)
  db.feats = scrubFeats(db.feats)
  db.streak = math.max(0, math.floor(tonumber(db.streak) or 0))
  db.bestStreak = math.max(db.streak, math.floor(tonumber(db.bestStreak) or 0))
  local tier = tonumber(db.titleStreak)
  if tier ~= 3 and tier ~= 5 and tier ~= 10 or db.streak < (tier or 0) then
    db.titleStreak = nil
  else
    db.titleStreak = tier
  end

  if from < 2 then
    -- v2: settings + scrubbed counters. v3: rivals, feats, streak.
    db.version = DB_VERSION
  else
    db.version = DB_VERSION
  end
  return db
end

function Stats.GetDB()
  return ensureDB()
end

function Stats.IsValidRace(race)
  return type(race) == "string" and VALID_RACE[race] or false
end

function Stats.IsValidClass(class)
  return type(class) == "string" and VALID_CLASS[class] or false
end

local function pruneRivals(db)
  local rows = {}
  for key, row in pairs(db.rivals) do
    rows[#rows + 1] = { key = key, last = row.last or 0 }
  end
  if #rows <= 30 then
    return
  end
  table.sort(rows, function(a, b)
    return a.last > b.last
  end)
  for i = 31, #rows do
    db.rivals[rows[i].key] = nil
  end
end

function Stats.TouchRival(person, side)
  if not person or type(person.name) ~= "string" then
    return nil
  end
  local key = nameKey(person.name)
  if not key or (side ~= "kills" and side ~= "deaths") then
    return nil
  end
  local db = ensureDB()
  local row = db.rivals[key]
  if not row then
    row = { name = displayName(person.name), kills = 0, deaths = 0, last = 0 }
    db.rivals[key] = row
  end
  row.name = displayName(person.name)
  row[side] = (row[side] or 0) + 1
  row.last = time()
  if Stats.IsValidRace(person.race) then
    row.race = person.race
  end
  if Stats.IsValidClass(person.class) then
    row.class = person.class
  end
  pruneRivals(db)
  return row
end

function Stats.UnlockFeat(id)
  if type(id) ~= "string" or id == "" then
    return false
  end
  local db = ensureDB()
  if db.feats[id] then
    return false
  end
  db.feats[id] = time()
  return true
end

function Stats.FeatTime(id)
  local db = ensureDB()
  return db.feats[id]
end

local function bumpStreak()
  local db = ensureDB()
  db.streak = (db.streak or 0) + 1
  if db.streak > (db.bestStreak or 0) then
    db.bestStreak = db.streak
  end
  local hit
  if db.streak == 3 or db.streak == 5 or db.streak == 10 then
    hit = db.streak
    db.titleStreak = hit
    Stats.UnlockFeat("streak" .. hit)
  end
  return db.streak, hit
end

local multiCount = 0
local lastAnnounceAt = 0
local MULTI_WINDOW = 12

function Stats.ResetAnnouncer()
  multiCount = 0
  lastAnnounceAt = 0
end

function Stats.AnnouncerCue()
  local streak = ensureDB().streak or 0
  local now = GetTime and GetTime() or 0
  if lastAnnounceAt > 0 and (now - lastAnnounceAt) <= MULTI_WINDOW then
    multiCount = multiCount + 1
  else
    multiCount = 1
  end
  lastAnnounceAt = now

  if streak <= 1 then
    return "FirstBlood"
  end
  if streak >= 9 then
    return "Godlike"
  end
  if multiCount >= 2 then
    if multiCount == 2 then
      return "DoubleKill"
    end
    if multiCount == 3 then
      return "TripleKill"
    end
    if multiCount == 4 then
      return "Rampage"
    end
    return "Massacre"
  end
  if streak == 3 then
    return "KillingSpree"
  end
  if streak == 4 then
    return "Dominating"
  end
  if streak == 5 then
    return "MegaKill"
  end
  if streak == 6 then
    return "Ownage"
  end
  if streak == 7 then
    return "Mayhem"
  end
  if streak == 8 then
    return "Carnage"
  end
  return nil
end

function Stats.BreakStreak()
  local db = ensureDB()
  local prev = db.streak or 0
  db.streak = 0
  db.titleStreak = nil
  Stats.ResetAnnouncer()
  if prev >= 3 then
    return prev
  end
  return nil
end

function Stats.TitleTier()
  local tier = ensureDB().titleStreak
  if tier == 3 or tier == 5 or tier == 10 then
    return tier
  end
  return nil
end

function Stats.RivalList()
  local rows = {}
  for _, row in pairs(ensureDB().rivals) do
    rows[#rows + 1] = row
  end
  table.sort(rows, function(a, b)
    return (a.last or 0) > (b.last or 0)
  end)
  return rows
end

function Stats.RecordDeathBy(killer)
  local db = ensureDB()
  db.totalDeaths = db.totalDeaths + 1
  if killer and Stats.IsValidRace(killer.race) then
    db.deaths.Race[killer.race] = (db.deaths.Race[killer.race] or 0) + 1
  end
  if killer and Stats.IsValidClass(killer.class) then
    db.deaths.Class[killer.class] = (db.deaths.Class[killer.class] or 0) + 1
  end
  if killer and type(killer.name) == "string" and killer.name ~= "" then
    db.lastKiller = scrubLastKiller(killer)
    Stats.TouchRival(killer, "deaths")
  end
  return Stats.BreakStreak()
end

function Stats.RecordKill(victim)
  local db = ensureDB()
  db.totalKills = db.totalKills + 1
  local raceCount, classCount = 0, 0
  if victim and Stats.IsValidRace(victim.race) then
    db.kills.Race[victim.race] = (db.kills.Race[victim.race] or 0) + 1
    raceCount = db.kills.Race[victim.race]
  end
  if victim and Stats.IsValidClass(victim.class) then
    db.kills.Class[victim.class] = (db.kills.Class[victim.class] or 0) + 1
    classCount = db.kills.Class[victim.class]
  end

  if db.lastKiller and victim and victim.name and Ambiguate then
    if Ambiguate(db.lastKiller.name, "none") == Ambiguate(victim.name, "none") then
      db.lastKiller = nil
    end
  end

  local hitKind, hitValue, hitKey
  for _, m in ipairs(Data.MILESTONES) do
    if raceCount == m then
      hitKind, hitValue, hitKey = "race", m, victim.race
    end
    if classCount == m then
      hitKind, hitValue, hitKey = "class", m, victim.class
    end
  end
  if raceCount == 1 and victim and victim.race then
    Stats.UnlockFeat("race:" .. victim.race)
  end
  if classCount == 1 and victim and victim.class then
    Stats.UnlockFeat("class:" .. victim.class)
  end
  if hitValue == 100 then
    Stats.UnlockFeat("milestone100")
  end
  local rival = Stats.TouchRival(victim, "kills")
  local streak, streakHit = bumpStreak()
  return raceCount, classCount, hitKind, hitValue, hitKey, rival, streakHit, streak
end

function Stats.IsRevenge(victimName)
  local db = ensureDB()
  if not db.lastKiller or not db.lastKiller.name or not victimName then
    return false
  end
  return Ambiguate(db.lastKiller.name, "none") == Ambiguate(victimName, "none")
end

function Stats.ClearRevenge()
  ensureDB().lastKiller = nil
end

function Stats.GetMilestoneSpeech(kind, value, key)
  local speech = Data.ActiveSpeech and Data.ActiveSpeech() or Data.Speech
  local pack = speech.milestones[kind]
  if not pack or not pack[value] then
    return nil
  end
  return pack[value][key]
end

_G[addonName] = ns
