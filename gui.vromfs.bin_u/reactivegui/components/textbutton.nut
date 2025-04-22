from "%globalsDarg/darg_library.nut" import *
let { cursorOverClickable } = gui_scene
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { btnA } = require("%rGui/controlsMenu/gpActBtn.nut")
let { getGamepadHotkey } = require("%rGui/controlsMenu/dargHotkeys.nut")
let { mkButtonHoldTooltip } = require("%rGui/tooltip.nut")


let ICON_SIZE = hdpx(70)
let buttonsHGap = hdpx(64)
let buttonsVGap = hdpx(20)
let paddingX = hdpx(38)
let hotkeySize = evenPx(50)
let hotkeyGap = evenPx(10)
let paddingXWithHotkey = paddingX - (hotkeySize + hotkeyGap) / 2
let textButtonUnseenMargin = hdpx(15)

let { defButtonHeight, defButtonMinWidth } = buttonStyles

let buttonFrames = {
  laurels = {
    left = "ui/gameuiskin#button_laurels_left.svg"
    right = "ui/gameuiskin#button_laurels_right.svg"
  }
}

let patternImage = {
  size = [ph(100), ph(100)]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#button_pattern.svg:{defButtonHeight}:{defButtonHeight}")
  keepAspect = KEEP_ASPECT_NONE
  color = Color(0, 0, 0, 35)
}

let pattern = {
  size = flex()
  clipChildren = true
  flow = FLOW_HORIZONTAL
  children = array(10, patternImage)
}

let mkGradient = @(override) {
  size = flex()
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#gradient_button.svg")
}.__update(override)

let mkButtonText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontSmallAccentedShaded, override)

let mkButtonTextMultiline = @(text, override = {}) {
  size = [defButtonMinWidth - 2 * paddingX, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  halign = ALIGN_CENTER
}.__update(fontTinyAccentedShaded, override)

let mkPriceTextsComp = @(text, priceComp, flow = FLOW_VERTICAL) {
  flow
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(3)
  children = [
    !text ? null : mkButtonText(text, fontTiny)
    priceComp
  ]
}

let mkFrameImg = @(text, frameId, iconSize) {
  key = text
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"{buttonFrames?[frameId].left}:{iconSize}:{iconSize}")
    }
    text
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"{buttonFrames?[frameId].right}:{iconSize}:{iconSize}")
    }
  ]
}

let mergeParam = @(key, s1, s2) s1?[key] == null ? (s2?[key] ?? {})
  : s2?[key] == null ? (s1?[key] ?? {})
  : s1[key].__merge(s2[key])
let mergeStyles = @(s1, s2) (s2?.len() ?? 0) == 0 ? s1
  : {
      ovr = mergeParam("ovr", s1, s2)
      childOvr = mergeParam("childOvr", s1, s2)
      gradientOvr = mergeParam("gradientOvr", s1, s2)
      hotkeyBlockOvr = mergeParam("hotkeyBlockOvr", s1, s2)
      hotkeys = s2?.hotkeys ?? s1?.hotkeys
      stateFlags = s2?.stateFlags ?? s1?.stateFlags
      tooltipCtor = s1?.tooltipCtor ?? s2?.tooltipCtor
      hasPattern = s2?.hasPattern ?? s1?.hasPattern ?? true
    }

let btnImgCache = {}
function mkBtnImg(btnId) {
  if (btnId not in btnImgCache) {
    let res = mkBtnImageComp(btnId, hotkeySize)
    btnImgCache[btnId] <- res == null ? res : freeze(res)
  }
  return btnImgCache[btnId]
}

let alwaysFalse = Watched(false)

function mkButtonContentWithHotkey(stateFlags, hotkeys, content, ovr = {}) {
  let hotkeyBase = getGamepadHotkey(hotkeys)
  let isHovered = Computed(@() (stateFlags.value & S_HOVER) != 0)
  let isHotkeyDisabled = hotkeyBase != btnA ? alwaysFalse : cursorOverClickable
  return function() {
    let res = {
      watch = [isGamepad, isHovered, isHotkeyDisabled]
      padding = [0, paddingX]
      children = content
    }
    let hotkey = isHovered.value ? btnA
      : isHotkeyDisabled.value ? null
      : hotkeyBase
    if (!isGamepad.value || hotkey == null)
      return res

    return res.__update({
      padding = [0, paddingXWithHotkey]
      gap = hotkeyGap
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        {
          size = [hotkeySize, hotkeySize]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = mkBtnImg(hotkey)
        }
        content
      ]
    },
    ovr)
  }
}

let mkImageTextContent = @(icon, iconSize, text, ovr = {}) {
  key = text
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      color = icon.color
      image = Picture($"{icon.name}:{iconSize}:{iconSize}:P")
      fallbackImage = Picture($"ui/gameuiskin#icon_contacts.svg:{iconSize}:{iconSize}:P")
    }
    {
      maxWidth = hdpx(250)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text
    }.__update(fontTinyAccentedShaded)
  ]
}.__update(ovr)

function mkIcon(path, size) {
  let iconSize = size ?? ICON_SIZE
  return {
    size = [iconSize, iconSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"{path}:{iconSize}:{iconSize}")
    keepAspect = KEEP_ASPECT_FIT
  }
}

function mkCustomButton(content, onClick, style = buttonStyles.PRIMARY) {
  let { ovr = {}, childOvr = {}, gradientOvr = {}, hotkeyBlockOvr = {}, hotkeys = null,
    tooltipCtor = null, hasPattern = true
  } = style
  let stateFlags = style?.stateFlags ?? Watched(0)
  let contentExt = mkButtonContentWithHotkey(stateFlags, hotkeys,
    (type(content) == "table") ? content.__merge(childOvr) : content,
    { size = ovr?.size }.__update(hotkeyBlockOvr)
  )

  local ovrExt = ovr
  let addChild = ovr?.children
  if (addChild != null) {
    ovrExt = clone ovr
    ovrExt.$rawdelete("children")
  }

  let key = ovr?.key ?? {}
  return @() {
    watch = stateFlags
    key
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    behavior = Behaviors.Button
    xmbNode = {}
    hotkeys
    sound = {
      click  = "click"
    }
    clickableInfo = { skipDescription = true }
    brightness = stateFlags.value & S_HOVER ? 1.5 : 1
    transform = {
      scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = [
      hasPattern ? pattern : null
      mkGradient(gradientOvr)
    ].append(contentExt, addChild)
  }.__update(ovrExt,
    tooltipCtor == null
      ? {
          onElemState = @(v) stateFlags(v)
          onClick
        }
      : mkButtonHoldTooltip(onClick, stateFlags, key, tooltipCtor))
}

let textButton = @(text, onClick, style = buttonStyles.PRIMARY)
  mkCustomButton(mkButtonText(text), onClick, style)

let textButtonMultiline = @(text, onClick, style = buttonStyles.COMMON)
  mkCustomButton(mkButtonTextMultiline(text), onClick, style)

return {
  paddingX
  mkFrameImg
  mkCustomButton
  mkImageTextContent
  mkButtonTextMultiline
  textButton
  textButtonMultiline
  mergeStyles
  buttonsHGap
  buttonsVGap
  buttonStyles
  textButtonUnseenMargin

  textButtonPrimary = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.PRIMARY, styleOvr)) 
  textButtonPurchase = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.PURCHASE, styleOvr)) 
  textButtonBattle = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.BATTLE, styleOvr)) 
  textButtonBright = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.BRIGHT, styleOvr)) 
  textButtonCommon = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.COMMON, styleOvr)) 
  textButtonSecondary = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.SECONDARY, styleOvr)) 
  textButtonPricePurchase = @(text, priceComp, onClick, styleOvr = null)
    mkCustomButton(mkPriceTextsComp(text, priceComp), onClick, mergeStyles(buttonStyles.PURCHASE, styleOvr)) 
  textButtonPricePurchaseLow = @(text, priceComp, onClick, styleOvr = null)
    mkCustomButton(mkPriceTextsComp(text, priceComp, FLOW_HORIZONTAL), onClick, mergeStyles(buttonStyles.PURCHASE, styleOvr)) 

  iconButtonPrimary = @(iconPath, onClick, styleOvr = null)
    mkCustomButton(mkIcon(iconPath, styleOvr?.iconSize), onClick, mergeStyles(buttonStyles.PRIMARY, styleOvr))
  iconButtonCommon = @(iconPath, onClick, styleOvr = null)
    mkCustomButton(mkIcon(iconPath, styleOvr?.iconSize), onClick, mergeStyles(buttonStyles.COMMON, styleOvr))
  }
