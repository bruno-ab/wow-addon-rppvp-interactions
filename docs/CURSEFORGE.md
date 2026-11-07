# Publicar no CurseForge

## Pacote pronto

```powershell
powershell -ExecutionPolicy Bypass -File scripts/pack-curseforge.ps1
```

Saída: `dist/BanterCombat-<versão>.zip` com `BanterCombat/` na raiz do zip (exigência do CurseForge / CurseForge App / Overwolf).

## Criar o projeto (primeira vez)

1. [CurseForge Authors](https://authors.curseforge.com/) → Create Project.
2. Game: **World of Warcraft** · Category: **Addons** · Subcategoria sugerida: **Combat** ou **PvP**.
3. Nome: `BanterCombat`.
4. Summary (EN, ~1 linha): *PvP kill banter, Dota-style announcer, rivals, chronicle and feats for Classic Era (also plays on WoW Forever).*
5. Aguarde aprovação do projeto.
6. Em About Project, anote o **Project ID** numérico e coloque no `.toc`:

```
## X-Curse-Project-ID: 123456
```

## Upload manual

1. Rode o script de zip.
2. Project → Files → Upload.
3. Game versions: marque **Classic Era** (interface `11507`). Forever (`16001`) não tem sabor oficial no CF — deixe na descrição que o mesmo build roda no cliente Forever.
4. Cole o trecho da versão em `CHANGELOG.md` na descrição do arquivo.
5. License no projeto: **All Rights Reserved** (código). Sons Valve: ver `Sounds/CREDITS.txt` — se a moderação pedir remoção, tire os `.ogg` e use só `soundFolder` com pacote do jogador.

## Git + BigWigs packager (opcional)

O repositório já tem `.pkgmeta`. Depois de ter `CF_API_KEY` e `X-Curse-Project-ID`, dá para automatizar com [BigWigsMods/packager](https://github.com/BigWigsMods/packager) em tag `v*`.

## Checklist antes de enviar

- [ ] `## Version` no `.toc` = nome do zip
- [ ] Sem pasta `docs/`, `.agents/`, `.git/` dentro do zip
- [ ] `Sounds/CREDITS.txt` presente
- [ ] Teste local: copiar pasta → `/reload` → `/banter announce`
