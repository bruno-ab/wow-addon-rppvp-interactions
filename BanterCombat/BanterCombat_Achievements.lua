-- PvP achievements. Race and class totals come from the kill book.
-- Zone, spell, honor and situation counts start when this build can see the event.
-- If the client has no signal, the bar stays at zero.

local addonName, ns = ...
ns = ns or {}
ns.Achievements = ns.Achievements or {}

local Achievements = ns.Achievements

local PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040

local function band(a, b)
  if bit and bit.band then
    return bit.band(a, b)
  end
  if bit32 and bit32.band then
    return bit32.band(a, b)
  end
  local result, place = 0, 1
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

local function isPlayer(flags)
  return type(flags) == "number" and band(flags, PLAYER) > 0
end

local function isHostile(flags)
  return type(flags) == "number" and band(flags, HOSTILE) > 0
end

local function lookup(list)
  local map = {}
  for i = 1, #list do
    map[list[i]] = true
  end
  return map
end

local CHARGE = lookup({ 100, 6178, 11578 })
local INTERCEPT = lookup({ 20252, 20616, 20617 })
local SHIELD = lookup({ 72, 1671, 1672, 6552, 6554 })
local BUBBLE = lookup({ 642, 1020 })
local POLY = lookup({ 118, 12824, 12825, 12826 })
local FREEZE = lookup({ 3355, 1499, 14310, 14311 })
local OPENER = lookup({
  1833, 8676, 8724, 8725, 11267, 11268, 11269,
  703, 8631, 8632, 8633, 11289, 11290,
})
local STEALTH = lookup({ 1784, 1856, 1857 })
local DISPEL = lookup({ 527, 988 })
local SUMMON = lookup({ 688, 697, 712, 691 })
local DOT = lookup({
  172, 6222, 6223, 7648, 11671, 11672, 25311,
  980, 1014, 6217, 11711, 11712, 11713,
  348, 707, 1094, 2941, 11665, 11667, 11668, 25309,
  18265, 18879, 18880, 18881,
})
local FROST = lookup({
  116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304,
  122, 865, 6131, 10230,
  120, 8492, 10159, 10160, 10161,
  10, 6141, 8427, 10185, 10186, 10187,
})
local FORM = {
  [768] = "cat",
  [5487] = "bear",
  [9634] = "bear",
  [24858] = "moon",
  [783] = "travel",
  [1066] = "travel",
}
local ANIMAL_FORM = { cat = true, bear = true, travel = true }
local MELEE = lookup({
  78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286,
  845, 7369, 11608, 11609, 20569,
  12294, 21551, 21552, 21553,
  23881, 23892, 23893, 23894,
  7384, 7887, 11584, 11585,
  5308, 20658, 20660, 20661, 20662,
  1464, 8820, 11604, 11605, 1680,
  1715, 7372, 7373,
  772, 6546, 6547, 6548, 11572, 11573, 11574,
  1752, 1757, 1758, 1759, 1760, 8621, 11293, 11294,
  53, 2589, 2590, 2591, 8721, 11279, 11280, 11281,
  2098, 6760, 6761, 6762, 8623, 8624, 11299, 11300,
  1776, 1777, 8629, 11285, 11286, 16511,
  2973, 14260, 14261, 14262, 14263, 14264, 14265,
  1495, 14269, 14270, 14271,
  1082, 3029, 5201, 9849, 9850,
  5221, 6800, 8992, 9829, 9830,
  1822, 1823, 1824, 9904,
  6807, 6808, 6809, 8972, 9745, 9880, 9881,
  779, 780, 769, 9754, 9908,
})
local CC = lookup({
  5782, 6213, 6215, 5484, 17928,
  8122, 8124, 10888, 10890, 5246,
  1513, 14326, 14327, 6358,
  700, 1090, 2937, 2637, 18657, 18658,
  605, 10911, 10912, 19386, 24132, 24133,
  6789, 17925, 17926,
})
local RACIAL = {
  [20594] = "stoneform",
  [20589] = "escape",
  [20580] = "shadowmeld",
  [20572] = "bloodfury",
  [33697] = "bloodfury",
  [33702] = "bloodfury",
  [7744] = "wotf",
  [20549] = "stomp",
  [20554] = "berserk",
  [26296] = "berserk",
  [26297] = "berserk",
  [59752] = "human",
}

local RIVAL = {
  Human = "Orc", Orc = "Human",
  Dwarf = "Tauren", Tauren = "Dwarf",
  NightElf = "Troll", Troll = "NightElf",
  Gnome = "Scourge", Scourge = "Gnome",
}

local ALLIANCE_RACES = { Human = true, Dwarf = true, NightElf = true, Gnome = true }
local HORDE_RACES = { Orc = true, Scourge = true, Tauren = true, Troll = true }

local COMBOS = {
  Alliance = {
    "Human:WARRIOR", "Human:PALADIN", "Human:ROGUE", "Human:PRIEST", "Human:MAGE", "Human:WARLOCK",
    "Dwarf:WARRIOR", "Dwarf:PALADIN", "Dwarf:HUNTER", "Dwarf:ROGUE", "Dwarf:PRIEST",
    "NightElf:WARRIOR", "NightElf:HUNTER", "NightElf:ROGUE", "NightElf:PRIEST", "NightElf:DRUID",
    "Gnome:WARRIOR", "Gnome:ROGUE", "Gnome:MAGE", "Gnome:WARLOCK",
  },
  Horde = {
    "Orc:WARRIOR", "Orc:HUNTER", "Orc:ROGUE", "Orc:SHAMAN", "Orc:WARLOCK",
    "Scourge:WARRIOR", "Scourge:ROGUE", "Scourge:PRIEST", "Scourge:MAGE", "Scourge:WARLOCK",
    "Tauren:WARRIOR", "Tauren:HUNTER", "Tauren:SHAMAN", "Tauren:DRUID",
    "Troll:WARRIOR", "Troll:HUNTER", "Troll:ROGUE", "Troll:PRIEST", "Troll:SHAMAN", "Troll:MAGE",
  },
}

local ENEMY_CLASS = {
  Alliance = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
  Horde = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "DRUID" },
}

local ZONES = {
  { id = "elwynn", continent = "ek", keys = { "elwynn" } },
  { id = "westfall", continent = "ek", keys = { "westfall", "cerro oeste" } },
  { id = "redridge", continent = "ek", keys = { "redridge", "cristarrubra" } },
  { id = "duskwood", continent = "ek", keys = { "duskwood", "crepúsculo", "crepusculo" } },
  { id = "stranglethorn", continent = "ek", keys = { "stranglethorn", "espinhaço", "espinhaco" } },
  { id = "swamp", continent = "ek", keys = { "swamp of sorrows", "pântano das mágoas", "pantano das magoas" } },
  { id = "burning", continent = "ek", keys = { "burning steppes", "estepes ardentes" } },
  { id = "searing", continent = "ek", keys = { "searing gorge", "garganta abrasadora" } },
  { id = "badlands", continent = "ek", keys = { "badlands", "ermos" } },
  { id = "hinterlands", continent = "ek", keys = { "hinterlands", "terras do interior" } },
  { id = "wpl", continent = "ek", keys = { "western plaguelands", "pestilentas ocidentais" } },
  { id = "epl", continent = "ek", keys = { "eastern plaguelands", "pestilentas orientais" } },
  { id = "hillsbrad", continent = "ek", keys = { "hillsbrad", "eira dos montes" } },
  { id = "arathi", continent = "ek", keys = { "arathi" } },
  { id = "wetlands", continent = "ek", keys = { "wetlands", "pantanal" } },
  { id = "loch", continent = "ek", keys = { "loch modan" } },
  { id = "tirisfal", continent = "ek", keys = { "tirisfal" } },
  { id = "silverpine", continent = "ek", keys = { "silverpine", "pinho prateado" } },
  { id = "alterac", continent = "ek", keys = { "alterac" } },
  { id = "barrens", continent = "kal", keys = { "barrens", "sertões", "sertoes" } },
  { id = "stonetalon", continent = "kal", keys = { "stonetalon", "torres de pedra" } },
  { id = "ashenvale", continent = "kal", keys = { "ashenvale", "vale gris" } },
  { id = "desolace", continent = "kal", keys = { "desolace", "desolação", "desolacao" } },
  { id = "feralas", continent = "kal", keys = { "feralas" } },
  { id = "dustwallow", continent = "kal", keys = { "dustwallow", "pântano vadeoso", "pantano vadeoso" } },
  { id = "needles", continent = "kal", keys = { "thousand needles", "mil agulhas" } },
  { id = "tanaris", continent = "kal", keys = { "tanaris" } },
  { id = "azshara", continent = "kal", keys = { "azshara" } },
  { id = "felwood", continent = "kal", keys = { "felwood", "selva maleva" } },
  { id = "winterspring", continent = "kal", keys = { "winterspring", "hibérnia", "hibernia" } },
  { id = "silithus", continent = "kal", keys = { "silithus" } },
  { id = "ungoro", continent = "kal", keys = { "ungoro", "un'goro" } },
}

local ICONS = {
  pvp = "Interface\\Icons\\INV_BannerPVP_02",
  ally = "Interface\\Icons\\INV_BannerPVP_01",
  sword = "Interface\\Icons\\Ability_Warrior_Charge",
  shield = "Interface\\Icons\\Spell_Holy_SealOfProtection",
  bow = "Interface\\Icons\\INV_Weapon_Bow_07",
  rogue = "Interface\\Icons\\Ability_Rogue_Ambush",
  holy = "Interface\\Icons\\Spell_Holy_Heal",
  nature = "Interface\\Icons\\Spell_Nature_Lightning",
  frost = "Interface\\Icons\\Spell_Frost_FrostBolt02",
  shadow = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
  druid = "Interface\\Icons\\Ability_Druid_CatForm",
  human = "Interface\\Icons\\INV_Misc_Head_Human_01",
  dwarf = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
  night = "Interface\\Icons\\INV_Misc_Head_NightElf_01",
  gnome = "Interface\\Icons\\INV_Misc_Head_Gnome_01",
  orc = "Interface\\Icons\\INV_Misc_Head_Orc_01",
  undead = "Interface\\Icons\\INV_Misc_Head_Undead_01",
  tauren = "Interface\\Icons\\INV_Misc_Head_Tauren_01",
  troll = "Interface\\Icons\\INV_Misc_Head_Troll_01",
  book = "Interface\\Icons\\INV_Misc_Book_09",
}

local live = {
  charged = {},
  poly = {},
  polyHurt = {},
  frost = {},
  opened = {},
  stealthBroken = {},
  victimForm = {},
  healer = {},
  melee = {},
  ranged = {},
  dot = {},
  attackers = {},
  hurtFriend = {},
  bgClasses = {},
  stompHits = {},
  seen = {},
  tookDamage = false,
  bfExpire = 0,
  bfWindow = 0,
  berserkExpire = 0,
  racialCasts = 0,
  bgRival = 0,
}

local function now()
  if GetTime then
    return GetTime()
  end
  return 0
end

local function later(seconds, fn)
  if C_Timer and C_Timer.After then
    C_Timer.After(seconds, fn)
  end
end

local function enabled()
  if ns.Options and ns.Options.Get and ns.Options.Get().enabled == false then
    return false
  end
  return true
end

local function ptLocale()
  return ns.LocaleCode == "ptBR"
end

local function text(pt, en)
  if ptLocale() then
    return pt
  end
  return en
end

local function myRace()
  if not UnitRace then
    return nil
  end
  return select(2, UnitRace("player"))
end

local function myClass()
  if not UnitClass then
    return nil
  end
  return select(2, UnitClass("player"))
end

local function myFaction()
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  if faction == "Alliance" or faction == "Horde" then
    return faction
  end
  local race = myRace()
  if HORDE_RACES[race] then
    return "Horde"
  end
  return "Alliance"
end

local function enemyRaces()
  if myFaction() == "Horde" then
    return { "Human", "Dwarf", "NightElf", "Gnome" }
  end
  return { "Orc", "Scourge", "Tauren", "Troll" }
end

local function enemyClasses()
  return ENEMY_CLASS[myFaction()] or ENEMY_CLASS.Alliance
end

local function enemyCombos()
  if myFaction() == "Horde" then
    return COMBOS.Alliance
  end
  return COMBOS.Horde
end

local function raceLabel(race)
  if ns.Data and ns.Data.RaceLabel then
    return ns.Data.RaceLabel(race)
  end
  return race or "?"
end

local function classLabel(class)
  if ns.Data and ns.Data.ClassLabel then
    return ns.Data.ClassLabel(class)
  end
  return class or "?"
end

local function zoneName()
  local name = ""
  if GetRealZoneText then
    name = GetRealZoneText() or ""
  end
  if name == "" and GetZoneText then
    name = GetZoneText() or ""
  end
  return name
end

local function inBattleground()
  return UnitInBattleground and UnitInBattleground("player")
end

local function bgKey()
  if not inBattleground() then
    return nil
  end
  local lower = zoneName():lower()
  if lower:find("warsong", 1, true) or lower:find("brado", 1, true) or lower:find("guerreiro", 1, true)
    or lower:find("schlucht", 1, true) or lower:find("goulet", 1, true) then
    return "warsong"
  end
  if lower:find("arathi", 1, true) then
    return "arathi"
  end
  if lower:find("alterac", 1, true) then
    return "alterac"
  end
  return "other"
end

local function isBattlegroundZone(lower)
  if lower:find("warsong", 1, true) or lower:find("brado", 1, true) or lower:find("gulch", 1, true) then
    return true
  end
  if lower:find("basin", 1, true) or lower:find("bacia", 1, true) or lower:find("cuenca", 1, true) then
    return true
  end
  if lower:find("alterac", 1, true) and (lower:find("valley", 1, true) or lower:find("vale", 1, true)) then
    return true
  end
  return false
end

local function Store()
  local db = ns.Stats and ns.Stats.GetDB and ns.Stats.GetDB()
  if type(db) ~= "table" then
    return nil
  end
  if type(db.achv) ~= "table" then
    db.achv = {}
  end
  local book = db.achv
  if type(book.n) ~= "table" then
    book.n = {}
  end
  if type(book.set) ~= "table" then
    book.set = {}
  end
  if type(book.when) ~= "table" then
    book.when = {}
  end
  return book, db
end

local function num(key)
  local book = Store()
  if not book then
    return 0
  end
  return math.max(0, math.floor(tonumber(book.n[key]) or 0))
end

local function setn(key, value)
  local book = Store()
  if not book then
    return 0
  end
  value = math.max(0, math.floor(tonumber(value) or 0))
  book.n[key] = value
  return value
end

local function addn(key, delta)
  return setn(key, num(key) + (delta or 1))
end

local function markSet(group, key)
  if type(key) ~= "string" or key == "" then
    return
  end
  local book = Store()
  if not book then
    return
  end
  if type(book.set[group]) ~= "table" then
    book.set[group] = {}
  end
  if not book.set[group][key] then
    book.set[group][key] = time()
  end
end

local function countOf(map, key)
  if type(map) ~= "table" then
    return 0
  end
  return tonumber(map[key]) or 0
end

local function killBook()
  local _, db = Store()
  return db
end

local function totalKills()
  local db = killBook()
  return db and tonumber(db.totalKills) or 0
end

local function raceKills(race)
  local db = killBook()
  if not db or type(db.kills) ~= "table" then
    return 0
  end
  return countOf(db.kills.Race, race)
end

local function classKills(class)
  local db = killBook()
  if not db or type(db.kills) ~= "table" then
    return 0
  end
  return countOf(db.kills.Class, class)
end

local function once(key, window)
  local at = now()
  local prev = live.seen[key]
  if prev and at - prev < (window or 8) then
    return false
  end
  live.seen[key] = at
  return true
end

local function syncHonor()
  local book = Store()
  if not book then
    return
  end
  if GetPVPLifetimeStats then
    local hk = tonumber((GetPVPLifetimeStats()))
    if hk and hk > num("apiHk") then
      setn("apiHk", hk)
    end
  end
  if GetPVPThisWeekStats then
    local _, _, honor = GetPVPThisWeekStats()
    if type(honor) == "number" and honor >= 0 then
      setn("weekHonor", honor)
      book.n.weekKnown = 1
    end
  end
  if GetHonorCurrency then
    local honor = GetHonorCurrency()
    if type(honor) == "number" and honor >= 0 then
      setn("lifeHonor", honor)
      book.n.lifeKnown = 1
    end
  end
end

local function honorable()
  syncHonor()
  if GetPVPLifetimeStats then
    return num("apiHk")
  end
  return totalKills()
end

local function seedBook()
  local book = Store()
  if not book or book.n.seededWorld then
    return
  end
  book.n.seededWorld = 1
  local db = killBook()
  local best = db and tonumber(db.bestStreak) or 0
  if best > num("bestWorld") then
    setn("bestWorld", best)
  end
end

local function noteTalents()
  if not GetNumTalentTabs or not GetTalentTabInfo then
    return
  end
  local tabs = GetNumTalentTabs()
  if type(tabs) ~= "number" or tabs < 1 then
    return
  end
  local parts = {}
  for tab = 1, tabs do
    local _, _, points = GetTalentTabInfo(tab)
    parts[#parts + 1] = tostring(math.floor(tonumber(points) or 0))
  end
  local key = table.concat(parts, ":")
  local book = Store()
  if not book then
    return
  end
  local prev = book.talent
  if type(prev) ~= "string" or prev == "" then
    book.talent = key
    return
  end
  if prev == key then
    return
  end
  local function piece(serial, index)
    local n = 0
    local seen = 0
    for token in string.gmatch(serial, "[^:]+") do
      seen = seen + 1
      if seen == index then
        n = tonumber(token) or 0
      end
    end
    return n
  end
  local dropped = false
  for index = 1, #parts do
    if piece(key, index) < piece(prev, index) then
      dropped = true
    end
  end
  book.talent = key
  if dropped then
    setn("faithful", 0)
  end
end

local function flushBg(previous)
  if not previous then
    return
  end
  local count = 0
  for _ in pairs(live.bgClasses) do
    count = count + 1
  end
  if count > num("arsenalBest") then
    setn("arsenalBest", count)
  end
  if (live.bgRival or 0) > num("rivalBest") then
    setn("rivalBest", live.bgRival or 0)
  end
  if (live.racialCasts or 0) >= 5 and once("racial5:" .. tostring(previous), 30) then
    addn("bgRacial5", 1)
  end
end

local function touchBg()
  local key = bgKey()
  if key == live.bgKey then
    return key
  end
  flushBg(live.bgKey)
  live.bgKey = key
  live.bgClasses = {}
  live.bgRival = 0
  live.racialCasts = 0
  live.racialUsed = false
  live.escapeUsed = false
  live.berserkUsed = false
  live.humanRacialUsed = false
  return key
end

local function matchZone(lower)
  if lower == "" or isBattlegroundZone(lower) then
    return nil
  end
  for i = 1, #ZONES do
    local zone = ZONES[i]
    local skip = false
    if zone.id == "arathi" and (lower:find("basin", 1, true) or lower:find("bacia", 1, true) or lower:find("cuenca", 1, true)) then
      skip = true
    end
    if zone.id == "alterac" and (lower:find("valley", 1, true) or lower:find("vale", 1, true)) then
      skip = true
    end
    if not skip then
      for k = 1, #zone.keys do
        if lower:find(zone.keys[k], 1, true) then
          return zone
        end
      end
    end
  end
  return nil
end

local function noteZone(race)
  local enemy = {}
  local races = enemyRaces()
  for i = 1, #races do
    enemy[races[i]] = true
  end
  if not enemy[race] then
    return
  end
  local lower = zoneName():lower()
  local key = bgKey()
  if key == "warsong" then
    markSet("cont", "kal")
    return
  end
  if key == "arathi" or key == "alterac" then
    markSet("cont", "ek")
    return
  end
  local zone = matchZone(lower)
  if not zone then
    return
  end
  markSet("zones", zone.id)
  markSet("cont", zone.continent)
  if zone.id == "ashenvale" then
    addn("ashenvale", 1)
  end
end

local function noteCorner(race)
  local races = enemyRaces()
  local enemy = false
  for i = 1, #races do
    if races[i] == race then
      enemy = true
    end
  end
  if not enemy then
    return
  end
  local book = Store()
  if not book then
    return
  end
  if type(book.set.corner) ~= "table" then
    book.set.corner = {}
  end
  book.set.corner[race] = time()
  local oldest, newest = nil, nil
  for i = 1, #races do
    local stamp = tonumber(book.set.corner[races[i]]) or 0
    if stamp <= 0 then
      return
    end
    if not oldest or stamp < oldest then
      oldest = stamp
    end
    if not newest or stamp > newest then
      newest = stamp
    end
  end
  if newest and oldest and newest - oldest <= 600 then
    setn("four", 1)
  end
end

local function forget(guid)
  if not guid then
    return
  end
  live.charged[guid] = nil
  live.poly[guid] = nil
  live.polyHurt[guid] = nil
  live.frost[guid] = nil
  live.opened[guid] = nil
  live.stealthBroken[guid] = nil
  live.victimForm[guid] = nil
  live.healer[guid] = nil
  live.melee[guid] = nil
  live.ranged[guid] = nil
  live.dot[guid] = nil
  live.attackers[guid] = nil
  live.hurtFriend[guid] = nil
end

local function allyLow()
  local function low(unit)
    if not UnitExists(unit) or (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)) then
      return false
    end
    local maxHealth = UnitHealthMax(unit)
    if not maxHealth or maxHealth <= 0 then
      return false
    end
    return UnitHealth(unit) / maxHealth <= 0.35
  end
  for i = 1, 4 do
    if low("party" .. i) then
      return true
    end
  end
  if IsInRaid and IsInRaid() then
    for i = 1, 40 do
      if low("raid" .. i) then
        return true
      end
    end
  end
  return false
end

local function isGroupGuid(guid)
  if not guid or not UnitGUID then
    return false
  end
  for i = 1, 4 do
    if UnitGUID("party" .. i) == guid then
      return true
    end
  end
  if IsInRaid and IsInRaid() then
    for i = 1, 40 do
      if UnitGUID("raid" .. i) == guid then
        return true
      end
    end
  end
  return false
end

local function humanSpell(name)
  if type(name) ~= "string" then
    return false
  end
  local lower = name:lower()
  if lower:find("perception", 1, true) or lower:find("percepção", 1, true) or lower:find("percepcao", 1, true) then
    return false
  end
  if lower:find("every man", 1, true) or lower:find("will to survive", 1, true) then
    return true
  end
  if lower:find("espírito resiliente", 1, true) or lower:find("espirito resiliente", 1, true) then
    return true
  end
  if lower:find("perseverança", 1, true) or lower:find("perseveranca", 1, true) then
    return true
  end
  return false
end

local function looksTotem(name)
  if type(name) ~= "string" then
    return false
  end
  local lower = name:lower()
  return lower:find("totem", 1, true) or lower:find("tótem", 1, true) or lower:find("тотем", 1, true)
end

local function looksTremor(name, spellId)
  if spellId == 8143 then
    return true
  end
  if type(name) ~= "string" then
    return false
  end
  local lower = name:lower()
  return lower:find("tremor", 1, true) or lower:find("trembl", 1, true) or lower:find("bebend", 1, true)
end

local function recent(stamp, window)
  return stamp and now() - stamp <= window
end

local function onRacial(kind)
  local at = now()
  if inBattleground() then
    touchBg()
    live.racialCasts = (live.racialCasts or 0) + 1
    live.racialUsed = true
  end
  if kind == "stoneform" then
    addn("stoneform", 1)
    local maxHealth = UnitHealthMax("player")
    local health = UnitHealth("player")
    if maxHealth and maxHealth > 0 and health / maxHealth < 0.10 then
      later(10, function()
        if not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
          addn("stoneLow", 1)
        end
      end)
    end
  elseif kind == "escape" then
    addn("escape", 1)
    live.escapeAt = at
    live.escapeUsed = true
  elseif kind == "shadowmeld" then
    live.meldAt = at
  elseif kind == "bloodfury" then
    live.bfExpire = at + 15
    live.bfWindow = 0
  elseif kind == "wotf" then
    addn("wotf", 1)
    live.wotfAt = at
  elseif kind == "stomp" then
    live.stompAt = at
    live.stompHits = {}
    later(1.2, function()
      local hits = 0
      for _ in pairs(live.stompHits) do
        hits = hits + 1
      end
      if hits >= 3 then
        addn("stompMulti", 1)
      end
    end)
  elseif kind == "berserk" then
    live.berserkExpire = at + 10
    live.berserkUsed = true
  elseif kind == "human" then
    live.humanAt = at
    live.humanRacialUsed = true
  end
end

local function mentionMe(lower)
  local name = UnitName("player")
  if type(name) ~= "string" or name == "" then
    return false
  end
  if lower:find(name:lower(), 1, true) then
    return true
  end
  if Ambiguate then
    local short = Ambiguate(name, "none")
    if type(short) == "string" and short ~= "" and lower:find(short:lower(), 1, true) then
      return true
    end
  end
  return false
end

local function factionOutcome(lower)
  local win = lower:find("wins", 1, true) or lower:find("venceu", 1, true) or lower:find("gewonnen", 1, true)
    or lower:find("victoire", 1, true) or lower:find("victoria", 1, true) or lower:find("vittoria", 1, true)
    or lower:find("побед", 1, true) or lower:find("승리", 1, true) or lower:find("胜利", 1, true) or lower:find("獲勝", 1, true)
  if not win then
    return nil
  end
  local alliance = lower:find("alliance", 1, true) or lower:find("aliança", 1, true) or lower:find("alianca", 1, true)
    or lower:find("allianz", 1, true) or lower:find("alianza", 1, true)
  local horde = lower:find("horde", 1, true) or lower:find("horda", 1, true)
  local mine = myFaction()
  if alliance and mine == "Alliance" then
    return "win"
  end
  if horde and mine == "Horde" then
    return "win"
  end
  if alliance or horde then
    return "loss"
  end
  return nil
end

local function onBgWin()
  if not once("bgwin", 20) then
    return
  end
  local key = bgKey() or live.bgKey or "other"
  addn("bgWin", 1)
  addn("bgWin:" .. key, 1)
  local row = addn("winRow", 1)
  if row > num("bestWinRow") then
    setn("bestWinRow", row)
  end
  if live.racialUsed then
    addn("racialWins", 1)
  end
  if live.escapeUsed and myRace() == "Gnome" and myClass() == "MAGE" then
    addn("gnomeMageWins", 1)
  end
  if live.humanRacialUsed and myRace() == "Human" and myClass() == "PALADIN" then
    addn("humanPalWins", 1)
  end
  if live.berserkUsed then
    addn("berserkWins", 1)
  end
end

local function onBgLoss()
  if not once("bgloss", 20) then
    return
  end
  setn("winRow", 0)
end

function Achievements.OnBgMessage(message)
  if not enabled() or type(message) ~= "string" then
    return
  end
  if not inBattleground() then
    return
  end
  touchBg()
  local lower = message:lower()
  local outcome = factionOutcome(lower)
  if outcome == "win" then
    onBgWin()
  elseif outcome == "loss" then
    onBgLoss()
  end
  if not mentionMe(lower) then
    return
  end
  local flagWord = lower:find("flag", 1, true) or lower:find("bandeira", 1, true) or lower:find("fahne", 1, true)
    or lower:find("drapeau", 1, true) or lower:find("bandera", 1, true) or lower:find("флаг", 1, true)
  local took = lower:find("captur", 1, true) or lower:find("captured", 1, true) or lower:find("erobert", 1, true)
    or lower:find("devolv", 1, true) or lower:find("returned", 1, true) or lower:find("zurück", 1, true)
    or lower:find("zuruck", 1, true) or lower:find("rendu", 1, true) or lower:find("devuelt", 1, true)
  if flagWord and took and once("flag:" .. lower, 4) then
    addn("flags", 1)
  end
  local defense = lower:find("defend", 1, true) or lower:find("defendeu", 1, true) or lower:find("verteid", 1, true)
    or lower:find("défend", 1, true) or lower:find("defendió", 1, true) or lower:find("defendio", 1, true)
  local place = lower:find("tower", 1, true) or lower:find("torre", 1, true) or lower:find("turm", 1, true)
    or lower:find("base", 1, true) or flagWord
  if defense and place and once("tower:" .. lower, 4) then
    addn("tower", 1)
  end
end

function Achievements.OnDeath()
  live.tookDamage = true
  live.bfExpire = 0
  live.bfWindow = 0
  live.berserkExpire = 0
  live.meldAt = nil
  live.clutchPending = false
  live.attackers = {}
end

function Achievements.OnKill(victim, isRevenge)
  if not enabled() or not victim then
    return
  end
  seedBook()
  noteTalents()
  addn("faithful", 1)
  syncHonor()
  local at = now()
  local bookDb = killBook()
  local streak = bookDb and tonumber(bookDb.streak) or 0
  local key = touchBg()
  if key then
    if streak > num("bestBg") then
      setn("bestBg", streak)
    end
  elseif streak > num("bestWorld") then
    setn("bestWorld", streak)
  end
  if victim.race then
    noteZone(victim.race)
    noteCorner(victim.race)
    if key and victim.race == RIVAL[myRace()] then
      live.bgRival = (live.bgRival or 0) + 1
      if live.bgRival > num("rivalBest") then
        setn("rivalBest", live.bgRival)
      end
    end
  end
  if victim.race and victim.class then
    addn("combo:" .. victim.race .. ":" .. victim.class, 1)
  end
  if key and victim.class then
    local allowed = {}
    local classes = enemyClasses()
    for i = 1, #classes do
      allowed[classes[i]] = true
    end
    if allowed[victim.class] then
      live.bgClasses[victim.class] = true
      local count = 0
      for _ in pairs(live.bgClasses) do
        count = count + 1
      end
      if count > num("arsenalBest") then
        setn("arsenalBest", count)
      end
    end
  end
  if isRevenge then
    addn("revenge", 1)
    addn("sweet", 1)
  end
  local guid = victim.guid
  if guid and recent(live.hurtFriend[guid], 15) then
    addn("friendKills", 1)
    if allyLow() then
      addn("savior", 1)
    end
  end
  if guid and live.stealthBroken[guid] and recent(live.stealthBroken[guid], 8) and victim.class == "ROGUE" then
    addn("stealthRogue", 1)
  end
  if guid and recent(live.healer[guid], 12) then
    addn("healerKills", 1)
  end
  if victim.class == "DRUID" and guid and live.victimForm[guid] == "animal" then
    addn("druidAnimal", 1)
  end
  if (victim.class == "WARRIOR" or victim.class == "PALADIN") and guid and not live.melee[guid] and live.ranged[guid] then
    addn("antiTank", 1)
  end
  local vl = nil
  if guid and UnitExists("target") and UnitGUID("target") == guid and UnitLevel then
    vl = UnitLevel("target")
  end
  local pl = UnitLevel and UnitLevel("player") or 0
  if vl and vl > 0 and pl > 0 then
    if pl - vl >= 10 then
      addn("lowLevel", 1)
    end
    if vl - pl >= 10 then
      addn("highLevel", 1)
    end
  end
  local class = myClass()
  local race = myRace()
  if class == "WARRIOR" and guid and recent(live.charged[guid], 8) then
    addn("chargeKills", 1)
  end
  if class == "HUNTER" and guid and not live.melee[guid] and live.ranged[guid] then
    addn("hunterRanged", 1)
  end
  if class == "ROGUE" then
    if guid and recent(live.opened[guid], 12) then
      addn("rogueOpen", 1)
    end
    if not live.tookDamage then
      addn("rogueClean", 1)
    end
  end
  if class == "MAGE" and guid and live.polyHurt[guid] then
    addn("polyKills", 1)
  end
  if class == "WARLOCK" and guid and live.dot[guid] then
    addn("dotKills", 1)
  end
  if class == "DRUID" then
    local form = live.myForm
    if form == "cat" or form == "bear" or form == "moon" then
      addn("form:" .. form, 1)
    elseif not form then
      addn("form:caster", 1)
    end
  end
  if recent(live.meldAt, 30) then
    addn("meldKills", 1)
    if race == "NightElf" and class == "DRUID" then
      addn("neDruidMeld", 1)
    end
  end
  if live.bfExpire > at then
    addn("bfKills", 1)
    live.bfWindow = (live.bfWindow or 0) + 1
    if live.bfWindow >= 5 then
      setn("bfBurst", 1)
    end
    if race == "Orc" and class == "WARRIOR" then
      addn("orcWarBf", 1)
    end
  end
  if live.berserkExpire > at then
    addn("berserkKills", 1)
    if race == "Troll" and class == "HUNTER" and guid and not live.melee[guid] and live.ranged[guid] then
      addn("trollHunter", 1)
    end
  end
  if recent(live.wotfAt, 20) and race == "Scourge" and class == "ROGUE" then
    addn("udRogue", 1)
  end
  if recent(live.stompAt, 20) and recent(live.totemAt, 60) and race == "Tauren" and class == "SHAMAN" then
    addn("taurenSham", 1)
  end
  if recent(live.humanAt, 20) then
    addn("humanTurns", 1)
  end
  local attackers = 0
  for _, stamp in pairs(live.attackers) do
    if at - stamp <= 12 then
      attackers = attackers + 1
    end
  end
  if attackers >= 3 and not live.clutchPending then
    live.clutchPending = true
    later(8, function()
      live.clutchPending = false
      if not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
        addn("lastStand", 1)
      end
    end)
  end
  forget(guid)
end

function Achievements.OnLog(subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName)
  if not enabled() or type(subevent) ~= "string" then
    return
  end
  spellId = tonumber(spellId)
  local at = now()
  local hostilePlayer = (isPlayer(sourceFlags) and isHostile(sourceFlags)) or (isPlayer(destFlags) and isHostile(destFlags))
  if hostilePlayer then
    live.hostileAt = at
  end
  if not inBattleground() and not recent(live.hostileAt, 20) then
    return
  end
  local player = UnitGUID("player")
  local mine = sourceGUID == player
  local onMe = destGUID == player
  local damage = subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_DAMAGE"
    or subevent == "SPELL_PERIODIC_DAMAGE"

  if damage and onMe and sourceGUID and sourceGUID ~= player and isPlayer(sourceFlags) then
    live.tookDamage = true
    live.attackers[sourceGUID] = at
  end
  if damage and not onMe and sourceGUID and sourceGUID ~= player and isPlayer(sourceFlags) and isPlayer(destFlags) then
    if isGroupGuid(destGUID) then
      live.hurtFriend[sourceGUID] = at
    end
  end
  if mine and destGUID and isPlayer(destFlags) then
    if subevent == "SWING_DAMAGE" or (spellId and MELEE[spellId] and damage) then
      live.melee[destGUID] = true
    elseif subevent == "RANGE_DAMAGE" or (damage and spellId and not MELEE[spellId]) then
      live.ranged[destGUID] = true
    end
    if damage and spellId and DOT[spellId] then
      live.dot[destGUID] = true
    end
    if damage and spellId and FROST[spellId] and myClass() == "MAGE" then
      local stamps = live.frost[destGUID] or {}
      local kept = {}
      for i = 1, #stamps do
        if at - stamps[i] <= 6 then
          kept[#kept + 1] = stamps[i]
        end
      end
      kept[#kept + 1] = at
      if #kept >= 3 then
        addn("frostCombo", 1)
        live.frost[destGUID] = {}
      else
        live.frost[destGUID] = kept
      end
    end
    if damage and live.poly[destGUID] and recent(live.poly[destGUID], 15) then
      live.polyHurt[destGUID] = true
    end
  end
  if (subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL") and isPlayer(sourceFlags) and sourceGUID ~= destGUID and isPlayer(destFlags) then
    live.healer[sourceGUID] = at
  end
  if mine and (subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL") then
    local amount = tonumber(select(15, CombatLogGetCurrentEventInfo())) or 0
    if amount > 0 and amount < 500000 then
      local class = myClass()
      if class == "PRIEST" then
        addn("priestHeal", amount)
      elseif class == "PALADIN" then
        addn("palHeal", amount)
      elseif class == "DRUID" then
        addn("druidHeal", amount)
      end
    end
  end
  if subevent == "SPELL_CAST_SUCCESS" and mine then
    local kind = spellId and RACIAL[spellId]
    if not kind and humanSpell(spellName) then
      kind = "human"
    end
    if kind then
      onRacial(kind)
    end
    if spellId and (CHARGE[spellId] or INTERCEPT[spellId]) then
      live.charged[destGUID or "target"] = at
    end
    if spellId and OPENER[spellId] then
      live.opened[destGUID or "target"] = at
    end
    if spellId and BUBBLE[spellId] then
      later(8, function()
        if not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
          addn("bubbles", 1)
        end
      end)
    end
    if spellId and SUMMON[spellId] and inBattleground() and myClass() == "WARLOCK" then
      addn("summons", 1)
    end
    if looksTotem(spellName) and myClass() == "SHAMAN" then
      addn("totems", 1)
      live.totemAt = at
      if looksTremor(spellName, spellId) then
        live.tremorAt = at
      end
    end
  end
  if subevent == "SPELL_INTERRUPT" and mine then
    if spellId and SHIELD[spellId] and myClass() == "WARRIOR" then
      addn("warriorInterrupt", 1)
    end
    if spellId == 20549 then
      addn("stompInterrupt", 1)
    end
  end
  if subevent == "SPELL_AURA_APPLIED" then
    if spellId and FORM[spellId] then
      if onMe then
        live.myForm = FORM[spellId]
      end
      if destGUID and ANIMAL_FORM[FORM[spellId]] then
        live.victimForm[destGUID] = "animal"
      end
    end
    if spellId and POLY[spellId] and mine then
      live.poly[destGUID] = at
    end
    if spellId == 3355 and (mine or sourceName == UnitName("player")) then
      addn("traps", 1)
      if destGUID then
        live.ranged[destGUID] = true
      end
    end
    if spellId == 20549 and destGUID and destGUID ~= player then
      live.stompHits[destGUID] = true
    end
  end
  if subevent == "SPELL_AURA_REMOVED" then
    if spellId and FORM[spellId] and onMe and live.myForm == FORM[spellId] then
      live.myForm = nil
    end
    if spellId and STEALTH[spellId] and destGUID and isPlayer(destFlags) then
      live.stealthBroken[destGUID] = at
    end
    if spellId and CC[spellId] and isPlayer(destFlags) and recent(live.tremorAt, 3) and myClass() == "SHAMAN" then
      addn("tremor", 1)
    end
  end
  if subevent == "SPELL_DISPEL" and mine and spellId and DISPEL[spellId] and isHostile(destFlags) and myClass() == "PRIEST" then
    addn("dispels", 1)
  end
end

local function partValue(part)
  if part.total then
    return totalKills()
  end
  if part.hk then
    return honorable()
  end
  if part.class then
    return classKills(part.class)
  end
  if part.key then
    return num(part.key)
  end
  return 0
end

local function joinParts(parts, mode)
  local bits = {}
  local done = mode == "and"
  local pickCur, pickGoal, pickRatio = 0, 1, mode == "and" and 99 or -1
  for i = 1, #parts do
    local cur = partValue(parts[i])
    local goal = parts[i].goal or 1
    bits[#bits + 1] = text(parts[i].pt, parts[i].en) .. " " .. cur .. "/" .. goal
    local ratio = goal > 0 and cur / goal or 0
    local met = cur >= goal
    if mode == "or" then
      if met then
        done = true
      end
      if ratio > pickRatio then
        pickRatio, pickCur, pickGoal = ratio, cur, goal
      end
    else
      if not met then
        done = false
      end
      if ratio < pickRatio then
        pickRatio, pickCur, pickGoal = ratio, cur, goal
      end
    end
  end
  if done then
    return pickGoal, pickGoal, table.concat(bits, "   "), true
  end
  if pickCur > pickGoal then
    pickCur = pickGoal
  end
  return pickCur, pickGoal, table.concat(bits, "   "), false
end

local function measure(def)
  local kind = def.kind
  if kind == "counter" then
    local cur = num(def.key)
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "kills" then
    local cur = totalKills()
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "hk" then
    local cur = honorable()
    local note = nil
    if not GetPVPLifetimeStats then
      note = text("Sem a conta do jogo: usa os abates do addon.", "No game honor counter: using addon kills.")
    end
    return cur, def.goal, note, cur >= def.goal
  end
  if kind == "raceKills" then
    local cur = raceKills(def.race)
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "raceSum" then
    local cur = 0
    for i = 1, #def.races do
      cur = cur + raceKills(def.races[i])
    end
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "raceEach" then
    local races = enemyRaces()
    local met = 0
    local bits = {}
    for i = 1, #races do
      local cur = raceKills(races[i])
      if cur >= 100 then
        met = met + 1
      end
      bits[#bits + 1] = raceLabel(races[i]) .. " " .. cur .. "/100"
    end
    return met, 4, table.concat(bits, "   "), met >= 4
  end
  if kind == "classKills" then
    local cur = classKills(def.class)
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "myClassKills" then
    local cur = classKills(myClass())
    return cur, def.goal, classLabel(myClass()), cur >= def.goal
  end
  if kind == "classEach" then
    local classes = ns.Data and ns.Data.CLASSES or {}
    local met = 0
    local bits = {}
    for i = 1, #classes do
      local cur = classKills(classes[i])
      if cur >= 50 then
        met = met + 1
      end
      bits[#bits + 1] = classLabel(classes[i]) .. " " .. cur .. "/50"
    end
    return met, #classes, table.concat(bits, "   "), #classes > 0 and met >= #classes
  end
  if kind == "combo" then
    local cur = num("combo:" .. def.race .. ":" .. def.class)
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "unique" then
    local list = enemyCombos()
    local have = 0
    for i = 1, #list do
      if num("combo:" .. list[i]) >= 1 then
        have = have + 1
      end
    end
    return have, #list, nil, #list > 0 and have >= #list
  end
  if kind == "zones" then
    local book = Store()
    local have = 0
    local set = book and book.set.zones or nil
    if type(set) == "table" then
      for i = 1, #ZONES do
        if set[ZONES[i].id] then
          have = have + 1
        end
      end
    end
    return have, #ZONES, nil, have >= #ZONES
  end
  if kind == "continents" then
    local book = Store()
    local set = book and book.set.cont or {}
    local bits = {}
    local have = 0
    if type(set) == "table" and set.kal then
      have = have + 1
      bits[#bits + 1] = "Kalimdor"
    else
      bits[#bits + 1] = text("Kalimdor ainda não", "Kalimdor still open")
    end
    if type(set) == "table" and set.ek then
      have = have + 1
      bits[#bits + 1] = text("Reinos do Leste", "Eastern Kingdoms")
    else
      bits[#bits + 1] = text("Reinos do Leste ainda não", "Eastern Kingdoms still open")
    end
    return have, 2, table.concat(bits, "   "), have >= 2
  end
  if kind == "four" then
    local races = enemyRaces()
    local book = Store()
    local corner = book and book.set.corner or {}
    local newest = 0
    local stamps = {}
    for i = 1, #races do
      stamps[i] = type(corner) == "table" and tonumber(corner[races[i]]) or 0
      if stamps[i] > newest then
        newest = stamps[i]
      end
    end
    local met = 0
    local bits = {}
    for i = 1, #races do
      local ok = stamps[i] > 0 and newest > 0 and newest - stamps[i] <= 600
      if ok then
        met = met + 1
      end
      bits[#bits + 1] = raceLabel(races[i]) .. (ok and " *" or "")
    end
    if met >= 4 then
      setn("four", 1)
    end
    local done = num("four") >= 1
    return done and 4 or met, 4, table.concat(bits, "   "), done
  end
  if kind == "arsenal" then
    local goal = #enemyClasses()
    local cur = num("arsenalBest")
    return cur, goal, text("Classes inimigas no mesmo campo.", "Enemy classes in one battleground."), cur >= goal
  end
  if kind == "honorWeek" or kind == "honorLife" then
    syncHonor()
    local known = kind == "honorWeek" and num("weekKnown") > 0 or num("lifeKnown") > 0
    if not known then
      return 0, def.goal, text("O cliente não informa este valor de honra.", "This client does not report that honor."), false
    end
    local cur = kind == "honorWeek" and num("weekHonor") or num("lifeHonor")
    return cur, def.goal, nil, cur >= def.goal
  end
  if kind == "and" then
    return joinParts(def.parts, "and")
  end
  if kind == "or" then
    return joinParts(def.parts, "or")
  end
  if kind == "revenge" then
    local cur = num("revenge")
    if ns.Stats and ns.Stats.FeatTime and ns.Stats.FeatTime("revenge") then
      cur = math.max(cur, 1)
    end
    return cur, 1, nil, cur >= 1
  end
  return 0, def.goal or 1, nil, false
end

local function gate(def)
  local raceOk = (not def.gateRaces) or def.gateRaces[myRace()]
  local classOk = (not def.gateClasses) or def.gateClasses[myClass()]
  if raceOk and classOk then
    return nil
  end
  local need = text(def.needPt or "outra raça ou classe", def.needEn or "another race or class")
  return text("Requer ", "Requires ") .. need
end

local function rowTitle(def)
  if def.ashen then
    local name = text("Defensor do Vale-gris", "Ashenvale Defender")
    if myFaction() == "Horde" then
      name = text("Ofensor do Vale-gris", "Ashenvale Offender")
    end
    return name
  end
  return text(def.pt, def.en)
end

local CATS = {
  { id = "summary", pt = "Visão", en = "Summary" },
  { id = "race", pt = "Raças", en = "Races" },
  { id = "class", pt = "Classes", en = "Classes" },
  { id = "combo", pt = "Combinações", en = "Combos" },
  { id = "marks", pt = "Marcos", en = "Milestones" },
  { id = "situation", pt = "Situação", en = "Situations" },
  { id = "racial", pt = "Raciais", en = "Racials" },
  { id = "identity", pt = "Ofício", en = "Craft" },
  { id = "lineage", pt = "Linhagem", en = "Lineage" },
  { id = "personal", pt = "Pessoal", en = "Personal" },
  { id = "counts", pt = "Contas", en = "Counts" },
  { id = "rivals", pt = "Rivais", en = "Rivals" },
  { id = "feats", pt = "Feitos", en = "Feats" },
  { id = "story", pt = "Crônica", en = "Chronicle" },
}

local function D(id, cat, kind, goal, icon, pt, en, ptDesc, enDesc, extra)
  local row = extra or {}
  row.id = id
  row.cat = cat
  row.kind = kind
  row.goal = goal
  row.icon = icon
  row.pt = pt
  row.en = en
  row.ptDesc = ptDesc
  row.enDesc = enDesc
  return row
end

local function catalog()
  local P = ICONS
  local list = {
    D("race_hunter", "race", "raceEach", 4, P.pvp,
      "Caçador de Raças", "Race Hunter",
      "100 abates de cada uma das 4 raças inimigas.", "100 kills of each of the 4 enemy races."),
    D("little_giant", "race", "raceSum", 100, P.tauren,
      "Pequeno Gigante", "Little Giant",
      "100 abates de gnomos ou anões, sendo tauren ou troll.", "100 Gnome or Dwarf kills as a Tauren or Troll.",
      { races = { "Gnome", "Dwarf" }, gateRaces = { Tauren = true, Troll = true }, needPt = "Tauren ou Troll", needEn = "Tauren or Troll" }),
    D("giant_slayer", "race", "raceKills", 100, P.gnome,
      "Giganticida", "Giantslayer",
      "100 abates de taurens, sendo gnomo ou anão.", "100 Tauren kills as a Gnome or Dwarf.",
      { race = "Tauren", gateRaces = { Gnome = true, Dwarf = true }, needPt = "Gnomo ou Anão", needEn = "Gnome or Dwarf" }),
    D("zone_sweep", "race", "zones", #ZONES, P.book,
      "Faxina Racial", "Racial Sweep",
      "Mate uma raça inimiga em cada zona contestada da lista.", "Kill an enemy race in each listed contested zone."),
    D("four_corners", "race", "four", 4, P.pvp,
      "Quatro Cantos", "Four Corners",
      "Mate cada uma das 4 raças inimigas em 10 minutos.", "Kill each of the 4 enemy races within 10 minutes."),
    D("continents", "race", "continents", 2, P.ally,
      "Dois Continentes", "Two Continents",
      "Mate um jogador em Kalimdor e outro nos Reinos do Leste.", "Kill a player in Kalimdor and one in the Eastern Kingdoms."),
    D("ashen_10", "race", "counter", 10, P.nature, "", "",
      "Mate 10 inimigos no Vale-gris.", "Kill 10 enemies in Ashenvale.", { key = "ashenvale", ashen = true }),
    D("ashen_20", "race", "counter", 20, P.nature, "", "",
      "Mate 20 inimigos no Vale-gris.", "Kill 20 enemies in Ashenvale.", { key = "ashenvale", ashen = true }),
    D("ashen_30", "race", "counter", 30, P.nature, "", "",
      "Mate 30 inimigos no Vale-gris.", "Kill 30 enemies in Ashenvale.", { key = "ashenvale", ashen = true }),
    D("class_each", "class", "classEach", 9, P.book,
      "Colecionador de Classes", "Class Collector",
      "50 abates de cada uma das 9 classes. A classe exclusiva da sua facção só entra em duelo.",
      "50 kills of each of the 9 classes. Your faction's exclusive class only counts in a duel."),
    D("mage_break", "class", "classKills", 250, P.frost,
      "Quebra-Magos", "Magebreaker",
      "250 abates de magos.", "250 Mage kills.", { class = "MAGE" }),
    D("anti_stealth", "class", "or", 100, P.rogue,
      "Anti-Furtivo", "Anti-Stealth",
      "100 abates de ladinos, ou 25 ladinos que saíram da furtividade ao te atacar.",
      "100 Rogue kills, or 25 Rogues who left stealth as they struck you.",
      { parts = {
        { class = "ROGUE", goal = 100, pt = "Ladinos", en = "Rogues" },
        { key = "stealthRogue", goal = 25, pt = "Furtivos", en = "From stealth" },
      } }),
    D("no_heal", "class", "or", 100, P.holy,
      "Sem Cura", "No Healing",
      "100 abates de sacerdotes, ou 25 inimigos que estavam curando um aliado.",
      "100 Priest kills, or 25 enemies who were healing an ally.",
      { parts = {
        { class = "PRIEST", goal = 100, pt = "Sacerdotes", en = "Priests" },
        { key = "healerKills", goal = 25, pt = "Curando", en = "Healing" },
      } }),
    D("end_line", "class", "or", 50, P.shadow,
      "Fim da Linha", "End of the Line",
      "50 abates de bruxos, ou 25 druidas em forma de animal.",
      "50 Warlock kills, or 25 Druids in animal form.",
      { parts = {
        { class = "WARLOCK", goal = 50, pt = "Bruxos", en = "Warlocks" },
        { key = "druidAnimal", goal = 25, pt = "Forma animal", en = "Animal form" },
      } }),
    D("same_class", "class", "myClassKills", 50, P.sword,
      "Duelo de Mesmas Armas", "Same Weapons",
      "50 abates de jogadores da sua própria classe.", "50 kills of players who share your class."),
    D("anti_tank", "class", "counter", 50, P.bow,
      "Anti-Tanque", "Anti-Tank",
      "50 abates de guerreiros ou paladinos só com dano à distância.",
      "50 Warrior or Paladin kills using only ranged damage.", { key = "antiTank" }),
    D("arsenal", "class", "arsenal", 8, P.pvp,
      "Arsenal Completo", "Full Arsenal",
      "Mate todas as classes da facção inimiga no mesmo campo de batalha. No clássico são 8: a nona não entra nesse campo.",
      "Kill every enemy-faction class in the same battleground. Classic fields 8; the ninth class is not there."),
    D("old_curse", "combo", "combo", 25, P.undead,
      "Maldição Antiga", "Old Curse",
      "25 abates de mortos-vivos bruxos.", "25 Undead Warlock kills.",
      { race = "Scourge", class = "WARLOCK" }),
    D("wild_nature", "combo", "combo", 25, P.tauren,
      "Natureza Selvagem", "Wild Nature",
      "25 abates de taurens druidas.", "25 Tauren Druid kills.",
      { race = "Tauren", class = "DRUID" }),
    D("night_shade", "combo", "combo", 25, P.night,
      "Sombras da Noite", "Night Shadows",
      "25 abates de elfos noturnos ladinos.", "25 Night Elf Rogue kills.",
      { race = "NightElf", class = "ROGUE" }),
    D("impossible", "combo", "unique", 20, P.book,
      "Combinação Impossível", "Impossible Mix",
      "Mate cada combinação de raça e classe que a facção inimiga pode ser.",
      "Kill every race and class combination the enemy faction can field."),
    D("hk_100", "marks", "hk", 100, P.pvp, "Abates Honrosos: 100", "Honorable Kills: 100",
      "100 abates honrosos.", "100 honorable kills."),
    D("hk_500", "marks", "hk", 500, P.pvp, "Abates Honrosos: 500", "Honorable Kills: 500",
      "500 abates honrosos.", "500 honorable kills."),
    D("hk_1000", "marks", "hk", 1000, P.pvp, "Abates Honrosos: 1.000", "Honorable Kills: 1,000",
      "1.000 abates honrosos.", "1,000 honorable kills."),
    D("hk_5000", "marks", "hk", 5000, P.pvp, "Abates Honrosos: 5.000", "Honorable Kills: 5,000",
      "5.000 abates honrosos.", "5,000 honorable kills."),
    D("hk_10000", "marks", "hk", 10000, P.pvp, "Abates Honrosos: 10.000", "Honorable Kills: 10,000",
      "10.000 abates honrosos.", "10,000 honorable kills."),
    D("hk_25000", "marks", "hk", 25000, P.pvp, "Abates Honrosos: 25.000", "Honorable Kills: 25,000",
      "25.000 abates honrosos.", "25,000 honorable kills."),
    D("last_blow", "marks", "kills", 100, P.sword,
      "Golpe Final", "Last Blow",
      "100 abates em que você deu o último golpe.", "100 killing blows."),
    D("wstreak_5", "marks", "counter", 5, P.sword, "Série no Mundo: 5", "World Streak: 5",
      "5 abates seguidos no mundo, sem morrer. A melhor série já gravada entra aqui.",
      "5 open-world kills without dying. The best streak already saved counts here.", { key = "bestWorld" }),
    D("wstreak_10", "marks", "counter", 10, P.sword, "Série no Mundo: 10", "World Streak: 10",
      "10 abates seguidos no mundo, sem morrer.", "10 open-world kills without dying.", { key = "bestWorld" }),
    D("wstreak_15", "marks", "counter", 15, P.sword, "Série no Mundo: 15", "World Streak: 15",
      "15 abates seguidos no mundo, sem morrer.", "15 open-world kills without dying.", { key = "bestWorld" }),
    D("wstreak_20", "marks", "counter", 20, P.sword, "Série no Mundo: 20", "World Streak: 20",
      "20 abates seguidos no mundo, sem morrer.", "20 open-world kills without dying.", { key = "bestWorld" }),
    D("bstreak_5", "marks", "counter", 5, P.pvp, "Série no Campo: 5", "Battleground Streak: 5",
      "5 abates seguidos dentro de um campo de batalha.", "5 kills in a battleground without dying.", { key = "bestBg" }),
    D("bstreak_10", "marks", "counter", 10, P.pvp, "Série no Campo: 10", "Battleground Streak: 10",
      "10 abates seguidos dentro de um campo de batalha.", "10 kills in a battleground without dying.", { key = "bestBg" }),
    D("bstreak_15", "marks", "counter", 15, P.pvp, "Série no Campo: 15", "Battleground Streak: 15",
      "15 abates seguidos dentro de um campo de batalha.", "15 kills in a battleground without dying.", { key = "bestBg" }),
    D("bstreak_20", "marks", "counter", 20, P.pvp, "Série no Campo: 20", "Battleground Streak: 20",
      "20 abates seguidos dentro de um campo de batalha.", "20 kills in a battleground without dying.", { key = "bestBg" }),
    D("bg_10", "marks", "counter", 10, P.ally, "Presença: 10", "Presence: 10",
      "Vença 10 campos de batalha.", "Win 10 battlegrounds.", { key = "bgWin" }),
    D("bg_50", "marks", "counter", 50, P.ally, "Presença: 50", "Presence: 50",
      "Vença 50 campos de batalha.", "Win 50 battlegrounds.", { key = "bgWin" }),
    D("bg_100", "marks", "counter", 100, P.ally, "Presença: 100", "Presence: 100",
      "Vença 100 campos de batalha.", "Win 100 battlegrounds.", { key = "bgWin" }),
    D("bg_500", "marks", "counter", 500, P.ally, "Presença: 500", "Presence: 500",
      "Vença 500 campos de batalha.", "Win 500 battlegrounds.", { key = "bgWin" }),
    D("bg_wsg", "marks", "counter", 10, P.pvp, "Presença na Ravina", "Warsong Presence",
      "Vença 10 vezes a Ravina Brado Guerreiro.", "Win Warsong Gulch 10 times.", { key = "bgWin:warsong" }),
    D("bg_ab", "marks", "counter", 10, P.pvp, "Presença em Arathi", "Arathi Presence",
      "Vença 10 vezes a Bacia Arathi.", "Win Arathi Basin 10 times.", { key = "bgWin:arathi" }),
    D("bg_av", "marks", "counter", 10, P.pvp, "Presença em Alterac", "Alterac Presence",
      "Vença 10 vezes o Vale Alterac.", "Win Alterac Valley 10 times.", { key = "bgWin:alterac" }),
    D("flag_25", "marks", "counter", 25, P.ally, "Bandeira Dourada: 25", "Gold Flag: 25",
      "Capture ou devolva 25 bandeiras.", "Capture or return 25 flags.", { key = "flags" }),
    D("flag_100", "marks", "counter", 100, P.ally, "Bandeira Dourada: 100", "Gold Flag: 100",
      "Capture ou devolva 100 bandeiras.", "Capture or return 100 flags.", { key = "flags" }),
    D("flag_250", "marks", "counter", 250, P.ally, "Bandeira Dourada: 250", "Gold Flag: 250",
      "Capture ou devolva 250 bandeiras.", "Capture or return 250 flags.", { key = "flags" }),
    D("anonymous", "marks", "counter", 100, P.sword,
      "Cobrador Anônimo", "Unseen Collector",
      "100 abates de quem estava atacando um aliado.", "100 kills of players who were attacking an ally.",
      { key = "friendKills" }),
    D("honor_week", "marks", "honorWeek", 10000, P.book,
      "Honra da Semana", "Honor This Week",
      "Ganhe 10.000 de honra em uma semana.", "Earn 10,000 honor in one week."),
    D("honor_life", "marks", "honorLife", 100000, P.book,
      "Acumulador de Honra", "Honor Hoarder",
      "Ganhe 100.000 de honra no total.", "Earn 100,000 honor in total."),
    D("unstoppable", "marks", "counter", 3, P.pvp,
      "Imparável", "Unstoppable",
      "Vença 3 campos de batalha seguidos.", "Win 3 battlegrounds in a row.", { key = "bestWinRow" }),
    D("low_level", "marks", "counter", 100, P.sword,
      "Sem Perdão: Abaixo", "No Mercy: Below",
      "100 abates de jogadores pelo menos 10 níveis abaixo.", "100 kills of players at least 10 levels below you.",
      { key = "lowLevel" }),
    D("high_level", "marks", "counter", 100, P.shield,
      "Sem Perdão: Acima", "No Mercy: Above",
      "100 abates de jogadores pelo menos 10 níveis acima.", "100 kills of players at least 10 levels above you.",
      { key = "highLevel" }),
    D("tower", "marks", "counter", 50, P.shield,
      "Defensor da Torre", "Tower Defender",
      "50 defesas de base, torre ou bandeira.", "Defend a base, tower, or flag 50 times.", { key = "tower" }),
    D("counterattack", "situation", "revenge", 1, P.sword,
      "Contra-ataque", "Counterattack",
      "Mate quem acabou de te matar.", "Kill the player who just killed you."),
    D("sweet", "situation", "counter", 3, P.sword,
      "Vingança Doce", "Sweet Revenge",
      "Mate 3 vezes alguém que tinha te matado antes.", "Three times, kill someone who had killed you.",
      { key = "sweet" }),
    D("savior", "situation", "counter", 50, P.holy,
      "Salvador", "Savior",
      "50 vezes, abata quem estava em cima de um aliado com pouca vida.",
      "50 times, kill someone who was on a badly hurt ally.", { key = "savior" }),
    D("last_stand", "situation", "counter", 1, P.shield,
      "Último de Pé", "Last One Standing",
      "Vença um duelo, ou sobreviva a um abate depois de ser atacado por 3 inimigos.",
      "Win a duel, or survive after a kill while 3 enemies were on you.", { key = "lastStand" }),
    D("human_spirit", "racial", "counter", 25, P.human,
      "Perseverança do Espírito", "Spirit of Redemption",
      "Vença 25 combates depois que a racial humana impedir a morte ou virar a luta. Sem essa habilidade no cliente, fica em zero.",
      "Win 25 fights after the human racial prevents death or turns the fight. With no such spell, this stays at zero.",
      { key = "humanTurns", gateRaces = { Human = true }, needPt = "Humano", needEn = "Human" }),
    D("dwarf_stone", "racial", "and", 50, P.dwarf,
      "Forma de Pedra", "Stoneform",
      "Use a racial 50 vezes em PvP e sobreviva 10 vezes com menos de 10% de vida depois dela.",
      "Use the racial 50 times in PvP, and survive 10 times from under 10% health after it.",
      { gateRaces = { Dwarf = true }, needPt = "Anão", needEn = "Dwarf", parts = {
        { key = "stoneform", goal = 50, pt = "Usos", en = "Uses" },
        { key = "stoneLow", goal = 10, pt = "Abaixo de 10%", en = "Under 10%" },
      } }),
    D("gnome_escape", "racial", "counter", 25, P.gnome,
      "Mestre da Fuga", "Escape Artist",
      "Escape 25 vezes de raiz ou lentidão com a racial.", "Escape a root or snare 25 times with the racial.",
      { key = "escape", gateRaces = { Gnome = true }, needPt = "Gnomo", needEn = "Gnome" }),
    D("ne_meld", "racial", "counter", 100, P.night,
      "Fusão com as Sombras", "Shadowmeld",
      "100 abates nos 30 segundos depois da racial.", "100 kills within 30 seconds of the racial.",
      { key = "meldKills", gateRaces = { NightElf = true }, needPt = "Elfo Noturno", needEn = "Night Elf" }),
    D("orc_fury", "racial", "and", 100, P.orc,
      "Fúria Sanguinária", "Blood Fury",
      "100 abates dentro da racial, e 5 abates numa única ativação.",
      "100 kills inside the racial, and 5 kills in a single activation.",
      { gateRaces = { Orc = true }, needPt = "Orc", needEn = "Orc", parts = {
        { key = "bfKills", goal = 100, pt = "Na janela", en = "In the window" },
        { key = "bfBurst", goal = 1, pt = "5 numa ativação", en = "5 in one use" },
      } }),
    D("undead_will", "racial", "counter", 50, P.undead,
      "Vontade dos Renegados", "Will of the Forsaken",
      "Quebre 50 medos, controles ou sonos com a racial.", "Break 50 fears, charms, or sleeps with the racial.",
      { key = "wotf", gateRaces = { Scourge = true }, needPt = "Morto-vivo", needEn = "Undead" }),
    D("tauren_stomp", "racial", "and", 50, P.tauren,
      "Pisada de Guerra", "War Stomp",
      "Acertar 3 ou mais inimigos com a pisada 50 vezes, e interromper 25 magias com ela.",
      "Hit 3 or more enemies with War Stomp 50 times, and interrupt 25 spells with it.",
      { gateRaces = { Tauren = true }, needPt = "Tauren", needEn = "Tauren", parts = {
        { key = "stompMulti", goal = 50, pt = "Três ou mais", en = "Three or more" },
        { key = "stompInterrupt", goal = 25, pt = "Interrupções", en = "Interrupts" },
      } }),
    D("troll_berserk", "racial", "or", 25, P.troll,
      "Berserking", "Berserking",
      "25 abates dentro da racial, ou 25 vitórias de campo em que ela foi usada.",
      "25 kills inside the racial, or 25 battleground wins in which it was used.",
      { gateRaces = { Troll = true }, needPt = "Troll", needEn = "Troll", parts = {
        { key = "berserkKills", goal = 25, pt = "Abates", en = "Kills" },
        { key = "berserkWins", goal = 25, pt = "Vitórias", en = "Wins" },
      } }),
    D("natural_rival", "racial", "counter", 25, P.pvp,
      "Rival Natural", "Natural Rival",
      "25 abates da raça rival num único campo de batalha.",
      "25 kills of your rival race in a single battleground.", { key = "rivalBest" }),
    D("racial_wins", "racial", "counter", 10, P.pvp,
      "Diferença Racial", "Racial Edge",
      "Vença 10 campos de batalha em que a racial foi usada.",
      "Win 10 battlegrounds in which your racial was used.", { key = "racialWins" }),
    D("war_craft", "identity", "or", 100, P.sword,
      "Guerreiro", "Warrior",
      "100 abates depois de Investida ou Interceptar, ou 25 interrupções com Golpe de Escudo ou Castigar.",
      "100 kills after Charge or Intercept, or 25 Shield Bash or Pummel interrupts.",
      { gateClasses = { WARRIOR = true }, needPt = "Guerreiro", needEn = "Warrior", parts = {
        { key = "chargeKills", goal = 100, pt = "Investida", en = "Charge" },
        { key = "warriorInterrupt", goal = 25, pt = "Interrupções", en = "Interrupts" },
      } }),
    D("pal_craft", "identity", "and", 25, P.holy,
      "Paladino", "Paladin",
      "Sobreviva a 25 bolhas e cure 100.000 de vida em PvP.",
      "Survive 25 Divine Shields and heal 100,000 health in PvP.",
      { gateClasses = { PALADIN = true }, needPt = "Paladino", needEn = "Paladin", parts = {
        { key = "bubbles", goal = 25, pt = "Bolhas", en = "Shields" },
        { key = "palHeal", goal = 100000, pt = "Cura", en = "Healing" },
      } }),
    D("hunt_craft", "identity", "and", 100, P.bow,
      "Caçador", "Hunter",
      "100 abates só com armadilha ou disparo, e prenda 50 inimigos com Congelante.",
      "100 kills with traps and shots only, and root 50 enemies with Freezing Trap.",
      { gateClasses = { HUNTER = true }, needPt = "Caçador", needEn = "Hunter", parts = {
        { key = "hunterRanged", goal = 100, pt = "À distância", en = "Ranged" },
        { key = "traps", goal = 50, pt = "Congelante", en = "Freezing Trap" },
      } }),
    D("rogue_craft", "identity", "and", 100, P.rogue,
      "Ladino", "Rogue",
      "100 aberturas furtivas que viram abate, e 25 abates sem receber dano.",
      "100 stealth openers that become a kill, and 25 kills without taking damage.",
      { gateClasses = { ROGUE = true }, needPt = "Ladino", needEn = "Rogue", parts = {
        { key = "rogueOpen", goal = 100, pt = "Aberturas", en = "Openers" },
        { key = "rogueClean", goal = 25, pt = "Sem dano", en = "Untouched" },
      } }),
    D("priest_craft", "identity", "and", 100, P.holy,
      "Sacerdote", "Priest",
      "Cure 500.000 de vida e dissipe 100 efeitos inimigos.",
      "Heal 500,000 health and dispel 100 enemy effects.",
      { gateClasses = { PRIEST = true }, needPt = "Sacerdote", needEn = "Priest", parts = {
        { key = "priestHeal", goal = 500000, pt = "Cura", en = "Healing" },
        { key = "dispels", goal = 100, pt = "Dissipar", en = "Dispels" },
      } }),
    D("sham_craft", "identity", "and", 100, P.nature,
      "Xamã", "Shaman",
      "Coloque 100 totens em PvP e remova 50 controles com o Totem Tremor.",
      "Drop 100 totems in PvP and clear 50 controls with Tremor Totem.",
      { gateClasses = { SHAMAN = true }, needPt = "Xamã", needEn = "Shaman", parts = {
        { key = "totems", goal = 100, pt = "Totens", en = "Totems" },
        { key = "tremor", goal = 50, pt = "Tremor", en = "Tremor" },
      } }),
    D("mage_craft", "identity", "and", 25, P.frost,
      "Mago", "Mage",
      "25 abates depois de Polimorfia, e 50 combos de três feitiços de gelo.",
      "25 kills after Polymorph, and 50 combos of three frost spells.",
      { gateClasses = { MAGE = true }, needPt = "Mago", needEn = "Mage", parts = {
        { key = "polyKills", goal = 25, pt = "Polimorfia", en = "Polymorph" },
        { key = "frostCombo", goal = 50, pt = "Gelo", en = "Frost" },
      } }),
    D("lock_craft", "identity", "and", 100, P.shadow,
      "Bruxo", "Warlock",
      "100 abates com dano ao longo do tempo, e invoque 50 demônios em campo de batalha.",
      "100 kills with damage over time, and summon 50 demons in battlegrounds.",
      { gateClasses = { WARLOCK = true }, needPt = "Bruxo", needEn = "Warlock", parts = {
        { key = "dotKills", goal = 100, pt = "DoTs", en = "DoTs" },
        { key = "summons", goal = 50, pt = "Demônios", en = "Demons" },
      } }),
    D("druid_craft", "identity", "and", 25, P.druid,
      "Druida", "Druid",
      "25 abates em gato, urso, luniscante e forma de cura, e 100.000 de cura em PvP.",
      "25 kills in cat, bear, moonkin, and caster form, and 100,000 healing in PvP.",
      { gateClasses = { DRUID = true }, needPt = "Druida", needEn = "Druid", parts = {
        { key = "form:cat", goal = 25, pt = "Gato", en = "Cat" },
        { key = "form:bear", goal = 25, pt = "Urso", en = "Bear" },
        { key = "form:moon", goal = 25, pt = "Luniscante", en = "Moonkin" },
        { key = "form:caster", goal = 25, pt = "Cura", en = "Caster" },
        { key = "druidHeal", goal = 100000, pt = "Vida curada", en = "Healing" },
      } }),
    D("line_orc_war", "lineage", "counter", 100, P.orc,
      "Orc Guerreiro", "Orc Warrior",
      "100 abates durante a Fúria Sanguinária.", "100 kills during Blood Fury.",
      { key = "orcWarBf", gateRaces = { Orc = true }, gateClasses = { WARRIOR = true }, needPt = "Orc Guerreiro", needEn = "Orc Warrior" }),
    D("line_troll_hunt", "lineage", "counter", 50, P.troll,
      "Troll Caçador", "Troll Hunter",
      "50 abates em Berserking só com disparos.", "50 Berserking kills with shots only.",
      { key = "trollHunter", gateRaces = { Troll = true }, gateClasses = { HUNTER = true }, needPt = "Troll Caçador", needEn = "Troll Hunter" }),
    D("line_ud_rogue", "lineage", "counter", 25, P.undead,
      "Morto-vivo Ladino", "Undead Rogue",
      "25 abates depois de quebrar medo ou controle mental.", "25 kills after breaking a fear or mind control.",
      { key = "udRogue", gateRaces = { Scourge = true }, gateClasses = { ROGUE = true }, needPt = "Morto-vivo Ladino", needEn = "Undead Rogue" }),
    D("line_human_pal", "lineage", "counter", 10, P.human,
      "Humano Paladino", "Human Paladin",
      "10 vitórias de campo em que a racial humana foi usada. Sem a habilidade, fica em zero.",
      "10 battleground wins in which the human racial was used. With no such spell, this stays at zero.",
      { key = "humanPalWins", gateRaces = { Human = true }, gateClasses = { PALADIN = true }, needPt = "Humano Paladino", needEn = "Human Paladin" }),
    D("line_gnome_mage", "lineage", "counter", 25, P.gnome,
      "Gnomo Mago", "Gnome Mage",
      "25 vitórias de campo depois de Mestre da Fuga naquela batalha.",
      "25 battleground wins after Escape Artist in that battle.",
      { key = "gnomeMageWins", gateRaces = { Gnome = true }, gateClasses = { MAGE = true }, needPt = "Gnomo Mago", needEn = "Gnome Mage" }),
    D("line_ne_druid", "lineage", "counter", 50, P.night,
      "Elfo Noturno Druida", "Night Elf Druid",
      "50 abates depois da Fusão com as Sombras.", "50 kills after Shadowmeld.",
      { key = "neDruidMeld", gateRaces = { NightElf = true }, gateClasses = { DRUID = true }, needPt = "Elfo Noturno Druida", needEn = "Night Elf Druid" }),
    D("line_tauren_sham", "lineage", "counter", 25, P.tauren,
      "Tauren Xamã", "Tauren Shaman",
      "25 abates depois da Pisada de Guerra com um totem recente.",
      "25 kills after War Stomp with a recent totem.",
      { key = "taurenSham", gateRaces = { Tauren = true }, gateClasses = { SHAMAN = true }, needPt = "Tauren Xamã", needEn = "Tauren Shaman" }),
    D("master", "personal", "kills", 1000, P.book,
      "Mestre da Sua Classe", "Master of Your Class",
      "1.000 abates neste personagem, na mesma raça e classe.",
      "1,000 kills on this character, same race and class."),
    D("faithful", "personal", "counter", 500, P.book,
      "Fiel ao Papel", "True to the Role",
      "500 abates sem reduzir os pontos de um ramo de talentos. Gastar ponto novo não zera.",
      "500 kills without lowering a talent tree. Spending a new point does not reset it.",
      { key = "faithful" }),
    D("pride", "personal", "and", 500, P.pvp,
      "Orgulho Racial", "Racial Pride",
      "500 abates, e 10 campos de batalha com pelo menos 5 usos da racial em cada um.",
      "500 kills, and 10 battlegrounds with at least 5 racial uses in each.",
      { parts = {
        { total = true, goal = 500, pt = "Abates", en = "Kills" },
        { key = "bgRacial5", goal = 10, pt = "Campos", en = "Battlegrounds" },
      } }),
  }
  local races = { "Human", "Dwarf", "NightElf", "Gnome", "Orc", "Scourge", "Tauren", "Troll" }
  local heads = {
    Human = P.human, Dwarf = P.dwarf, NightElf = P.night, Gnome = P.gnome,
    Orc = P.orc, Scourge = P.undead, Tauren = P.tauren, Troll = P.troll,
  }
  local ptName = {
    Human = "Humanos", Dwarf = "Anões", NightElf = "Elfos Noturnos", Gnome = "Gnomos",
    Orc = "Orcs", Scourge = "Mortos-vivos", Tauren = "Taurens", Troll = "Trolls",
  }
  local enName = {
    Human = "Humans", Dwarf = "Dwarves", NightElf = "Night Elves", Gnome = "Gnomes",
    Orc = "Orcs", Scourge = "Undead", Tauren = "Tauren", Troll = "Trolls",
  }
  for i = 1, #races do
    local race = races[i]
    table.insert(list, 1 + i, D("exec:" .. race, "race", "raceKills", 500, heads[race],
      "Carrasco de " .. ptName[race], enName[race] .. " Slayer",
      "500 abates desta raça.", "500 kills of this race.", { race = race }))
  end
  return list
end

local DEFS = catalog()

local function viewOf(def)
  seedBook()
  local blocked = gate(def)
  local progress, goal, detail, done = measure(def)
  goal = goal or def.goal or 1
  if goal < 1 then
    goal = 1
  end
  progress = math.max(0, math.floor(tonumber(progress) or 0))
  if blocked then
    done = false
  end
  local book = Store()
  local when = nil
  if book then
    if done then
      if not book.when[def.id] then
        book.when[def.id] = time()
      end
      when = book.when[def.id]
    else
      book.when[def.id] = nil
    end
  end
  local ratio = goal > 0 and progress / goal or 0
  if ratio > 1 then
    ratio = 1
  end
  return {
    id = def.id,
    title = rowTitle(def),
    desc = text(def.ptDesc, def.enDesc),
    detail = detail,
    progress = progress,
    goal = goal,
    done = done and true or false,
    when = when,
    icon = def.icon or ICONS.pvp,
    blocked = blocked,
    ratio = ratio,
    cat = def.cat,
  }
end

function Achievements.Categories()
  local rows = {}
  for i = 1, #CATS do
    rows[i] = { id = CATS[i].id, label = text(CATS[i].pt, CATS[i].en) }
  end
  return rows
end

function Achievements.IsLedger(page)
  return page == "counts" or page == "rivals" or page == "feats" or page == "story"
end

function Achievements.List(page)
  local rows = {}
  for i = 1, #DEFS do
    local def = DEFS[i]
    if page == "summary" or def.cat == page then
      rows[#rows + 1] = viewOf(def)
    end
  end
  if page == "summary" then
    table.sort(rows, function(a, b)
      local aBlock = a.blocked and 1 or 0
      local bBlock = b.blocked and 1 or 0
      if aBlock ~= bBlock then
        return aBlock < bBlock
      end
      local aDone = a.done and 1 or 0
      local bDone = b.done and 1 or 0
      if aDone ~= bDone then
        return aDone < bDone
      end
      if a.ratio ~= b.ratio then
        return a.ratio > b.ratio
      end
      return (a.title or "") < (b.title or "")
    end)
  end
  return rows
end

function Achievements.Counts()
  local done, total = 0, #DEFS
  for i = 1, #DEFS do
    local row = viewOf(DEFS[i])
    if row.done then
      done = done + 1
    end
  end
  return done, total
end

local watch = CreateFrame("Frame")
watch:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
watch:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
watch:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
watch:RegisterEvent("DUEL_FINISHED")
watch:RegisterEvent("PLAYER_REGEN_ENABLED")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
watch:SetScript("OnEvent", function(_, event, message)
  if event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or event == "CHAT_MSG_BG_SYSTEM_HORDE" or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
    Achievements.OnBgMessage(message)
    return
  end
  if event == "DUEL_FINISHED" then
    if not enabled() then
      return
    end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
      return
    end
    if UnitExists("target") and UnitIsDead("target") and once("duel", 5) then
      addn("lastStand", 1)
    end
    return
  end
  if event == "PLAYER_REGEN_ENABLED" then
    live.tookDamage = false
    live.attackers = {}
    return
  end
  if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BATTLEFIELD_STATUS" then
    syncHonor()
    touchBg()
  end
end)

_G[addonName] = ns
