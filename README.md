# BanterCombat

**Version 1.0.0** · WoW Classic Era (`11507`) · WoW Forever classic beta (`16001`)

PvP immersion addon: kill/death banter, Dota-style announcer (First Blood, multi-kills, Ownage, streaks), rivals, chronicle, feats, and optional addon sync.

## Install

Copy `BanterCombat/` into the client `Interface\AddOns\` folder, then `/reload`.

## Announcer

| Cue | When |
|-----|------|
| First Blood | First kill of the session; again after entering a BG |
| Double / Triple / Ultra / Rampage | 2–5+ kills within 12 seconds |
| Ownage | Revenge kill, or streak 6 |
| Killing Spree … Holy Shit | Streak 3 → 10+ |

Volume and channel: `/banter config`. Custom pack: put `.ogg` files in `Sounds/MyPack/` and set the folder name in Lines options.

## Commands

| Command | What it does |
|---------|----------------|
| `/banter config` | Options |
| `/banter announce` | Preview announcer cues |
| `/banter test` | Preview speech popup |
| `/banter stats` | Totals |
| `/banter hide` | Hide popup + clear queue |

## Release package

```powershell
powershell -ExecutionPolicy Bypass -File scripts/pack-curseforge.ps1
```

Upload `dist/BanterCombat-1.0.0.zip`. Guide: [docs/CURSEFORGE.md](docs/CURSEFORGE.md).

## License

Code and art: **All Rights Reserved** ([LICENSE](LICENSE)).  
Announcer audio: **© Valve Corporation** — `BanterCombat/Sounds/CREDITS.txt`.

## Links

- Source: https://github.com/bruno-ab/wow-addon-rppvp-interactions
- Changelog: [CHANGELOG.md](CHANGELOG.md)
