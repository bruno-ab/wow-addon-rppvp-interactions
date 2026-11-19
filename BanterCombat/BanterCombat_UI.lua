local addonName, ns = ...
ns = ns or {}
ns.UI = ns.UI or {}

local UI = ns.UI
local Data = ns.Data

local queue = {}
local showing = false
local hideTicker
local enterGroup
local generation = 0

local function colorize(text, hex)
  if not text or text == "" then
    return ""
  end
  if WrapTextInColorCode then
    return WrapTextInColorCode(text, hex)
  end
  return "|c" .. hex .. text .. "|r"
end

local function classIconMarkup(classToken)
  if not classToken or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[classToken] then
    return ""
  end
  local c = CLASS_ICON_TCOORDS[classToken]
  local l, r, t, b = c[1], c[2], c[3], c[4]
  if CreateTextureMarkup then
    return CreateTextureMarkup(
      "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
      256, 256, 14, 14, l, r, t, b
    ) .. " "
  end
  return string.format(
    "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:14:14:0:0:256:256:%d:%d:%d:%d|t ",
    math.floor(l * 256 + 0.5),
    math.floor(r * 256 + 0.5),
    math.floor(t * 256 + 0.5),
    math.floor(b * 256 + 0.5)
  )
end

local function rarityHex(kind, rarity)
  local colors = Data.RARITY_COLOR or {}
  if kind == "revenge" then
    return colors.revenge or "FFFFD100"
  end
  if kind == "milestone" then
    return colors.milestone or "FFFFD100"
  end
  if rarity and colors[rarity] then
    return colors[rarity]
  end
  if kind == "death" then
    return colors.death or "FFCC6666"
  end
  return colors.common or "FF9D9D9D"
end

local function hexToRGB(hex)
  hex = tostring(hex or "FFFFFFFF")
  if #hex == 8 then
    hex = hex:sub(3)
  end
  local r = tonumber(hex:sub(1, 2), 16) or 255
  local g = tonumber(hex:sub(3, 4), 16) or 255
  local b = tonumber(hex:sub(5, 6), 16) or 255
  return r / 255, g / 255, b / 255
end

local function inkTint(r, g, b)
  return 0.10 + r * 0.42, 0.08 + g * 0.42, 0.06 + b * 0.38
end

local function stopHide()
  if hideTicker then
    hideTicker:Cancel()
    hideTicker = nil
  end
end

local ANNOUNCER_FLASH = {
  FirstBlood = { 1.00, 0.18, 0.12 },
  DoubleKill = { 1.00, 0.55, 0.12 },
  TripleKill = { 1.00, 0.72, 0.15 },
  UltraKill = { 1.00, 0.35, 0.85 },
  Rampage = { 0.95, 0.15, 0.55 },
  KillingSpree = { 0.25, 0.85, 1.00 },
  Dominating = { 0.85, 0.20, 1.00 },
  MegaKill = { 1.00, 0.82, 0.15 },
  Unstoppable = { 0.40, 1.00, 0.55 },
  WickedSick = { 0.55, 1.00, 0.20 },
  MonsterKill = { 1.00, 0.25, 0.35 },
  Godlike = { 0.75, 0.35, 1.00 },
  HolyShit = { 1.00, 0.95, 0.35 },
  Ownage = { 1.00, 0.75, 0.10 },
  Kill = { 0.75, 0.75, 0.80 },
}

local RARITY_BAR_WIDTH = {
  common = 0.28,
  rare = 0.48,
  epic = 0.72,
  legendary = 1.0,
  revenge = 0.85,
  milestone = 0.85,
  death = 0.40,
}

local KIND_BAND = {
  kill = { 0.75, 0.18, 0.14 },
  death = { 0.35, 0.10, 0.12 },
  revenge = { 1.00, 0.75, 0.12 },
  rival = { 0.85, 0.35, 0.15 },
  milestone = { 0.95, 0.80, 0.25 },
  streak = { 0.55, 0.25, 0.95 },
}

local function settings()
  return ns.Options and ns.Options.Get and ns.Options.Get() or {}
end

local function visualFxOn()
  local s = settings()
  return s.visualFx ~= false
end

local function themeName()
  local t = settings().uiTheme
  if t == "auto" or t == nil or t == "" then
    if UnitInBattleground and UnitInBattleground("player") then
      return "dark"
    end
    return "dark"
  end
  if t == "dark" or t == "minimal" or t == "parchment" then
    return t
  end
  return "dark"
end

local function setFontSafe(fontString, path, size, flags)
  if not fontString or not fontString.SetFont then
    return
  end
  local ok = pcall(fontString.SetFont, fontString, path, size, flags)
  if not ok then
    pcall(fontString.SetFont, fontString, "Fonts\\FRIZQT__.TTF", size, flags)
  end
end

local function paintSolid(tex, r, g, b, a)
  if not tex then
    return
  end
  if tex.SetColorTexture then
    tex:SetColorTexture(r, g, b, a)
  else
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetVertexColor(r, g, b, a)
  end
end

local function setCueWash(frame, announcer, kind)
  if not frame.CueWash then
    return
  end
  -- Deaths and plain kills stay dry — no celebration wash.
  if not visualFxOn() or kind == "death" or kind == "milestone" or (not announcer) or announcer == "Kill" then
    frame.CueWash:Hide()
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer]
  if not rgb then
    frame.CueWash:Hide()
    return
  end
  local a = isHeroCue(announcer) and 0.36 or 0.18
  frame.CueWash:ClearAllPoints()
  frame.CueWash:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  frame.CueWash:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  frame.CueWash:SetWidth(isHeroCue(announcer) and 168 or 140)
  frame.CueWash:SetTexture("Interface\\Buttons\\WHITE8X8")
  frame.CueWash:SetVertexColor(rgb[1], rgb[2], rgb[3], a)
  frame.CueWash:Show()
end

local HERO_CUES = {
  FirstBlood = true, Ownage = true, Godlike = true, HolyShit = true,
  MonsterKill = true, Rampage = true, UltraKill = true,
}

local FLASH_DELAY = {
  FirstBlood = 0.32, DoubleKill = 0.18, TripleKill = 0.20, UltraKill = 0.22,
  Rampage = 0.24, KillingSpree = 0.22, Dominating = 0.24, MegaKill = 0.22,
  Unstoppable = 0.24, WickedSick = 0.22, MonsterKill = 0.28, Godlike = 0.36,
  HolyShit = 0.30, Ownage = 0.26, Kill = 0.04,
}

local RACE_PORTRAIT = {
  Human = "Interface\\Icons\\INV_Misc_Head_Human_01",
  Dwarf = "Interface\\Icons\\INV_Misc_Head_Dwarf_01",
  NightElf = "Interface\\Icons\\INV_Misc_Head_NightElf_01",
  Gnome = "Interface\\Icons\\INV_Misc_Head_Gnome_01",
  Orc = "Interface\\Icons\\INV_Misc_Head_Orc_01",
  Scourge = "Interface\\Icons\\INV_Misc_Head_Undead_01",
  Undead = "Interface\\Icons\\INV_Misc_Head_Undead_01",
  Tauren = "Interface\\Icons\\INV_Misc_Head_Tauren_01",
  Troll = "Interface\\Icons\\INV_Misc_Head_Troll_01",
}

local function isHeroCue(announcer)
  return announcer and HERO_CUES[announcer] and true or false
end

local function setAnimScale(anim, fromX, fromY, toX, toY)
  if not anim then
    return
  end
  if anim.SetScaleFrom then
    anim:SetScaleFrom(fromX, fromY)
    anim:SetScaleTo(toX, toY)
  elseif anim.SetFromScale then
    anim:SetFromScale(fromX, fromY)
    anim:SetToScale(toX, toY)
  elseif anim.SetScale then
    anim:SetOrigin("CENTER", 0, 0)
    anim:SetScale(toX / math.max(fromX, 0.01), toY / math.max(fromY, 0.01))
  end
end

local enterPunch
local function ensureEnterAnim(frame, punch)
  punch = punch or 1.06
  if enterGroup and enterPunch == punch then
    enterGroup:Stop()
    return enterGroup
  end
  if enterGroup then
    enterGroup:Stop()
  end
  enterPunch = punch
  enterGroup = frame:CreateAnimationGroup()
  local scale = enterGroup:CreateAnimation("Scale")
  setAnimScale(scale, 0.90, 0.90, 1.0, 1.0)
  scale:SetDuration(punch >= 1.08 and 0.14 or 0.16)
  scale:SetSmoothing("OUT")
  scale:SetOrder(1)

  local hit = enterGroup:CreateAnimation("Scale")
  setAnimScale(hit, 1.0, 1.0, punch, punch)
  hit:SetDuration(0.07)
  hit:SetOrder(2)
  hit:SetSmoothing("OUT")

  local settle = enterGroup:CreateAnimation("Scale")
  setAnimScale(settle, punch, punch, 1.0, 1.0)
  settle:SetDuration(0.11)
  settle:SetOrder(3)
  settle:SetSmoothing("IN")
  return enterGroup
end

local flashGroup
local flashAnim
local flashToken = 0
local function playFlash(frame, announcer, kind)
  if not visualFxOn() or not frame or not frame.Flash then
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer] or KIND_BAND[kind] or { 1, 1, 1 }
  local peak = isHeroCue(announcer) and 0.48 or 0.26
  if kind == "death" then
    peak = 0.22
  end
  frame.Flash:SetTexture("Interface\\Buttons\\WHITE8X8")
  frame.Flash:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
  frame.Flash:SetAlpha(peak)
  frame.Flash:Show()
  if not flashGroup then
    flashGroup = frame.Flash:CreateAnimationGroup()
    flashAnim = flashGroup:CreateAnimation("Alpha")
    flashGroup:SetScript("OnFinished", function()
      if frame.Flash then
        frame.Flash:Hide()
        frame.Flash:SetAlpha(0)
      end
    end)
  else
    flashGroup:Stop()
  end
  local a = flashAnim
  if a.SetFromAlpha then
    a:SetFromAlpha(peak)
    a:SetToAlpha(0)
  else
    a:SetChange(-peak)
  end
  a:SetDuration(isHeroCue(announcer) and 0.50 or 0.36)
  a:SetSmoothing("OUT")
  flashGroup:Play()
end

local function playFlashSynced(frame, announcer, kind, myGen)
  local delay = FLASH_DELAY[announcer or "Kill"] or 0.08
  if kind == "death" then
    delay = 0.05
  end
  flashToken = flashToken + 1
  local token = flashToken
  if delay <= 0.02 then
    playFlash(frame, announcer, kind)
    return
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(delay, function()
      if token ~= flashToken or myGen ~= generation then
        return
      end
      playFlash(frame, announcer, kind)
    end)
  else
    playFlash(frame, announcer, kind)
  end
end

local function resolveDuration(payload)
  local base = tonumber(settings().duration) or 4
  local scale = base / 4
  local kind = payload and payload.kind or "kill"
  local announcer = payload and payload.announcer
  if kind == "death" then
    return math.max(1.6, 2.5 * scale)
  end
  if kind == "milestone" then
    return math.max(2.4, 3.5 * scale)
  end
  if isHeroCue(announcer) then
    return math.max(3.5, 5.0 * scale)
  end
  if announcer and announcer ~= "Kill" then
    return math.max(2.6, 3.6 * scale)
  end
  return math.max(2.0, 3.0 * scale)
end

local function queuePriority(payload)
  local kind = payload and payload.kind or "kill"
  local announcer = payload and payload.announcer
  if kind == "revenge" or announcer == "Ownage" then
    return 90
  end
  if isHeroCue(announcer) then
    return 85
  end
  if kind == "kill" or kind == "rival" or kind == "streak" then
    return 70
  end
  if kind == "milestone" then
    return 40
  end
  if kind == "death" then
    return 30
  end
  return 50
end

local function shortDisplayName(name)
  if ns.Stats and ns.Stats.DisplayName then
    return ns.Stats.DisplayName(name) or name
  end
  if type(name) ~= "string" then
    return nil
  end
  return name:match("^([^%-]+)") or name
end

local function ctxLabel(ctx)
  local L = ns.L or {}
  if ctx == "bg" then
    return L.COMP_LOG_CTX_bg or "CB"
  end
  if ctx == "duel" then
    return L.COMP_LOG_CTX_duel or "duelo"
  end
  return L.COMP_LOG_CTX_world or "mundo"
end

local function ensureOverlayFonts(frame)
  if not frame.Subject then
    frame.Subject = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.Subject:SetWidth(78)
    frame.Subject:SetJustifyH("CENTER")
  end
  if not frame.Meta then
    frame.Meta = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.Meta:SetWidth(200)
    frame.Meta:SetJustifyH("RIGHT")
  end
end

local function applyPopupScale(frame)
  local scale = tonumber(settings().popupScale) or 1
  if scale < 0.7 then
    scale = 0.7
  elseif scale > 1.4 then
    scale = 1.4
  end
  if frame.SetScale then
    frame:SetScale(scale)
  end
end

local function applyThemeChrome(frame, announcer)
  local theme = themeName()
  frame._uiTheme = theme
  if frame.PaperTop then frame.PaperTop:Hide() end
  if frame.PaperMid then frame.PaperMid:Hide() end
  if frame.PaperBot then frame.PaperBot:Hide() end
  if frame.SocketFrame then frame.SocketFrame:Hide() end

  local border = ANNOUNCER_FLASH[announcer] or { 0.72, 0.58, 0.28 }
  -- Forever: SetBackdrop often no-ops without BackdropTemplate. Shade is the real fill.
  local shadeR, shadeG, shadeB, shadeA = 0.03, 0.03, 0.04, 0.94
  if theme == "parchment" then
    shadeR, shadeG, shadeB, shadeA = 0.12, 0.09, 0.06, 0.94
  elseif theme == "minimal" then
    shadeR, shadeG, shadeB, shadeA = 0.04, 0.04, 0.05, 0.90
  end
  if frame.Shade then
    frame.Shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    paintSolid(frame.Shade, shadeR, shadeG, shadeB, shadeA)
    frame.Shade:Show()
  end
  -- SetBackdrop once per theme; only retint the border per cue.
  local chromeKey = theme
  if frame.SetBackdrop and frame._chromeKey ~= chromeKey then
    frame._chromeKey = chromeKey
    pcall(frame.SetBackdrop, frame, {
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false, edgeSize = theme == "minimal" and 1 or 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
  end
  if frame.SetBackdropColor then
    frame:SetBackdropColor(shadeR, shadeG, shadeB, shadeA)
  end
  if frame.SetBackdropBorderColor then
    local ba = theme == "minimal" and 0.45 or 0.85
    frame:SetBackdropBorderColor(border[1] * 0.9, border[2] * 0.9, border[3] * 0.9, ba)
  end
  frame._dialogueSkin = false
end

local function setKindBand(frame, kind, announcer, deathRight)
  if not frame.KindBand then
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer] or KIND_BAND[kind] or KIND_BAND.kill
  if kind == "death" then
    rgb = { 0.72, 0.12, 0.14 }
  elseif kind == "revenge" then
    rgb = { 1.00, 0.78, 0.18 }
  elseif kind == "milestone" then
    rgb = { 0.95, 0.82, 0.28 }
  end
  paintSolid(frame.KindBand, rgb[1], rgb[2], rgb[3], 1)
  frame.KindBand:ClearAllPoints()
  local width = (kind == "death") and 6 or ((kind == "revenge" or kind == "milestone") and 4 or 3)
  if deathRight then
    frame.KindBand:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.KindBand:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  else
    frame.KindBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.KindBand:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  end
  frame.KindBand:SetWidth(width)
  frame.KindBand:Show()
end

local function setRarityBar(frame, kind, rarity)
  if not frame.RarityBar or not frame.RarityBarBg then
    return
  end
  local frac = RARITY_BAR_WIDTH[rarity] or RARITY_BAR_WIDTH[kind] or 0.35
  local hex = rarityHex(kind, rarity)
  local r, g, b = hexToRGB(hex)
  local full = 300
  frame.RarityBarBg:ClearAllPoints()
  frame.RarityBarBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 96, 11)
  frame.RarityBarBg:SetSize(full, 2)
  paintSolid(frame.RarityBarBg, 1, 1, 1, 0.08)
  frame.RarityBarBg:Show()
  frame.RarityBar:ClearAllPoints()
  frame.RarityBar:SetPoint("LEFT", frame.RarityBarBg, "LEFT", 0, 0)
  frame.RarityBar:SetSize(math.max(18, full * frac), 2)
  paintSolid(frame.RarityBar, r, g, b, 0.95)
  frame.RarityBar:Show()
end

local CUE_LABELS = {
  FirstBlood = "FIRST BLOOD",
  DoubleKill = "DOUBLE KILL",
  TripleKill = "TRIPLE KILL",
  UltraKill = "ULTRA KILL",
  Rampage = "RAMPAGE",
  KillingSpree = "KILLING SPREE",
  Dominating = "DOMINATING",
  MegaKill = "MEGA KILL",
  Unstoppable = "UNSTOPPABLE",
  WickedSick = "WICKED SICK",
  MonsterKill = "MONSTER KILL",
  Godlike = "GODLIKE",
  HolyShit = "HOLY SHIT",
  Ownage = "OWNAGE",
  Kill = "KILL",
}

local function setStreakBig(frame, streak, announcer)
  if not frame.StreakBig then
    return
  end
  streak = tonumber(streak) or 0
  if settings().showStreak == false or streak < 2 then
    frame.StreakBig:Hide()
    return
  end
  frame.StreakBig:SetText("x" .. tostring(streak))
  local rgb = ANNOUNCER_FLASH[announcer] or { 1, 0.75, 0.3 }
  frame.StreakBig:SetTextColor(rgb[1], rgb[2], rgb[3], 0.11)
  setFontSafe(frame.StreakBig, "Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
  frame.StreakBig:ClearAllPoints()
  frame.StreakBig:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
  frame.StreakBig:Show()
end

local function setHeroCue(frame, announcer, badge, kind, textLeft)
  if not frame.Combo then
    return
  end
  textLeft = textLeft or 96
  local label
  local feat = kind == "milestone"
  if feat and type(badge) == "string" and badge ~= "" then
    label = badge
  elseif announcer and announcer ~= "Kill" and CUE_LABELS[announcer] then
    label = CUE_LABELS[announcer]
  elseif type(badge) == "string" and badge ~= "" and string.upper(badge) ~= "KILL" and not feat then
    label = badge
  end
  if type(label) ~= "string" or label == "" then
    frame.Combo:Hide()
    if frame.Badge then
      frame.Badge:Hide()
    end
    if frame.Divider then
      frame.Divider:Hide()
    end
    if frame.Text then
      frame.Text:ClearAllPoints()
      frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft, -18)
      frame.Text:SetSize(310, 44)
    end
    return false
  end
  local rgb = ANNOUNCER_FLASH[announcer] or { 1, 0.78, 0.28 }
  if feat then
    rgb = { 1.00, 0.84, 0.28 }
  elseif kind == "revenge" then
    rgb = { 1.00, 0.82, 0.20 }
  end
  local shown = feat and label or string.upper(label)
  frame.Combo:SetText(shown)
  frame.Combo:SetTextColor(rgb[1], rgb[2], rgb[3], 1)
  setFontSafe(frame.Combo, "Fonts\\FRIZQT__.TTF", isHeroCue(announcer) and 19 or (feat and 16 or 17), "OUTLINE")
  frame.Combo:ClearAllPoints()
  frame.Combo:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft, -6)
  frame.Combo:SetWidth(300)
  frame.Combo:Show()
  if frame.Badge then
    frame.Badge:Hide()
  end
  if frame.Text then
    frame.Text:ClearAllPoints()
    frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft, -36)
    frame.Text:SetSize(310, 36)
  end
  if frame.Divider then
    paintSolid(frame.Divider, rgb[1], rgb[2], rgb[3], 0.30)
    frame.Divider:ClearAllPoints()
    frame.Divider:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft, -30)
    frame.Divider:SetSize(230, 1)
    frame.Divider:Show()
  end
  return true
end

local function setMedal(frame, kind, textLeft)
  if not frame.Medal then
    return
  end
  if kind ~= "revenge" and kind ~= "rival" and kind ~= "milestone" then
    frame.Medal:Hide()
    return
  end
  textLeft = textLeft or 96
  if kind == "revenge" then
    frame.Medal:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
  elseif kind == "rival" then
    frame.Medal:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_2")
  else
    frame.Medal:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
  end
  frame.Medal:ClearAllPoints()
  frame.Medal:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft - 18, -10)
  frame.Medal:SetSize(14, 14)
  frame.Medal:SetVertexColor(1, 1, 1, 1)
  frame.Medal:Show()
end

local function setFactionRing(frame, unit, classToken, announcer)
  if not frame.FactionRing then
    return
  end
  frame.FactionRing:Show()
  frame.FactionRing:ClearAllPoints()
  frame.FactionRing:SetPoint("CENTER", frame.Portrait, "CENTER", 0, 0)
  frame.FactionRing:SetSize(78, 78)
  frame.FactionRing:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  frame.FactionRing:SetTexCoord(0.15, 0.85, 0.15, 0.85)
  local rgb = ANNOUNCER_FLASH[announcer]
  local faction = unit and UnitExists(unit) and UnitFactionGroup and UnitFactionGroup(unit)
  if rgb then
    frame.FactionRing:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
  elseif faction == "Alliance" then
    frame.FactionRing:SetVertexColor(0.35, 0.55, 1.0, 1)
  elseif faction == "Horde" then
    frame.FactionRing:SetVertexColor(0.95, 0.25, 0.18, 1)
  elseif classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
    local c = RAID_CLASS_COLORS[classToken]
    frame.FactionRing:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, 1)
  else
    frame.FactionRing:SetVertexColor(0.85, 0.7, 0.35, 1)
  end
  if frame.PortraitShadow then
    paintSolid(frame.PortraitShadow, 0, 0, 0, 0.55)
    frame.PortraitShadow:ClearAllPoints()
    frame.PortraitShadow:SetPoint("CENTER", frame.Portrait, "CENTER", 2, -2)
    frame.PortraitShadow:SetSize(62, 62)
    frame.PortraitShadow:Show()
  end
end

local function layoutKillcam(frame, deathLayout, compact)
  ensureOverlayFonts(frame)
  if frame.SocketFrame then
    frame.SocketFrame:Hide()
  end
  local portraitSide = deathLayout and "RIGHT" or "LEFT"
  local textLeft = deathLayout and 18 or 96
  local portraitX = deathLayout and -18 or 18
  if frame.Portrait then
    frame.Portrait:ClearAllPoints()
    frame.Portrait:SetSize(56, 56)
    frame.Portrait:SetPoint(portraitSide, frame, portraitSide, portraitX, 8)
    frame.Portrait:Show()
  end
  if frame.Model then
    frame.Model:ClearAllPoints()
    frame.Model:SetSize(56, 56)
    frame.Model:SetPoint(portraitSide, frame, portraitSide, portraitX, 8)
    frame.Model:SetFrameLevel((frame:GetFrameLevel() or 1) + 3)
  end
  if frame.FactionRing then
    frame.FactionRing:SetFrameLevel((frame:GetFrameLevel() or 1) + 5)
  end
  if frame.PortraitShadow and frame.Portrait then
    frame.PortraitShadow:ClearAllPoints()
    frame.PortraitShadow:SetPoint("CENTER", frame.Portrait, "CENTER", deathLayout and -2 or 2, -2)
  end
  if frame.Combo then
    frame.Combo:SetJustifyH("LEFT")
  end
  if frame.Text then
    frame.Text:SetJustifyH("LEFT")
    frame.Text:SetJustifyV("TOP")
    if frame.Text.SetWordWrap then
      frame.Text:SetWordWrap(true)
    end
    setFontSafe(frame.Text, "Fonts\\FRIZQT__.TTF", compact and 12 or 13, "")
  end
  if frame.Speaker then
    frame.Speaker:ClearAllPoints()
    frame.Speaker:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", textLeft, 12)
    frame.Speaker:SetWidth(310)
    frame.Speaker:SetJustifyH("LEFT")
    setFontSafe(frame.Speaker, "Fonts\\FRIZQT__.TTF", 11, "")
  end
  if frame.Subject then
    frame.Subject:ClearAllPoints()
    if frame.Portrait then
      frame.Subject:SetPoint("TOP", frame.Portrait, "BOTTOM", 0, -1)
    else
      frame.Subject:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 4)
    end
    frame.Subject:SetWidth(86)
    frame.Subject:SetHeight(30)
    frame.Subject:SetJustifyH("CENTER")
    if frame.Subject.SetWordWrap then
      frame.Subject:SetWordWrap(true)
    end
    setFontSafe(frame.Subject, "Fonts\\FRIZQT__.TTF", 9, "")
  end
  if frame.Meta then
    frame.Meta:ClearAllPoints()
    frame.Meta:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -8)
    frame.Meta:SetWidth(210)
    frame.Meta:SetJustifyH("RIGHT")
    setFontSafe(frame.Meta, "Fonts\\FRIZQT__.TTF", 10, "")
  end
  if frame.RarityBarBg then
    frame.RarityBarBg:ClearAllPoints()
    frame.RarityBarBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", textLeft, 9)
  end
  return textLeft
end

function UI.RefreshMinimapStreak(streak)
  local btn = _G.BanterCombatMinimapButton
  local icon = btn and btn.Icon
  if not icon then
    return
  end
  streak = tonumber(streak) or 0
  if streak >= 10 then
    icon:SetVertexColor(1.0, 0.55, 0.1)
  elseif streak >= 5 then
    icon:SetVertexColor(0.75, 0.35, 1.0)
  elseif streak >= 3 then
    icon:SetVertexColor(0.25, 0.85, 1.0)
  else
    icon:SetVertexColor(1, 1, 1)
  end
end

local portraitToken = 0
local function applyPortrait(frame, unitOrNil, classToken, useModel)
  portraitToken = portraitToken + 1
  local myToken = portraitToken
  if frame.Model then
    frame.Model:Hide()
    if frame.Model.ClearModel then
      frame.Model:ClearModel()
    end
  end
  if frame.Portrait then
    frame.Portrait:Show()
  end

  local texture = frame.Portrait
  if texture then
    texture:Show()
    if unitOrNil and UnitExists(unitOrNil) then
      SetPortraitTexture(texture, unitOrNil)
      texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
      -- Prefer race head when we know the race; class icon as last resort.
      local raceIcon = frame._portraitRace and RACE_PORTRAIT[frame._portraitRace]
      if raceIcon then
        texture:SetTexture(raceIcon)
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      else
        local coords = CLASS_ICON_TCOORDS and classToken and CLASS_ICON_TCOORDS[classToken]
        texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        if coords then
          texture:SetTexCoord(unpack(coords))
        else
          texture:SetTexCoord(0, 1, 0, 1)
        end
      end
    end
  end

  -- 3D model is deferred so SetUnit never blocks the KB frame.
  if useModel and frame.Model and unitOrNil and UnitExists(unitOrNil) and frame.Model.SetUnit then
    local unit = unitOrNil
    local defer = function()
      if myToken ~= portraitToken or not frame:IsShown() then
        return
      end
      if not UnitExists(unit) then
        return
      end
      local ok = pcall(function()
        frame.Model:SetUnit(unit)
        if frame.Model.SetPortraitZoom then
          frame.Model:SetPortraitZoom(1)
        end
        if frame.Model.SetCamDistanceScale then
          frame.Model:SetCamDistanceScale(1)
        end
        if frame.Model.SetRotation then
          frame.Model:SetRotation(0)
        end
        frame.Model:SetFrameLevel((frame:GetFrameLevel() or 1) + 3)
        frame.Model:Show()
        if frame.Portrait then
          frame.Portrait:Hide()
        end
      end)
      if not ok and frame.Portrait then
        frame.Portrait:Show()
      end
    end
    if C_Timer and C_Timer.After then
      C_Timer.After(0, defer)
    else
      defer()
    end
  end
end

function UI.ApplySavedPosition(modeOffset)
  local frame = BanterCombatPopup
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if not frame or not s then
    return
  end
  frame:ClearAllPoints()
  local point, rel, x, y = s.point, s.relPoint, s.x, s.y
  if point == "BOTTOM" and (rel or "BOTTOM") == "BOTTOM" and (x or 0) == 0 and (y or 0) == 160 then
    point, rel, x, y = nil, nil, nil, nil
  end
  point = point or "CENTER"
  rel = rel or "CENTER"
  x = x or 0
  y = y or 20
  s.point, s.relPoint, s.x, s.y = point, rel, x, y
  -- Ephemeral mode bias: world slightly higher, BG lower — does not rewrite saved drag.
  local ox, oy = 0, 0
  if modeOffset ~= false then
    if UnitInBattleground and UnitInBattleground("player") then
      oy = -72
    else
      oy = 28
    end
  end
  if PixelUtil and PixelUtil.SetPoint then
    PixelUtil.SetPoint(frame, point, UIParent, rel, x + ox, y + oy)
  else
    frame:SetPoint(point, UIParent, rel, x + ox, y + oy)
  end
end

function BanterCombat_SavePopupPosition(frame)
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if not s or not frame then
    return
  end
  local point, _, relPoint, x, y = frame:GetPoint(1)
  if point then
    -- Reverse ephemeral world/BG bias so the saved anchor stays stable.
    y = y or 0
    if UnitInBattleground and UnitInBattleground("player") then
      y = y + 72
    else
      y = y - 28
    end
    s.point, s.relPoint, s.x, s.y = point, relPoint, x, y
  end
end

local ANNOUNCER_FILES = {
  FirstBlood = "Interface\\AddOns\\BanterCombat\\Sounds\\FirstBlood.ogg",
  DoubleKill = "Interface\\AddOns\\BanterCombat\\Sounds\\DoubleKill.ogg",
  TripleKill = "Interface\\AddOns\\BanterCombat\\Sounds\\TripleKill.ogg",
  UltraKill = "Interface\\AddOns\\BanterCombat\\Sounds\\UltraKill.ogg",
  Rampage = "Interface\\AddOns\\BanterCombat\\Sounds\\Rampage.ogg",
  KillingSpree = "Interface\\AddOns\\BanterCombat\\Sounds\\KillingSpree.ogg",
  Dominating = "Interface\\AddOns\\BanterCombat\\Sounds\\Dominating.ogg",
  MegaKill = "Interface\\AddOns\\BanterCombat\\Sounds\\MegaKill.ogg",
  Unstoppable = "Interface\\AddOns\\BanterCombat\\Sounds\\Unstoppable.ogg",
  WickedSick = "Interface\\AddOns\\BanterCombat\\Sounds\\WickedSick.ogg",
  MonsterKill = "Interface\\AddOns\\BanterCombat\\Sounds\\MonsterKill.ogg",
  Godlike = "Interface\\AddOns\\BanterCombat\\Sounds\\Godlike.ogg",
  HolyShit = "Interface\\AddOns\\BanterCombat\\Sounds\\HolyShit.ogg",
  Ownage = "Interface\\AddOns\\BanterCombat\\Sounds\\Ownage.ogg",
}

local SOUND_CHANNELS = {
  Master = true,
  SFX = true,
  Dialog = true,
  Ambience = true,
}

local function resolveChannel(settings)
  local channel = settings and settings.soundChannel
  if type(channel) == "string" and SOUND_CHANNELS[channel] then
    return channel
  end
  return "Master"
end

local lastGoodChannel

local function playFile(path, settings)
  if not path or not PlaySoundFile then
    return false
  end
  local volume = tonumber(settings and settings.announcerVolume)
  if volume == nil then
    volume = 100
  end
  if volume <= 0 then
    return false
  end
  -- Forever often has Dialog muted (Spoken uses Master). Always prefer Master.
  local preferred = resolveChannel(settings)
  if preferred == "Dialog" then
    preferred = "Master"
  end
  if volume < 40 then
    preferred = "Ambience"
  end
  -- Try the last successful channel first, then a short fallback list (not 6 every KB).
  local order = { lastGoodChannel, preferred, "Master", "SFX" }
  local seen = {}
  for i = 1, #order do
    local channel = order[i]
    if channel and not seen[channel] then
      seen[channel] = true
      local ok, willPlay, handle = pcall(function()
        return PlaySoundFile(path, channel)
      end)
      if ok and (willPlay == true or type(willPlay) == "number" or type(handle) == "number") then
        lastGoodChannel = channel
        return true
      end
    end
  end
  return false
end

local function playSoftKit(settings)
  local volume = tonumber(settings and settings.announcerVolume)
  if volume ~= nil and volume <= 0 then
    return false
  end
  -- Numeric kits; require a real success return (pcall alone is not enough).
  local kits = { 856, 888, 8959, 8960 }
  for i = 1, #kits do
    local kit = kits[i]
    if PlaySound then
      local ok, played = pcall(PlaySound, kit, "Master")
      if ok and played ~= false then
        return true
      end
      ok, played = pcall(PlaySound, kit)
      if ok and played ~= false then
        return true
      end
    end
  end
  return false
end

local function playAnnouncer(id)
  if not id then
    return false
  end
  local settings = ns.Options and ns.Options.Get and ns.Options.Get()
  -- Light sting for ordinary kills (streak 1–2 after First Blood).
  -- Prefer real .ogg on Forever; soft kits often "succeed" silently.
  if id == "Kill" then
    return playFile(ANNOUNCER_FILES.Dominating, settings)
      or playFile(ANNOUNCER_FILES.DoubleKill, settings)
      or playSoftKit(settings)
  end
  local builtin = ANNOUNCER_FILES[id]
  if not builtin then
    return false
  end
  local folder = settings and settings.soundFolder
  if type(folder) == "string" then
    folder = folder:gsub("[^%w]", "")
  end
  if folder and folder ~= "" then
    local customA = "Interface\\AddOns\\BanterCombat\\Sounds\\" .. folder .. "\\" .. id .. ".ogg"
    local customB = "Interface/AddOns/BanterCombat/Sounds/" .. folder .. "/" .. id .. ".ogg"
    if playFile(customA, settings) or playFile(customB, settings) then
      return true
    end
  end
  local slash = builtin:gsub("\\", "/")
  return playFile(builtin, settings) or playFile(slash, settings)
end

local function playShowSound(kind, rarity, announcer)
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if not s or not s.sound then
    return
  end
  if playAnnouncer(announcer) then
    return
  end
  if playSoftKit(s) then
    return
  end
  local name = "igMainMenuOptionCheckBoxOn"
  if kind == "revenge" or kind == "milestone" then
    name = "RaidWarning"
  elseif kind == "death" then
    name = "igQuestFailed"
  elseif rarity == "legendary" then
    name = "LEVELUPSOUND"
  elseif rarity == "epic" then
    name = "ReadyCheck"
  elseif rarity == "rare" then
    name = "igQuestListOpen"
  end
  if PlaySound then
    pcall(PlaySound, name, "Master")
    pcall(PlaySound, name)
  end
end

function UI.PlayPreviewSound(entry)
  if type(entry) ~= "table" then
    return false
  end
  if entry.announcer then
    return playAnnouncer(entry.announcer)
  end
  if entry.sound and PlaySound then
    local ok = pcall(PlaySound, entry.sound)
    return ok and true or false
  end
  return false
end

local function tintEdge(frame, kind, rarity, announcer)
  if not frame.EdgeGlow then
    return
  end
  if themeName() == "minimal" then
    frame.EdgeGlow:Hide()
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer]
  local r, g, b, a
  if rgb then
    r, g, b, a = rgb[1], rgb[2], rgb[3], 0.10
  else
    local hex = rarityHex(kind, rarity)
    r = (tonumber(hex:sub(3, 4), 16) or 180) / 255
    g = (tonumber(hex:sub(5, 6), 16) or 180) / 255
    b = (tonumber(hex:sub(7, 8), 16) or 180) / 255
    a = 0.08
  end
  paintSolid(frame.EdgeGlow, r, g, b, a)
  frame.EdgeGlow:Show()
end

local function addonLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded(name)
  end
  if IsAddOnLoaded then
    return IsAddOnLoaded(name)
  end
  return false
end

local function applyFallbackBackdrop(frame)
  if frame.PaperTop then
    local plate = "Interface\\AddOns\\BanterCombat\\Art\\Plate.tga"
    frame.PaperTop:SetTexture(plate)
    frame.PaperMid:SetTexture(plate)
    frame.PaperBot:SetTexture(plate)
    frame.PaperTop:SetTexCoord(0, 1, 0, 0.33)
    frame.PaperMid:SetTexCoord(0, 1, 0.33, 0.66)
    frame.PaperBot:SetTexCoord(0, 1, 0.66, 1)
    local width = frame:GetWidth() or 460
    local cap = 48
    frame.PaperTop:ClearAllPoints()
    frame.PaperBot:ClearAllPoints()
    frame.PaperMid:ClearAllPoints()
    frame.PaperTop:SetSize(width, cap)
    frame.PaperBot:SetSize(width, cap)
    frame.PaperTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.PaperBot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.PaperMid:SetPoint("TOPLEFT", frame.PaperTop, "BOTTOMLEFT", 0, 0)
    frame.PaperMid:SetPoint("BOTTOMRIGHT", frame.PaperBot, "TOPRIGHT", 0, 0)
    frame.PaperTop:Show()
    frame.PaperMid:Show()
    frame.PaperBot:Show()
  end
  if frame.SetBackdrop then
    pcall(frame.SetBackdrop, frame, nil)
  end
  if frame.EdgeGlow then
    frame.EdgeGlow:Show()
  end
  frame._dialogueSkin = false
end

function UI.DressDialogue(frame)
  frame = frame or BanterCombatPopup
  if not frame or not frame.PaperTop then
    return
  end
  applyPopupScale(frame)
  applyThemeChrome(frame)
  local theme = themeName()
  if theme == "dark" or theme == "minimal" then
    if frame.SocketFrame then
      frame.SocketFrame:Hide()
    end
    if frame.EdgeGlow and theme == "dark" then
      frame.EdgeGlow:Show()
    elseif frame.EdgeGlow then
      frame.EdgeGlow:Hide()
    end
    return
  end
  if not addonLoaded("DialogueUI") then
    applyFallbackBackdrop(frame)
    return
  end
  if frame.SetBackdrop then
    pcall(frame.SetBackdrop, frame, nil)
  end
  local dark = type(DialogueUI_DB) == "table" and DialogueUI_DB.Theme == 2
  local folder = dark and "Theme_Dark" or "Theme_Brown"
  local file = "Interface/AddOns/DialogueUI/Art/" .. folder .. "/Parchment.png"
  local width = frame:GetWidth()
  if not width or width < 64 then
    width = 460
  end
  local capHeight = width * (256 / 1024)
  local strips = { frame.PaperTop, frame.PaperMid, frame.PaperBot }
  local bands = { { 0, 256 }, { 256, 896 }, { 896, 1152 } }
  for i = 1, 3 do
    strips[i]:SetTexture(file)
    strips[i]:SetTexCoord(0, 1, bands[i][1] / 2048, bands[i][2] / 2048)
    strips[i]:Show()
  end
  frame.PaperTop:ClearAllPoints()
  frame.PaperBot:ClearAllPoints()
  frame.PaperMid:ClearAllPoints()
  frame.PaperTop:SetSize(width, capHeight)
  frame.PaperBot:SetSize(width, capHeight)
  frame.PaperTop:SetPoint("CENTER", frame, "TOP", 0, 0)
  frame.PaperBot:SetPoint("CENTER", frame, "BOTTOM", 0, 0)
  frame.PaperMid:SetPoint("TOPLEFT", frame.PaperTop, "BOTTOMLEFT", 0, 0)
  frame.PaperMid:SetPoint("BOTTOMRIGHT", frame.PaperBot, "TOPRIGHT", 0, 0)
  if frame.Header then
    frame.Header:Hide()
  end
  local socket = frame.SocketFrame
  if not socket then
    socket = CreateFrame("Frame", nil, frame)
    socket:SetSize(52, 58)
    local ring = socket:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    socket.Ring = ring
    frame.SocketFrame = socket
  end
  socket:Show()
  socket.Ring:SetTexture(file)
  socket.Ring:SetTexCoord(0, 0.65625 * (46 / 358), 0.56640625, 0.61328125)
  socket:ClearAllPoints()
  socket:SetPoint("TOP", frame, "TOP", 0, -20)
  if frame.Model then
    frame.Model:SetFrameLevel(frame:GetFrameLevel() + 2)
  end
  socket:SetFrameLevel(frame:GetFrameLevel() + 6)
  local hole = 36
  if frame.Portrait then
    frame.Portrait:ClearAllPoints()
    frame.Portrait:SetSize(hole, hole)
    frame.Portrait:SetPoint("CENTER", socket, "CENTER", 0, 3)
  end
  if frame.Model then
    frame.Model:ClearAllPoints()
    frame.Model:SetSize(hole, hole)
    frame.Model:SetPoint("CENTER", socket, "CENTER", 0, 3)
  end
  if frame.Badge then
    frame.Badge:SetJustifyH("CENTER")
    frame.Badge:SetWidth(280)
  end
  if frame.Speaker then
    frame.Speaker:SetJustifyH("CENTER")
    frame.Speaker:SetWidth(280)
  end
  if frame.Text then
    frame.Text:SetJustifyH("CENTER")
    frame.Text:SetJustifyV("MIDDLE")
    frame.Text:SetSize(280, 56)
  end
  if frame.Medal then
    frame.Medal:Hide()
  end
  if frame.EdgeGlow then
    frame.EdgeGlow:Hide()
  end
  if frame.Speaker and frame.Speaker.SetFontObject and DUIFont_Quest_Title_16 then
    frame.Speaker:SetFontObject(DUIFont_Quest_Title_16)
  end
  if frame.Text and frame.Text.SetFontObject and DUIFont_Quest_Paragraph then
    frame.Text:SetFontObject(DUIFont_Quest_Paragraph)
  end
  if frame.Badge and frame.Badge.SetFontObject and DUIFont_QuestType_Left then
    frame.Badge:SetFontObject(DUIFont_QuestType_Left)
  end
  frame._dialogueSkin = true
  frame._dialogueDark = dark and true or false
end

local function buildSubjectLine(payload, kind)
  local L = ns.L or {}
  -- Kill: fallen player. Death: killer. Milestone: keep empty-ish or feat target.
  local raceTok = payload.victimRace
  local classTok = payload.victimClass
  local name = shortDisplayName(payload.victimName)
  local bits = {}
  if raceTok and Data.RaceLabel then
    bits[#bits + 1] = Data.RaceLabel(raceTok)
  end
  if classTok and Data.ClassLabel then
    bits[#bits + 1] = Data.ClassLabel(classTok)
  end
  if name and name ~= "" and name ~= "?" then
    bits[#bits + 1] = name
  elseif kind == "milestone" then
    return ""
  end
  if #bits == 0 then
    return L.ENEMY_FALLBACK or "Inimigo"
  end
  return table.concat(bits, " · ")
end

local function buildMetaLine(payload, kind)
  local L = ns.L or {}
  local bits = {}
  local ctx = payload.context
  if ctx then
    bits[#bits + 1] = ctxLabel(ctx)
  end
  if type(payload.zone) == "string" and payload.zone ~= "" then
    bits[#bits + 1] = payload.zone
  end
  if payload.revenge then
    bits[#bits + 1] = L.COMP_LOG_REVENGE or "vingança"
  end
  local rk = tonumber(payload.rivalKills)
  local rd = tonumber(payload.rivalDeaths)
  if rk and rd and (rk > 0 or rd > 0) then
    bits[#bits + 1] = (L.RIVAL_SCORE or "%d–%d"):format(rk, rd)
  elseif kind == "rival" and rk then
    bits[#bits + 1] = (L.RIVAL_SCORE or "%d–%d"):format(rk, rd or 0)
  end
  return table.concat(bits, " · ")
end

local showingPayload

local function showNow(payload)
  local frame = BanterCombatPopup
  if not frame then
    showing = false
    showingPayload = nil
    return
  end
  local s = settings()
  local duration = resolveDuration(payload)
  generation = generation + 1
  local myGen = generation
  showingPayload = payload

  stopHide()
  if UIFrameFadeRemoveFrame then
    UIFrameFadeRemoveFrame(frame)
  end
  UI.ApplySavedPosition(true)

  local kind = payload.kind or "kill"
  local rarity = payload.rarity or "common"
  local announcer = payload.announcer
  local streak = tonumber(payload.streak) or 0
  local deathLayout = kind == "death"
  local compact = s.compactBanner == true
  if kind == "milestone" then
    compact = false
  end

  applyPopupScale(frame)
  applyThemeChrome(frame, announcer)
  local textLeft = layoutKillcam(frame, deathLayout, compact)
  tintEdge(frame, kind, rarity, announcer)
  setKindBand(frame, kind, announcer, deathLayout)
  setRarityBar(frame, kind, rarity)
  if frame.RarityBarBg then
    frame.RarityBarBg:ClearAllPoints()
    frame.RarityBarBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", textLeft, 9)
  end
  setHeroCue(frame, announcer, payload.badge, kind, textLeft)
  local medalKind = kind
  if payload.revenge then
    medalKind = "revenge"
  end
  setMedal(frame, medalKind, textLeft)
  setStreakBig(frame, streak, announcer)
  setCueWash(frame, announcer, kind)
  if UI.RefreshMinimapStreak then
    UI.RefreshMinimapStreak(streak)
  end

  local bodyR, bodyG, bodyB = 0.90, 0.88, 0.84
  if themeName() == "parchment" then
    bodyR, bodyG, bodyB = 0.93, 0.88, 0.78
  elseif kind == "death" then
    bodyR, bodyG, bodyB = 0.88, 0.58, 0.58
  elseif kind == "milestone" then
    bodyR, bodyG, bodyB = 0.95, 0.90, 0.70
  end

  -- Signature stays the player (who spoke); subject line carries the fallen.
  local speaker = payload.speaker or UnitName("player") or "?"
  local icon = classIconMarkup(payload.class)
  local title = payload.title
  if frame.Speaker then
    if compact and kind ~= "milestone" then
      frame.Speaker:Hide()
    else
      local nameText = icon .. "|cffE8C56A" .. speaker .. "|r"
      if title and title ~= "" then
        nameText = nameText .. "  |cff8A7A5A· " .. title .. "|r"
        frame.Speaker:SetHeight(16)
      else
        frame.Speaker:SetHeight(14)
      end
      frame.Speaker:SetText(nameText)
      frame.Speaker:SetTextColor(0.91, 0.77, 0.42)
      frame.Speaker:Show()
    end
  end

  if frame.Text then
    if compact and kind ~= "milestone" then
      frame.Text:Hide()
    else
      frame.Text:SetText(payload.text or "")
      frame.Text:SetTextColor(bodyR, bodyG, bodyB)
      frame.Text:Show()
    end
  end

  if frame.Subject then
    local subject = buildSubjectLine(payload, kind)
    if subject ~= "" then
      frame.Subject:SetText(subject)
      frame.Subject:SetTextColor(0.72, 0.70, 0.64)
      frame.Subject:Show()
    else
      frame.Subject:Hide()
    end
  end
  if frame.Meta then
    local meta = buildMetaLine(payload, kind)
    if meta ~= "" then
      frame.Meta:SetText(meta)
      frame.Meta:SetTextColor(0.55, 0.55, 0.50)
      frame.Meta:Show()
    else
      frame.Meta:Hide()
    end
  end

  local portraitClass = payload.victimClass or payload.class
  local portraitRace = payload.victimRace
  local portraitUnit = payload.portraitUnit
  if kind == "death" then
    -- Prefer target if it still matches the killer; else race/class fallback.
    if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
      local tname = UnitName("target")
      if not payload.victimName or (tname and shortDisplayName(tname) == shortDisplayName(payload.victimName)) then
        portraitUnit = "target"
      else
        portraitUnit = nil
      end
    else
      portraitUnit = nil
    end
  else
    if not (portraitUnit and UnitExists(portraitUnit)) then
      if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
        portraitUnit = "target"
      else
        portraitUnit = nil
      end
    end
  end
  frame._portraitRace = portraitRace
  applyPortrait(frame, portraitUnit, portraitClass, s.useModel ~= false)
  setFactionRing(frame, portraitUnit, portraitClass, deathLayout and nil or announcer)

  frame:Show()
  frame:SetAlpha(1)
  local punch = 1.04
  if isHeroCue(announcer) then
    punch = 1.10
  elseif kind == "revenge" then
    punch = 1.08
  elseif kind == "death" or announcer == "Kill" or not announcer then
    punch = 1.03
  end
  if visualFxOn() then
    local okAnim, ag = pcall(ensureEnterAnim, frame, punch)
    if okAnim and ag then
      pcall(function()
        ag:Stop()
        ag:Play()
      end)
    end
    if UIFrameFadeIn then
      pcall(UIFrameFadeIn, frame, isHeroCue(announcer) and 0.12 or 0.10, 0.40, 1)
    end
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(0.3, function()
      if myGen ~= generation or not frame:IsShown() then
        return
      end
      if (frame:GetAlpha() or 0) < 0.7 then
        frame:SetAlpha(1)
      end
    end)
  end
  playFlashSynced(frame, announcer or (kind == "death" and "Kill") or "Kill", kind, myGen)
  if not payload.silent and not payload.soundPlayed then
    playShowSound(kind, rarity, announcer)
  end

  hideTicker = C_Timer.NewTimer(duration, function()
    hideTicker = nil
    if myGen ~= generation then
      return
    end
    if frame:IsShown() then
      if visualFxOn() then
        pcall(function()
          local slide = frame:CreateAnimationGroup()
          local tr = slide:CreateAnimation("Translation")
          tr:SetOffset(0, deathLayout and -12 or 16)
          tr:SetDuration(0.32)
          tr:SetSmoothing("IN")
          slide:Play()
        end)
      end
      if UIFrameFadeOut then
        pcall(UIFrameFadeOut, frame, 0.32, frame:GetAlpha(), 0)
      else
        frame:SetAlpha(0)
      end
      C_Timer.After(0.38, function()
        if myGen ~= generation then
          return
        end
        frame:Hide()
        frame:SetAlpha(1)
        showing = false
        showingPayload = nil
        UI.Pump()
      end)
    else
      showing = false
      showingPayload = nil
      UI.Pump()
    end
  end)
end

function UI.Pump()
  if showing then
    return
  end
  local nextPayload = table.remove(queue, 1)
  if not nextPayload then
    return
  end
  showing = true
  showNow(nextPayload)
end

function UI.Enqueue(payload)
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if s and s.enabled == false then
    return
  end
  if s and s.showDeaths == false and payload and payload.kind == "death" then
    return
  end
  payload = payload or {}
  payload._prio = queuePriority(payload)

  -- Kill / revenge preempt a milestone toast so the feat never erases the killcam.
  if showing and showingPayload and showingPayload.kind == "milestone" then
    local incoming = payload._prio or 0
    if incoming >= 70 then
      local held = showingPayload
      generation = generation + 1
      stopHide()
      showing = false
      showingPayload = nil
      table.insert(queue, 1, held)
      table.insert(queue, 1, payload)
      while #queue > 10 do
        table.remove(queue)
      end
      UI.Pump()
      return
    end
  end

  -- Insert by priority so feats wait behind kills already queued.
  local inserted = false
  for i = 1, #queue do
    if (payload._prio or 0) > (queue[i]._prio or 0) then
      table.insert(queue, i, payload)
      inserted = true
      break
    end
  end
  if not inserted then
    queue[#queue + 1] = payload
  end
  while #queue > 10 do
    table.remove(queue)
  end
  UI.Pump()
end

function UI.Show(payload)
  UI.Enqueue(payload)
end

function UI.HideNow()
  generation = generation + 1
  stopHide()
  wipe(queue)
  showing = false
  local frame = BanterCombatPopup
  if frame then
    if UIFrameFadeRemoveFrame then
      UIFrameFadeRemoveFrame(frame)
    end
    frame:Hide()
    frame:SetAlpha(1)
  end
end

function UI.QueueSize()
  return #queue + (showing and 1 or 0)
end

if BanterCombatPopup then
  UI.DressDialogue(BanterCombatPopup)
end

_G[addonName] = ns
