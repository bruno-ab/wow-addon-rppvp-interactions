local addonName, ns = ...
ns = ns or {}
ns.L = ns.L or {}

local locale = GetLocale and GetLocale() or "enUS"

local ptBR = {
  LOADED = "BanterCombat carregado. /banter help",
  HELP = "comandos: test, revenge, milestone, stats, config, queue, hide, debug, history, ignore, help",
  REVENGE = "VINGANÇA",
  MILESTONE = "CONQUISTA · %d %s",
  OPT_TITLE = "BanterCombat — Opções",
  OPT_ENABLE = "Ativar pop-ups",
  OPT_SYNC = "Sincronizar com oponente (WHISPER)",
  OPT_GROUP = "Também enviar em PARTY/RAID/INSTANCE",
  OPT_SOUND = "Som ao exibir",
  OPT_MODEL = "Retrato 3D (quando possível)",
  OPT_DURATION = "Duração (segundos)",
  OPT_PVP_ONLY = "Só em flag PvP / campo de batalha",
  OPT_RESET_POS = "Resetar posição do frame",
  OPT_CLOSE = "Fechar",
  OPT_SHOW_GROUP = "Mostrar banters do grupo",
  OPT_SHOW_DEATHS = "Mostrar pop-ups de morte",
  OPT_HOSTILE = "Só inimigos (não duelo amigo)",
  OPT_CHAT = "Espelhar fala no chat (emote)",
  OPT_DEBUG = "Debug",
  STATS = "Kills=%d Deaths=%d",
  LAST_KILLER = "Último killer: %s (%s / %s)",
  QUEUE = "Fila: %d",
  TOP_RACE = "Top raças:",
  TOP_CLASS = "Top classes:",
}

local enUS = {
  LOADED = "BanterCombat loaded. /banter help",
  HELP = "commands: test, revenge, milestone, stats, config, queue, hide, debug, history, ignore, help",
  REVENGE = "REVENGE",
  MILESTONE = "ACHIEVEMENT · %d %s",
  OPT_TITLE = "BanterCombat — Options",
  OPT_ENABLE = "Enable popups",
  OPT_SYNC = "Sync to opponent (WHISPER)",
  OPT_GROUP = "Also send on PARTY/RAID/INSTANCE",
  OPT_SOUND = "Play sound on show",
  OPT_MODEL = "3D portrait when possible",
  OPT_DURATION = "Duration (seconds)",
  OPT_PVP_ONLY = "Only while PvP flagged / in battleground",
  OPT_RESET_POS = "Reset frame position",
  OPT_CLOSE = "Close",
  OPT_SHOW_GROUP = "Show group banters",
  OPT_SHOW_DEATHS = "Show death popups",
  OPT_HOSTILE = "Hostile only (skip friendly duels)",
  OPT_CHAT = "Mirror line to chat (emote)",
  OPT_DEBUG = "Debug",
  STATS = "Kills=%d Deaths=%d",
  LAST_KILLER = "Last killer: %s (%s / %s)",
  QUEUE = "Queue: %d",
  TOP_RACE = "Top races:",
  TOP_CLASS = "Top classes:",
}

local catalogs = {
  ptBR = ptBR,
  enUS = enUS,
}

ns.LocaleCode = (locale == "ptBR" or locale == "ptPT") and "ptBR" or "enUS"
setmetatable(ns.L, {
  __index = function(_, key)
    local pack = catalogs[ns.LocaleCode] or enUS
    return pack[key] or enUS[key] or key
  end,
})

function ns.SetLocale(code)
  if catalogs[code] then
    ns.LocaleCode = code
  end
end

_G[addonName] = ns
