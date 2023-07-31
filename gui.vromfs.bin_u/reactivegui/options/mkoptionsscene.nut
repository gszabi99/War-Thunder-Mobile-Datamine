from "%globalsDarg/darg_library.nut" import *
let { contentOffset, minContentOffset, contentWidth, contentWidthFull, tabW } = require("optionsStyle.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let backButton = require("%rGui/components/backButton.nut")

let { registerScene } = require("%rGui/navState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let mkOption = require("mkOption.nut")
let mkOptionsTabs = require("mkOptionsTabs.nut")
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { isGamepad, isKeyboard } = require("%rGui/activeControls.nut")

let backButtonHeight = hdpx(60)
let gapBackButton = hdpx(50)
let topAreaSize = saBorders[1] + backButtonHeight + gapBackButton
let gradientHeightBottom = hdpxi(256)
let gradientHeightTop = min(topAreaSize, gradientHeightBottom)
let isMoveByKeys = Computed(@() isGamepad.value || isKeyboard.value)

let pageHeight = sh(100)
let pageMask = mkBitmapPicture(2, (pageHeight / 10).tointeger(),
  function(params, bmp) {
    let { w, h } = params
    let gradStart1 = gradientHeightBottom * h / pageHeight
    let gradStart2 = h - (gradientHeightTop / 10).tointeger()
    for (local y = 0; y < h; y++) {
      let v = y < gradStart1 ? lerpClamped(0, gradStart1, 0.0, 1.0, y)
      : y > gradStart2 ? lerpClamped(gradStart2, h - 1, 1.0, 0.0, y)
      : 1.0
      let part = (v * v * 0xFF + 0.5).tointeger()
      let color = Color(part, part, part, part)
      for (local x = 0; x < w; x++)
        bmp.setPixel(x, y, color)
    }
  })

let function mkVerticalPannableArea(content, override) {
  let root = {
    watch = isMoveByKeys
    rendObj = ROBJ_MASK
    image = pageMask
  }.__update(override)

  let pannable = {
    size = flex()
    behavior = Behaviors.Pannable
    skipDirPadNav = true
    xmbNode = {
      canFocus = @() false
      scrollSpeed = 5.0
      isViewport = true
      scrollToEdge = true
      screenSpaceNav = true
    }
  }

  return @() isMoveByKeys.value
    ? root.__merge({
        padding = [topAreaSize, 0, gradientHeightBottom, 0]
        children = pannable.__merge({
          children = content
        })
      })
    : root.__merge({
        children = pannable.__merge({
          flow = FLOW_VERTICAL
          children = [
            { size = [flex(), topAreaSize] }
            content
            { size = [flex(), gradientHeightBottom] }
          ]
        })
      })
}

let function mkOptionsScene(sceneId, tabs, isOpened = null, addHeaderComp = null) {
  isOpened = isOpened ?? mkWatched(persist, $"{sceneId}_isOpened", false)
  let curTabIdx = mkWatched(persist, $"{sceneId}_curTabIdx", 0)
  let close = @() isOpened(false)
  let backBtn = backButton(close)
  isAuthorized.subscribe(@(_) isOpened(false))

  let resetCurTabIdx = @() curTabIdx(tabs.findindex(@(t) t?.isVisible.value ?? true))

  foreach(idx, tab in tabs) {
    let { isVisible = null } = tab
    if (isVisible == null)
      continue
    let tabIdx = idx
    isVisible.subscribe(@(v) v || tabIdx != curTabIdx.value ? null : resetCurTabIdx())
    if (tabIdx == curTabIdx.value)
      resetCurTabIdx()
  }

  let function curOptionsContent() {
    let tab = tabs?[curTabIdx.value]
    let { isFullWidth = false } = tab
    return tab?.content
      ? {
          watch = curTabIdx
          size = [isFullWidth ? contentWidthFull : contentWidth, flex()]
          children = {
            pos = [isFullWidth ? minContentOffset : contentOffset, 0]
            key = tab
            size = flex()
            flow = FLOW_VERTICAL
            children = tab?.content
            animations = wndSwitchAnim
          }
        }
      : {
          watch = curTabIdx
          size = flex()
          children = mkVerticalPannableArea(
            {
              pos = [contentOffset, 0]
              key = tab
              size = [contentWidth, SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              children = tab?.options.filter(@(v) v != null).map(mkOption)
              animations = wndSwitchAnim
            },
            {
              size = [sw(100) - tabW - saBorders[1], sh(100)]
              pos = [0, -topAreaSize]
            })
        }
  }

  let tabsList = mkOptionsTabs(tabs, curTabIdx)

  let optionsScene = bgShaded.__merge({
    key = {}
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    gap = hdpx(50)

    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = [
          backBtn
          addHeaderComp
        ]
      }
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        children = [
          tabsList
          curOptionsContent
        ]
      }
    ]
    animations = wndSwitchAnim
  })
  registerScene(sceneId, optionsScene, close, isOpened)

  return function(pageId = null) {
    if (pageId != null)
      curTabIdx(tabs.findindex(@(v) v?.id == pageId && (v?.isVisible.value ?? true)) ?? curTabIdx.value)
    isOpened(true)
  }
}
return mkOptionsScene