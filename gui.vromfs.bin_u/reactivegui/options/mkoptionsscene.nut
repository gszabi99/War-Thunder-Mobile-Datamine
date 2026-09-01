from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/loginState.nut" import isAuthorized
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/tabs.nut" import tabExtraWidth
from "%rGui/navState.nut" import registerScene
import "%rGui/options/mkChildrenOptions.nut" as mkChildrenOptions
import "%rGui/options/mkOption.nut" as mkOption
import "%rGui/options/mkOptionsTabs.nut" as mkOptionsTabs
from "%rGui/options/optionsStyle.nut" import contentOffset, minContentOffset, contentWidth, tabW
from "%rGui/style/backgrounds.nut" import bgShadedDark
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const backButtonHeight = hdpx(60)
const gapBackButton = hdpx(50)
const pageBlocksGap = hdpx(30)
let topAreaSize = saBorders[1] + backButtonHeight + gapBackButton
let gradientHeightBottom = saBorders[1]
let gradientHeightTop = min(topAreaSize, gradientHeightBottom)

let scrollHandler = ScrollHandler()

let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100),
  [gradientHeightTop, gradientHeightBottom],
  [topAreaSize, gradientHeightBottom])

let mkTabsVerticalPannableArea = verticalPannableAreaCtor(
  sh(100) - topAreaSize + pageBlocksGap,
  [pageBlocksGap, gradientHeightBottom])

let scrollArrowsBlock = {
  size = [SIZE_TO_CONTENT, saSize[1] + saBorders[1]]
  hplace = ALIGN_CENTER
  pos = [0, -topAreaSize + saBorders[1] / 2]
  children = [
    mkScrollArrow(scrollHandler, MR_T, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
  ]
}

function mkOptionsScene(sceneId, tabs, isOpened = null, curTabId = null, headerComp = null, tabsPannableOvr = {}) {
  isOpened = isOpened ?? mkWatched(persist, $"{sceneId}_isOpened", false)
  curTabId = curTabId ?? Watched(null)
  let findTabIdxById = @(pageId) pageId == null ? null
    : tabs.findindex(@(v) v?.id == pageId && (v?.isVisible.get() ?? true))
  let curTabIdx = mkWatched(persist, $"{sceneId}_curTabIdx", findTabIdxById(curTabId.get()) ?? 0)
  let close = @() isOpened.set(false)
  let backBtn = backButton(function() {
    curTabId.set(null)
    close()
  })
  isAuthorized.subscribe(@(_) isOpened.set(false))

  let resetCurTabIdx = @() curTabIdx.set(tabs.findindex(@(t) t?.isVisible.get() ?? true))

  foreach(idx, tab in tabs) {
    let { isVisible = null } = tab
    if (isVisible == null)
      continue
    let tabIdx = idx
    isVisible.subscribe(@(v) v || tabIdx != curTabIdx.get() ? null : resetCurTabIdx())
    if (tabIdx == curTabIdx.get() && !isVisible.get())
      resetCurTabIdx()
  }

  function setTabById(id) {
    let idx = findTabIdxById(id)
    if (idx != null && (tabs[idx]?.isVisible.get() ?? true))
      curTabIdx.set(idx)
  }
  curTabId.subscribe(setTabById)
  curTabIdx.subscribe(@(_) scrollHandler.scrollToY(0))

  function curOptionsContent() {
    let tab = tabs?[curTabIdx.get()]
    let { isFullWidth = false } = tab
    return (tab?.content ?? tab?.contentCtor)
      ? {
          watch = curTabIdx
          size = [isFullWidth ? FLEX : contentWidth, FLEX]
          children = {
            pos = [isFullWidth ? 0 : contentOffset, 0]
            padding = [0, 0, 0, isFullWidth ? minContentOffset : 0]
            key = tab
            size = FLEX
            flow = FLOW_VERTICAL
            children = tab?.content ?? tab?.contentCtor()
            animations = wndSwitchAnim
          }
        }
      : {
          watch = curTabIdx
          size = FLEX
          children = tab?.children
            ? mkChildrenOptions(tab?.children)
            : [
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
                  { size = [saSize[0] - tabW, sh(100)] },
                  { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
                scrollArrowsBlock
              ]
        }
  }

  let tabsList = mkTabsVerticalPannableArea(
    mkOptionsTabs(tabs, curTabIdx),
    { size = [tabW + hdpx(25), sh(100) - topAreaSize] }.__merge(tabsPannableOvr),
    { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler }
  )

  let optionsScene = bgShadedDark.__merge({
    key = {}
    size = FLEX
    padding = saBordersRv
    flow = FLOW_VERTICAL

    function onAttach() {
      if (curTabIdx.get() not in tabs || !(tabs[curTabIdx.get()]?.isVisible.get() ?? true))
        resetCurTabIdx()
    }

    children = [
      headerComp ?? headerGradientBg(backBtn)
      {
        size = [saSize[0] + tabExtraWidth, FLEX]
        pos = [-tabExtraWidth, 0]
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
    isOpened.set(true)
  }
}
return {
  mkOptionsScene
  mkVerticalPannableArea
  topAreaSize
  gradientHeightBottom
}