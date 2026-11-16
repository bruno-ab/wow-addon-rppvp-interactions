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
  if not visualFxOn() then
    frame.CueWash:Hide()
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer]
  if not rgb and kind == "death" then
    rgb = { 0.55, 0.08, 0.10 }
  end
  if not rgb then
    frame.CueWash:Hide()
    return
  end
  local a = (announcer == "FirstBlood" or announcer == "Ownage" or announcer == "HolyShit" or announcer == "Godlike") and 0.35 or 0.20
  frame.CueWash:ClearAllPoints()
  frame.CueWash:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  frame.CueWash:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  frame.CueWash:SetWidth(148)
  -- ADD blend: white base + vertex tint reads cleaner than solid ColorTexture.
  frame.CueWash:SetTexture("Interface\\Buttons\\WHITE8X8")
  frame.CueWash:SetVertexColor(rgb[1], rgb[2], rgb[3], a)
  frame.CueWash:Show()
end

local function ensureEnterAnim(frame)
  if enterGroup then
    return enterGroup
  end
  enterGroup = frame:CreateAnimationGroup()
  local scale = enterGroup:CreateAnimation("Scale")
  if scale.SetScaleFrom then
    scale:SetScaleFrom(0.88, 0.88)
    scale:SetScaleTo(1.0, 1.0)
  elseif scale.SetFromScale then
    scale:SetFromScale(0.88, 0.88)
    scale:SetToScale(1.0, 1.0)
  else
    scale:SetOrigin("CENTER", 0, 0)
    if scale.SetScale then
      scale:SetScale(1.12, 1.12)
    end
  end
  scale:SetDuration(0.18)
  scale:SetSmoothing("OUT")
  scale:SetOrder(1)

  local punch = enterGroup:CreateAnimation("Scale")
  if punch.SetScaleFrom then
    punch:SetScaleFrom(1.0, 1.0)
    punch:SetScaleTo(1.06, 1.06)
  elseif punch.SetFromScale then
    punch:SetFromScale(1.0, 1.0)
    punch:SetToScale(1.06, 1.06)
  elseif punch.SetScale then
    punch:SetOrigin("CENTER", 0, 0)
    punch:SetScale(1.06, 1.06)
  end
  punch:SetDuration(0.08)
  punch:SetOrder(2)
  punch:SetSmoothing("OUT")

  local settle = enterGroup:CreateAnimation("Scale")
  if settle.SetScaleFrom then
    settle:SetScaleFrom(1.06, 1.06)
    settle:SetScaleTo(1.0, 1.0)
  elseif settle.SetFromScale then
    settle:SetFromScale(1.06, 1.06)
    settle:SetToScale(1.0, 1.0)
  elseif settle.SetScale then
    settle:SetOrigin("CENTER", 0, 0)
    settle:SetScale(0.943, 0.943)
  end
  settle:SetDuration(0.12)
  settle:SetOrder(3)
  settle:SetSmoothing("IN")
  return enterGroup
end

local flashGroup
local function playFlash(frame, announcer, kind)
  if not visualFxOn() or not frame or not frame.Flash then
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer] or KIND_BAND[kind] or { 1, 1, 1 }
  local peak = (announcer == "FirstBlood" or announcer == "HolyShit" or announcer == "Ownage" or announcer == "Godlike") and 0.42 or 0.28
  frame.Flash:SetTexture("Interface\\Buttons\\WHITE8X8")
  frame.Flash:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
  frame.Flash:SetAlpha(peak)
  frame.Flash:Show()
  if flashGroup then
    flashGroup:Stop()
  end
  flashGroup = frame.Flash:CreateAnimationGroup()
  local a = flashGroup:CreateAnimation("Alpha")
  if a.SetFromAlpha then
    a:SetFromAlpha(peak)
    a:SetToAlpha(0)
  else
    a:SetChange(-peak)
  end
  a:SetDuration(0.42)
  a:SetSmoothing("OUT")
  flashGroup:SetScript("OnFinished", function()
    if frame.Flash then
      frame.Flash:Hide()
      frame.Flash:SetAlpha(0)
    end
  end)
  flashGroup:Play()
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
  if frame.SetBackdrop then
    pcall(frame.SetBackdrop, frame, {
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false, edgeSize = theme == "minimal" and 1 or 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    if frame.SetBackdropColor then
      frame:SetBackdropColor(shadeR, shadeG, shadeB, shadeA)
    end
    if frame.SetBackdropBorderColor then
      local ba = theme == "minimal" and 0.45 or 0.85
      frame:SetBackdropBorderColor(border[1] * 0.9, border[2] * 0.9, border[3] * 0.9, ba)
    end
  end
  frame._dialogueSkin = false
end

local function setKindBand(frame, kind, announcer)
  if not frame.KindBand then
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer] or KIND_BAND[kind] or KIND_BAND.kill
  paintSolid(frame.KindBand, rgb[1], rgb[2], rgb[3], 1)
  frame.KindBand:ClearAllPoints()
  frame.KindBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  frame.KindBand:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  frame.KindBand:SetWidth(3)
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

local function setHeroCue(frame, announcer, badge)
  if not frame.Combo then
    return
  end
  -- Ordinary "Kill" cue stays quiet — hero title only for multi/streak/special.
  local label
  if announcer and announcer ~= "Kill" and CUE_LABELS[announcer] then
    label = CUE_LABELS[announcer]
  elseif type(badge) == "string" and badge ~= "" and string.upper(badge) ~= "KILL" then
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
    if frame.Medal then
      frame.Medal:Hide()
    end
    -- Banter text moves up when there is no hero cue.
    if frame.Text then
      frame.Text:ClearAllPoints()
      frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 96, -22)
      frame.Text:SetSize(300, 42)
    end
    return
  end
  local rgb = ANNOUNCER_FLASH[announcer] or { 1, 0.78, 0.28 }
  frame.Combo:SetText(string.upper(label))
  frame.Combo:SetTextColor(rgb[1], rgb[2], rgb[3], 1)
  setFontSafe(frame.Combo, "Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
  frame.Combo:Show()
  if frame.Badge then
    frame.Badge:Hide()
  end
  if frame.Medal then
    frame.Medal:Hide()
  end
  if frame.Text then
    frame.Text:ClearAllPoints()
    frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 96, -40)
    frame.Text:SetSize(300, 34)
  end
  if frame.Divider then
    paintSolid(frame.Divider, rgb[1], rgb[2], rgb[3], 0.28)
    frame.Divider:ClearAllPoints()
    frame.Divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 96, -34)
    frame.Divider:SetSize(220, 1)
    frame.Divider:Show()
  end
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

local function layoutKillcam(frame)
  if frame.SocketFrame then
    frame.SocketFrame:Hide()
  end
  if frame.Portrait then
    frame.Portrait:ClearAllPoints()
    frame.Portrait:SetSize(60, 60)
    frame.Portrait:SetPoint("LEFT", frame, "LEFT", 18, 0)
    frame.Portrait:Show()
  end
  if frame.Model then
    frame.Model:ClearAllPoints()
    frame.Model:SetSize(60, 60)
    frame.Model:SetPoint("LEFT", frame, "LEFT", 18, 0)
    frame.Model:SetFrameLevel((frame:GetFrameLevel() or 1) + 3)
  end
  if frame.FactionRing then
    frame.FactionRing:SetFrameLevel((frame:GetFrameLevel() or 1) + 5)
  end
  if frame.Combo then
    frame.Combo:ClearAllPoints()
    frame.Combo:SetPoint("TOPLEFT", frame, "TOPLEFT", 96, -11)
    frame.Combo:SetWidth(290)
    frame.Combo:SetJustifyH("LEFT")
  end
  if frame.Text then
    frame.Text:ClearAllPoints()
    frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 96, -40)
    frame.Text:SetSize(300, 34)
    frame.Text:SetJustifyH("LEFT")
    frame.Text:SetJustifyV("TOP")
    setFontSafe(frame.Text, "Fonts\\FRIZQT__.TTF", 13, "")
  end
  if frame.Speaker then
    frame.Speaker:ClearAllPoints()
    frame.Speaker:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 96, 15)
    frame.Speaker:SetWidth(300)
    frame.Speaker:SetJustifyH("LEFT")
    setFontSafe(frame.Speaker, "Fonts\\FRIZQT__.TTF", 11, "")
  end
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

local function applyPortrait(frame, unitOrNil, classToken, useModel)
  if frame.Model then
    frame.Model:Hide()
    if frame.Model.ClearModel then
      frame.Model:ClearModel()
    end
  end
  if frame.Portrait then
    frame.Portrait:Show()
  end

  if useModel and frame.Model and unitOrNil and UnitExists(unitOrNil) and frame.Model.SetUnit then
    local ok = pcall(function()
      frame.Model:SetUnit(unitOrNil)
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
    if ok then
      return
    end
  end

  local texture = frame.Portrait
  if not texture then
    return
  end
  texture:Show()
  if unitOrNil and UnitExists(unitOrNil) then
    SetPortraitTexture(texture, unitOrNil)
    -- Slight crop so the face fills the ring better.
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return
  end
  local coords = CLASS_ICON_TCOORDS and classToken and CLASS_ICON_TCOORDS[classToken]
  texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
  if coords then
    texture:SetTexCoord(unpack(coords))
  else
    texture:SetTexCoord(0, 1, 0, 1)
  end
end

function UI.ApplySavedPosition()
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
  if PixelUtil and PixelUtil.SetPoint then
    PixelUtil.SetPoint(frame, point, UIParent, rel, x, y)
  else
    frame:SetPoint(point, UIParent, rel, x, y)
  end
end

function BanterCombat_SavePopupPosition(frame)
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if not s or not frame then
    return
  end
  local point, _, relPoint, x, y = frame:GetPoint(1)
  if point then
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
  -- Only true / numeric handle counts as success. Nil must NOT short-circuit —
  -- Forever can return nil even when the file never started.
  local order = { "Master", preferred, "SFX", false, "Ambience", "Dialog" }
  local seen = {}
  for i = 1, #order do
    local channel = order[i]
    local key = channel == false and "*" or channel
    if not seen[key] then
      seen[key] = true
      local ok, willPlay, handle
      if channel then
        ok, willPlay, handle = pcall(function()
          return PlaySoundFile(path, channel)
        end)
      else
        ok, willPlay, handle = pcall(function()
          return PlaySoundFile(path)
        end)
      end
      if ok and (willPlay == true or type(willPlay) == "number" or type(handle) == "number") then
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

local function showNow(payload)
  local frame = BanterCombatPopup
  if not frame then
    showing = false
    return
  end
  local s = settings()
  local duration = tonumber(s.duration) or 4
  generation = generation + 1
  local myGen = generation

  stopHide()
  if UIFrameFadeRemoveFrame then
    UIFrameFadeRemoveFrame(frame)
  end
  UI.ApplySavedPosition()

  local kind = payload.kind or "kill"
  local rarity = payload.rarity or "common"
  local announcer = payload.announcer
  local streak = tonumber(payload.streak) or 0

  -- Cinematic killcam chrome for every theme (no DialogueUI parchment stack).
  applyPopupScale(frame)
  applyThemeChrome(frame, announcer)
  layoutKillcam(frame)
  tintEdge(frame, kind, rarity, announcer)
  setKindBand(frame, kind, announcer)
  setRarityBar(frame, kind, rarity)
  setHeroCue(frame, announcer, payload.badge)
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
  end

  -- Signature: killer name + title (small, muted gold).
  local speaker = payload.speaker or UnitName("player") or "?"
  local icon = classIconMarkup(payload.class)
  local title = payload.title
  if frame.Speaker then
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

  if frame.Text then
    frame.Text:SetText(payload.text or "")
    frame.Text:SetTextColor(bodyR, bodyG, bodyB)
    frame.Text:Show()
  end

  -- Portrait: victim on KB, killer on death.
  local portraitClass = payload.victimClass or payload.class
  local portraitUnit = payload.portraitUnit
  if kind == "death" then
    portraitUnit = payload.unit or portraitUnit
    portraitClass = payload.class
  else
    if not (portraitUnit and UnitExists(portraitUnit)) then
      if UnitExists("target") and UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
        portraitUnit = "target"
      else
        portraitUnit = nil
      end
    end
  end
  applyPortrait(frame, portraitUnit, portraitClass, s.useModel ~= false)
  setFactionRing(frame, portraitUnit, portraitClass, announcer)

  -- Forever: Scale anim / UIFrameFadeIn can fail and leave alpha at 0 (invisible toast).
  frame:Show()
  frame:SetAlpha(1)
  if visualFxOn() then
    local okAnim, ag = pcall(ensureEnterAnim, frame)
    if okAnim and ag then
      pcall(function()
        ag:Stop()
        ag:Play()
      end)
    end
    if UIFrameFadeIn then
      pcall(UIFrameFadeIn, frame, 0.15, 0.35, 1)
    end
  end
  -- Safety net if fade/anim left the frame too dim.
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
  playFlash(frame, announcer or (kind == "death" and nil) or "Kill", kind)
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
          tr:SetOffset(0, 16)
          tr:SetDuration(0.35)
          tr:SetSmoothing("IN")
          slide:Play()
        end)
      end
      if UIFrameFadeOut then
        pcall(UIFrameFadeOut, frame, 0.35, frame:GetAlpha(), 0)
      else
        frame:SetAlpha(0)
      end
      C_Timer.After(0.4, function()
        if myGen ~= generation then
          return
        end
        frame:Hide()
        frame:SetAlpha(1)
        showing = false
        UI.Pump()
      end)
    else
      showing = false
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
  queue[#queue + 1] = payload
  while #queue > 8 do
    table.remove(queue, 1)
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
