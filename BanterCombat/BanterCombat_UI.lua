local addonName, ns = ...
ns = ns or {}
ns.UI = ns.UI or {}

local UI = ns.UI
local HIDE_DELAY = 4.0
local hideTicker

local function stopHide()
  if hideTicker then
    hideTicker:Cancel()
    hideTicker = nil
  end
end

local function applyPortrait(texture, unitOrNil, classToken)
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

--- payload: { speaker, text, badge, class, unit }
function UI.Show(payload)
  local frame = BanterCombatPopup
  if not frame then
    return
  end
  stopHide()
  UIFrameFadeRemoveFrame(frame)

  payload = payload or {}
  if frame.Badge then
    if payload.badge and payload.badge ~= "" then
      frame.Badge:SetText("|cFFFFD100" .. payload.badge .. "|r")
      frame.Badge:Show()
    else
      frame.Badge:SetText("")
      frame.Badge:Hide()
    end
  end
  if frame.Speaker then
    frame.Speaker:SetText(payload.speaker or UnitName("player") or "?")
  end
  if frame.Text then
    frame.Text:SetText(payload.text or "")
  end
  applyPortrait(frame.Portrait, payload.unit, payload.class)

  frame:SetAlpha(0)
  frame:Show()
  UIFrameFadeIn(frame, 0.25, 0, 1)

  hideTicker = C_Timer.NewTimer(HIDE_DELAY, function()
    hideTicker = nil
    if frame:IsShown() then
      UIFrameFadeOut(frame, 0.6, frame:GetAlpha(), 0)
      C_Timer.After(0.65, function()
        if frame:GetAlpha() < 0.05 then
          frame:Hide()
          frame:SetAlpha(1)
        end
      end)
    end
  end)
end

function UI.HideNow()
  stopHide()
  local frame = BanterCombatPopup
  if frame then
    UIFrameFadeRemoveFrame(frame)
    frame:Hide()
    frame:SetAlpha(1)
  end
end

_G[addonName] = ns
