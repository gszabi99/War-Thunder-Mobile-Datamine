from "%globalsDarg/darg_library.nut" import *

let mkOption = require("%rGui/options/mkOption.nut")
let { tabW } = require("%rGui/options/optionsStyle.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkHorizontalTabs } = require("%rGui/components/horizontalTabs.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let contentWidth = saSize[0] - tabW - saBorders[0]
let pannableAreaWidth = saSize[0] - tabW + saBorders[0]
let backButtonHeight = hdpx(60)
let gapBackButton = hdpx(50)
let tabHeight = hdpx(120)

let topAreaSize = saBorders[1] + backButtonHeight + gapBackButton - tabHeight
let gradientHeightBottom = saBorders[1] * 2
let gradientHeightTop = saBorders[1]

let scrollHandler = ScrollHandler()

let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100) - tabHeight,
  [gradientHeightTop, gradientHeightBottom],
  [topAreaSize, gradientHeightBottom])

let scrollArrowsBlock = {
  size = FLEX_V
  padding = [0, 0, gradientHeightBottom, 0]
  hplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_T, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
  ]
}

function mkChildrenOptions(tabs) {
  let curTabIdx = mkWatched(persist, $"childrenOptions_curTabIdx", 0)
  let resetCurTabIdx = @() curTabIdx.set(tabs.findindex(@(_) true))

  curTabIdx.subscribe(@(_) scrollHandler.scrollToY(0))
  let gap = hdpx(50)

  function curOptionsContent() {
    let tab = tabs?[curTabIdx.get()]
    return {
      watch = curTabIdx
      children = [
        mkVerticalPannableArea(
          {
            size = [contentWidth, SIZE_TO_CONTENT]
            padding = [0, saBorders[0]]
            key = tab
            flow = FLOW_VERTICAL
            halign = ALIGN_LEFT
            children = tab?.options.filter(@(v) v != null).map(mkOption)
            animations = wndSwitchAnim
          },
          { size = [pannableAreaWidth, saSize[1] - tabHeight - gap] },
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
        scrollArrowsBlock
      ]
    }
  }

  return {
    size = flex()
    function onAttach() {
      if (curTabIdx.get() not in tabs)
        resetCurTabIdx()
    }
    children = {
      size = [contentWidth, flex()]
      flow = FLOW_VERTICAL
      gap
      children = [
        mkHorizontalTabs(tabs, curTabIdx).__update({ padding = [0, 0, 0, saBorders[0]] })
        curOptionsContent
      ]
    }
    animations = wndSwitchAnim
  }
}

return mkChildrenOptions