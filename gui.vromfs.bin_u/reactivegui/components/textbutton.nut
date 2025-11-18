from "%globalsDarg/darg_library.nut" import *
let { cursorOverClickable } = gui_scene
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkBtnImageComp } = require("%rGui/controlsMenu/gamepadImgByKey.nut")
let { btnA } = require("%rGui/controlsMenu/gpActBtn.nut")
let { getGamepadHotkey } = require("%rGui/controlsMenu/dargHotkeys.nut")
let { mkButtonHoldTooltip, REPAY_TIME } = require("%rGui/tooltip.nut")
let { commonGlare } = require("%rGui/components/glare.nut")


let ICON_SIZE = hdpx(70)
let buttonsHGap = hdpx(64)
let buttonsVGap = hdpx(20)
let paddingX = hdpx(38)
let hotkeySize = evenPx(50)
let hotkeyGap = evenPx(10)
let paddingXWithHotkey = paddingX - (hotkeySize + hotkeyGap) / 2
let textButtonUnseenMargin = hdpx(15)

let { defButtonHeight, defButtonMinWidth } = buttonStyles
let buttonTextWidth = defButtonMinWidth - 2 * paddingX

let buttonFrames = {
  laurels = {
    left = "ui/gameuiskin#button_laurels_left.svg"
    right = "ui/gameuiskin#button_laurels_right.svg"
  }
}

let patternImage = {
  size = ph(100)
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

let mkButtonTextMultiline = @(text, override = {}) {
  size = [buttonTextWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  halign = ALIGN_CENTER
}.__update(fontTinyShadedBold, override)

function mkButtonText(text, style, ovr = {}) {
  let { useFlexText = false } = style
  let res = {
    rendObj = ROBJ_TEXT
    text
  }.__update(fontSmallShadedBold, ovr)

  if (useFlexText || calc_comp_size(res)[0] <= buttonTextWidth)
    return res
  return mkButtonTextMultiline(text, ovr)
}

let mkPriceTextsComp = @(text, priceComp, style = {}, flow = FLOW_VERTICAL) {
  flow
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(3)
  children = [
    !text ? null : mkButtonText(text, style, {}.__update(fontTinyShadedBold, style?.childOvr ?? {}))
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
      gradientContainerOvr = mergeParam("gradientContainerOvr", s1, s2)
      borderGradientOvr = mergeParam("borderGradientOvr", s1, s2)
      hotkeys = s2?.hotkeys ?? s1?.hotkeys
      stateFlags = s2?.stateFlags ?? s1?.stateFlags
      tooltipCtor = s1?.tooltipCtor ?? s2?.tooltipCtor
      hasPattern = s2?.hasPattern ?? s1?.hasPattern ?? false
      hasGlare = s2?.hasGlare ?? s1?.hasGlare ?? false
      repayTime = s1?.repayTime ?? s2?.repayTime ?? REPAY_TIME
      useFlexText = s2?.useFlexText ?? s1?.useFlexText ?? false
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
  let isHovered = Computed(@() (stateFlags.get() & S_HOVER) != 0)
  let isHotkeyDisabled = hotkeyBase != btnA ? alwaysFalse : cursorOverClickable
  return function() {
    let res = {
      watch = [isGamepad, isHovered, isHotkeyDisabled]
      padding = [0, paddingX]
      children = content
    }
    let hotkey = isHovered.get() ? btnA
      : isHotkeyDisabled.get() ? null
      : hotkeyBase
    if (!isGamepad.get() || hotkey == null)
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
      size = iconSize
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
    }.__update(fontTinyAccentedShadedBold)
  ]
}.__update(ovr)

function mkIcon(path, size) {
  let iconSize = size ?? ICON_SIZE
  return {
    size = iconSize
    rendObj = ROBJ_IMAGE
    image = Picture($"{path}:{iconSize}:{iconSize}")
    keepAspect = KEEP_ASPECT_FIT
  }
}

function mkCustomButton(content, onClick, style = buttonStyles.PRIMARY) {
  let { ovr = {}, childOvr = {}, gradientOvr = {}, hotkeyBlockOvr = {}, hotkeys = null, hasGlare = false
    tooltipCtor = null, hasPattern = false, repayTime = 0.3, gradientContainerOvr = {}, borderGradientOvr = {}
  } = style
  let ovrSize = ovr?.size
  let hasGradient = gradientOvr?.color != null
  let hasBorderGradient = borderGradientOvr?.color != null
  let stateFlags = style?.stateFlags ?? Watched(0)
  let contentExt = mkButtonContentWithHotkey(stateFlags, hotkeys,
    (type(content) == "table") ? content.__merge(childOvr) : content,
    { size = ovrSize }.__update(hotkeyBlockOvr)
  )

  local ovrExt = ovr
  let addChild = ovr?.children
  if (addChild != null) {
    ovrExt = clone ovr
    ovrExt.$rawdelete("children")
  }

  let contentW = calc_comp_size(contentExt)[0]
  if ((type(ovrSize?[0]) != "integer" && type(ovrSize?[0]) != "float" && ovr?.minWidth != null && contentW > ovr.minWidth))
    ovrExt = ovr.__merge({ minWidth = contentW })

  let key = ovr?.key ?? {}
  return @() {
    watch = stateFlags
    key
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    fillColor = hasBorderGradient ? 0xFFB9B9B9 : null
    behavior = Behaviors.Button
    xmbNode = {}
    hotkeys
    sound = { click = "click" }
    clickableInfo = { skipDescription = true }
    brightness = stateFlags.get() & S_HOVER ? 1.25 : 1
    transform = {
      scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    children = {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = {
        size = flex()
        rendObj = ROBJ_BOX
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        clipChildren = true
        children = [
          hasPattern ? pattern : null
          hasGradient ? mkGradient(gradientOvr) : null
          hasGlare ? commonGlare : null
        ].append(contentExt, addChild)
      }.__update(gradientContainerOvr)
    }.__update(hasBorderGradient ? borderGradientOvr : {})
  }.__update(ovrExt, tooltipCtor == null
      ? {
          onElemState = @(v) stateFlags.set(v)
          onClick
        }
      : mkButtonHoldTooltip(onClick, stateFlags, key, tooltipCtor, repayTime))
}

let textButton = @(text, onClick, style = buttonStyles.PRIMARY)
  mkCustomButton(mkButtonText(text, style, style?.childOvr ?? {}), onClick, style)

let textButtonMultiline = @(text, onClick, style = buttonStyles.COMMON)
  mkCustomButton(mkButtonTextMultiline(text), onClick, style)

return {
  paddingX
  mkFrameImg
  mkGradient
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
  ICON_SIZE
  buttonTextWidth

  textButtonPrimary = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.PRIMARY, styleOvr)) 
  textButtonPurchase = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.PURCHASE, styleOvr)) 
  textButtonBattle = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.BATTLE, styleOvr)) 
  textButtonCommon = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.COMMON, styleOvr)) 
  textButtonInactive = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.INACTIVE, styleOvr)) 
  textButtonSecondary = @(text, onClick, styleOvr = null)
    textButton(text, onClick, mergeStyles(buttonStyles.SECONDARY, styleOvr)) 
  textButtonPricePurchase = @(text, priceComp, onClick, styleOvr = null)
    mkCustomButton(mkPriceTextsComp(text, priceComp, styleOvr), onClick, mergeStyles(buttonStyles.PURCHASE, styleOvr)) 
  textButtonPricePurchaseLow = @(text, priceComp, onClick, styleOvr = null)
    mkCustomButton(mkPriceTextsComp(text, priceComp, styleOvr, FLOW_HORIZONTAL), onClick, mergeStyles(buttonStyles.PURCHASE, styleOvr)) 

  iconButtonPrimary = @(iconPath, onClick, styleOvr = null)
    mkCustomButton(mkIcon(iconPath, styleOvr?.iconSize), onClick, mergeStyles(buttonStyles.PRIMARY, styleOvr))
  iconButtonCommon = @(iconPath, onClick, styleOvr = null)
    mkCustomButton(mkIcon(iconPath, styleOvr?.iconSize), onClick, mergeStyles(buttonStyles.COMMON, styleOvr))
  iconButtonInactive = @(iconPath, onClick, styleOvr = null)
    mkCustomButton(mkIcon(iconPath, styleOvr?.iconSize), onClick, mergeStyles(buttonStyles.INACTIVE, styleOvr))
  }
