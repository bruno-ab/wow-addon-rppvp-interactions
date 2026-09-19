# BanterCombat — WoW Classic PvP Banter Addon

**Version 1.2.0** · WoW Classic Era / Hardcore (1.15)

### English

PvP banter addon for **WoW Classic Era / Hardcore**. When you kill (or die to) another player, BanterCombat shows a styled popup with taunts, revenge lines, race/class milestones, rarity colors, and optional addon-to-addon sync so opponents and party members can see the same moment.

### Português

Addon de provocação PvP para **WoW Classic Era / Hardcore**. Ao matar (ou morrer para) outro jogador, o BanterCombat exibe um pop-up com falas, vingança, conquistas por raça/classe, cores por raridade e sync opcional entre addons para o oponente e o grupo verem o mesmo momento.

## Installation / Instalação

Copy `BanterCombat/` → `World of Warcraft\_classic_era_\Interface\AddOns\` → `/reload`

Copie `BanterCombat/` → `World of Warcraft\_classic_era_\Interface\AddOns\` → `/reload`

## Commands / Comandos

| Command | English | Português |
|---------|---------|-----------|
| `/banter test` | Test popup | Pop-up de teste |
| `/banter revenge` | Revenge line | Vingança |
| `/banter milestone` | Milestone (50 Orcs) | Conquista (50 Orcs) |
| `/banter stats` | Totals + top races/classes | Totais + top raças/classes |
| `/banter config` | Options panel | Opções |
| `/banter queue` | Queue size | Tamanho da fila |
| `/banter hide` | Hide + clear queue | Esconde + limpa fila |
| `/banter debug [on\|off]` | Debug log | Log de diagnóstico |
| `/banter history` | Recent lines | Últimas falas |
| `/banter ignore <name>` | Ignore player (`list` / `clear`) | Ignora jogador (`list` / `clear`) |
| `/banter unignore <name>` | Remove ignore | Remove ignore |
| `/banter help` | Help | Ajuda |

## Highlights 1.2 / Destaques 1.2

**EN**
- Filters: hostile only, show deaths, group banters
- Optional chat emote; debug / history / ignore
- Truncated & sanitized encode; fixed dedup prune
- Options refresh + UI Scale anim (Classic-safe)

**PT**
- Filtros: só inimigos, mostrar mortes, banters do grupo
- Emote opcional no chat; debug / history / ignore
- Encode truncado/sanitizado; dedup prune corrigido
- Options refresh + UI Scale anim (Classic-safe)

## Highlights 1.1 / Destaques 1.1

**EN**
- Popup queue, options, drag + saved position
- Rarity colors + class icon
- Sync WHISPER + PARTY/RAID/INSTANCE (protocol v2)
- Revenge, milestones 10/50/100, sound, optional 3D model

**PT**
- Fila de pop-ups, opções, drag + posição salva
- Cores por raridade + ícone de classe
- Sync WHISPER + PARTY/RAID/INSTANCE (protocolo v2)
- Vingança, marcos 10/50/100, som, model 3D opcional

Changelog: [docs/17-9-2026.md](docs/17-9-2026.md) · Tests: [docs/RegressionTesting.md](docs/RegressionTesting.md)
