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
  if kind == "death" then
    return colors.death or "FFCC6666"
  end
  return colors[rarity or "common"] or "FFB0B0B0"
end

local function stopHide()
  if hideTicker then
    hideTicker:Cancel()
    hideTicker = nil
  end
end

local function ensureEnterAnim(frame)
  if enterGroup then
    return enterGroup
  end
  enterGroup = frame:CreateAnimationGroup()
  local scale = enterGroup:CreateAnimation("Scale")
  if scale.SetScaleFrom then
    scale:SetScaleFrom(0.92, 0.92)
    scale:SetScaleTo(1.0, 1.0)
  elseif scale.SetFromScale then
    scale:SetFromScale(0.92, 0.92)
    scale:SetToScale(1.0, 1.0)
  else
    -- Classic-style relative scale change toward 1
    scale:SetOrigin("CENTER", 0, 0)
    if scale.SetScale then
      scale:SetScale(1.08, 1.08)
    end
  end
  scale:SetDuration(0.22)
  scale:SetSmoothing("OUT")
  scale:SetOrder(1)
  return enterGroup
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
      if frame.Model.SetRotation then
        frame.Model:SetRotation(0)
      end
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
  if unitOrNil and UnitExists(unitOrNil) then
    SetPortraitTexture(texture, unitOrNil)
    texture:SetTexCoord(0, 1, 0, 1)
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

local function playShowSound(kind)
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if not s or not s.sound then
    return
  end
  -- Classic-friendly named sounds first
  local name = "igMainMenuOptionCheckBoxOn"
  if kind == "revenge" or kind == "milestone" then
    name = "RaidWarning"
  elseif kind == "death" then
    name = "igQuestFailed"
  elseif kind == "kill" then
    name = "LEVELUPSOUND"
  end
  if not pcall(PlaySound, name) then
    pcall(PlaySound, 888)
  end
end

local function tintEdge(frame, kind, rarity)
  if frame._dialogueSkin or not frame.EdgeGlow then
    return
  end
  local hex = rarityHex(kind, rarity)
  local r = (tonumber(hex:sub(3, 4), 16) or 180) / 255
  local g = (tonumber(hex:sub(5, 6), 16) or 180) / 255
  local b = (tonumber(hex:sub(7, 8), 16) or 180) / 255
  if frame.EdgeGlow.SetColorTexture then
    frame.EdgeGlow:SetColorTexture(r, g, b, 0.28)
  else
    frame.EdgeGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.EdgeGlow:SetVertexColor(r, g, b, 0.28)
  end
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
  if not frame.SetBackdrop then
    return
  end
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
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
  local s = ns.Options and ns.Options.Get and ns.Options.Get() or {}
  local duration = tonumber(s.duration) or 4
  generation = generation + 1
  local myGen = generation

  stopHide()
  if UIFrameFadeRemoveFrame then
    UIFrameFadeRemoveFrame(frame)
  end
  UI.ApplySavedPosition()
  UI.DressDialogue(frame)

  local kind = payload.kind or "kill"
  local rarity = payload.rarity or "common"
  local hex = rarityHex(kind, rarity)
  tintEdge(frame, kind, rarity)

  local titleR, titleG, titleB = 1, 0.82, 0
  local bodyR, bodyG, bodyB = 1, 1, 1
  local accentR, accentG, accentB = 0.8, 0.2, 0.16
  if frame._dialogueSkin then
    if frame._dialogueDark then
      titleR, titleG, titleB = 0.9, 0.9, 0.9
      bodyR, bodyG, bodyB = 0.7, 0.7, 0.7
      accentR, accentG, accentB = 0.796, 0.784, 0.584
    else
      titleR, titleG, titleB = 0.19, 0.17, 0.13
      bodyR, bodyG, bodyB = 0.19, 0.17, 0.13
      accentR, accentG, accentB = 0.416, 0.18, 0.165
    end
  end

  if frame.Badge then
    if payload.badge and payload.badge ~= "" then
      if frame._dialogueSkin then
        frame.Badge:SetText(payload.badge)
        frame.Badge:SetTextColor(accentR, accentG, accentB)
      else
        frame.Badge:SetText(colorize(payload.badge, Data.RARITY_COLOR.milestone or "FFFFD100"))
      end
      frame.Badge:Show()
      if frame.Medal and not frame._dialogueSkin then
        frame.Medal:Show()
      end
    else
      frame.Badge:SetText("")
      frame.Badge:Hide()
      if frame.Medal then
        frame.Medal:Hide()
      end
    end
  end

  local speaker = payload.speaker or UnitName("player") or "?"
  local icon = classIconMarkup(payload.class)
  if frame.Speaker then
    local tag = ""
    if rarity and rarity ~= "common" and kind ~= "revenge" and kind ~= "milestone" then
      tag = frame._dialogueSkin and (" [" .. rarity .. "]") or (" " .. colorize("[" .. rarity .. "]", hex))
    end
    if frame._dialogueSkin then
      frame.Speaker:SetText(icon .. speaker .. tag)
      frame.Speaker:SetTextColor(titleR, titleG, titleB)
    else
      frame.Speaker:SetText(icon .. colorize(speaker, hex) .. tag)
    end
  end
  if frame.Text then
    if frame._dialogueSkin then
      frame.Text:SetText(payload.text or "")
      frame.Text:SetTextColor(bodyR, bodyG, bodyB)
    else
      frame.Text:SetText(colorize(payload.text or "", hex))
    end
  end

  if frame._dialogueSkin and frame.SocketFrame then
    local hasBadge = frame.Badge and frame.Badge:IsShown()
    frame.SocketFrame:ClearAllPoints()
    frame.SocketFrame:SetPoint("TOP", frame, "TOP", 0, -22)
    if frame.Badge then
      frame.Badge:ClearAllPoints()
      frame.Badge:SetPoint("TOP", frame.SocketFrame, "BOTTOM", 0, -2)
    end
    if frame.Speaker then
      frame.Speaker:ClearAllPoints()
      if hasBadge then
        frame.Speaker:SetPoint("TOP", frame.Badge, "BOTTOM", 0, -1)
      else
        frame.Speaker:SetPoint("TOP", frame.SocketFrame, "BOTTOM", 0, -4)
      end
    end
    if frame.Text and frame.Speaker then
      frame.Text:ClearAllPoints()
      frame.Text:SetPoint("TOP", frame.Speaker, "BOTTOM", 0, -4)
    end
  end

  applyPortrait(frame, payload.unit, payload.class, s.useModel ~= false)

  frame:SetAlpha(0)
  frame:Show()
  local ag = ensureEnterAnim(frame)
  ag:Stop()
  ag:Play()
  UIFrameFadeIn(frame, 0.22, 0, 1)
  playShowSound(kind)

  hideTicker = C_Timer.NewTimer(duration, function()
    hideTicker = nil
    if myGen ~= generation then
      return
    end
    if frame:IsShown() then
      UIFrameFadeOut(frame, 0.5, frame:GetAlpha(), 0)
      C_Timer.After(0.55, function()
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
