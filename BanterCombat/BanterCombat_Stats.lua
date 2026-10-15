local addonName, ns = ...
ns = ns or {}
ns.Stats = ns.Stats or {}

local Stats = ns.Stats
local Data = ns.Data

local DB_VERSION = 4

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

local sessionKills = 0
local sessionDeaths = 0

local function clip(text, maxLen)
  if type(text) ~= "string" then
    return nil
  end
  text = text:gsub("|", ""):gsub("[\001-\031]", " ")
  text = text:match("^%s*(.-)%s*$") or ""
  if text == "" then
    return nil
  end
  return text:sub(1, maxLen)
end

local function countOf(n)
  return math.max(0, math.floor(tonumber(n) or 0))
end

local function contextOf(value)
  if value == "bg" or value == "duel" or value == "world" then
    return value
  end
  return "world"
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
        local meetings = {}
        if type(v.meetings) == "table" then
          local startAt = math.max(1, #v.meetings - 11)
          for i = startAt, #v.meetings do
            local meeting = v.meetings[i]
            if type(meeting) == "table" and (meeting.side == "kills" or meeting.side == "deaths") then
              meetings[#meetings + 1] = {
                side = meeting.side,
                time = math.max(0, math.floor(tonumber(meeting.time) or 0)),
                zone = clip(meeting.zone, 48),
                context = contextOf(meeting.context),
              }
            end
          end
        end
        out[k] = {
          name = v.name:sub(1, 48),
          kills = kills,
          deaths = deaths,
          last = math.max(0, math.floor(tonumber(v.last) or 0)),
          race = (type(v.race) == "string" and VALID_RACE[v.race]) and v.race or nil,
          class = (type(v.class) == "string" and VALID_CLASS[v.class]) and v.class or nil,
          worldKills = countOf(v.worldKills),
          bgKills = countOf(v.bgKills),
          duelKills = countOf(v.duelKills),
          worldDeaths = countOf(v.worldDeaths),
          bgDeaths = countOf(v.bgDeaths),
          duelDeaths = countOf(v.duelDeaths),
          meetings = meetings,
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

local function scrubPlain(text, maxLen)
  return clip(text, maxLen)
end

local function scrubZones(map)
  if type(map) ~= "table" then
    return {}
  end
  local out = {}
  local n = 0
  for k, v in pairs(map) do
    local name = clip(k, 64)
    if name and type(v) == "number" and v > 0 and n < 40 then
      out[name] = math.floor(v)
      n = n + 1
    end
  end
  return out
end

local function scrubChronicle(list)
  if type(list) ~= "table" then
    return {}
  end
  local out = {}
  local limit = math.min(#list, 40)
  for i = 1, limit do
    local row = list[i]
    if type(row) == "table" and type(row.name) == "string" and row.name ~= "" then
      local sex = tonumber(row.sex)
      out[#out + 1] = {
        name = scrubPlain(row.name, 48) or "?",
        race = (type(row.race) == "string" and VALID_RACE[row.race]) and row.race or nil,
        class = (type(row.class) == "string" and VALID_CLASS[row.class]) and row.class or nil,
        zone = scrubPlain(row.zone, 64),
        spell = scrubPlain(row.spell, 48),
        level = math.max(0, math.floor(tonumber(row.level) or 0)),
        myClass = (type(row.myClass) == "string" and VALID_CLASS[row.myClass]) and row.myClass or nil,
        sex = (sex == 2 or sex == 3) and sex or nil,
        mySex = (tonumber(row.mySex) == 2 or tonumber(row.mySex) == 3) and tonumber(row.mySex) or nil,
        time = math.max(0, math.floor(tonumber(row.time) or 0)),
        first = row.first and true or nil,
        test = row.test and true or nil,
        victimLevel = math.max(0, math.floor(tonumber(row.victimLevel) or 0)),
        subzone = scrubPlain(row.subzone, 64),
        context = (row.context == "bg" or row.context == "duel" or row.context == "world") and row.context or nil,
      }
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
  db.settings.lineRevenge = scrubPlain(db.settings.lineRevenge, 120)
  db.settings.lineStreak = scrubPlain(db.settings.lineStreak, 120)
  db.settings.lineDeath = scrubPlain(db.settings.lineDeath, 120)
  local folder = scrubPlain(db.settings.soundFolder, 32)
  if folder then
    folder = folder:gsub("[^%w]", "")
    if folder == "" then
      folder = nil
    end
  end
  db.settings.soundFolder = folder
  db.rivals = scrubRivals(db.rivals)
  db.feats = scrubFeats(db.feats)
  db.chronicle = scrubChronicle(db.chronicle)
  db.zones = scrubZones(db.zones)
  db.streak = math.max(0, math.floor(tonumber(db.streak) or 0))
  db.bestStreak = math.max(db.streak, math.floor(tonumber(db.bestStreak) or 0))
  local tier = tonumber(db.titleStreak)
  if tier ~= 3 and tier ~= 5 and tier ~= 10 or db.streak < (tier or 0) then
    db.titleStreak = nil
  else
    db.titleStreak = tier
  end

  if from < 2 then
    -- v2: settings + scrubbed counters. v3: rivals, feats, streak. v4: chronicle.
    db.version = DB_VERSION
  else
    db.version = DB_VERSION
  end
  return db
end

function Stats.GetDB()
  return ensureDB()
end

function Stats.Chronicle()
  return ensureDB().chronicle
end

function Stats.ClearTestChronicle()
  local db = ensureDB()
  local kept = {}
  for i = 1, #db.chronicle do
    if not db.chronicle[i].test then
      kept[#kept + 1] = db.chronicle[i]
    end
  end
  local hasFirst = false
  for i = 1, #kept do
    if kept[i].first then
      hasFirst = true
      break
    end
  end
  if kept[1] and not hasFirst then
    kept[1].first = true
  end
  db.chronicle = kept
end

function Stats.RememberChronicle(info)
  if type(info) ~= "table" or type(info.name) ~= "string" or info.name == "" then
    return
  end
  local db = ensureDB()
  local sex = tonumber(info.sex)
  local row = {
    name = info.name,
    race = (type(info.race) == "string" and VALID_RACE[info.race]) and info.race or nil,
    class = (type(info.class) == "string" and VALID_CLASS[info.class]) and info.class or nil,
    zone = info.zone,
    spell = info.spell,
    level = tonumber(info.level) or 0,
    myClass = (type(info.myClass) == "string" and VALID_CLASS[info.myClass]) and info.myClass or nil,
    sex = (sex == 2 or sex == 3) and sex or nil,
    mySex = (tonumber(info.mySex) == 2 or tonumber(info.mySex) == 3) and tonumber(info.mySex) or nil,
    time = time(),
    first = #db.chronicle == 0 and true or nil,
    test = info.test and true or nil,
    victimLevel = math.max(0, math.floor(tonumber(info.victimLevel) or 0)),
    subzone = info.subzone,
    context = (info.context == "bg" or info.context == "duel" or info.context == "world") and info.context or nil,
  }
  db.chronicle[#db.chronicle + 1] = row
  while #db.chronicle > 40 do
    if db.chronicle[2] then
      table.remove(db.chronicle, 2)
    else
      break
    end
  end
  db.chronicle = scrubChronicle(db.chronicle)
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

function Stats.TouchRival(person, side, info)
  if not person or type(person.name) ~= "string" then
    return nil
  end
  local key = nameKey(person.name)
  if not key or (side ~= "kills" and side ~= "deaths") then
    return nil
  end
  info = info or {}
  local ctx = contextOf(info.context)
  local db = ensureDB()
  local row = db.rivals[key]
  if not row then
    row = { name = displayName(person.name), kills = 0, deaths = 0, last = 0, meetings = {} }
    db.rivals[key] = row
  end
  row.name = displayName(person.name)
  row[side] = (row[side] or 0) + 1
  row.last = time()
  local prefix = ctx == "bg" and "bg" or ctx == "duel" and "duel" or "world"
  local field = prefix .. (side == "kills" and "Kills" or "Deaths")
  row[field] = (row[field] or 0) + 1
  row.meetings = type(row.meetings) == "table" and row.meetings or {}
  row.meetings[#row.meetings + 1] = {
    side = side,
    time = time(),
    zone = clip(info.zone, 48),
    context = ctx,
  }
  while #row.meetings > 12 do
    table.remove(row.meetings, 1)
  end
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

function Stats.CueFor(streak, multiCount)
  streak = tonumber(streak) or 0
  multiCount = tonumber(multiCount) or 1
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

function Stats.AnnouncerCue()
  local streak = ensureDB().streak or 0
  local now = GetTime and GetTime() or 0
  if lastAnnounceAt > 0 and (now - lastAnnounceAt) <= MULTI_WINDOW then
    multiCount = multiCount + 1
  else
    multiCount = 1
  end
  lastAnnounceAt = now
  return Stats.CueFor(streak, multiCount)
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

function Stats.RecordDeathBy(killer, info)
  local db = ensureDB()
  sessionDeaths = sessionDeaths + 1
  db.totalDeaths = db.totalDeaths + 1
  if killer and Stats.IsValidRace(killer.race) then
    db.deaths.Race[killer.race] = (db.deaths.Race[killer.race] or 0) + 1
  end
  if killer and Stats.IsValidClass(killer.class) then
    db.deaths.Class[killer.class] = (db.deaths.Class[killer.class] or 0) + 1
  end
  if killer and type(killer.name) == "string" and killer.name ~= "" then
    db.lastKiller = scrubLastKiller(killer)
    Stats.TouchRival(killer, "deaths", info)
  end
  return Stats.BreakStreak()
end

function Stats.RecordKill(victim, info)
  local db = ensureDB()
  sessionKills = sessionKills + 1
  db.totalKills = db.totalKills + 1
  info = info or {}
  if type(info.zone) == "string" and info.zone ~= "" then
    db.zones[info.zone] = (db.zones[info.zone] or 0) + 1
  end
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
  local rival = Stats.TouchRival(victim, "kills", info)
  local personal
  if rival and (rival.kills == 5 or rival.kills == 10) then
    personal = rival.kills
  end
  local streak, streakHit = bumpStreak()
  return raceCount, classCount, hitKind, hitValue, hitKey, rival, streakHit, streak, personal
end

function Stats.Session()
  return sessionKills, sessionDeaths, ensureDB().streak or 0
end

function Stats.RivalByName(name)
  local key = nameKey(name)
  if not key then
    return nil
  end
  return ensureDB().rivals[key]
end

function Stats.Spotlight()
  local db = ensureDB()
  local nemesis, prey
  local nemesisDeaths, preyKills = -1, -1
  for _, row in pairs(db.rivals) do
    if (row.deaths or 0) > nemesisDeaths then
      nemesisDeaths = row.deaths or 0
      nemesis = row
    end
    if (row.kills or 0) > preyKills then
      preyKills = row.kills or 0
      prey = row
    end
  end
  local zone, best = nil, 0
  for name, count in pairs(db.zones) do
    if count > best then
      zone, best = name, count
    end
  end
  if nemesisDeaths <= 0 then
    nemesis = nil
  end
  if preyKills <= 0 then
    prey = nil
  end
  return nemesis, prey, zone
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
