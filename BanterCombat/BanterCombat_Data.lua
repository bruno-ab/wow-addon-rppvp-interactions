local addonName, ns = ...
ns = ns or {}

--[[
  Banco de falas — WoW Classic Era / Hardcore.
  Chaves de raça/classe em inglês (API). Textos em PT-BR.
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

ns.Data.Speech = {
  kill = {
    common = {
      "Menos um.",
      "O chão é o seu lugar.",
      "Próximo!",
      "Fácil demais.",
      "Caia e fique quieto.",
      "Vitória.",
      "Você tropeçou na própria arrogância.",
      "Outro corpo no caminho.",
    },
    rare_race = {
      Human = { "Mais um Humano orgulhoso no pó.", "Stormwind vai sentir essa falta." },
      Dwarf = { "Anão curto, queda curta.", "A cerveja não salvou você." },
      NightElf = { "A Lua não cobre os mortos, Elfo.", "Teldrassil longe demais para te salvar." },
      Gnome = { "Gnomo: pequeno alvo, grande erro.", "Engrenagens espalhadas." },
      Orc = { "Menos um Orc.", "Orgrimmar perde força hoje." },
      Scourge = { "De volta ao túmulo, Morto-vivo.", "A peste não te protege de mim." },
      Tauren = { "O boi caiu.", "Thunder Bluff vai ouvir o trovão da queda." },
      Troll = { "Troll no chão — sem regenerar dessa vez.", "Sen'jin não te alcança agora." },
    },
    rare_class = {
      WARRIOR = { "Guerreiro sem fôlego.", "Sua fúria acabou." },
      PALADIN = { "A Luz piscou — e apagou.", "Paladino caído, juramento quebrado." },
      HUNTER = { "Caçador virou presa.", "Seu pet não te salvou." },
      ROGUE = { "Ladino descoberto — e acabado.", "Sombras não escondem a morte." },
      PRIEST = { "Sem cura para isso, Sacerdote.", "Sua fé não bastou." },
      SHAMAN = { "Os elementos se calaram, Xamã.", "Totens no chão." },
      MAGE = { "Magia frágil.", "Sem portal de fuga." },
      WARLOCK = { "Seu demônio não te puxou a tempo.", "Almas demais, vida de menos." },
      DRUID = { "Forma nenhuma te salvou, Druida.", "A natureza olhou para o outro lado." },
    },
    epic = {
      WARRIOR = {
        MAGE = { "Espada corta feitiço — e ego.", "Seu gelo derreteu na minha lâmina." },
        ROGUE = { "Guerreiro vs Ladino: força venceu astúcia." },
        PRIEST = { "Sua cura não acompanhou minha fúria." },
      },
      MAGE = {
        WARRIOR = { "Armadura não para uma bola de fogo bem colocada." },
        ROGUE = { "Polymorph? Não. Incineração." },
        HUNTER = { "Distância? Eu encurto com gelo." },
      },
      ROGUE = {
        MAGE = { "Antes do cast, a faca.", "Seu escudo de mana não cobre as costas." },
        PRIEST = { "Silêncio? Eu cheguei primeiro." },
        WARRIOR = { "Charge? Eu já estava atrás de você." },
      },
      PALADIN = {
        WARLOCK = { "A Luz queima demônios — e Bruxos." },
        UNDEAD = { "A Luz não falha com Mortos-vivos." },
      },
      HUNTER = {
        ROGUE = { "Armadilha pronta. Você que pisou." },
        MAGE = { "Feitiço longo, flecha rápida." },
      },
      PRIEST = {
        WARLOCK = { "Sombra contra sombra — a minha venceu." },
        ROGUE = { "Você sumiu. Eu rezei. Você caiu." },
      },
      SHAMAN = {
        MAGE = { "Fogo elemental > fogo arcano." },
        WARRIOR = { "Choque e queda." },
      },
      WARLOCK = {
        PALADIN = { "A Luz hesita. O Caos não." },
        PRIEST = { "Sua fé alimentou meu demônio." },
      },
      DRUID = {
        ROGUE = { "Urso > faca.", "Raízes — e fim." },
        MAGE = { "Cyclone? Eu espero. Depois eu mato." },
      },
    },
    legendary = {
      -- Classe vs Classe / lore
      { class = "MAGE", vsClass = "WARRIOR", text = "Entre runas e aço, o Arcano lembrou quem manda em Azeroth." },
      { class = "WARRIOR", vsClass = "MAGE", text = "Nenhuma torre de Ironforge ensinou o que a frente de batalha cobra." },
      { race = "Orc", vsRace = "Human", text = "A Aliança esqueceu a Sedenda — eu não." },
      { race = "Human", vsRace = "Orc", text = "Stormwind se ergueu das cinzas. Você, não." },
      { race = "NightElf", vsRace = "Orc", text = "Ashenvale ainda chora. Eu cobro a dívida em sangue." },
      { race = "Tauren", vsRace = "Dwarf", text = "A Mãe Terra não distingue — mas eu escolho quem cai." },
      { class = "PALADIN", vsClass = "WARLOCK", text = "Enquanto houver um juramento, o Caos encontra limite." },
      { class = "ROGUE", vsClass = "ROGUE", text = "Dois ladinos. Um erro. Um sobrevivente." },
      { class = "PRIEST", vsClass = "PRIEST", text = "Luz e Sombra — hoje a minha doutrina prevaleceu." },
      { class = "HUNTER", vsClass = "DRUID", text = "Caçador e guarda da floresta. Só um continua a trilha." },
    },
  },

  death = {
    common = {
      "Dessa vez… você.",
      "Vou lembrar desse nome.",
      "A dívida ficou aberta.",
      "Bom golpe. Não será o último.",
      "Caí. Mas não esqueci.",
      "Respire fundo. Eu volto.",
    },
    rare_race = {
      Human = { "Um Humano me derrubou. Temporário." },
      Orc = { "Orc… anotei." },
      Scourge = { "Morto-vivo me matou. Irônico." },
      NightElf = { "Elfo da Noite — a Lua te favoreceu hoje." },
    },
    rare_class = {
      MAGE = { "Mago… sua magia falou mais alto — por agora." },
      ROGUE = { "Ladino. Clássico." },
      WARRIOR = { "Guerreiro bruto. Respeito. Vingança depois." },
      HUNTER = { "Caçador. A presa sou eu, desta vez." },
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
    "Dívida paga!",
    "A vingança é um prato que se come frio!",
    "Eu disse que voltaria.",
    "Conta fechada. Com juros.",
    "Você me matou. Eu te apaguei.",
    "Lembra de mim? Agora sou a última coisa que você vê.",
    "Do pó eu me ergui. Você, não.",
    "Vingança servida — bem passada.",
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
}

_G[addonName] = ns
