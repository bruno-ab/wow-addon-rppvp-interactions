# BanterCombat

**Version 1.8.2** · WoW Classic Era (`11507`) · WoW Forever classic beta (`16001`)

PvP immersion addon: kill/death banter popups, Dota-style announcer sounds, rivals ledger, chronicle, feats, and optional addon-to-addon sync.

Addon de imersão PvP: falas de abate/morte, anunciador estilo Dota, rivais, crônica, feitos e sync opcional entre clientes.

## CurseForge package

```powershell
powershell -ExecutionPolicy Bypass -File scripts/pack-curseforge.ps1
```

Upload `dist/BanterCombat-1.8.2.zip`. Full steps: [docs/CURSEFORGE.md](docs/CURSEFORGE.md).

## Install

Copy `BanterCombat/` into:

- Classic Era: `World of Warcraft\_classic_era_\Interface\AddOns\`
- WoW Forever: the client’s `Interface\AddOns\` folder

Then `/reload`.

## Commands

| Command | What it does |
|---------|----------------|
| `/banter` / `/banter help` | Help |
| `/banter config` | Options |
| `/banter announce` | Preview announcer cues |
| `/banter test` | Test popup |
| `/banter stats` | Kill/death totals |
| `/banter hide` | Hide popup + clear queue |

## Features

- Kill and death speech (revenge, streak titles, race/class milestones, custom lines)
- Announcer cues: First Blood → multi-kills → Killing Spree … Holy Shit (+ Ownage preview)
- Optional custom `Sounds/<folder>/` pack (same file names)
- Rivals book, chronicle, achievements/compendium
- Whisper + group sync when the other player also runs BanterCombat
- Quiet battleground chat option (UI/sounds stay)

## License

Code and art: **All Rights Reserved** (see [LICENSE](LICENSE)).  
Announcer audio: **© Valve Corporation** — see `BanterCombat/Sounds/CREDITS.txt`.

## Links

- Source: https://github.com/bruno-ab/wow-addon-rppvp-interactions
- Changelog: [CHANGELOG.md](CHANGELOG.md)
