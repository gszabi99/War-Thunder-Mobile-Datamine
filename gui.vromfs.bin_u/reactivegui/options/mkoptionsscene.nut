from "%globalsDarg/darg_library.nut" import *
let { contentOffset, minContentOffset, contentWidth, contentWidthFull, tabW } = require("optionsStyle.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")

let { registerScene } = require("%rGui/navState.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let mkOption = require("mkOption.nut")
let mkOptionsTabs = require("mkOptionsTabs.nut")


let backButtonHeight = hdpx(60)
let gapBackButton = hdpx(50)
let topAreaSize = saBorders[1] + backButtonHeight + gapBackButton
let gradientHeightBottom = saBorders[1]
let gradientHeightTop = min(topAreaSize, gradientHeightBottom)

let scrollHandler = ScrollHandler()

let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100),
  [gradientHeightTop, gradientHeightBottom],
  [topAreaSize, gradientHeightBottom])

let scrollArrowsBlock = {
  size = [SIZE_TO_CONTENT, saSize[1] + saBorders[1]]
  hplace = ALIGN_CENTER
  pos = [0, -topAreaSize + saBorders[1] / 2]
  children = [
    mkScrollArrow(scrollHandler, MR_T)
    mkScrollArrow(scrollHandler, MR_B)
  ]
}

function mkOptionsScene(sceneId, tabs, isOpened = null, curTabId = null, addHeaderComp = null) {
  isOpened = isOpened ?? mkWatched(persist, $"{sceneId}_isOpened", false)
  curTabId = curTabId ?? Watched(null)
  let findTabIdxById = @(pageId) pageId == null ? null
    : tabs.findindex(@(v) v?.id == pageId && (v?.isVisible.value ?? true))
  let curTabIdx = mkWatched(persist, $"{sceneId}_curTabIdx", findTabIdxById(curTabId.value) ?? 0)
  let close = @() isOpened(false)
  let backBtn = backButton(function() {
    curTabId(null)
    close()
  })
  isAuthorized.subscribe(@(_) isOpened(false))

  let resetCurTabIdx = @() curTabIdx(tabs.findindex(@(t) t?.isVisible.value ?? true))

  foreach(idx, tab in tabs) {
    let { isVisible = null } = tab
    if (isVisible == null)
      continue
    let tabIdx = idx
    isVisible.subscribe(@(v) v || tabIdx != curTabIdx.value ? null : resetCurTabIdx())
    if (tabIdx == curTabIdx.value && !isVisible.value)
      resetCurTabIdx()
  }

  function setTabById(id) {
    let idx = findTabIdxById(id)
    if (idx != null && (tabs[idx]?.isVisible.value ?? true))
      curTabIdx(idx)
  }
  curTabId.subscribe(setTabById)
  curTabIdx.subscribe(@(_) scrollHandler.scrollToY(0))

  function curOptionsContent() {
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
          children = [
            mkVerticalPannableArea(
              {
                pos = [contentOffset, 0]
                key = tab
                size = [contentWidth, SIZE_TO_CONTENT]
                flow = FLOW_VERTICAL
                halign = ALIGN_CENTER
                children = tab?.options.filter(@(v) v != null).map(mkOption)
                animations = wndSwitchAnim
              },
              { size = [sw(100) - tabW - saBorders[1], sh(100)] },
              { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
            scrollArrowsBlock
          ]
        }
  }

  let tabsList = mkOptionsTabs(tabs, curTabIdx)

  let optionsScene = bgShaded.__merge({
    key = {}
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    gap = hdpx(50)

    function onAttach() {
      if (curTabIdx.value not in tabs || !(tabs[curTabIdx.value]?.isVisible.value ?? true))
        resetCurTabIdx()
    }

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
    setTabById(pageId)
    isOpened(true)
  }
}
return {
  mkOptionsScene
  mkVerticalPannableArea
  topAreaSize
  gradientHeightBottom
}