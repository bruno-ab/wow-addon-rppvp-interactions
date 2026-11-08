# Changelog

## 1.0.6

- Killing blow always prints in local chat; optional `/say` via “Avisar killing blow no chat” (on by default).
- Extra Forever detection: honor session HK poll + target-death ticker every 0.25s.

## 1.0.5

- Kill detection fallbacks for Forever: CLEU varargs, chat “Você matou/slain”, target-death watch.
- Debug now prints CLEU kill-related lines (`cleu live`, `PARTY_KILL`, `UNIT_DIED`, `chat-kill`).

## 1.0.4

- Real kills now play the announcer immediately (same path as `/banter announce`).
- Detect players by GUID when combat-log flags omit TYPE_PLAYER; wider UNIT_DIED killing-blow window; friendlier hostile filter.

## 1.0.3

- Re-encode announcer `.ogg` to 44.1 kHz mono (Forever rejected 22.05 kHz Vorbis).
- Fix PlaySoundFile success check (nil is failure); force Master instead of muted Dialog.

## 1.0.2

- Fix silent kills on Forever: PlaySoundFile now prefers Master (Dialog is often muted), and ordinary streak 1–2 kills play a light sting.
- Detect killing blows via `UNIT_DIED` when `PARTY_KILL` is missing in world PvP.

## 1.0.1

- Fix ADDON_ACTION_BLOCKED on Forever/Classic: rival score tooltip no longer calls `GameTooltip:Show()` from a hooked path (that tainted Blizzard UI).

## 1.0.0 — First public release

### Announcer (PvPSound-style for Forever)

- **First Blood** plays once per session (not on every post-death kill); resets when entering a battleground.
- **Ownage** on revenge kills and on streak 6 (UT-style slot in the Dota ladder).
- Multi-kill window (12s): Double → Triple → Ultra → Rampage.
- Streak ladder: Killing Spree → Dominating → Mega Kill → Ownage → Wicked Sick → Monster Kill → Godlike → Holy Shit.
- Announcer **volume** slider and **sound channel** (Dialog / SFX / Master / Ambience).
- Custom pack drop-in via `Sounds/<folder>/` + option `soundFolder` (see `Sounds/Packs/README.txt`).

### Immersion & stats polish

- Rival personal marks on the **1st**, 5th and 10th kill against the same name.
- Session kills/deaths/streak on the minimap tooltip (already present; kept for v1).
- Rival score on unit tooltips, quiet battleground chat, rival alert, chronicle context.

### Packaging

- CurseForge-ready zip (`scripts/pack-curseforge.ps1`).
- Floating debug buttons removed in 1.8.2.

## 1.8.2

- Removed floating Test / Sounds / Chronicle debug buttons.
- Removed “Test a line” from the minimap menu. Preview via `/banter test` and `/banter announce`.

## 1.8.1

- Dota 2 announcer pack wired end-to-end.
- Custom sound subfolder option with fallback to built-in oggs.
- Packaging metadata for CurseForge.

## 1.8.0

- Rival alert, quiet battleground chat, chronicle context (world / bg / duel).

## 1.5.0 – 1.7.x

- Rivals ledger, chronicle, achievements, streak titles, sync, custom lines.
