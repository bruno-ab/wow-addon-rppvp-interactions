# Análise de addons de PvP e propostas para o BanterCombat

Versão olhada: 1.7.8. A leitura dos outros addons veio das páginas públicas (CurseForge e o guia de PvP clássico do Wowhead), em outubro de 2026. Nenhum deles foi instalado nem testado neste cliente.

O BanterCombat não é um painel de campo de batalha. Ele fala no abate, guarda rivais, conta uma crônica e mede feitos com o que o registro de combate deixa ver. As propostas abaixo ficam nesse recorte.

## O que o addon já faz

- Pop-up de abate e de morte, com raridade, vingança, marco, série e título.
- Anunciador local, de First Blood a Godlike, numa janela de 12 segundos.
- Livro de rivais com placar dos dois lados, no máximo 30 nomes.
- Crônica em primeira pessoa, com zona, nível de quem conta e o golpe. O primeiro capítulo fica. O resto cabe em 40.
- Compêndio no formato de conquistas: raça, classe, combinação, abates, campo, honra, situação, racial, identidade, linhagem e meta pessoal.
- Fala própria (até 8 linhas comuns e 8 épicas), gênero em português, e linha de zona em Ravina, Arathi e Vale Gris.
- Sussurro da fala para o outro cliente, espelho em emote, ou uma frase só no chat de texto.
- Menu do minimapa, backup e carga do banco do personagem.

## Addons olhados

| Addon | Para que serve | O que interessa aqui |
|---|---|---|
| [Rivals](https://www.curseforge.com/wow/addons/rivals) | História de mundo aberto e duelo no Classic Era. Série, medalhas no estilo Halo, ficha do oponente e placar de duelo. | Separar mundo, campo e duelo. Resumo de nêmesis e zona. Medalha visual na série, além do som. |
| [PvP Stats (Classic)](https://www.curseforge.com/wow/addons/pvp-stats-classic) | Abates, assistências, séries, mais de 450 feitos, histórico por jogador e anúncio no grupo. | Placar no tooltip. Marco no 5º e no 10º abate da mesma pessoa. Anúncio editável. Campo sem spam no chat. |
| [OWPvP](https://www.curseforge.com/wow/addons/owpvp) | Crônica de mundo aberto no TBC: encontro, ficha, revanche e recompensa. | Nível do alvo, subzona, hora e dificuldade gravados no encontro. Ficha por nome, não só um contador. |
| [PvPLedger](https://www.curseforge.com/wow/addons/pvpledger) | Banco de abates e mortes, com abas de zona, classe e rival. | Tooltip do minimapa com o placar da sessão. Lista recente maior do que a crônica. |
| [PvP Announcer](https://www.curseforge.com/wow/addons/pvpannouncer-tbc) | Anúncio de killing blow, série e placar ao vivo, com som trocável. | Contador na tela só da sessão. Pasta de sons do jogador. Texto de cada anúncio editável. |
| [Spy Classic](https://www.curseforge.com/wow/addons/spy-classic) | Avisa inimigo próximo, com lista, histórico e “matar à vista”. | A ideia de marcar um rival. O radar e a leitura de furtividade ficam de fora. |
| [BattlegroundEnemies](https://www.curseforge.com/wow/addons/battlegroundenemies) | Quadros de aliado e inimigo, vida, alcance, objetivo e chamada de alvo. | Nada para copiar. É outro produto. |
| [Capping](https://www.curseforge.com/wow/addons/capping-bg-timers) | Tempo de fila, base, bandeira e estimativa de placar. | Nada para copiar. O feito de campo do BanterCombat já lê o chat do campo. |
| [GladiatorlosSA2](https://www.curseforge.com/wow/addons/gladiatorlossa2) | Voz para feitiço inimigo, interrupção, cura e berloque. | Nada para copiar. O anunciador daqui é de abate, não de cooldown. |

## O que não entra

- Quadro de inimigos, timer de base, estimativa de pontuação e ícone de chamada.
- Voz avisando Polymorph, chute, bolha ou berloque.
- Lista de quem está por perto e detecção de furtividade. O Spy faz isso e o próprio guia do Wowhead trata como controverso.
- Ranking entre jogadores de outros clientes. O PvP Stats tem leaderboard, mas isso pede um servidor.
- Cópia do registro de combate com dano, cura e ouro gasto, como a ficha do Rivals. A crônica já guarda o golpe que fechou o encontro.

## Propostas

Cada item diz de onde veio, o que muda e o que permanece.

### 1. Placar no tooltip do inimigo

O PvP Stats mostra, ao passar o mouse num jogador, quantas vezes você o matou e quantas vezes ele te matou.

No BanterCombat o número já existe em `rivals`, mas só aparece no compêndio. Um gancho no tooltip do nome hostil, com uma linha `3–1`, usa o livro atual. Sem nome no livro, o tooltip não ganha linha.

### 2. Marco contra a mesma pessoa

O PvP Stats avisa no 1º, 5º e 10º abate daquele nome. Aqui a vingança olha só o último killer, e a fala de rival entra com uma morte sua ou dois abates seus. Não há um marco de “décima vez contra este nome”.

A fala pode usar o mesmo caminho do marco de raça e classe, com um selo próprio. O contador do rival continua sendo a fonte. Não cria outro banco.

### 3. Sessão no botão do minimapa

O PvP Announcer e o PvPLedger separam o placar da luta de agora do placar da vida. O minimapa do BanterCombat só diz como abrir o compêndio.

O tooltip do botão pode mostrar abates, mortes e série desde o login, sem gravar isso no banco. Morrer já zera a série do anunciador. A sessão zera no `/reload`, a vida não.

### 4. Mundo, campo e duelo em separado

O Rivals não mistura duelo com mundo aberto. O PvP Stats desliga o anúncio de grupo dentro do campo.

Hoje um abate em duelo amistoso pode ser barrado por `hostileOnly`, mas o que passa entra no mesmo livro, na mesma crônica e nos mesmos feitos de raça. Vale um marca no encontro: `world`, `bg` ou `duel`. A Visão e a crônica filtram por ela. Os totais antigos continuam somando os três, para não zerar quem já jogou.

### 5. Nível do alvo e subzona na crônica

O OWPvP guarda o nível dos dois, a subzona e a hora. A crônica daqui guarda o seu nível, a zona e o golpe. O feito Sem Perdão já olha a diferença de 10 níveis quando o cliente informa o nível da vítima, mas esse número não entra no capítulo.

Acrescentar nível do alvo, subzona e hora no texto não muda o tom. O capítulo deixa de dizer só “um orc guerreiro no Vale Gris”.

### 6. Aviso de rival, sem radar

O Spy tem “matar à vista”: um alarme quando aquele nome age por perto. A parte perigosa é a lista de todo inimigo que o registro de combate denuncia, inclusive furtivo.

Dá para usar só o livro que já existe. Se um nome com pelo menos dois encontros aparecer num evento hostil de jogador, o addon toca o som de vingança e mostra o placar. Não há lista de proximidade, não há varredura de furtividade e a opção nasce desligada.

### 7. Aviso quando um feito fecha

O painel de conquistas do jogo e o PvP Stats avisam na hora. Aqui o feito só aparece na próxima vez que se abre o compêndio, com a data em `book.when`.

Um pop-up curto, reusando a fila que já existe, no momento em que a barra chega ao fim. Sem som de anunciador. O compêndio continua sendo o lugar da lista.

### 8. Calar a fala no campo, deixar o som

No PvP Stats o anúncio de grupo desliga sozinho no campo. Aqui `chatAnnounce` e `chatOnly` valem em todo lugar. Numa ravina cheia, a frase no chat atrapalha o chamado do grupo.

Uma opção “sem frase no campo” corta SAY e emote só dentro de campo de batalha. O pop-up e o First Blood continuam. O sussurro para quem morreu também, porque é o outro cliente, não o chat do grupo.

### 9. Ficha do nome, além do placar

OWPvP e PvP Stats guardam cada encontro com data. O rival daqui é um contador. A crônica é um texto com teto de 40 e esquece o meio da lista.

Uma aba do rival, aberta pelo nome, lista data, zona e lado (abate ou morte). A crônica continua sendo a narrativa. A ficha é o arquivo. O teto pode ser maior que 30 rivais na lista curta: a lista do compêndio mostra os 30 mais recentes, a ficha guarda o resto até um limite explícito.

### 10. Visão com nêmesis, presa e zona

O Rivals resume, na entrada, quem mais te mata, quem você mais mata e onde isso acontece. A Visão daqui ordena feitos pela barra mais cheia. Com tudo em zero, a primeira página vira a escada de abates honrosos.

No topo da Visão, três linhas calculadas do livro: nêmesis, presa e zona com mais abates. Não é feito novo. É leitura do que já está salvo.

### 11. Texto de anúncio por tipo

O PvP Announcer deixa editar cada frase. As “minhas falas” daqui entram na metade dos abates comuns ou épicos e não cobrem série, morte nem vingança.

Estender o editor para uma linha de série, uma de queda e uma de vingança. O sorteio atual permanece quando a linha do jogador está vazia.

### 12. Pasta de sons do jogador

O PvP Announcer troca o arquivo de cada anúncio. Os doze ogg daqui são fixos, com crédito no `Sounds/CREDITS.txt`.

Uma opção aponta outra pasta dentro do addon, com os mesmos nomes de arquivo. Se o arquivo não existir, volta o som atual. O crédito do pacote CC-BY continua na pasta original.

## Ordem sugerida

1. Tooltip, sessão no minimapa e aviso de feito fechado. Usam dados que já estão na memória.
2. Marca mundo/campo/duelo e nível do alvo na crônica. Mexe no que é gravado, então entra com a versão seguinte do banco.
3. Marco do mesmo nome, aviso de rival e silêncio de frase no campo.
4. Ficha, resumo da Visão, textos por tipo e pasta de sons. São telas novas.

BattlegroundEnemies, Capping e GladiatorlosSA2 ficam de fora dessa ordem.
