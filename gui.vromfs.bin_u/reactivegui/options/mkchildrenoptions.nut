from "%globalsDarg/darg_library.nut" import *
from "%rGui/battlePass/passPkg.nut" import contentH
from "%rGui/components/horizontalTabs.nut" import mkHorizontalTabs
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
import "%rGui/options/mkOption.nut" as mkOption
from "%rGui/options/optionsStyle.nut" import tabW
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import selectColor


let contentWidth = saSize[0] - tabW - saBorders[0]
let pannableAreaWidth = saSize[0] - tabW + saBorders[0]

const backButtonHeight = hdpx(60)
const gapBackButton = hdpx(50)
const tabHeight = hdpx(120)

let topAreaSize = saBorders[1] + backButtonHeight + gapBackButton - tabHeight
let gradientHeightBottom = saBorders[1] * 2
let gradientHeightTop = saBorders[1]

let scrollHandler = ScrollHandler()

let mkVerticalPannableArea = verticalPannableAreaCtor(contentH,
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

  curTabIdx.subscribe(@(_) scrollHandler.scrollToY(0))
  const gap = hdpx(50)

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
            halign = ALIGN_CENTER
            hplace = ALIGN_CENTER
            gap = hdpx(20)
            children = tab?.options.filter(@(v) v != null).map(mkOption)
            animations = wndSwitchAnim
          },
          { size = [pannableAreaWidth, contentH] },
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
        scrollArrowsBlock
      ]
    }
  }

  return {
    size = FLEX
    function onAttach() {
      if (curTabIdx.get() not in tabs || !(tabs[curTabIdx.get()]?.isVisible.get() ?? true))
        resetCurTabIdx()
    }
    children = {
      size = [FLEX, contentH]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      margin = [0, 0, 0, saBorders[0]]
      gap
      children = [
        {
          size = const [FLEX, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          children = [
            mkHorizontalTabs(tabs, curTabIdx)
            {
              size = [FLEX, hdpx(4)]
              rendObj = ROBJ_SOLID
              color = selectColor
            }
          ]
        }
        curOptionsContent
      ]
    }
    animations = wndSwitchAnim
  }
}

return mkChildrenOptions