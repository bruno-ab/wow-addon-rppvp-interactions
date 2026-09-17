local addonName, ns = ...
ns = ns or {}
ns.Stats = ns.Stats or {}

local Stats = ns.Stats
local Data = ns.Data

local DB_VERSION = 2

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

  if from < 2 then
    -- v2: settings + scrubbed counters
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
  end
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

  if db.lastKiller and victim and victim.name then
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
  return raceCount, classCount, hitKind, hitValue, hitKey
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
  local pack = Data.Speech.milestones[kind]
  if not pack or not pack[value] then
    return nil
  end
  return pack[value][key]
end

_G[addonName] = ns
