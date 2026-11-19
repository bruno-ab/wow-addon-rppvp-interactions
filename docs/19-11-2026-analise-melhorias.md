# Análise de melhorias — BanterCombat 1.0.26

Comparação com addons muito usados no Classic/Forever, no recorte de **imersão PvP** (não radar, não frames de CB, não timers).

Referências: dG Killshot, KillingBlow_Enhanced, Spy Classic, Rivals, PvP Stats Classic, OWPvP, PvPLedger, PvP Announcer, Ink & Embers / DialogueUI; e o que deliberadamente não competir (Capping, BattlegroundTargets, Gladius/Gladdy, GladiatorlosSA2).

A análise de [14-10-2026](14-10-2026-analise-pvp.md) cobre a primeira leva. A maior parte dela **já entrou** (tooltip, sessão no minimapa, contexto world/bg/duel, nível/subzona, rival alert, toast de feito, quiet BG, falas próprias, pasta de som).

---

## Posicionamento

| Família | Exemplos | Relação com BanterCombat |
|---------|----------|--------------------------|
| Anunciador de KB | dG Killshot, KillingBlow_Enhanced | Concorrência direta no som/pop-up; eles são mais “arcade”, BC é mais “livro + fala” |
| Ledger / rivalidade | Rivals, PvP Stats, OWPvP, PvPLedger | Mesmo território narrativo; BC já é mais rico em crônica/feitos |
| Radar / KoS | Spy | Só copiar o *conceito* de marcar rival — nunca a lista de proximidade |
| Competitivo CB/arena | Capping, BGT, Gladius, OmniBar | **Fora de escopo** |

Força atual do BanterCombat: killcam + anunciador Dota + rivais + diário + crônica por dia + desafios gated. Fraqueza relativa: polish de produto (settings, HUD, share, empacotamento) e algumas “features de 1 clique” que o Killshot popularizou.

---

## Já coberto (não reinventar)

- Placar no tooltip do inimigo  
- Sessão no tooltip do minimapa  
- Contexto `world` / `bg` / `duel`  
- Crônica com local, ambiente, memória de rival, golpe, nível  
- Aviso de rival (`rivalAlert`)  
- Toast de feito + marcos 1/5/10 contra o mesmo nome  
- `quietBg`, falas custom, pasta de som, temas de pop-up  

---

## Lacunas de alto valor (cabe no DNA do addon)

### 1. HUD de sessão ao vivo (estilo Killshot / PvP Announcer)

Minimapa mostra sessão no hover; falta um contador **sempre visível e arrastável**: abates / mortes / série da sessão, com lock. Toggle na config. Baixo risco, alto “feel” de addon maduro.

### 2. Ficha do rival (estilo OWPvP / PvP Stats)

Hoje: lista plana no Compêndio. Falta abrir um nome e ver **timeline** (data, zona, lado, duelo). Os `meetings` já existem no DB — falta UI.

### 3. Lista Kill-on-Sight explícita (só o que o Spy faz bem sem radar)

`rivalAlert` avisa quem já está no livro. Falta marcar “caçar este nome” com som/toast dedicado e motivo curto. Sem lista de nearby, sem scan de stealth.

### 4. Screenshot / emote no marco (Killshot)

Opções: screenshot em First Blood / série 5+ / vingança; emote opcional (`/flex` ou texto custom). Clássico em addons de KB; opcional e desligado por padrão.

### 5. Filtros no Compêndio

Diário e Rivais: filtrar por `world|bg|duel`, por dia, buscar nome. Contas: toggle “só facção inimiga”. Padrão de ledger (PvPLedger / Details-like filters).

### 6. Assistências (com cuidado no Forever)

Killshot e meters separam KB vs assist. Hoje o Forever já força cuidado com honor/assist. Se houver sinal limpo (grupo + CLEU), um contador `assists` no Resumo + diário enriquece sem virar Details.

### 7. Settings no menu Esc (padrão CurseForge)

Painel próprio + slash existem; falta registro em **Interface Options / Settings** (como dG Killshot). Reduz atrito para quem instala e não lê o README.

### 8. LibDataBroker / minimap broker

Botão custom funciona; brokers (Titan, Bazooka, MinimapButtonBag) esperam LDB. Compatibilidade “de addon grande”.

### 9. Perfis account vs personagem

`SavedVariablesPerCharacter` é certo para livro. Perfil de **opções** (som, tema, quiet BG, linhas) em `SavedVariables` account-wide — padrão AceDB/Details.

### 10. Export / share

- Copiar capítulo do dia ou placar do rival para o chat (ou caixa de texto).  
- Backup JSON/string já existe em espírito; um “Share last chapter” fecha o loop narrativo.

### 11. Execute cue (Killshot)

Som curto quando o alvo hostil cai abaixo de X% HP. É PvP útil e ainda cabe em “anunciador”, não em Gladius. Desligado por padrão.

### 12. Empacotamento e docs de produto

README ainda fala **1.0.0**; CurseForge ID placeholder; locales não-pt/en em grande parte stub. Addons populares vencem também por página Curse + changelog + install óbvio.

---

## Lacunas médias (polish)

| Item | De onde vem a ideia |
|------|---------------------|
| Medalha/ícone visual na série (além do som) | Rivals / Halo-style |
| Contador de KB da BG só na sessão (reset ao sair) | KillingBlow_Enhanced |
| Busca de rival por nome | Spy Statistics |
| Ignorar guilda amiga / whitelist | Spy Ignore patterns |
| Mais packs de som documentados (UT/MK) sem trocar o default Valve | Killshot packs |
| Scroll + bookmark na crônica (“último dia lido”) | Immersion / livros UI |
| Teste automatizado smoke dos parsers de zona/raça | prática de addons grandes |

---

## Não fazer (mesmo sendo popular)

- Radar / nearby / stealth detect (Spy) — controverso e fora do tom.  
- Frames de CB, timers de base, estimativa de placar (Capping, BGT).  
- Arena DR / trinket / CD enemy (Gladius, OmniBar, BigDebuffs).  
- Voz de spell inimigo (GladiatorlosSA2).  
- Leaderboard online entre jogadores.  
- Virar damage meter.

---

## Ordem sugerida (próximas versões)

1. **HUD de sessão + Options no Esc** — percepção imediata de addon “acabado”.  
2. **Ficha do rival + filtros no diário** — usa dados que já gravamos.  
3. **KoS manual + screenshot/emote opcional** — feature Killshot sem sair do nicho.  
4. **Perfis de opções account-wide + LDB** — qualidade de distribuição.  
5. **Execute cue + assists (se estável no Forever)** — só depois de telemetria/debug limpa.  
6. **CurseForge + README + locales** — crescimento de audiência.

---

## Critério de corte

Toda feature nova deve responder: *isso melhora a história do abate, o livro, ou o anunciador — ou só copia um addon de combate competitivo?*  
Se for a segunda, fica de fora.
