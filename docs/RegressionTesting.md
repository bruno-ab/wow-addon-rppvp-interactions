# Regression Testing — BanterCombat

## Smoke (`/reload` após cada mudança)

| # | Ação | Esperado |
|---|------|----------|
| 1 | `/reload` | Sem erros Lua; mensagem de load |
| 2 | `/banter test` | Pop-up com cor de raridade + ícone de classe |
| 2b | Botão **Testar** (canto superior esquerdo) | Cada clique avança abate → comum → incomum → épico → lendário → vingança → conquista → morte. O selo mostra o nome da raridade na cor dela (cinza, verde, roxo, laranja). Arrastar com o botão direito move o botão |
| 2c | Pop-up com DialogueUI ativo | Pergaminho da janela de diálogo do Forever (tema claro ou escuro do DialogueUI). Sem DialogueUI, volta a borda clássica de diálogo |
| 3 | `/banter revenge` | Badge dourado + medalha + som (se ligado) |
| 4 | `/banter milestone` | Texto de 50 Orcs + badge CONQUISTA |
| 5 | `/banter test` ×5 rápido | Fila: pop-ups em sequência, não só o último |
| 6 | `/banter queue` | Contagem coerente |
| 7 | `/banter config` | Painel abre; toggles (incl. hostile/deaths/group/chat/debug) persistem após `/reload` |
| 8 | Arrastar o pop-up | Posição salva após `/reload` |
| 9 | Reset posição no config | Volta ao centro da tela |
| 10 | `/banter hide` | Esconde e limpa a fila |
| 11 | `/banter stats` | Totais + top raças/classes |
| 12 | `/banter debug` | Toggle; com on, kills imprimem log |
| 13 | `/banter history` | Últimas falas após testes |
| 14 | `/banter ignore AlvoTeste` + kill sync | Remote/local do nome ignorado não aparece |
| 15 | Botão do minimapa | Clique esquerdo abre o compêndio. Clique direito abre o menu: liga e desliga as opções, troca o idioma, faz backup, carrega dados, abre Minhas falas, o painel completo e um teste. Arrastar move o botão |
| 16 | Opções → Idioma | Cicla os idiomas oficiais. A fala de teste seguinte sai nesse idioma. `auto` segue o idioma do cliente |
| 17 | Compêndio → Rivais | Lista nome, placar dos dois lados e data do último encontro. Vazio até existir histórico |
| 18 | Compêndio → Abates, Campo, Honra, Situação | Abates honrosos e séries ficam em Abates. Vitória, bandeira e torre ficam em Campo. Honra da semana e do total ficam em Honra. Cobrador Anônimo fica em Situação. O primeiro de cada raça e classe aparece na seção correspondente, com a data antiga |
| 19 | `/banter rival`, `/banter streak`, `/banter zone` | Fala de rival (4–2), série de 5 com título debaixo do nome, e linha da zona atual (ou da ravina) |
| 20 | `/banter lines` | Editor abre. Linha comum e épica ficam salvas depois de `/reload`. Máximo 8 por lista |
| 21 | Som ligado, botão Testar | Comum quase mudo, incomum um clique, épico um acorde, lendário uma fanfarra. Vingança e conquista continuam com o aviso de raide. Morte continua com o som de falha |
| 22 | `/banter announce` | Cada chamada toca o próximo anúncio, de First Blood até Godlike. Em combate, o primeiro abate da vida é First Blood, o segundo em até 12s é Double Kill, o nono sem morrer é Godlike. Morrer volta a First Blood |
| 22b | `/banter test` com som ligado | O primeiro teste de abate toca First Blood. Outro teste em até 12s sobe a escada. O teste de morte zera, e o abate seguinte volta a First Blood |
| 22c | Botão Sons | Um clique percorre First Blood até Godlike e depois os sons de raridade. O rótulo mostra o som atual. Outro clique para. Arrastar Testar move os dois |
| 23 | Compêndio → Crônica | Sem abates novos, mostra o texto vazio ou os capítulos de feitos e conquistas já alcançados. Depois de um abate, o capítulo traz raça, classe, zona, nível, golpe e nome. As setas trocam de capítulo |
| 23b | Botão Crônica | O primeiro clique abre a crônica com um orc guerreiro. O segundo continua o mesmo par com o outro texto. O terceiro acrescenta uma elfa ladina. O quarto apaga só esses capítulos de teste |
| 24 | Compêndio | Janela com pergaminho na coluna dos feitos, faixa e categorias à esquerda. O pergaminho não cobre o menu. Visão mostra as conquistas mais perto do fim. Contra raças, Contra classes, Combinações, Abates, Campo, Honra, Situação, Raciais, Identidade, Linhagem e Pessoal separam os feitos. Raça ou classe errada fica cinza. As setas trocam a página e ficam cinza no fim. Contas, Rivais e Crônica continuam na lista |
| 25 | Menu → backup, carregar, só no chat | Backup abre o texto já selecionado, começando com `BC1:`. Colar um texto inválido não apaga nada. Colar o backup devolve as contas. Com “janela de abate vira uma frase no chat” ligado, o abate sai em SAY e o pop-up não abre. O botão Testar ainda mostra a janela |
| 26 | Tooltip, sessão, Visão, rival, campo quieto | O login não acusa erro de HookScript. Um nome do livro ganha o placar no tooltip. O minimapa mostra a sessão. A Visão mostra nêmesis, presa e zona. O 5º abate do mesmo nome usa a fala pessoal. No campo, com a opção ligada, não sai frase no chat e o pop-up continua. O aviso de rival só aparece se a opção for ligada. Minhas falas grava vingança, série, queda e a pasta de sons |

## PvP (2 clientes com o addon)

| # | Ação | Esperado |
|---|------|----------|
| A | Kill em world/BG | Pop-up local + whisper `BANTER_MSG` no derrotado |
| B | Kill com party sync on | Mensagem também em PARTY/RAID/INSTANCE |
| C | Matar quem te matou | Badge VINGANÇA |
| D | 10º kill da mesma raça | Fala de marco |
| E | Cliente só v1 | Ainda decodifica (compat) |
| F | Opção “só PvP” on, sem flag | Sem pop-up em PvE |
| G | `hostileOnly` on + duelo amigo | Sem pop-up de kill |
| H | `showDeaths` off | Morte registra stats, sem pop-up |
| I | `showGroupBanter` off | Recebe whisper, ignora PARTY/RAID |
| J | `chatAnnounce` on | Emote com a fala no chat |
| K | Dois clientes, série de 3+ | O pop-up do outro mostra o título debaixo do nome |
| L | Morrer com série ≥ 3 | A fala é de queda e a série zera |

## Não-regredir

- Sem double-fire no mesmo GUID em <1.5s
- Sem crash se `GetPlayerInfoByGUID` falhar
- SavedVariables version ≥ 2 com counters scrubbed
- Payload addon ≤ limites (texto 180, badge 48)
- Reabrir config não “desmarca” toggles já salvos
