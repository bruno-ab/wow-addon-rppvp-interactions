# Changelog

## 1.0.25

- Challenges show the condition under the title (e.g. “Matar 500 Trolls”).
- Hide unobtainable feats: same-faction race slayers/firsts and empty race/class categories.
- Rival, diary, chronicle and spotlight names strip the realm (name only).
- Diary grouped by day with colored sides; chronicle chapters show meta (name · race · class · zone · date).

## 1.0.24

- Duel outcome by relative HP (ignore cancels); remember duel opponent; skip nameless duel log rows.
- Compendium polish: hide stuck Contas headers, empty diary/rivals states, shared log formatting, wider challenge tabs.
- Minimap menu hover; race fallback via GUID; locale bits for level/context/empty feats.

## 1.0.23

- Compendium redesigned like Ink & Embers Legacy: Overview, Challenges (sub-tabs), Counts, Rivals, Chronicle, PvP Diary.
- Rich PvP log (`pvpLog`) + duel W–L; kills/deaths/duels store level, zone, map, context, self/pet.
- Hide race/class-gated achievements that do not apply to the current character.

## 1.0.22

- Fix: menus opaque again on Forever (solid WHITE8X8 fill; BackdropTemplate when available).
- Fix: kill popup invisible — no longer stuck at alpha 0 when fade/scale anim fails; Shade is the real opaque toast fill.

## 1.0.21

- Fix: feat toast kept repeating "Primeiro Orc" — dated feats now persist in `book.when` so FreshTitle only fires once.
- Normalize race tokens (`Undead` → `Scourge`, race ids) so undead/other race feats and counters count correctly.

## 1.0.20

- Killcam polish: cinematic toast (shade + left accent + soft cue wash), no spaced-caps / DialogueUI stack on the banner.
- Clean title only on special cues; banter rises when there is no hero line; portrait crop + ring tinted by announcer; quieter flash/signature.

## 1.0.19

- Killcam popup redesign: hero cue (FIRST BLOOD), larger victim portrait + faction ring, compact dark layout.
- Banter in the middle, killer name/title as gold signature; cue wash/flash; streak watermark; default theme Dark PvP (+ Auto).

## 1.0.18

- Options / Lines / Backup / Minimap menu / Compendium use default WoW dialog chrome (no Plate.tga).
- “Mostrar o banner também no chat” prints badge + speaker + line locally; “Só no chat” skips the popup.

## 1.0.17

- Visual upgrade: punch/flash by announcer cue, streak number, rarity bar, kind band, combo label, slide-out fade.
- Themes: Pergaminho / Dark PvP / Minimal; popup scale; toggles for streak + visual FX.
- Minimap icon tints with streak; kill popup prefers target portrait + faction ring.

## 1.0.16

- Fix: with debug on, `tostring` of secret CLEU names aborted the combat handler before `lastBlow` — every real KB looked like an assist.
- Honor HK credits again when you recently engaged (mine hit / hostile target); CLEU lastBlow recorded before debug/achievements.

## 1.0.15

- Options: button to test announcer (sound + pop-up).
- Forever secret GUIDs: restore KB credit (CONTROL_PLAYER, target fallback, name fallback “Inimigo”, UNIT_DIED without GUID compare).
- Tooltip rival score no longer errors on secret unit tokens.

## 1.0.14

- Show BanterCombat version in chat on login / reload.

## 1.0.13

- Forever: stop Lua spam from secret `UnitGUID`/`UnitName` compares (`guid == ""`, target watch, CLEU).
- All GUID/name ops go through secret-safe helpers (`SafeEqual`, `NameUsable`, `SafeString`).

## 1.0.12

- Forever: chat kill path no longer errors on secret strings (was treating every KB as assist).
- Honor HK window widened to 8s; `lastBlow` only cleared after a successful kill credit.
- Cache known player GUIDs (trap/DoT KB without target); stop parsing HONOR_GAIN chat (assists).

## 1.0.11

- Kill sting prefers Dominating/DoubleKill `.ogg` before soft kits (kits could “succeed” without audio on Forever).

## 1.0.10

- Count hunter trap / pet / totem damage as yours (CLEU `AFFILIATION_MINE`) so fire-trap killing blows play sound.
- Honor KB window 3s when lastBlow was ours; debug shows spell name on ignored assists.

## 1.0.9

- Restore kill sound on Forever: honor HK counts only with a fresh last hit (≤2s), not pure assists.
- Soft `Kill` cue falls back to Dominating/DoubleKill `.ogg` when PlaySound kits fail.

## 1.0.8

- Stop treating honor kills as killing blows (assists were opening the kill window).
- Only CLEU PARTY_KILL / recent last-hit UNIT_DIED / “Você matou” chat count; tighten last-hit window to 1.5s.

## 1.0.7

- Fix killing-blow name showing as `?` on Forever (remember last hostile target/hit; skip whisper to `?`).

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
