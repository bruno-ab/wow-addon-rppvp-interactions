# Regression Testing — BanterCombat

## Smoke (`/reload` após cada mudança)

| # | Ação | Esperado |
|---|------|----------|
| 1 | `/reload` | Sem erros Lua; mensagem de load |
| 2 | `/banter test` | Pop-up com cor de raridade + ícone de classe |
| 3 | `/banter revenge` | Badge dourado + medalha + som (se ligado) |
| 4 | `/banter milestone` | Texto de 50 Orcs + badge CONQUISTA |
| 5 | `/banter test` ×5 rápido | Fila: pop-ups em sequência, não só o último |
| 6 | `/banter queue` | Contagem coerente |
| 7 | `/banter config` | Painel abre; toggles (incl. hostile/deaths/group/chat/debug) persistem após `/reload` |
| 8 | Arrastar o pop-up | Posição salva após `/reload` |
| 9 | Reset posição no config | Volta ao BOTTOM +160 |
| 10 | `/banter hide` | Esconde e limpa a fila |
| 11 | `/banter stats` | Totais + top raças/classes |
| 12 | `/banter debug` | Toggle; com on, kills imprimem log |
| 13 | `/banter history` | Últimas falas após testes |
| 14 | `/banter ignore AlvoTeste` + kill sync | Remote/local do nome ignorado não aparece |

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

## Não-regredir

- Sem double-fire no mesmo GUID em <1.5s
- Sem crash se `GetPlayerInfoByGUID` falhar
- SavedVariables version ≥ 2 com counters scrubbed
- Payload addon ≤ limites (texto 180, badge 48)
- Reabrir config não “desmarca” toggles já salvos
