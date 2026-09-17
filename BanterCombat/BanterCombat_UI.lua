local addonName, ns = ...
ns = ns or {}
ns.UI = ns.UI or {}

local UI = ns.UI
local Data = ns.Data
local L = ns.L

local queue = {}
local showing = false
local hideTicker
local animGroup

local function colorize(text, hex)
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
  -- file 256x256 typically; coords are 0-1
  local l, r, t, b = c[1], c[2], c[3], c[4]
  if CreateTextureMarkup then
    return CreateTextureMarkup(
      "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
      256, 256, 14, 14, l, r, t, b
    ) .. " "
  end
  return string.format(
    "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:14:14:0:0:256:256:%d:%d:%d:%d|t ",
    math.floor(l * 256), math.floor(r * 256), math.floor(t * 256), math.floor(b * 256)
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

local function ensureAnim(frame)
  if animGroup then
    return animGroup
  end
  animGroup = frame:CreateAnimationGroup()
  local trans = animGroup:CreateAnimation("Translation")
  trans:SetOffset(0, 18)
  trans:SetDuration(0.28)
  trans:SetSmoothing("OUT")
  trans:SetOrder(1)
  local alpha = animGroup:CreateAnimation("Alpha")
  if alpha.SetFromAlpha then
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
  else
    alpha:SetChange(1)
  end
  alpha:SetDuration(0.28)
  alpha:SetOrder(1)
  return animGroup
end

local function applyPortrait(frame, unitOrNil, classToken, useModel)
  if frame.Model then
    frame.Model:Hide()
    frame.Model:ClearModel()
  end
  if frame.Portrait then
    frame.Portrait:Show()
  end

  if useModel and frame.Model and unitOrNil and UnitExists(unitOrNil) and frame.Model.SetUnit then
    local ok = pcall(function()
      frame.Model:SetUnit(unitOrNil)
      if frame.Model.SetPortraitZoom then
        frame.Model:SetPortraitZoom(0.6)
      end
      if frame.Model.SetRotation then
        frame.Model:SetRotation(0.2)
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
  local point, rel, x, y = s.point or "BOTTOM", s.relPoint or "BOTTOM", s.x or 0, s.y or 160
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
  s.point, s.relPoint, s.x, s.y = point, relPoint, x, y
end

local function playShowSound(kind)
  local s = ns.Options and ns.Options.Get and ns.Options.Get()
  if not s or not s.sound then
    return
  end
  local id = 888 -- level up-ish classic fallback
  if kind == "revenge" or kind == "milestone" then
    id = 12891 -- raid warning feel / classic may remap
  elseif kind == "death" then
    id = 8959
  end
  pcall(PlaySound, id)
end

local function showNow(payload)
  local frame = BanterCombatPopup
  if not frame then
    showing = false
    return
  end
  local s = ns.Options and ns.Options.Get and ns.Options.Get() or {}
  local duration = tonumber(s.duration) or 4

  stopHide()
  UIFrameFadeRemoveFrame(frame)
  UI.ApplySavedPosition()

  local kind = payload.kind or "kill"
  local rarity = payload.rarity or "common"
  local hex = rarityHex(kind, rarity)

  if frame.Badge then
    if payload.badge and payload.badge ~= "" then
      frame.Badge:SetText(colorize(payload.badge, Data.RARITY_COLOR.milestone or "FFFFD100"))
      frame.Badge:Show()
      if frame.Medal then
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
    frame.Speaker:SetText(icon .. colorize(speaker, hex))
  end
  if frame.Text then
    frame.Text:SetText(colorize(payload.text or "", hex))
  end

  applyPortrait(frame, payload.unit, payload.class, s.useModel)

  frame:SetAlpha(0)
  frame:Show()
  local ag = ensureAnim(frame)
  ag:Stop()
  frame:SetAlpha(1)
  ag:Play()
  -- also soft fade-in if alpha anim unsupported
  UIFrameFadeIn(frame, 0.2, 0, 1)
  playShowSound(kind)

  hideTicker = C_Timer.NewTimer(duration, function()
    hideTicker = nil
    if frame:IsShown() then
      UIFrameFadeOut(frame, 0.55, frame:GetAlpha(), 0)
      C_Timer.After(0.6, function()
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
  queue[#queue + 1] = payload
  -- cap queue
  while #queue > 8 do
    table.remove(queue, 1)
  end
  UI.Pump()
end

-- Back-compat
function UI.Show(payload)
  UI.Enqueue(payload)
end

function UI.HideNow()
  stopHide()
  wipe(queue)
  showing = false
  local frame = BanterCombatPopup
  if frame then
    UIFrameFadeRemoveFrame(frame)
    frame:Hide()
    frame:SetAlpha(1)
  end
end

function UI.QueueSize()
  return #queue + (showing and 1 or 0)
end

_G[addonName] = ns
