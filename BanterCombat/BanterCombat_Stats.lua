local addonName, ns = ...
ns = ns or {}
ns.Stats = ns.Stats or {}

local Stats = ns.Stats
local Data = ns.Data

local DB_VERSION = 1

local function ensureDB()
  if type(BanterCombatDB) ~= "table" then
    BanterCombatDB = {}
  end
  local db = BanterCombatDB
  if db.version ~= DB_VERSION then
    db.version = DB_VERSION
  end
  db.kills = db.kills or {}
  db.kills.Race = db.kills.Race or {}
  db.kills.Class = db.kills.Class or {}
  db.deaths = db.deaths or {}
  db.deaths.Race = db.deaths.Race or {}
  db.deaths.Class = db.deaths.Class or {}
  db.totalKills = db.totalKills or 0
  db.totalDeaths = db.totalDeaths or 0
  -- lastKiller: { name, race, class, guid, time }
  return db
end

function Stats.GetDB()
  return ensureDB()
end

function Stats.RecordDeathBy(killer)
  local db = ensureDB()
  db.totalDeaths = (db.totalDeaths or 0) + 1
  if killer and killer.race then
    db.deaths.Race[killer.race] = (db.deaths.Race[killer.race] or 0) + 1
  end
  if killer and killer.class then
    db.deaths.Class[killer.class] = (db.deaths.Class[killer.class] or 0) + 1
  end
  if killer and killer.name then
    db.lastKiller = {
      name = killer.name,
      race = killer.race,
      class = killer.class,
      guid = killer.guid,
      time = time(),
    }
  end
end

--- @return number raceCount, number classCount, string|nil milestoneKind, number|nil milestoneValue, string|nil milestoneKey
function Stats.RecordKill(victim)
  local db = ensureDB()
  db.totalKills = (db.totalKills or 0) + 1
  local raceCount, classCount = 0, 0
  if victim and victim.race then
    db.kills.Race[victim.race] = (db.kills.Race[victim.race] or 0) + 1
    raceCount = db.kills.Race[victim.race]
  end
  if victim and victim.class then
    db.kills.Class[victim.class] = (db.kills.Class[victim.class] or 0) + 1
    classCount = db.kills.Class[victim.class]
  end

  -- Limpa vingança se pagamos a dívida
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
      -- Classe tem prioridade se empatar no mesmo abate
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
  local db = ensureDB()
  db.lastKiller = nil
end

function Stats.GetMilestoneSpeech(kind, value, key)
  local pack = Data.Speech.milestones[kind]
  if not pack or not pack[value] then
    return nil
  end
  return pack[value][key]
end

_G[addonName] = ns
