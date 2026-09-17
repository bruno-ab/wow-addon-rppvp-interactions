# BanterCombat — WoW Classic PvP Banter Addon

Addon de provocação PvP para **WoW Classic Era / Hardcore (1.15)**.

Quando você mata ou morre para outro jogador, um pop-up estilo diálogo aparece com falas baseadas em raça, classe, **vingança** e **marcos de abates**. Se o oponente também tiver o addon, a mensagem sincroniza via `BANTER_MSG`.

## Instalação

1. Copie a pasta `BanterCombat` para:
   `World of Warcraft\_classic_era_\Interface\AddOns\`
2. Reinicie o cliente ou `/reload`
3. Verifique se **BanterCombat** está habilitado na lista de addons

## Comandos

| Comando | Efeito |
|--------|--------|
| `/banter test` | Pop-up de teste (kill) |
| `/banter revenge` | Pop-up de vingança |
| `/banter milestone` | Pop-up de conquista (50 Orcs) |
| `/banter stats` | Totais de kills/deaths |
| `/banter hide` | Esconde o frame |

## Mecânicas

- **Self-View:** pop-up local imediato
- **Target-View:** `C_ChatInfo.SendAddonMessage` / prefixo `BANTER_MSG` (WHISPER)
- **Vingança:** se você matar quem te matou por último → fala prioritária
- **Conquistas:** 10 / 50 / 100 kills por raça ou classe
- **Raridade:** Lendária 1% · Épica 15% · Rara 20% · Comum 64%
- **SavedVariablesPerCharacter:** `BanterCombatDB`

## Estrutura

```
BanterCombat/
  BanterCombat.toc
  BanterCombat_Data.lua    # banco de falas
  BanterCombat_Stats.lua   # vingança + marcos + DB
  BanterCombat_UI.xml      # frame
  BanterCombat_UI.lua      # show/fade
  BanterCombat.lua         # CLEU + messaging
```

## Skills usadas no desenvolvimento

- `wow-addon-dev` (dinasor/wowar)
- `wow-api-framexml` / `wow-api-widget` / `wow-api-escape-sequences` (jburlison/wowaddonapiagents)

## Interface

`## Interface: 11507` (Classic Era 1.15.x)
