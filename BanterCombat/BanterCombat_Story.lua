local addonName, ns = ...
ns = ns or {}

local MAP_ZONE = {
  [1440] = "ashenvale",
  [1460] = "warsong",
  [1461] = "arathi",
}

local function norm(text)
  if type(text) ~= "string" then
    return ""
  end
  return text:lower()
end

local function matchZone(text)
  local s = norm(text)
  if s == "" then
    return nil
  end
  if s:find("warsong", 1, true) or s:find("brado guerreiro", 1, true) or s:find("grito de guerra", 1, true) or s:find("warsongschlucht", 1, true) or s:find("goulet des warsong", 1, true) or s:find("песни войны", 1, true) or s:find("전쟁노래", 1, true) or s:find("战歌", 1, true) or s:find("戰歌", 1, true) then
    return "warsong"
  end
  if s:find("arathi", 1, true) or s:find("arathibecken", 1, true) or s:find("арати", 1, true) or s:find("아라시", 1, true) or s:find("阿拉希", 1, true) then
    return "arathi"
  end
  if s:find("ashenvale", 1, true) or s:find("cinzento", 1, true) or s:find("eschental", 1, true) or s:find("orneval", 1, true) or s:find("vallefresno", 1, true) or s:find("valtetra", 1, true) or s:find("ясеневый", 1, true) or s:find("잿빛", 1, true) or s:find("灰谷", 1, true) or s:find("梣谷", 1, true) then
    return "ashenvale"
  end
  return nil
end

function ns.CurrentZone()
  if C_Map and C_Map.GetBestMapForUnit then
    local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
    if ok and id and MAP_ZONE[id] then
      return MAP_ZONE[id]
    end
  end
  local zone = matchZone(GetRealZoneText and GetRealZoneText()) or matchZone(GetZoneText and GetZoneText()) or matchZone(GetSubZoneText and GetSubZoneText())
  return zone
end

local PT_GENDER = {
  { "Humano orgulhoso", "Humana orgulhosa" },
  { "Paladino caído", "Paladina caída" },
  { "orgulhoso", "orgulhosa" },
  { "caído", "caída" },
  { "Caído", "Caída" },
}

function ns.Genderize(text, sex)
  if type(text) ~= "string" or sex ~= 3 or ns.LocaleCode ~= "ptBR" then
    return text
  end
  for i = 1, #PT_GENDER do
    text = text:gsub(PT_GENDER[i][1], PT_GENDER[i][2])
  end
  return text
end

local OVERLAY = {
  enUS = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} to {deaths}. The account stays open.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Again, {name}. Score {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Rival marked. {kills} kills, {deaths} deaths.",
    ["Três sem cair. A série começou."] = "Three without falling. The streak has started.",
    ["Cinco no chão. Implacável."] = "Five on the ground. Relentless.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Ten without dying. The field learned the name.",
    ["A série quebrou em {streak}."] = "The streak broke at {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} kills… and a fall.",
    ["Em série"] = "On a streak",
    ["Implacável"] = "Relentless",
    ["Lenda do campo"] = "Legend of the field",
    ["A ravina não tem bandeira para você."] = "The gulch has no flag for you.",
    ["O meio da ravina ficou mais quieto."] = "The middle of the gulch got quieter.",
    ["A bacia guarda mais um corpo."] = "The basin keeps another body.",
    ["Nem o estábulo te escondeu."] = "Not even the stables hid you.",
    ["Ashenvale fica com o corpo."] = "Ashenvale keeps the body.",
    ["A floresta aceitou mais um."] = "The forest took another.",
  },
  deDE = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} zu {deaths}. Die Rechnung bleibt offen.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Wieder du, {name}. Stand {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Rivale markiert. {kills} Siege, {deaths} Tode.",
    ["Três sem cair. A série começou."] = "Drei ohne zu fallen. Die Serie hat begonnen.",
    ["Cinco no chão. Implacável."] = "Fünf am Boden. Unerbittlich.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Zehn ohne zu sterben. Das Feld kennt den Namen.",
    ["A série quebrou em {streak}."] = "Die Serie brach bei {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} Siege… und ein Sturz.",
    ["Em série"] = "In Serie",
    ["Implacável"] = "Unerbittlich",
    ["Lenda do campo"] = "Legende des Feldes",
    ["A ravina não tem bandeira para você."] = "Die Schlucht hat keine Flagge für dich.",
    ["O meio da ravina ficou mais quieto."] = "Die Mitte der Schlucht wurde stiller.",
    ["A bacia guarda mais um corpo."] = "Das Becken behält noch einen Körper.",
    ["Nem o estábulo te escondeu."] = "Nicht einmal der Stall hat dich versteckt.",
    ["Ashenvale fica com o corpo."] = "Das Eschental behält den Körper.",
    ["A floresta aceitou mais um."] = "Der Wald hat noch einen genommen.",
  },
  frFR = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name} : {kills} à {deaths}. Le compte reste ouvert.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Encore toi, {name}. Score {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Rival marqué. {kills} victimes, {deaths} morts.",
    ["Três sem cair. A série começou."] = "Trois sans tomber. La série commence.",
    ["Cinco no chão. Implacável."] = "Cinq au sol. Implacable.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Dix sans mourir. Le champ a appris le nom.",
    ["A série quebrou em {streak}."] = "La série s'est brisée à {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} victimes… et une chute.",
    ["Em série"] = "En série",
    ["Implacável"] = "Implacable",
    ["Lenda do campo"] = "Légende du champ",
    ["A ravina não tem bandeira para você."] = "Le goulet n'a pas de drapeau pour toi.",
    ["O meio da ravina ficou mais quieto."] = "Le milieu du goulet s'est tu.",
    ["A bacia guarda mais um corpo."] = "Le bassin garde un corps de plus.",
    ["Nem o estábulo te escondeu."] = "Même l'écurie ne t'a pas caché.",
    ["Ashenvale fica com o corpo."] = "Orneval garde le corps.",
    ["A floresta aceitou mais um."] = "La forêt en a pris un de plus.",
  },
  esES = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} a {deaths}. La cuenta sigue abierta.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Otra vez, {name}. Marcador {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Rival marcado. {kills} bajas, {deaths} muertes.",
    ["Três sem cair. A série começou."] = "Tres sin caer. La racha ha empezado.",
    ["Cinco no chão. Implacável."] = "Cinco en el suelo. Implacable.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Diez sin morir. El campo aprendió el nombre.",
    ["A série quebrou em {streak}."] = "La racha se rompió en {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} bajas… y una caída.",
    ["Em série"] = "En racha",
    ["Implacável"] = "Implacable",
    ["Lenda do campo"] = "Leyenda del campo",
    ["A ravina não tem bandeira para você."] = "La garganta no tiene bandera para ti.",
    ["O meio da ravina ficou mais quieto."] = "El centro de la garganta se quedó en silencio.",
    ["A bacia guarda mais um corpo."] = "La cuenca guarda otro cuerpo.",
    ["Nem o estábulo te escondeu."] = "Ni el establo te escondió.",
    ["Ashenvale fica com o corpo."] = "Vallefresno se queda con el cuerpo.",
    ["A floresta aceitou mais um."] = "El bosque aceptó a uno más.",
  },
  esMX = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} a {deaths}. La cuenta sigue abierta.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Otra vez, {name}. Marcador {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Rival marcado. {kills} bajas, {deaths} muertes.",
    ["Três sem cair. A série começou."] = "Tres sin caer. La racha empezó.",
    ["Cinco no chão. Implacável."] = "Cinco en el suelo. Implacable.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Diez sin morir. El campo aprendió el nombre.",
    ["A série quebrou em {streak}."] = "La racha se rompió en {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} bajas… y una caída.",
    ["Em série"] = "En racha",
    ["Implacável"] = "Implacable",
    ["Lenda do campo"] = "Leyenda del campo",
    ["A ravina não tem bandeira para você."] = "La garganta no tiene bandera para ti.",
    ["O meio da ravina ficou mais quieto."] = "El centro de la garganta quedó en silencio.",
    ["A bacia guarda mais um corpo."] = "La cuenca guarda otro cuerpo.",
    ["Nem o estábulo te escondeu."] = "Ni el establo te escondió.",
    ["Ashenvale fica com o corpo."] = "Vallefresno se queda con el cuerpo.",
    ["A floresta aceitou mais um."] = "El bosque aceptó a uno más.",
  },
  itIT = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} a {deaths}. Il conto resta aperto.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Di nuovo, {name}. Punteggio {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Rivale segnato. {kills} uccisioni, {deaths} morti.",
    ["Três sem cair. A série começou."] = "Tre senza cadere. La serie è iniziata.",
    ["Cinco no chão. Implacável."] = "Cinque a terra. Implacabile.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Dieci senza morire. Il campo ha imparato il nome.",
    ["A série quebrou em {streak}."] = "La serie si è spezzata a {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} uccisioni… e una caduta.",
    ["Em série"] = "In serie",
    ["Implacável"] = "Implacabile",
    ["Lenda do campo"] = "Leggenda del campo",
    ["A ravina não tem bandeira para você."] = "La gola non ha una bandiera per te.",
    ["O meio da ravina ficou mais quieto."] = "Il centro della gola si è fatto più quieto.",
    ["A bacia guarda mais um corpo."] = "Il bacino tiene un altro corpo.",
    ["Nem o estábulo te escondeu."] = "Nemmeno la stalla ti ha nascosto.",
    ["Ashenvale fica com o corpo."] = "Valtetra tiene il corpo.",
    ["A floresta aceitou mais um."] = "La foresta ne ha preso un altro.",
  },
  ruRU = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} к {deaths}. Счёт ещё открыт.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "Снова ты, {name}. Счёт {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "Соперник отмечен. {kills} убийств, {deaths} смертей.",
    ["Três sem cair. A série começou."] = "Три без падения. Серия началась.",
    ["Cinco no chão. Implacável."] = "Пять на земле. Неумолимый.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "Десять без смерти. Поле узнало имя.",
    ["A série quebrou em {streak}."] = "Серия оборвалась на {streak}.",
    ["{streak} abates… e uma queda."] = "{streak} убийств… и падение.",
    ["Em série"] = "В серии",
    ["Implacável"] = "Неумолимый",
    ["Lenda do campo"] = "Легенда поля",
    ["A ravina não tem bandeira para você."] = "У ущелья нет флага для тебя.",
    ["O meio da ravina ficou mais quieto."] = "Середина ущелья стала тише.",
    ["A bacia guarda mais um corpo."] = "Низина хранит ещё одно тело.",
    ["Nem o estábulo te escondeu."] = "Даже конюшня тебя не спрятала.",
    ["Ashenvale fica com o corpo."] = "Ясеневый лес оставляет тело себе.",
    ["A floresta aceitou mais um."] = "Лес принял ещё одного.",
  },
  koKR = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}: {kills} 대 {deaths}. 장부는 아직 열려 있다.",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "또 너냐, {name}. 전적 {kills}–{deaths}.",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "숙적 기록. 처치 {kills}, 사망 {deaths}.",
    ["Três sem cair. A série começou."] = "세 번을 쓰러지지 않았다. 연승이 시작됐다.",
    ["Cinco no chão. Implacável."] = "다섯이 바닥에 있다. 무자비하다.",
    ["Dez sem morrer. O campo aprendeu o nome."] = "죽지 않고 열. 전장이 이름을 배웠다.",
    ["A série quebrou em {streak}."] = "연승이 {streak}에서 끊겼다.",
    ["{streak} abates… e uma queda."] = "처치 {streak}… 그리고 한 번의 추락.",
    ["Em série"] = "연승 중",
    ["Implacável"] = "무자비",
    ["Lenda do campo"] = "전장의 전설",
    ["A ravina não tem bandeira para você."] = "협곡에는 너를 위한 깃발이 없다.",
    ["O meio da ravina ficou mais quieto."] = "협곡 한가운데가 더 조용해졌다.",
    ["A bacia guarda mais um corpo."] = "분지가 시신 하나를 더 품는다.",
    ["Nem o estábulo te escondeu."] = "마구간도 너를 숨기지 못했다.",
    ["Ashenvale fica com o corpo."] = "잿빛 골짜기가 시신을 남긴다.",
    ["A floresta aceitou mais um."] = "숲이 하나를 더 받아 들였다.",
  },
  zhCN = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}：{kills} 比 {deaths}。账还没结。",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "又是你，{name}。比分 {kills}–{deaths}。",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "宿敌已记下。击杀 {kills}，死亡 {deaths}。",
    ["Três sem cair. A série começou."] = "三场未倒。连杀开始了。",
    ["Cinco no chão. Implacável."] = "五个倒在地上。无情。",
    ["Dez sem morrer. O campo aprendeu o nome."] = "十场未死。战场记住了这个名字。",
    ["A série quebrou em {streak}."] = "连杀断在 {streak}。",
    ["{streak} abates… e uma queda."] = "{streak} 次击杀……然后倒下。",
    ["Em série"] = "连杀中",
    ["Implacável"] = "无情",
    ["Lenda do campo"] = "战场传说",
    ["A ravina não tem bandeira para você."] = "峡谷没有属于你的旗帜。",
    ["O meio da ravina ficou mais quieto."] = "峡谷中央安静了些。",
    ["A bacia guarda mais um corpo."] = "盆地又留下一具尸体。",
    ["Nem o estábulo te escondeu."] = "马厩也藏不住你。",
    ["Ashenvale fica com o corpo."] = "灰谷留下了这具尸体。",
    ["A floresta aceitou mais um."] = "森林又收下了一个。",
  },
  zhTW = {
    ["{name}: {kills} a {deaths}. A conta continua."] = "{name}：{kills} 比 {deaths}。帳還沒結。",
    ["De novo, {name}. Placar {kills}–{deaths}."] = "又是你，{name}。比分 {kills}–{deaths}。",
    ["Rival marcado. {kills} abates, {deaths} mortes."] = "宿敵已記下。擊殺 {kills}，死亡 {deaths}。",
    ["Três sem cair. A série começou."] = "三場未倒。連殺開始了。",
    ["Cinco no chão. Implacável."] = "五個倒在地上。無情。",
    ["Dez sem morrer. O campo aprendeu o nome."] = "十場未死。戰場記住了這個名字。",
    ["A série quebrou em {streak}."] = "連殺斷在 {streak}。",
    ["{streak} abates… e uma queda."] = "{streak} 次擊殺……然後倒下。",
    ["Em série"] = "連殺中",
    ["Implacável"] = "無情",
    ["Lenda do campo"] = "戰場傳說",
    ["A ravina não tem bandeira para você."] = "峽谷沒有屬於你的旗幟。",
    ["O meio da ravina ficou mais quieto."] = "峽谷中央安靜了些。",
    ["A bacia guarda mais um corpo."] = "盆地又留下一具屍體。",
    ["Nem o estábulo te escondeu."] = "馬廄也藏不住你。",
    ["Ashenvale fica com o corpo."] = "梣谷留下了這具屍體。",
    ["A floresta aceitou mais um."] = "森林又收下了一個。",
  },
}

local function replaceStrings(node, map)
  if type(node) == "string" then
    return map[node] or node
  end
  if type(node) ~= "table" then
    return node
  end
  for k, v in pairs(node) do
    node[k] = replaceStrings(v, map)
  end
  return node
end

local packs = ns.Data and ns.Data.LocaleSpeech
if packs then
  for code, map in pairs(OVERLAY) do
    if packs[code] then
      replaceStrings(packs[code], map)
    end
  end
end

_G[addonName] = ns
