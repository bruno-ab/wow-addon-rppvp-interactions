local addonName, ns = ...
ns = ns or {}
ns.Chronicle = ns.Chronicle or {}

local Chronicle = ns.Chronicle
local Data = ns.Data
local L = ns.L

local FEM_RACE = {
  ["Humano"] = "Humana",
  ["Anão"] = "Anã",
  ["Elfo da Noite"] = "Elfa da Noite",
  ["Gnomo"] = "Gnomida",
  ["Orc"] = "Orquisa",
  ["Morto-vivo"] = "Morta-viva",
  ["Tauren"] = "Taurena",
  ["Troll"] = "Trollesa",
}

local FEM_CLASS = {
  ["Guerreiro"] = "Guerreira",
  ["Paladino"] = "Paladina",
  ["Caçador"] = "Caçadora",
  ["Ladino"] = "Ladina",
  ["Sacerdote"] = "Sacerdotisa",
  ["Mago"] = "Maga",
  ["Bruxo"] = "Bruxa",
  ["Druida"] = "Druidesa",
}

local DAY_OPEN = {
  ptBR = {
    first = "Ainda era cedo na minha história: nível {level}, {pg:um|uma} {myclass} aprendendo o peso do próprio nome. Naquele dia o caminho passou por {places}. {ambient}",
    again = "No dia {date} eu já carregava o ofício de {myclass} no nível {level}. O caminho cruzou {places}. {ambient}",
  },
  enUS = {
    first = "It was still early in my story: level {level}, a {myclass} learning the weight of my own name. That day the road ran through {places}. {ambient}",
    again = "On {date} I already carried the craft of a {myclass} at level {level}. The road crossed {places}. {ambient}",
  },
}

local DAY_CLOSE = {
  ptBR = {
    one = "O caderno fechou com um único nome: {names}. Bastou.",
    few = "Antes do fim do dia, {count} encontros ficaram gravados: {names}.",
    many = "Foi um dia longo. {count} nomes entraram no caderno — {names} — e o chão ainda cheirava a ferro.",
  },
  enUS = {
    one = "The book closed on a single name: {names}. It was enough.",
    few = "Before the day ended, {count} meetings stayed written: {names}.",
    many = "It was a long day. {count} names entered the book — {names} — and the ground still smelled of iron.",
  },
}

local RELATION = {
  ptBR = {
    firstEver = "Meu primeiro alvo no mundo foi {g:um|uma} {race} {class}. Eu ainda não sabia o nome. Depois soube: {name}.",
    stranger = "Encontrei {g:um|uma} {race} {class} que eu nunca tinha visto. O nome veio depois do golpe: {name}.",
    rematch = "{name} voltou. Já tínhamos história — placar {priorKills}–{priorDeaths} — e {g:ele|ela} ainda era {g:um|uma} {race} {class}.",
    hunted = "{name} já tinha me derrubado {priorDeaths} {priorDeathsWord}. Desta vez fui eu quem encontrou {g:um|uma} {race} {class} no caminho.",
    rival = "O rival {name} cruzou o campo de novo. {priorKills} abates meus, {priorDeaths} quedas. {g:Um|Uma} {race} {class} que o caderno já conhecia.",
    revenge = "Vingança. {name} ainda tinha o gosto do meu último sangue na boca quando {g:um|uma} {race} {class} caiu sob o meu golpe.",
    sameDay = "Mais tarde, no mesmo dia, {name} — de novo {g:um|uma} {race} {class} — apareceu onde eu ainda estava.",
  },
  enUS = {
    firstEver = "My first quarry in the world was a {race} {class}. I did not know the name yet. Then I learned it: {name}.",
    stranger = "I met a {race} {class} I had never seen. The name came after the blow: {name}.",
    rematch = "{name} came back. We already had a history — score {priorKills}–{priorDeaths} — and they were still a {race} {class}.",
    hunted = "{name} had already put me down {priorDeaths} {priorDeathsWord}. This time I was the one who found a {race} {class} on the road.",
    rival = "Rival {name} crossed the field again. {priorKills} kills of mine, {priorDeaths} falls. A {race} {class} the book already knew.",
    revenge = "Revenge. {name} still had the taste of my last blood when a {race} {class} fell under my blow.",
    sameDay = "Later the same day, {name} — again a {race} {class} — showed up where I still stood.",
  },
}

local PLACE = {
  ptBR = {
    withSub = "O duelo aconteceu em {zone}, no trecho chamado {subzone}.",
    zoneOnly = "O campo era {zone}.",
    bg = "Estávamos em campo de batalha: {zone}.",
    duel = "Foi um duelo marcado em {zone}.",
    unknown = "O lugar não tinha nome no mapa, só no corpo.",
  },
  enUS = {
    withSub = "The fight happened in {zone}, in the stretch called {subzone}.",
    zoneOnly = "The field was {zone}.",
    bg = "We were in a battleground: {zone}.",
    duel = "It was a marked duel in {zone}.",
    unknown = "The place had no name on the map, only on the body.",
  },
}

local COMBAT = {
  ptBR = {
    spell = "{detail} O golpe que fechou tudo foi {spell}.",
    nospell = "{detail} O último gesto não pediu nome — só resultado.",
    above = " {g:Ele|Ela} vinha {gap} níveis acima. Mesmo assim o chão escolheu o meu lado.",
    below = " {g:Ele|Ela} estava {gap} níveis abaixo. Não houve perdão no caderno.",
    streak = " A série ia em {streak}. O campo já sabia a conta.",
  },
  enUS = {
    spell = "{detail} The blow that closed it was {spell}.",
    nospell = "{detail} The last gesture asked for no name — only an ending.",
    above = " They came in {gap} levels above. Even so the ground chose my side.",
    below = " They stood {gap} levels below. The book showed no mercy.",
    streak = " The streak sat at {streak}. The field already knew the count.",
  },
}

local AMBIENT = {
  ptBR = {
    ashenvale = "A floresta de Vale Gris falava baixo, como quem esconde bandeira entre as folhas.",
    warsong = "A ravina ecoava grito e metal; o meio do campo não perdoa quem hesita.",
    arathi = "A bacia aberta de Arathi deixava cada passo visível demais.",
    alterac = "O frio de Alterac entrava pela armadura antes do golpe.",
    barrens = "O sertão seco estalava sob os pés; poeira e distância eram a única sombra.",
    stranglethorn = "O Espinhaço úmido cheirava a seiva e emboscada.",
    hillsbrad = "Eira dos Montes misturava estrada de pedra com rancor antigo.",
    stonetalon = "Torres de Pedra cortavam o vento em lâminas finas.",
    duskwood = "O Crepúsculo parecia noite mesmo de dia.",
    elwynn = "Elwynn ainda fingia paz de fazenda, até o aço discordar.",
    tirisfal = "Tirisfal tinha cheiro de cripta aberta e névoa sem dono.",
    default = "O ar do campo carregava ferro, suor e a pressa de quem não pede licença.",
  },
  enUS = {
    ashenvale = "Ashenvale spoke softly, like a forest hiding a banner in the leaves.",
    warsong = "The gulch echoed with shout and steel; the midfield forgives no hesitation.",
    arathi = "The open basin of Arathi made every step too visible.",
    alterac = "Alterac cold slid under the armor before the blow did.",
    barrens = "The dry Barrens cracked underfoot; dust and distance were the only shade.",
    stranglethorn = "Stranglethorn smelled of sap and ambush.",
    hillsbrad = "Hillsbrad mixed stone road with old grudges.",
    stonetalon = "Stonetalon cut the wind into thin blades.",
    duskwood = "Duskwood felt like night even at noon.",
    elwynn = "Elwynn still pretended farmstead peace, until steel disagreed.",
    tirisfal = "Tirisfal smelled of an open crypt and ownerless mist.",
    default = "The field air carried iron, sweat, and the haste of those who ask no leave.",
  },
}

local function pair(a, b)
  return { a, b }
end

local DETAIL = {
  ptBR = {
    Human = {
      WARRIOR = pair("A espada ainda queria parecer lei de cidade, e o grito de guerra saiu tarde.", "Havia brasão demais naquele peito para um duelo sem testemunha."),
      PALADIN = pair("A Luz piscou no martelo como quem pede licença antes de condenar.", "O juramento pesava mais que a armadura, até o chão discordar."),
      HUNTER = pair("O falcão circulou uma vez, leal demais para um campo sem floresta.", "A armadilha estava posta para um bicho, e eu não era o bicho."),
      ROGUE = pair("A adaga saiu da capa como quem pede desculpa e não recebe.", "Veneno de rua, pressa de beco, e mesmo assim chegou atrasado."),
      PRIEST = pair("A prece começou em voz alta e terminou no meio da palavra.", "Havia cura demais nas mãos para um duelo que já tinha dono."),
      SHAMAN = pair("O totem de um humano soa sempre um pouco emprestado.", "O raio obedeceu, mas olhou para trás antes de cair."),
      MAGE = pair("As runas da túnica apagaram na ordem em que foram escritas.", "O polimorfo procurou um carneiro e encontrou o meu nome."),
      WARLOCK = pair("O diabrete hesitou, como se a cidade ainda tivesse lei.", "A maldição tinha sotaque de biblioteca e pouca fome."),
      DRUID = pair("Folha nenhuma esconde um humano que aprendeu o bosque tarde.", "A forma de urso guardava um gesto de praça, não de mato."),
    },
    Dwarf = {
      WARRIOR = pair("O machado subiu devagar, do jeito de quem cava rancor desde a pedra.", "A barba ainda apontava para a frente quando o corpo já não acompanhava."),
      PALADIN = pair("A Luz desceu na bigorna da fé e saiu em faísca curta.", "O martelo tinha peso de mina, e a mina acabou."),
      HUNTER = pair("O tiro de rifle desenhou uma linha reta demais para um duelo.", "O urso ao lado dele rosnou para o dono, não para mim."),
      ROGUE = pair("Baixo, rápido, e ainda assim a sombra era curta demais.", "A adaga cheirava a óleo de arma, não a flor de veneno."),
      PRIEST = pair("A bênção saiu rouca, como canto de taverna sagrada.", "Ajoelhar na pedra é o ofício deles. Desta vez a pedra não devolveu."),
      SHAMAN = pair("O totem fincou na terra como estaca de acampamento.", "O fogo do ancestral hesitou diante de um anão sem montanha."),
      MAGE = pair("A barreira tinha gosto de cerveja e pouca teoria.", "O gelo formou um caneco e quebrou do mesmo jeito."),
      WARLOCK = pair("O demônio era pequeno, teimoso, e obedeceu até o fim.", "A maldição desceu como pickareta: fundo, e tarde."),
      DRUID = pair("Raiz de anão é teimosia, não é bosque.", "A forma de felino ficou baixa e mesmo assim foi vista."),
    },
    NightElf = {
      WARRIOR = pair("A glaive cortou o ar em silêncio, como se a floresta ainda mandasse.", "Havia séculos na postura e um segundo a menos do que precisava."),
      PALADIN = pair("A Luz neles parece lua emprestada, bonita e distante.", "O juramento élfico não cabe num martelo, e o martelo soube."),
      HUNTER = pair("A flecha nasceu do escuro e morreu na luz do meu golpe.", "O gato-de-névoa olhou para a dona como quem já sabia."),
      ROGUE = pair("Sumir é o idioma deles. Desta vez a frase ficou pela metade.", "A lâmina saiu das folhas sem farfalhar, e mesmo assim eu ouvi."),
      PRIEST = pair("A prece à Eluna chegou azul e foi embora sem resposta.", "Curar um elfo é tentar segurar água da lua."),
      SHAMAN = pair("O totem élfico pede licença às raízes antes de bater.", "O raio desceu branco, quase prata, e não bastou."),
      MAGE = pair("O arcano deles é antigo e mesmo assim chegou segundo.", "As runas brilharam em darnassiano e apagaram em silêncio."),
      WARLOCK = pair("Corrupção em pele de elfo parece uma ofensa ao próprio bosque.", "O demonete se escondeu na sombra da orelha e não salvou ninguém."),
      DRUID = pair("A forma de coruja abriu a asa tarde demais.", "Raízes élficas são educadas. As minhas não foram."),
    },
    Gnome = {
      WARRIOR = pair("O grito de guerra saiu agudo e a espada, teimosa, quase acertou.", "Pequeno não é leve quando a raiva cabe inteira no peito."),
      PALADIN = pair("A Luz numa armadura de gnomo parece lanterna de bolso.", "O martelo era curto e a fé, comprida. A fé chegou tarde."),
      HUNTER = pair("A engenhoca disparou sozinha e o bicho olhou sem entender.", "Havia mais parafuso do que flecha naquele caçador."),
      ROGUE = pair("A bomba de fumaça cobriu todo mundo, menos o golpe.", "Veneno de frasco pequeno, pressa de quem vive baixo."),
      PRIEST = pair("A cura piscava como lâmpada com mau contato.", "A prece tinha três palavras técnicas e nenhuma chegou ao fim."),
      SHAMAN = pair("O totem era uma geringonça e o raio, um curto-circuito.", "Os elementos não assinam contrato com engrenagem."),
      MAGE = pair("O polimorfo virou faísca, não animal, e se perdeu no ar.", "Havia mais invento que magia na manga, e os dois falharam juntos."),
      WARLOCK = pair("O diabrete usava um óculos minúsculo e mesmo assim errou.", "A maldição foi calculada. O duelo não."),
      DRUID = pair("A forma animal ficou do tamanho da ambição, não do corpo.", "Folha, parafuso e presas. Só as presas chegaram perto."),
    },
    Orc = {
      WARRIOR = pair("O machado subiu com o grito, e o grito durou mais que o braço.", "Honra de orc é reta. Desta vez a reta acabou em mim."),
      PALADIN = pair("Ver a Luz num orc é ver uma fogueira dentro de uma forja.", "O martelo sagrado tinha cabo de guerra e pouca paz."),
      HUNTER = pair("O lobo mordeu o ar onde eu já não estava.", "A flecha orc é grossa. O intervalo entre elas foi o meu."),
      ROGUE = pair("Orc que se esconde ainda respira alto demais.", "A adaga era de osso e a pressa, de quem não nasceu para a sombra."),
      PRIEST = pair("A sombra orc reza com os dentes, e os dentes fecharam tarde.", "Havia cura e havia fome. A fome perdeu."),
      SHAMAN = pair("O totem cravou e o ancestral gritou o nome errado.", "O raio desceu vermelho, de guerra, e eu já tinha saído de baixo."),
      MAGE = pair("Magia de orc queima como se ainda fosse machado.", "A runa foi pintada com pressa e apagou com pressa."),
      WARLOCK = pair("O demônio puxava a corrente e o orc puxava o demônio.", "A maldição tinha gosto de sangue velho e chegou cansada."),
      DRUID = pair("A forma de lobo orc uiva antes de morder. Eu ouvi a tempo.", "Raiz nenhuma segura um orc que decidiu avançar. O golpe segurou."),
    },
    Scourge = {
      WARRIOR = pair("O osso rangeu no lugar da voz, e a espada veio fria.", "Não há fôlego num morto-vivo. O golpe também não precisou de fôlego."),
      PALADIN = pair("A Luz numa carne caída parece ironia, e a ironia quebrou.", "O martelo sagrado não sabe a quem salvar quando o corpo já foi."),
      HUNTER = pair("O morcego girou e a flecha podre passou rente.", "Caçar sem pulso é insistência. A insistência acabou."),
      ROGUE = pair("A adaga não precisava de veneno. A lâmina já estava morta.", "Sumir, para um morto, é só voltar ao que já era."),
      PRIEST = pair("A prece sombria saiu da garganta como poeira de cripta.", "Curar quem não vive é teimosia. A teimosia caiu."),
      SHAMAN = pair("O totem fincou em terra que não aceita morto.", "O raio não gosta de osso. Mesmo assim tentou."),
      MAGE = pair("O gelo neles é quase natural, e por isso chegou sem pressa.", "A runa necromântica piscou e esqueceu a palavra."),
      WARLOCK = pair("Dois mortos no mesmo corpo, e nenhum dos dois mandou.", "A maldição encontrou a casa ocupada e foi embora."),
      DRUID = pair("A forma animal numa carne caída é uma ofensa ao ciclo.", "A raiz recusou aquele chão. Eu não recusei o golpe."),
    },
    Tauren = {
      WARRIOR = pair("O machado desceu como tronco. O intervalo coube inteiro.", "Grande demais para errar, e mesmo assim o vento passou primeiro."),
      PALADIN = pair("A Luz num tauren parece sol de planície, larga e lenta.", "O martelo precisou de espaço. O duelo não deu."),
      HUNTER = pair("O kodo não coube na mira, e a flecha também não coube em mim.", "Havia terra demais entre os cascos e o meu pé."),
      ROGUE = pair("Esconder um tauren é pedir ao mundo que finja.", "A adaga era pequena para aquele peito, e chegou mesmo assim tarde."),
      PRIEST = pair("A prece saiu grave, de peito fundo, e morreu no ar.", "Curar aquela massa leva tempo. O tempo não estava do lado deles."),
      SHAMAN = pair("O totem parecia chifre fincado, e o ancestral reconheceu o dono tarde.", "O raio desceu largo, de tempestade de planície, e eu já tinha um passo."),
      MAGE = pair("Magia lenta em corpo grande. A runa não terminou de abrir.", "O gelo subiu pelo pelo e quebrou antes do joelho."),
      WARLOCK = pair("O demônio ficou pequeno debaixo daquele peito.", "A maldição subiu como fumaça de cachimbo e se perdeu."),
      DRUID = pair("A forma de alce ainda tinha o peso do povo, não do bosque.", "A raiz tentou ser educada com um tauren. Eu não."),
    },
    Troll = {
      WARRIOR = pair("A presa apareceu no sorriso antes da lâmina.", "Regenerar não adianta quando o golpe acerta o riso."),
      PALADIN = pair("A Luz num troll parece empréstimo, e o empréstimo venceu juros.", "O martelo sagrado escorregou numa presa e não voltou."),
      HUNTER = pair("O raptor bateu o rabo e a flecha saiu rindo.", "Havia veneno na ponta e pressa demais no braço."),
      ROGUE = pair("O vodu na lâmina cheira a erva e a pressa.", "Sumir no mato é o ofício. O mato, desta vez, era meu."),
      PRIEST = pair("A sombra troll reza com osso e com riso. Os dois calaram.", "A cura deles volta. O duelo não esperou a volta."),
      SHAMAN = pair("O totem de crânio olhou para o dono e não avisou.", "O raio desceu com cheiro de ritual e pouca mira."),
      MAGE = pair("A magia troll dança. Desta vez a dança tropeçou.", "A runa foi desenhada em presa e apagou em sangue."),
      WARLOCK = pair("O loa e o demônio disputaram o mesmo peito. Nenhum ficou.", "A maldição tinha sotaque de ilha e chegou mareada."),
      DRUID = pair("A forma de felino ainda ria quando caiu.", "A raiz prendeu um tornozelo que já estava regenerando. O golpe foi mais rápido."),
    },
  },
  enUS = {
    Human = {
      WARRIOR = pair("The sword still wanted to look like city law, and the war cry came late.", "There was too much crest on that chest for a duel without witnesses."),
      PALADIN = pair("The Light flickered on the hammer like a pardon asked too late.", "The oath outweighed the armor, until the ground disagreed."),
      HUNTER = pair("The hawk circled once, too loyal for a field without a forest.", "The trap was laid for a beast, and I was not the beast."),
      ROGUE = pair("The dagger left the cloak like an apology nobody accepted.", "Street poison, alley haste, and still it arrived late."),
      PRIEST = pair("The prayer started loud and died in the middle of the word.", "There was too much healing in those hands for a duel already owned."),
      SHAMAN = pair("A human totem always sounds a little borrowed.", "The lightning obeyed, then looked back before it fell."),
      MAGE = pair("The runes on the robe went out in the order they were written.", "Polymorph looked for a sheep and found my name."),
      WARLOCK = pair("The imp hesitated, as if the city still had a law.", "The curse had a library accent and very little hunger."),
      DRUID = pair("No leaf hides a human who learned the wood too late.", "The bear shape kept a city gesture, not a wild one."),
    },
    Dwarf = {
      WARRIOR = pair("The axe rose slowly, the way a grudge is mined from stone.", "The beard still pointed forward when the body no longer followed."),
      PALADIN = pair("The Light came down on the anvil of faith and left as a short spark.", "The hammer had the weight of a mine, and the mine ran out."),
      HUNTER = pair("The rifle shot drew a line too straight for a duel.", "The bear beside them growled at its master, not at me."),
      ROGUE = pair("Short, quick, and still the shadow was too short.", "The dagger smelled of gun oil, not of nightshade."),
      PRIEST = pair("The blessing came out hoarse, a tavern hymn gone sacred.", "Kneeling on stone is their trade. This time the stone did not answer."),
      SHAMAN = pair("The totem bit the earth like a camp stake.", "Ancestral fire hesitated before a dwarf without a mountain."),
      MAGE = pair("The barrier tasted of ale and thin theory.", "The ice formed a tankard and broke the same way."),
      WARLOCK = pair("The demon was small, stubborn, and obeyed to the end.", "The curse came down like a pick: deep, and late."),
      DRUID = pair("A dwarf's root is stubbornness, not a forest.", "The cat shape stayed low and was seen anyway."),
    },
    NightElf = {
      WARRIOR = pair("The glaive cut the air in silence, as if the forest still commanded.", "There were centuries in the stance and one second too few."),
      PALADIN = pair("The Light on them looks like borrowed moonlight, pretty and far.", "An elven oath does not fit a hammer, and the hammer knew."),
      HUNTER = pair("The arrow was born in the dark and died in the light of my blow.", "The nightsaber looked at its mistress as if it already knew."),
      ROGUE = pair("Vanishing is their language. This time the sentence stopped halfway.", "The blade left the leaves without a rustle, and still I heard it."),
      PRIEST = pair("The prayer to Elune arrived blue and left without an answer.", "Healing an elf is trying to hold moonlight."),
      SHAMAN = pair("An elven totem asks the roots for leave before it strikes.", "The lightning came down white, almost silver, and was not enough."),
      MAGE = pair("Their arcane is old, and still it arrived second.", "The runes glowed in Darnassian and went out in silence."),
      WARLOCK = pair("Corruption on elven skin looks like an insult to the wood itself.", "The felhunter hid in the shadow of an ear and saved no one."),
      DRUID = pair("The owl shape opened a wing a moment too late.", "Elven roots are polite. Mine were not."),
    },
    Gnome = {
      WARRIOR = pair("The war cry came out high, and the stubborn sword nearly landed.", "Small is not light when the whole anger fits in the chest."),
      PALADIN = pair("The Light in gnome plate looks like a pocket lantern.", "The hammer was short and the faith was long. The faith arrived late."),
      HUNTER = pair("The gadget fired on its own and the beast stared, confused.", "There was more bolt than arrow in that hunter."),
      ROGUE = pair("The smoke bomb covered everyone except the blow.", "Poison from a tiny vial, haste from someone who lives low."),
      PRIEST = pair("The heal flickered like a lamp with a bad contact.", "The prayer had three technical words and none of them finished."),
      SHAMAN = pair("The totem was a contraption and the lightning a short circuit.", "The elements do not sign contracts with gears."),
      MAGE = pair("Polymorph turned into a spark, not a beast, and lost itself.", "There was more invention than magic in the sleeve, and both failed together."),
      WARLOCK = pair("The imp wore a tiny lens and still missed.", "The curse was calculated. The duel was not."),
      DRUID = pair("The animal shape grew to the size of the ambition, not the body.", "Leaf, screw, and fang. Only the fang came close."),
    },
    Orc = {
      WARRIOR = pair("The axe rose with the roar, and the roar outlasted the arm.", "Orcish honor runs straight. This time the straight line ended on me."),
      PALADIN = pair("Light in an orc is a bonfire inside a forge.", "The holy hammer had a war-haft and very little peace."),
      HUNTER = pair("The wolf bit the air where I no longer stood.", "An orc arrow is thick. The gap between them was mine."),
      ROGUE = pair("An orc who hides still breathes too loud.", "The dagger was bone, the haste of someone not born to shadow."),
      PRIEST = pair("Orcish shadow prays through the teeth, and the teeth closed late.", "There was healing and there was hunger. Hunger lost."),
      SHAMAN = pair("The totem struck and the ancestor shouted the wrong name.", "The lightning came down red, war-colored, and I had already stepped aside."),
      MAGE = pair("Orcish magic burns as if it were still an axe.", "The rune was painted in a hurry and died in a hurry."),
      WARLOCK = pair("The demon pulled the chain and the orc pulled the demon.", "The curse tasted of old blood and arrived tired."),
      DRUID = pair("The orcish wolf howls before it bites. I heard it in time.", "No root holds an orc who has decided to charge. The blow did."),
    },
    Scourge = {
      WARRIOR = pair("Bone creaked where a voice should be, and the sword came cold.", "There is no breath in the undead. The blow did not need breath either."),
      PALADIN = pair("Light in fallen flesh looks like irony, and the irony broke.", "A holy hammer does not know whom to save when the body is already gone."),
      HUNTER = pair("The bat wheeled and the rotten arrow passed close.", "Hunting without a pulse is insistence. The insistence ended."),
      ROGUE = pair("The dagger needed no poison. The blade was already dead.", "For the dead, vanishing is only returning to what they were."),
      PRIEST = pair("The shadow prayer left the throat like crypt dust.", "Healing what does not live is stubbornness. The stubbornness fell."),
      SHAMAN = pair("The totem bit earth that does not accept the dead.", "Lightning dislikes bone. It tried anyway."),
      MAGE = pair("Frost is almost natural on them, so it arrived without hurry.", "The necromantic rune blinked and forgot the word."),
      WARLOCK = pair("Two dead things in one body, and neither was in command.", "The curse found the house occupied and left."),
      DRUID = pair("An animal shape in fallen flesh is an insult to the cycle.", "The root refused that ground. I did not refuse the blow."),
    },
    Tauren = {
      WARRIOR = pair("The axe came down like a trunk. The gap fit me whole.", "Too large to miss, and still the wind arrived first."),
      PALADIN = pair("The Light on a tauren looks like prairie sun, wide and slow.", "The hammer needed room. The duel did not give it."),
      HUNTER = pair("The kodo would not fit the aim, and the arrow would not fit me.", "There was too much earth between those hooves and my foot."),
      ROGUE = pair("Hiding a tauren asks the world to pretend.", "The dagger was small for that chest, and still it arrived late."),
      PRIEST = pair("The prayer came out deep, from a vast chest, and died in the air.", "Healing that mass takes time. Time was not on their side."),
      SHAMAN = pair("The totem looked like a planted horn, and the ancestor knew its child too late.", "The lightning came down wide, a prairie storm, and I already had one step."),
      MAGE = pair("Slow magic in a large body. The rune never finished opening.", "Frost climbed the hide and broke before the knee."),
      WARLOCK = pair("The demon looked small beneath that chest.", "The curse rose like pipe smoke and lost itself."),
      DRUID = pair("The elk shape still carried the weight of a people, not of a wood.", "The root tried to be polite to a tauren. I was not."),
    },
    Troll = {
      WARRIOR = pair("The tusk showed in the grin before the blade did.", "Regenerating does not help when the blow lands on the laugh."),
      PALADIN = pair("Light on a troll looks borrowed, and the loan collected interest.", "The holy hammer slipped on a tusk and did not return."),
      HUNTER = pair("The raptor cracked its tail and the arrow left laughing.", "There was poison on the point and too much haste in the arm."),
      ROGUE = pair("Voodoo on a blade smells of herbs and hurry.", "Vanishing into the brush is the trade. This time the brush was mine."),
      PRIEST = pair("Troll shadow prays with bone and with laughter. Both went quiet.", "Their healing comes back. The duel did not wait for the return."),
      SHAMAN = pair("The skull totem looked at its owner and did not warn them.", "The lightning came down smelling of ritual and poor aim."),
      MAGE = pair("Troll magic dances. This time the dance tripped.", "The rune was drawn on a tusk and erased in blood."),
      WARLOCK = pair("The loa and the demon fought for the same chest. Neither stayed.", "The curse had an island accent and arrived seasick."),
      DRUID = pair("The cat shape was still laughing when it fell.", "The root caught an ankle that was already knitting. The blow was faster."),
    },
  },
}

local FEATS = {
  ptBR = {
    revenge = "A vingança não devolveu o que eu tinha perdido. Só pôs o nome de volta na minha boca, e dessa vez fui eu quem o escreveu no chão.",
    legendary = "Houve uma frase que o campo repetiu sem mim. Foi a primeira vez que a fala saiu lendária, como se outra voz tivesse emprestado a minha.",
    milestone100 = "Cem do mesmo sangue ou do mesmo ofício. A conta deixou de ser vaidade e virou o mapa do lugar.",
    streak3 = "Três sem cair. Ainda era promessa, mas o chão já tinha dono por um instante.",
    streak5 = "Cinco. O corpo pedia pausa e a série recusou, com a educação de quem não pretende pedir licença.",
    streak10 = "Dez sem morrer. Passei a assinar o campo com o nome, não só com o golpe.",
    ["race:Human"] = "O primeiro humano caiu e a Aliança deixou de ser um estandarte distante. Passou a ter um rosto.",
    ["race:Dwarf"] = "O primeiro anão ensinou que pedra também sangra, só que devagar e com rancor.",
    ["race:NightElf"] = "O primeiro elfo da noite caiu sem fazer barulho. O silêncio, esse sim, ficou.",
    ["race:Gnome"] = "O primeiro gnomo provou que invento nenhum substitui o instante em que o corpo aceita o chão.",
    ["race:Orc"] = "O primeiro orc gritou até o fim. O grito ficou mais tempo que o machado.",
    ["race:Scourge"] = "O primeiro morto-vivo já estava morto. Mesmo assim houve uma segunda morte, e essa foi minha.",
    ["race:Tauren"] = "O primeiro tauren cobriu o sol por um segundo. Quando levantou poeira, o campo parecia menor.",
    ["race:Troll"] = "O primeiro troll ainda sorria. A regeneração não teve tempo de opinar.",
    ["class:WARRIOR"] = "O primeiro guerreiro me mostrou o ofício sem discurso: lâmina, passo, e o chão.",
    ["class:PALADIN"] = "O primeiro paladino trouxe a Luz para um duelo que não pedia bênção.",
    ["class:HUNTER"] = "O primeiro caçador atirou como quem conversa com o mato. A conversa terminou em mim.",
    ["class:ROGUE"] = "O primeiro ladino quase não existiu até existir demais, colado nas minhas costas.",
    ["class:PRIEST"] = "O primeiro sacerdote dividiu o ar entre cura e condenação. Nenhuma das duas acabou a frase.",
    ["class:SHAMAN"] = "O primeiro xamã fincou o totem como quem apresenta a família. A família chegou tarde.",
    ["class:MAGE"] = "O primeiro mago escreveu no ar uma palavra que eu interrompi.",
    ["class:WARLOCK"] = "O primeiro bruxo veio acompanhado. O acompanhante não mudou o fim.",
    ["class:DRUID"] = "O primeiro druida mudou de forma e esqueceu que o golpe não muda com ela.",
  },
  enUS = {
    revenge = "Revenge did not give back what I had lost. It only put the name back in my mouth, and this time I was the one who wrote it on the ground.",
    legendary = "There was a line the field repeated without me. That was the first time the speech came out legendary, as if another voice had lent me mine.",
    milestone100 = "One hundred of the same blood or the same trade. The count stopped being vanity and became the map of the place.",
    streak3 = "Three without falling. It was still a promise, but the ground had an owner for a moment.",
    streak5 = "Five. The body asked for a pause and the streak refused, with the manners of someone who will not ask leave.",
    streak10 = "Ten without dying. I started signing the field with my name, not only with the blow.",
    ["race:Human"] = "The first human fell and the Alliance stopped being a distant banner. It had a face.",
    ["race:Dwarf"] = "The first dwarf taught me that stone bleeds too, only slowly, and with a grudge.",
    ["race:NightElf"] = "The first night elf fell without a sound. The silence is what stayed.",
    ["race:Gnome"] = "The first gnome proved that no invention replaces the moment a body accepts the ground.",
    ["race:Orc"] = "The first orc roared to the end. The roar outlasted the axe.",
    ["race:Scourge"] = "The first Forsaken was already dead. Even so there was a second death, and that one was mine.",
    ["race:Tauren"] = "The first tauren covered the sun for a second. When the dust rose, the field looked smaller.",
    ["race:Troll"] = "The first troll was still smiling. Regeneration did not get a vote.",
    ["class:WARRIOR"] = "The first warrior showed me the trade without a speech: blade, step, and the ground.",
    ["class:PALADIN"] = "The first paladin brought the Light into a duel that had not asked for a blessing.",
    ["class:HUNTER"] = "The first hunter shot as if talking to the brush. The talk ended on me.",
    ["class:ROGUE"] = "The first rogue barely existed until they existed too much, against my back.",
    ["class:PRIEST"] = "The first priest split the air between healing and judgment. Neither finished the sentence.",
    ["class:SHAMAN"] = "The first shaman planted a totem like a family introduction. The family arrived late.",
    ["class:MAGE"] = "The first mage wrote a word in the air that I interrupted.",
    ["class:WARLOCK"] = "The first warlock came with company. The company did not change the ending.",
    ["class:DRUID"] = "The first druid changed shape and forgot that the blow does not change with it.",
  },
}

local MILESTONE = {
  ptBR = {
    class = {
      [10] = {
        WARRIOR = "Dez guerreiros. O choque das lâminas deixou de me assustar e passou a me orientar.",
        PALADIN = "Dez paladinos. A Luz deles aprendeu a piscar quando eu chego.",
        HUNTER = "Dez caçadores. O mato deixou de esconder a flecha por inteiro.",
        ROGUE = "Dez ladinos. A sombra já não me pega pelas costas sem avisar.",
        PRIEST = "Dez sacerdotes. A prece quebra no meio quando o duelo tem pressa.",
        SHAMAN = "Dez xamãs. O totem cai antes do raio terminar o nome.",
        MAGE = "Dez magos. O polimorfo não encontra mais o meu rosto a tempo.",
        WARLOCK = "Dez bruxos. O demônio olha para o dono antes de olhar para mim.",
        DRUID = "Dez druidas. A forma animal não esconde mais o gesto.",
      },
      [50] = {
        WARRIOR = "Cinquenta guerreiros. O grito de guerra chega atrasado quando me vê.",
        PALADIN = "Cinquenta paladinos. Já conheço o martelo pelo peso do juramento.",
        HUNTER = "Cinquenta caçadores. O bicho deles hesita antes de saltar.",
        ROGUE = "Cinquenta ladinos. O veneno já tem gosto de rotina.",
        PRIEST = "Cinquenta sacerdotes. Já distingo a cura da condenação no primeiro gesto.",
        SHAMAN = "Cinquenta xamãs. Os elementos já me tratam como intrometido conhecido.",
        MAGE = "Cinquenta magos. O gelo e o fogo disputam quem me evita primeiro.",
        WARLOCK = "Cinquenta bruxos. O medo voltou para quem o lançou.",
        DRUID = "Cinquenta druidas. A raiz nasce cansada debaixo de mim.",
      },
      [100] = {
        WARRIOR = "Cem guerreiros. A linha de frente abre sozinha quando eu chego.",
        PALADIN = "Cem paladinos. A fé deles passou a me saudar de longe.",
        HUNTER = "Cem caçadores. A mira me procura e me perde no mesmo instante.",
        ROGUE = "Cem ladinos. Sumir deixou de ser vantagem.",
        PRIEST = "Cem sacerdotes. A Luz e a Sombra já me tratam pelo nome.",
        SHAMAN = "Cem xamãs. A tempestade mudou de lado.",
        MAGE = "Cem magos. A runa apaga quando eu cruzo o campo.",
        WARLOCK = "Cem bruxos. A maldição perdeu o endereço.",
        DRUID = "Cem druidas. O bosque deixou de escolher o lado deles.",
      },
    },
    race = {
      [10] = {
        Human = "Dez humanos. A Aliança já não me vê como acidente de estrada.",
        Dwarf = "Dez anões. A pedra começou a me reconhecer pelo peso do passo.",
        NightElf = "Dez elfos da noite. O silêncio deles já não me confunde.",
        Gnome = "Dez gnomos. O invento parou de me surpreender antes do corpo.",
        Orc = "Dez orcs. O grito virou paisagem, não ameaça.",
        Scourge = "Dez mortos-vivos. A segunda morte deixou de ser novidade.",
        Tauren = "Dez taurens. A poeira que eles levantam já faz parte do caminho.",
        Troll = "Dez trolls. O riso regenera. O duelo, não.",
      },
      [50] = {
        Human = "Cinquenta humanos. Já leio o brasão antes da lâmina.",
        Dwarf = "Cinquenta anões. O rancor deles tem medida, e eu aprendi a conta.",
        NightElf = "Cinquenta elfos da noite. A floresta já não esconde o gesto.",
        Gnome = "Cinquenta gnomos. A faísca avisa, e eu já saio do lugar.",
        Orc = "Cinquenta orcs. A honra deles ficou previsível, e ainda assim pesada.",
        Scourge = "Cinquenta mortos-vivos. O frio da lâmina virou clima.",
        Tauren = "Cinquenta taurens. O chão avisa quando um deles decide avançar.",
        Troll = "Cinquenta trolls. A presa no sorriso já é um parágrafo conhecido.",
      },
      [100] = {
        Human = "Cem humanos. A cidade inteira cabe numa cicatriz só.",
        Dwarf = "Cem anões. A montanha ficou pequena no relato.",
        NightElf = "Cem elfos da noite. A lua já não toma partido.",
        Gnome = "Cem gnomos. Nenhuma engrenagem reescreve esse número.",
        Orc = "Cem orcs. O grito de guerra mudou de dono.",
        Scourge = "Cem mortos-vivos. Até a cripta perde a conta.",
        Tauren = "Cem taurens. A planície inteira sabe o meu passo.",
        Troll = "Cem trolls. A regeneração desistiu de argumentar.",
      },
    },
  },
  enUS = {
    class = {
      [10] = {
        WARRIOR = "Ten warriors. The clash of blades stopped frightening me and started to guide me.",
        PALADIN = "Ten paladins. Their Light learned to flicker when I arrive.",
        HUNTER = "Ten hunters. The brush no longer hides the whole arrow.",
        ROGUE = "Ten rogues. Shadow no longer takes my back without a warning.",
        PRIEST = "Ten priests. The prayer breaks in the middle when the duel is in a hurry.",
        SHAMAN = "Ten shamans. The totem falls before the lightning finishes the name.",
        MAGE = "Ten mages. Polymorph no longer finds my face in time.",
        WARLOCK = "Ten warlocks. The demon looks at its master before it looks at me.",
        DRUID = "Ten druids. The animal shape no longer hides the gesture.",
      },
      [50] = {
        WARRIOR = "Fifty warriors. The war cry arrives late when it sees me.",
        PALADIN = "Fifty paladins. I know the hammer by the weight of the oath.",
        HUNTER = "Fifty hunters. Their beast hesitates before it leaps.",
        ROGUE = "Fifty rogues. The poison already tastes like routine.",
        PRIEST = "Fifty priests. I can tell healing from judgment in the first gesture.",
        SHAMAN = "Fifty shamans. The elements already treat me as a familiar intruder.",
        MAGE = "Fifty mages. Frost and fire argue over which one avoids me first.",
        WARLOCK = "Fifty warlocks. The fear went back to the one who cast it.",
        DRUID = "Fifty druids. The root grows tired beneath me.",
      },
      [100] = {
        WARRIOR = "One hundred warriors. The front line opens on its own when I arrive.",
        PALADIN = "One hundred paladins. Their faith started greeting me from far off.",
        HUNTER = "One hundred hunters. The aim seeks me and loses me in the same instant.",
        ROGUE = "One hundred rogues. Vanishing stopped being an advantage.",
        PRIEST = "One hundred priests. The Light and the Shadow already know me by name.",
        SHAMAN = "One hundred shamans. The storm changed sides.",
        MAGE = "One hundred mages. The rune goes out when I cross the field.",
        WARLOCK = "One hundred warlocks. The curse lost the address.",
        DRUID = "One hundred druids. The wood stopped choosing their side.",
      },
    },
    race = {
      [10] = {
        Human = "Ten humans. The Alliance no longer sees me as a roadside accident.",
        Dwarf = "Ten dwarves. The stone started to know me by the weight of the step.",
        NightElf = "Ten night elves. Their silence no longer confuses me.",
        Gnome = "Ten gnomes. The invention stopped surprising me before the body did.",
        Orc = "Ten orcs. The roar became landscape, not a threat.",
        Scourge = "Ten Forsaken. The second death stopped being news.",
        Tauren = "Ten tauren. The dust they raise is part of the road now.",
        Troll = "Ten trolls. The laugh regenerates. The duel does not.",
      },
      [50] = {
        Human = "Fifty humans. I read the crest before the blade.",
        Dwarf = "Fifty dwarves. Their grudge has a measure, and I learned the sum.",
        NightElf = "Fifty night elves. The forest no longer hides the gesture.",
        Gnome = "Fifty gnomes. The spark warns me, and I am already gone.",
        Orc = "Fifty orcs. Their honor became predictable, and it is still heavy.",
        Scourge = "Fifty Forsaken. The cold of the blade became weather.",
        Tauren = "Fifty tauren. The ground warns me when one of them decides to charge.",
        Troll = "Fifty trolls. The tusk in the grin is a paragraph I already know.",
      },
      [100] = {
        Human = "One hundred humans. A whole city fits in a single scar.",
        Dwarf = "One hundred dwarves. The mountain grew small in the telling.",
        NightElf = "One hundred night elves. The moon no longer takes a side.",
        Gnome = "One hundred gnomes. No gear rewrites that number.",
        Orc = "One hundred orcs. The war cry changed owners.",
        Scourge = "One hundred Forsaken. Even the crypt loses count.",
        Tauren = "One hundred tauren. The whole prairie knows my step.",
        Troll = "One hundred trolls. Regeneration gave up the argument.",
      },
    },
  },
}

local function packLang()
  if ns.LocaleCode == "ptBR" then
    return "ptBR"
  end
  return "enUS"
end

local function classLabel(token, sex)
  local label = (token and Data.ClassLabel(token)) or "?"
  if sex == 3 and ns.LocaleCode == "ptBR" and FEM_CLASS[label] then
    return FEM_CLASS[label]
  end
  return label
end

local function raceLabel(token, sex)
  local label = (token and Data.RaceLabel(token)) or "?"
  if sex == 3 and ns.LocaleCode == "ptBR" and FEM_RACE[label] then
    return FEM_RACE[label]
  end
  return label
end

local function langDeathsWord(lang, n)
  if lang == "ptBR" then
    if n == 1 then
      return "vez"
    end
    return "vezes"
  end
  if n == 1 then
    return "time"
  end
  return "times"
end

local function fill(text, ctx)
  ctx = ctx or {}
  local sex = ctx.sex
  local spell = ctx.spell
  if type(spell) ~= "string" or spell == "" then
    spell = L.NARR_SPELL
  end
  local zone = ctx.zone
  if type(zone) ~= "string" or zone == "" then
    zone = L.NARR_ZONE
  end
  local level = tonumber(ctx.level) or 0
  local levelText = level > 0 and tostring(level) or "?"
  local deaths = tonumber(ctx.priorDeaths) or 0
  local deathsWord = langDeathsWord(ctx.lang, deaths)
  text = text:gsub("{detail}", ctx.detail or "")
  text = text:gsub("{ambient}", ctx.ambient or "")
  text = text:gsub("{places}", ctx.places or zone)
  text = text:gsub("{date}", ctx.date or "")
  text = text:gsub("{subzone}", ctx.subzone or "")
  text = text:gsub("{names}", ctx.names or "")
  text = text:gsub("{priorKills}", tostring(ctx.priorKills or 0))
  text = text:gsub("{priorDeaths}", tostring(deaths))
  text = text:gsub("{priorDeathsWord}", deathsWord)
  text = text:gsub("{gap}", tostring(ctx.gap or 0))
  text = text:gsub("{streak}", tostring(ctx.streak or 0))
  text = text:gsub("{race}", raceLabel(ctx.race, sex))
  text = text:gsub("{class}", classLabel(ctx.class, sex))
  text = text:gsub("{myclass}", classLabel(ctx.myClass, ctx.mySex))
  text = text:gsub("{zone}", zone)
  text = text:gsub("{spell}", spell)
  text = text:gsub("{name}", ctx.name or "?")
  text = text:gsub("{level}", levelText)
  text = text:gsub("{count}", tostring(ctx.count or 0))
  local female = sex == 3
  local playerFemale = ctx.mySex == 3
  text = text:gsub("{pg:([^|}]+)|([^}]+)}", function(masc, fem)
    if playerFemale then
      return fem
    end
    return masc
  end)
  text = text:gsub("{g:([^|}]+)|([^}]+)}", function(masc, fem)
    if female then
      return fem
    end
    return masc
  end)
  if ns.Genderize then
    text = ns.Genderize(text, sex)
  end
  text = text:gsub("  +", " ")
  text = text:gsub("%s+\n", "\n")
  text = text:gsub("\n%s+", "\n")
  return text
end

local function detailFor(lang, race, class, variant)
  local racePack = DETAIL[lang] and DETAIL[lang][race]
  local lines = racePack and class and racePack[class]
  if type(lines) ~= "table" or #lines == 0 then
    if lang == "ptBR" then
      return "O encontro ficou preso na memória mesmo sem brasão."
    end
    return "The meeting stayed in memory even without a crest."
  end
  local index = ((variant or 1) - 1) % #lines + 1
  return lines[index]
end

local function shortName(name)
  if ns.Stats and ns.Stats.DisplayName then
    return ns.Stats.DisplayName(name) or name or "?"
  end
  if type(name) ~= "string" or name == "" then
    return "?"
  end
  local bare = name:match("^([^%-]+)")
  return (bare and bare ~= "" and bare) or name
end

local function myFaction()
  local faction = UnitFactionGroup and UnitFactionGroup("player")
  if faction == "Alliance" or faction == "Horde" then
    return faction
  end
  return "Alliance"
end

local ALLIANCE = { Human = true, Dwarf = true, NightElf = true, Gnome = true }
local HORDE = { Orc = true, Scourge = true, Tauren = true, Troll = true }

local function isEnemyRace(race)
  if myFaction() == "Horde" then
    return ALLIANCE[race] and true or false
  end
  return HORDE[race] and true or false
end

local function add(chapters, title, text, meta)
  if type(text) == "string" and text ~= "" then
    chapters[#chapters + 1] = { title = title, text = text, meta = meta }
  end
end

local function dayKey(stamp)
  stamp = tonumber(stamp) or 0
  if stamp <= 0 or not date then
    return "0"
  end
  return date("%Y-%m-%d", stamp)
end

local function dayLabel(lang, stamp)
  stamp = tonumber(stamp) or 0
  if stamp <= 0 or not date then
    return lang == "ptBR" and "Dia sem data" or "Undated day"
  end
  if lang == "ptBR" then
    return date("%d/%m/%Y", stamp)
  end
  return date("%Y-%m-%d", stamp)
end

local function ambientFor(lang, zone)
  local pack = AMBIENT[lang] or AMBIENT.enUS
  local lower = type(zone) == "string" and zone:lower() or ""
  local keys = {
    { "ashenvale", "vale-gris", "vale gris", "ashenvale" },
    { "warsong", "brado", "ravina", "warsong", "gulch" },
    { "arathi", "arathi", "bacia" },
    { "alterac", "alterac" },
    { "barrens", "sertões", "sertoes", "barrens" },
    { "stranglethorn", "espinhaço", "espinhaco", "stranglethorn" },
    { "hillsbrad", "eira", "hillsbrad" },
    { "stonetalon", "torres de pedra", "stonetalon" },
    { "duskwood", "crepúsculo", "crepusculo", "duskwood" },
    { "elwynn", "elwynn" },
    { "tirisfal", "tirisfal" },
  }
  local map = {
    ashenvale = pack.ashenvale,
    warsong = pack.warsong,
    arathi = pack.arathi,
    alterac = pack.alterac,
    barrens = pack.barrens,
    stranglethorn = pack.stranglethorn,
    hillsbrad = pack.hillsbrad,
    stonetalon = pack.stonetalon,
    duskwood = pack.duskwood,
    elwynn = pack.elwynn,
    tirisfal = pack.tirisfal,
  }
  for i = 1, #keys do
    local id = keys[i][1]
    for k = 2, #keys[i] do
      if lower:find(keys[i][k], 1, true) then
        return map[id] or pack.default
      end
    end
  end
  return pack.default
end

local function joinPlaces(lang, rows)
  local seen, list = {}, {}
  for i = 1, #rows do
    local zone = rows[i].zone
    local sub = rows[i].subzone
    local label = nil
    if type(zone) == "string" and zone ~= "" then
      if type(sub) == "string" and sub ~= "" and sub ~= zone then
        label = zone .. " (" .. sub .. ")"
      else
        label = zone
      end
    elseif type(sub) == "string" and sub ~= "" then
      label = sub
    end
    if label and not seen[label] then
      seen[label] = true
      list[#list + 1] = label
    end
  end
  if #list == 0 then
    return lang == "ptBR" and "um campo sem nome" or "a nameless field"
  end
  if #list == 1 then
    return list[1]
  end
  if #list == 2 then
    return list[1] .. (lang == "ptBR" and " e " or " and ") .. list[2]
  end
  local last = table.remove(list)
  return table.concat(list, ", ") .. (lang == "ptBR" and " e " or " and ") .. last
end

local function relationKey(row, seenNamesToday, globalFirst)
  if globalFirst or row.first then
    return "firstEver"
  end
  local who = shortName(row.name)
  if seenNamesToday[who] then
    return "sameDay"
  end
  if row.revenge then
    return "revenge"
  end
  local priorKills = tonumber(row.priorKills) or 0
  local priorDeaths = tonumber(row.priorDeaths) or 0
  -- Legacy rows: infer from live rival book when possible.
  if priorKills == 0 and priorDeaths == 0 and ns.Stats and ns.Stats.RivalByName then
    local rival = ns.Stats.RivalByName(row.name)
    if rival then
      priorKills = math.max(0, (rival.kills or 1) - 1)
      priorDeaths = rival.deaths or 0
      row.priorKills = priorKills
      row.priorDeaths = priorDeaths
    end
  end
  if priorDeaths > priorKills and priorDeaths > 0 then
    return "hunted"
  end
  if priorKills >= 3 or (priorKills >= 1 and priorDeaths >= 1) then
    return "rival"
  end
  if priorKills >= 1 then
    return "rematch"
  end
  return "stranger"
end

local function placeLine(lang, row)
  local pack = PLACE[lang] or PLACE.enUS
  local zone = row.zone
  local sub = row.subzone
  if row.context == "bg" and type(zone) == "string" and zone ~= "" then
    return fill(pack.bg, { zone = zone, lang = lang })
  end
  if row.context == "duel" and type(zone) == "string" and zone ~= "" then
    return fill(pack.duel, { zone = zone, lang = lang })
  end
  if type(zone) == "string" and zone ~= "" and type(sub) == "string" and sub ~= "" and sub ~= zone then
    return fill(pack.withSub, { zone = zone, subzone = sub, lang = lang })
  end
  if type(zone) == "string" and zone ~= "" then
    return fill(pack.zoneOnly, { zone = zone, lang = lang })
  end
  return pack.unknown
end

local function combatLine(lang, row, detail, variant)
  local pack = COMBAT[lang] or COMBAT.enUS
  local ctx = {
    detail = detail,
    spell = row.spell,
    sex = row.sex,
    streak = row.streak,
    lang = lang,
  }
  local body
  if type(row.spell) == "string" and row.spell ~= "" then
    body = fill(pack.spell, ctx)
  else
    body = fill(pack.nospell, ctx)
  end
  local vl = tonumber(row.victimLevel) or 0
  local pl = tonumber(row.level) or 0
  if vl > 0 and pl > 0 then
    local gap = math.abs(vl - pl)
    if gap >= 5 then
      ctx.gap = gap
      if vl > pl then
        body = body .. fill(pack.above, ctx)
      elseif pl > vl then
        body = body .. fill(pack.below, ctx)
      end
    end
    body = body .. " " .. L.NARR_LEVEL:format(vl)
  end
  if (tonumber(row.streak) or 0) >= 3 then
    body = body .. fill(pack.streak, ctx)
  end
  return body
end

local function writeEncounter(lang, row, opts)
  opts = opts or {}
  local who = shortName(row.name)
  local rel = relationKey(row, opts.seenNamesToday or {}, opts.globalFirst)
  local relTpl = (RELATION[lang] or RELATION.enUS)[rel] or RELATION.enUS.stranger
  local detail = detailFor(lang, row.race, row.class, opts.variant or 1)
  local ctx = {
    name = who,
    race = row.race,
    class = row.class,
    zone = row.zone,
    subzone = row.subzone,
    spell = row.spell,
    level = row.level,
    myClass = row.myClass,
    sex = row.sex,
    mySex = row.mySex,
    priorKills = row.priorKills or 0,
    priorDeaths = row.priorDeaths or 0,
    streak = row.streak or 0,
    detail = detail,
    lang = lang,
  }
  local parts = {
    fill(relTpl, ctx),
    placeLine(lang, row),
    combatLine(lang, row, detail, opts.variant),
  }
  return table.concat(parts, " "), who
end

local function writeDayChapter(lang, dayRows, dayIndex, isFirstDay)
  local stamp = dayRows[1] and dayRows[1].time or 0
  local label = dayLabel(lang, stamp)
  local places = joinPlaces(lang, dayRows)
  local ambient = ambientFor(lang, dayRows[1] and dayRows[1].zone)
  local openPack = DAY_OPEN[lang] or DAY_OPEN.enUS
  local openTpl = (isFirstDay or (dayRows[1] and dayRows[1].first)) and openPack.first or openPack.again
  local myClass = dayRows[1] and dayRows[1].myClass
  local mySex = dayRows[1] and dayRows[1].mySex
  local level = dayRows[1] and dayRows[1].level or 0
  local paragraphs = {
    fill(openTpl, {
      level = level,
      myClass = myClass,
      mySex = mySex,
      places = places,
      ambient = ambient,
      date = label,
      lang = lang,
    }),
  }
  local seenNamesToday = {}
  local names = {}
  local comboSeen = {}
  for i = 1, #dayRows do
    local row = dayRows[i]
    local combo = (row.race or "?") .. ":" .. (row.class or "?")
    comboSeen[combo] = (comboSeen[combo] or 0) + 1
    local prose, who = writeEncounter(lang, row, {
      seenNamesToday = seenNamesToday,
      globalFirst = isFirstDay and i == 1,
      variant = comboSeen[combo],
    })
    paragraphs[#paragraphs + 1] = prose
    seenNamesToday[who] = true
    names[#names + 1] = who
  end
  local closePack = DAY_CLOSE[lang] or DAY_CLOSE.enUS
  local closeTpl = closePack.one
  if #dayRows >= 5 then
    closeTpl = closePack.many
  elseif #dayRows >= 2 then
    closeTpl = closePack.few
  end
  local nameList
  if #names > 6 then
    local head = {}
    for i = 1, 6 do
      head[i] = names[i]
    end
    nameList = table.concat(head, ", ") .. (lang == "ptBR" and " e outros" or " and others")
  else
    nameList = table.concat(names, ", ")
  end
  paragraphs[#paragraphs + 1] = fill(closeTpl, {
    count = #dayRows,
    names = nameList,
    lang = lang,
  })
  local title = (L.NARR_DAY or (lang == "ptBR" and "Dia %s" or "Day %s")):format(label)
  local meta = places .. " · " .. tostring(#dayRows) .. (lang == "ptBR" and " encontros" or " meetings")
  return title, table.concat(paragraphs, "\n\n"), meta
end

function Chronicle.Chapters()
  local lang = packLang()
  local chapters = {}
  local list = ns.Stats and ns.Stats.Chronicle and ns.Stats.Chronicle() or {}

  local days, order = {}, {}
  for i = 1, #list do
    local row = list[i]
    local key = dayKey(row.time)
    if not days[key] then
      days[key] = {}
      order[#order + 1] = key
    end
    days[key][#days[key] + 1] = row
  end
  table.sort(order)
  local originDay = order[1]
  -- Newest day first for reading; origin day still opens with the "first story" voice.
  table.sort(order, function(a, b)
    return a > b
  end)
  for d = 1, #order do
    local rows = days[order[d]]
    table.sort(rows, function(a, b)
      return (a.time or 0) < (b.time or 0)
    end)
    local title, text, meta = writeDayChapter(lang, rows, d, order[d] == originDay)
    add(chapters, title, text, meta)
  end

  local feats = FEATS[lang] or {}
  local featOrder = {
    { "revenge", L.FEAT_REVENGE },
    { "legendary", L.FEAT_LEGENDARY },
    { "milestone100", L.FEAT_MILESTONE100 },
    { "streak3", L.FEAT_STREAK3 },
    { "streak5", L.FEAT_STREAK5 },
    { "streak10", L.FEAT_STREAK10 },
  }
  local function pushFeat(id, title)
    local when = ns.Stats and ns.Stats.FeatTime and ns.Stats.FeatTime(id)
    local body = feats[id]
    if when and body then
      local stamp = date and date("%d/%m/%Y", when) or nil
      add(chapters, title, body, stamp)
    end
  end
  for i = 1, #featOrder do
    pushFeat(featOrder[i][1], featOrder[i][2])
  end
  local races = {
    "Human", "Dwarf", "NightElf", "Gnome", "Orc", "Scourge", "Tauren", "Troll",
  }
  for i = 1, #races do
    if isEnemyRace(races[i]) then
      pushFeat("race:" .. races[i], L.FEAT_RACE:format(Data.RaceLabel(races[i])))
    end
  end
  local classes = Data.CLASSES
  for i = 1, #classes do
    pushFeat("class:" .. classes[i], L.FEAT_CLASS:format(Data.ClassLabel(classes[i])))
  end

  local db = ns.Stats and ns.Stats.GetDB and ns.Stats.GetDB() or {}
  local kills = db.kills or {}
  local mile = MILESTONE[lang]
  if mile then
    for v = 1, #Data.MILESTONES do
      local value = Data.MILESTONES[v]
      for i = 1, #classes do
        local class = classes[i]
        local count = kills.Class and tonumber(kills.Class[class]) or 0
        local body = mile.class[value] and mile.class[value][class]
        if count >= value and body then
          add(chapters, L.MILESTONE:format(value, Data.ClassLabel(class)), body)
        end
      end
      for i = 1, #races do
        local race = races[i]
        if isEnemyRace(race) then
          local count = kills.Race and tonumber(kills.Race[race]) or 0
          local body = mile.race[value] and mile.race[value][race]
          if count >= value and body then
            add(chapters, L.MILESTONE:format(value, Data.RaceLabel(race)), body)
          end
        end
      end
    end
  end
  return chapters
end

_G[addonName] = ns
