local addonName, ns = ...
ns = ns or {}

--[[
  Banco de falas — WoW Classic Era / Hardcore.
  Chaves de raça/classe em inglês (API). Textos-base em PT-BR.
  Outros idiomas oficiais: BanterCombat_Speech.lua.
]]

ns.Data = ns.Data or {}

ns.Data.MILESTONES = { 10, 50, 100 }

ns.Data.RACES = {
  Alliance = { "Human", "Dwarf", "NightElf", "Gnome" },
  Horde = { "Orc", "Scourge", "Tauren", "Troll" },
}

ns.Data.CLASSES = {
  "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}

ns.Data.RACE_LABEL = {
  Human = "Humano",
  Dwarf = "Anão",
  NightElf = "Elfo da Noite",
  Gnome = "Gnomo",
  Orc = "Orc",
  Scourge = "Morto-vivo",
  Tauren = "Tauren",
  Troll = "Troll",
}

ns.Data.CLASS_LABEL = {
  WARRIOR = "Guerreiro",
  PALADIN = "Paladino",
  HUNTER = "Caçador",
  ROGUE = "Ladino",
  PRIEST = "Sacerdote",
  SHAMAN = "Xamã",
  MAGE = "Mago",
  WARLOCK = "Bruxo",
  DRUID = "Druida",
}

-- Probabilidades (soma = 100)
ns.Data.RARITY_WEIGHTS = {
  { key = "legendary", weight = 1 },
  { key = "epic", weight = 15 },
  { key = "rare", weight = 20 },
  { key = "common", weight = 64 },
}

-- Hex sem o prefixo |c (ARGB). A chave "rare" é o degrau Incomum (verde).
ns.Data.RARITY_COLOR = {
  common = "FF9D9D9D",
  rare = "FF1EFF00",
  epic = "FFA335EE",
  legendary = "FFFF8000",
  revenge = "FFFFD100",
  milestone = "FFFFD100",
  death = "FFCC6666",
}

ns.Data.Speech = {
  kill = {
    common = {
      "O nome some do campo. O corpo fica.",
      "A terra aceitou você sem cerimônia.",
      "Quem vier depois já sabe o preço.",
      "Você veio preparado para outra luta.",
      "Fique aí. O campo segue sem você.",
      "Este pedaço de terra mudou de mãos.",
      "A arrogância chegou primeiro. A queda veio atrás.",
      "Mais um nome que o vento vai levar.",
    },
    rare_race = {
      Human = { "O brasão de Ventobravo ficou no pó.", "Ventobravo vai contar um lugar vazio à mesa." },
      Dwarf = { "A barba ainda apontava para a frente. O corpo, não.", "Nem a cerveja de Altaforja segurou essa queda." },
      NightElf = { "A Lua viu, elfo. Desta vez ela não cobriu ninguém.", "Teldrassil fica longe demais para puxar você de volta." },
      Gnome = { "Engrenagem pequena, erro do tamanho de Gnomeregan.", "As engrenagens ficaram. O gnomo, não." },
      Orc = { "Orgrimmar perde mais um nome no vento.", "O portão de Orgrimmar fica um guerreiro mais leve." },
      Scourge = { "A Cidade Baixa já te esperava. Eu só abri a porta.", "A peste para nos vivos. Em você, ela não tinha mais o que fazer." },
      Tauren = { "O chifre bateu na terra. Penhasco do Trovão vai ouvir.", "Penhasco do Trovão ouve o baque, não o trovão." },
      Troll = { "Sen'jin não regenera um nome que o chão já levou.", "A vila fica longe. O chão daqui é mais rápido." },
    },
    rare_class = {
      WARRIOR = { "A fúria saiu pela boca e não voltou.", "O grito de guerra morreu no meio da sílaba." },
      PALADIN = { "A Luz piscou no martelo e apagou no chão.", "O juramento ficou de pé. O paladino, não." },
      HUNTER = { "A flecha ainda estava no arco quando a presa mudou de lado.", "A fera olhou para o dono e chegou tarde." },
      ROGUE = { "A sombra te entregou. O resto foi curto.", "A capa cobriu o corpo. Não cobriu o fim." },
      PRIEST = { "A prece chegou na palavra errada.", "Havia fé nas mãos. O duelo já tinha dono." },
      SHAMAN = { "Os elementos ouviram o nome e escolheram o silêncio.", "O totem fincou. A terra não devolveu." },
      MAGE = { "A runa apagou na ordem em que foi escrita.", "O portal abriu para o lugar errado." },
      WARLOCK = { "O diabrete hesitou. Esse segundo foi o último.", "O pacto cobrou em alma. O corpo não tinha troco." },
      DRUID = { "Urso, gato ou árvore: nenhuma forma devolveu o fôlego.", "A clareira viu e não tomou partido. Eu tomei." },
    },
    epic = {
      WARRIOR = {
        MAGE = { "Espada corta feitiço — e ego.", "Seu gelo derreteu na minha lâmina." },
        ROGUE = { "A astúcia chegou primeiro. A força ficou por último." },
        PRIEST = { "Sua cura não acompanhou minha fúria." },
        HUNTER = { "Flechas quebram. Escudos não." },
        WARLOCK = { "Demônio ou não — a lâmina chega." },
        DRUID = { "Urso ou gato: a fúria é mais alta." },
        SHAMAN = { "Totens caem. Guerreiros ficam." },
        PALADIN = { "A bolha pediu um segundo. O golpe não esperou." },
        WARRIOR = { "Dois guerreiros. Um de pé." },
      },
      MAGE = {
        WARRIOR = { "Armadura não para uma bola de fogo bem colocada." },
        ROGUE = { "O carneiro não veio. O fogo, sim." },
        HUNTER = { "A distância encolheu no gelo." },
        PRIEST = { "Sua sombra derreteu no meu fogo." },
        WARLOCK = { "O caos gritou. O arcano falou por último." },
        DRUID = { "As raízes pediram tempo. A nevasca não deu." },
        SHAMAN = { "O fogo da torre falou mais alto que o totem." },
        PALADIN = { "A Luz pisca. O Arcano explode." },
        MAGE = { "Duelo de torres. Eu fiquei de pé." },
      },
      ROGUE = {
        MAGE = { "Antes da última sílaba, a faca.", "Seu escudo de mana não cobre as costas." },
        PRIEST = { "O silêncio chegou. Eu cheguei antes." },
        WARRIOR = { "A investida veio de frente. Eu já estava atrás." },
        HUNTER = { "A armadilha estava armada. Eu passei por cima." },
        WARLOCK = { "O medo nem chegou a sair da boca." },
        DRUID = { "A forma de viagem não corre mais rápido que a faca." },
        SHAMAN = { "O lobo fantasma correu. O xamã ficou." },
        PALADIN = { "A bolha estourou nas costas. O juramento não alcançou." },
        ROGUE = { "Duas capas. Uma sombra. Eu saí dela primeiro." },
      },
      PALADIN = {
        WARLOCK = { "A Luz queima demônios — e Bruxos." },
        ROGUE = { "Consagração encontra sombra." },
        MAGE = { "A imunidade segurou o estouro. A aula acabou aí." },
        WARRIOR = { "Retribuição cobrada." },
        PRIEST = { "Duas luzes. A minha julgou." },
        HUNTER = { "Flecha desviada pela graça." },
        DRUID = { "A natureza se curva ao juramento." },
        SHAMAN = { "Totem vs martelo — martelo." },
        PALADIN = { "Dois juramentos. Um quebrado." },
      },
      HUNTER = {
        ROGUE = { "Armadilha pronta. Você que pisou." },
        MAGE = { "Feitiço longo, flecha rápida." },
        WARRIOR = { "Você correu em círculo. A flecha não." },
        WARLOCK = { "A fera obedece. O demônio chegou tarde." },
        PRIEST = { "Sem parede, sem prece. A flecha achou o peito." },
        DRUID = { "A floresta tem dois caçadores. Sobrou um." },
        SHAMAN = { "O choque saiu. A concussão chegou primeiro." },
        PALADIN = { "A bolha acabou. A flecha entrou no que restou." },
        HUNTER = { "Dois caçadores. Uma mira ficou." },
      },
      PRIEST = {
        WARLOCK = { "Sombra contra sombra — a minha venceu." },
        ROGUE = { "Você sumiu. Eu rezei. Você caiu." },
        MAGE = { "Contador de magia: eu." },
        WARRIOR = { "O muro de escudos cobre o peito. A mente ficou aberta." },
        HUNTER = { "O disparo espalhou o corpo. A mente já era minha." },
        DRUID = { "A cura quente apagou no meio do nome." },
        SHAMAN = { "Tirei o feitiço da cabeça. O resto veio junto." },
        PALADIN = { "Luz vs Luz. A minha condenou." },
        PRIEST = { "Dois púlpitos. Um silêncio." },
      },
      SHAMAN = {
        MAGE = { "O fogo do espírito falou mais alto que o da torre." },
        WARRIOR = { "Choque e queda." },
        ROGUE = { "O totem engoliu a facada." },
        WARLOCK = { "Tirei a maldição. O fim veio atrás." },
        PRIEST = { "A terra tremeu e o medo não saiu." },
        HUNTER = { "O gelo no pé acabou a corrida." },
        DRUID = { "A terra escolheu o xamã." },
        PALADIN = { "Totem de fogo derrete fé rasa." },
        SHAMAN = { "Dois xamãs. Um espírito." },
      },
      WARLOCK = {
        PALADIN = { "A Luz hesita. O Caos não." },
        PRIEST = { "Sua fé alimentou meu demônio." },
        MAGE = { "A boca do mago fechou. A sombra entrou." },
        ROGUE = { "O medo segurou. A alma saiu. O adeus foi curto." },
        WARRIOR = { "Não houve coleira. Houve o fim." },
        HUNTER = { "A fera obedeceu ao dono. O caçador vil obedeceu a mim." },
        DRUID = { "O ciclone girou. A maldição ficou no corpo." },
        SHAMAN = { "O totem comeu um feitiço. O segundo não pediu licença." },
        WARLOCK = { "Dois pactos. Um senhor." },
      },
      DRUID = {
        ROGUE = { "A faca achou pelo. O urso achou o pescoço.", "Raízes — e fim." },
        MAGE = { "O vento te segurou. Eu esperei. Depois acabei." },
        WARRIOR = { "O golpe na cabeça. O silêncio da clareira." },
        HUNTER = { "A presa virou predador." },
        WARLOCK = { "O veneno saiu. A fúria ficou." },
        PRIEST = { "A seiva que era sua passou para mim." },
        SHAMAN = { "Raízes vs totem — raízes." },
        PALADIN = { "O urso recebeu a Luz e devolveu silêncio." },
        DRUID = { "Dois guardiões. Uma clareira." },
      },
    },
    legendary = {
      { class = "MAGE", vsClass = "WARRIOR", text = "Entre runas e aço, o Arcano lembrou quem manda em Azeroth." },
      { class = "WARRIOR", vsClass = "MAGE", text = "Nenhuma torre de Ironforge ensinou o que a frente de batalha cobra." },
      { class = "ROGUE", vsClass = "MAGE", text = "Antes da sílaba final, a lâmina já havia escrito o epílogo." },
      { class = "PALADIN", vsClass = "WARLOCK", text = "Enquanto houver um juramento, o Caos encontra limite." },
      { class = "WARLOCK", vsClass = "PALADIN", text = "A Luz brilha. O abismo engole." },
      { class = "HUNTER", vsClass = "DRUID", text = "Caçador e guarda da floresta. Só um continua a trilha." },
      { class = "DRUID", vsClass = "HUNTER", text = "A natureza não escolhe lados — eu escolhi o seu fim." },
      { class = "PRIEST", vsClass = "PRIEST", text = "Luz e Sombra — hoje a minha doutrina prevaleceu." },
      { class = "ROGUE", vsClass = "ROGUE", text = "Dois ladinos. Um erro. Um sobrevivente." },
      { class = "SHAMAN", vsClass = "MAGE", text = "Os espíritos sopraram mais forte que qualquer grimório." },
      { class = "WARRIOR", vsClass = "ROGUE", text = "Astúcia corta. Fúria esmaga." },
      { race = "Orc", vsRace = "Human", text = "A Aliança esqueceu a Segunda Guerra. Eu não." },
      { race = "Human", vsRace = "Orc", text = "Stormwind se ergueu das cinzas. Você, não." },
      { race = "NightElf", vsRace = "Orc", text = "Ashenvale ainda chora. Eu cobro a dívida em sangue." },
      { race = "Orc", vsRace = "NightElf", text = "A floresta queimou uma vez. Sua queda é a segunda." },
      { race = "Tauren", vsRace = "Dwarf", text = "A Mãe Terra não distingue — mas eu escolho quem cai." },
      { race = "Dwarf", vsRace = "Tauren", text = "A montanha é mais dura que o pasto." },
      { race = "Gnome", vsRace = "Troll", text = "A engenharia contou um. A regeneração contou zero." },
      { race = "Troll", vsRace = "Gnome", text = "Pequeno alvo… grande explosão de ódio." },
      { race = "Scourge", vsRace = "Human", text = "Lordaeron já morreu. Você só atrasou o óbvio." },
      { race = "Human", vsRace = "Scourge", text = "A peste encontra aço — e perde." },
    },
  },

  death = {
    common = {
      "Desta vez o chão ficou comigo. O nome, eu levo.",
      "Esse nome entra na conta. A terra guarda o resto.",
      "A dívida ficou aberta no meio do campo.",
      "O golpe foi limpo. A resposta ainda não saiu.",
      "Caí com o nome na boca. Ele não sai.",
      "Respira. O caminho de volta já tem dono.",
    },
    rare_race = {
      Human = { "Um humano me deitou. O brasão dele não fica." },
      Orc = { "Orc. O nome entrou na conta antes do corpo esfriar." },
      Scourge = { "Um morto-vivo me deitou. A volta ainda está em aberto." },
      NightElf = { "A Lua ficou com o elfo desta vez. A dívida, comigo." },
    },
    rare_class = {
      MAGE = { "A magia falou mais alto. O aço ainda não respondeu." },
      ROGUE = { "A faca veio de onde a capa ainda estava." },
      WARRIOR = { "O golpe foi de frente. A resposta espera a próxima vez." },
      HUNTER = { "A flecha achou o peito. A trilha de volta já está marcada." },
    },
    epic = {
      MAGE = { WARRIOR = { "Seu gelo me pegou. Meu aço te espera." } },
      ROGUE = { PRIEST = { "Nas sombras você venceu. Na luz eu cobro." } },
      WARLOCK = { PALADIN = { "O Caos riu hoje. A Luz responde amanhã." } },
    },
    legendary = {
      { text = "Azeroth não esquece. Nem eu." },
      { text = "Marque este dia. O próximo é meu." },
    },
  },

  revenge = {
    "A dívida fechou no seu peito.",
    "A vingança esfriou no caminho. Chegou do mesmo jeito.",
    "Eu avisei que o nome voltava. Aqui está.",
    "A conta fechou, e os juros vieram no aço.",
    "Você me deitou uma vez. Eu te tirei do campo.",
    "Você me conhece. Esta é a última vez que o olhar alcança.",
    "Eu levantei do pó. Você fica nele.",
    "A vingança chegou passada do ponto, e ainda assim serviu.",
  },

  milestones = {
    race = {
      [10] = {
        Orc = "Dez Orcs no chão. Orgrimmar já sussurra meu nome.",
        Human = "Dez Humanos. A Aliança sente o corte.",
        Scourge = "Dez Mortos-vivos. A peste perde terreno.",
        Tauren = "Dez Taurens. O trovão agora é meu.",
        Troll = "Dez Trolls. Sem regenerar o ego.",
        Dwarf = "Dez Anões. A montanha cede.",
        NightElf = "Dez Elfos da Noite. A Lua se cala.",
        Gnome = "Dez Gnomos. Engrenagens demais no chão.",
      },
      [50] = {
        Orc = "Cinqüenta Orcs no chão! O Pesadelo de Orgrimmar!",
        Human = "Cinqüenta Humanos! Stormwind treme!",
        Scourge = "Cinqüenta Mortos-vivos! Até a Cidade Baixa cala!",
        Tauren = "Cinqüenta Taurens! Mulgore ouve o eco!",
        Troll = "Cinqüenta Trolls! Sen'jin sem resposta!",
        Dwarf = "Cinqüenta Anões! Ironforge em silêncio!",
        NightElf = "Cinqüenta Elfos! Darnassus sem luar!",
        Gnome = "Cinqüenta Gnomos! Gnomeregan em panes!",
      },
      [100] = {
        Orc = "CEM Orcs. Lenda viva contra a Horda.",
        Human = "CEM Humanos. A Aliança conhece o medo.",
        Scourge = "CEM Mortos-vivos. Nem a morte te protege de mim.",
        Tauren = "CEM Taurens. A Mãe Terra testemunhou.",
        Troll = "CEM Trolls. Fim da regeneração.",
        Dwarf = "CEM Anões. A bigorna quebrou.",
        NightElf = "CEM Elfos da Noite. Era das Trevas, para eles.",
        Gnome = "CEM Gnomos. Experimento concluído.",
      },
    },
    class = {
      [10] = {
        MAGE = "Décimo Mago derrotado. Sua magia não tem mais segredos para mim!",
        WARRIOR = "Dez Guerreiros. A linha de frente cede.",
        ROGUE = "Dez Ladinos. As sombras são minhas.",
        PRIEST = "Dez Sacerdotes. Sem absolvição.",
        HUNTER = "Dez Caçadores. A presa inverteu o jogo.",
        WARLOCK = "Dez Bruxos. Demônios sem dono.",
        PALADIN = "Dez Paladinos. A Luz piscou demais.",
        SHAMAN = "Dez Xamãs. Elementos silenciados.",
        DRUID = "Dez Druidas. A natureza escolheu o outro lado.",
      },
      [50] = {
        MAGE = "Cinqüenta Magos! As torres tremeram!",
        WARRIOR = "Cinqüenta Guerreiros! Nenhum charge te salva!",
        ROGUE = "Cinqüenta Ladinos! Sem stealth seguro!",
        PRIEST = "Cinqüenta Sacerdotes! Fé insuficiente!",
        HUNTER = "Cinqüenta Caçadores! Sem pet que baste!",
        WARLOCK = "Cinqüenta Bruxos! O Caos cobrou o preço!",
        PALADIN = "Cinqüenta Paladinos! Bolhas estouradas!",
        SHAMAN = "Cinqüenta Xamãs! Totens no chão!",
        DRUID = "Cinqüenta Druidas! Formas esgotadas!",
      },
      [100] = {
        MAGE = "CEM Magos. Arquimago do campo de batalha.",
        WARRIOR = "CEM Guerreiros. Campeão sem rival.",
        ROGUE = "CEM Ladinos. Mestre das sombras abatidas.",
        PRIEST = "CEM Sacerdotes. Inquisidor sem piedade.",
        HUNTER = "CEM Caçadores. Predador absoluto.",
        WARLOCK = "CEM Bruxos. O abismo olhou — e piscou.",
        PALADIN = "CEM Paladinos. A Luz aprendeu respeito.",
        SHAMAN = "CEM Xamãs. Senhor dos elementos caídos.",
        DRUID = "CEM Druidas. Guardião… ou algo pior.",
      },
    },
  },

  rival = {
    "{name}. {kills} vezes eu fiquei. {deaths} vezes a terra ficou comigo.",
    "Outra vez, {name}. O campo já conhece esse placar: {kills}–{deaths}.",
    "O nome {name} já tem história. {kills} abates, {deaths} quedas.",
  },

  personal = {
    [5] = "Cinco vezes, {name}. O nome já tem dono.",
    [10] = "Dez vezes, {name}. Isso deixou de ser encontro.",
  },

  streak = {
    [3] = { "Três nomes no chão e o meu ainda de pé." },
    [5] = { "Cinco quedas. O campo começa a desviar de mim." },
    [10] = { "Dez sem cair. O campo já sussurra o nome antes do golpe." },
  },

  streakBreak = {
    "A série parou em {streak}. O chão cobrou a vez.",
    "{streak} nomes, e depois o meu no pó.",
  },

  titles = {
    [3] = "Em série",
    [5] = "Implacável",
    [10] = "Lenda do campo",
  },

  zone = {
    warsong = {
      "A ravina ficou com a bandeira. Você ficou com o chão.",
      "O meio da ravina perdeu uma voz.",
    },
    arathi = {
      "A bacia de Arathi guarda mais um nome entre os moinhos.",
      "Nem o estábulo, nem a mina, nem o moinho te esconderam.",
    },
    ashenvale = {
      "Vale Gris fica com o corpo entre as cinzas.",
      "A floresta de Vale Gris aceitou mais um sem cerimônia.",
    },
  },
}

function ns.Data.ActiveSpeech()
  local code = ns.LocaleCode or "ptBR"
  if code == "ptBR" then
    return ns.Data.Speech
  end
  local packs = ns.Data.LocaleSpeech
  if packs and packs[code] then
    return packs[code]
  end
  if packs and packs.enUS then
    return packs.enUS
  end
  return ns.Data.Speech
end

local function labelFrom(group, key, fallback)
  if not key then
    return "?"
  end
  local code = ns.LocaleCode or "ptBR"
  local labels = ns.Data.LocaleLabels
  if code ~= "ptBR" and labels and labels[code] and labels[code][group] and labels[code][group][key] then
    return labels[code][group][key]
  end
  if code == "ptBR" then
    return fallback[key] or key
  end
  if labels and labels.enUS and labels.enUS[group] and labels.enUS[group][key] then
    return labels.enUS[group][key]
  end
  return fallback[key] or key
end

function ns.Data.RaceLabel(race)
  return labelFrom("race", race, ns.Data.RACE_LABEL)
end

function ns.Data.ClassLabel(class)
  return labelFrom("class", class, ns.Data.CLASS_LABEL)
end

_G[addonName] = ns
