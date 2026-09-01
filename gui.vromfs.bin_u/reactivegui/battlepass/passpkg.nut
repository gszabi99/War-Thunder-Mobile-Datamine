from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle, bpCardPadding
from "%rGui/battlePass/passRewardsListComp.nut" import purchBtnHeight
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/levelBlockPkg.nut" import mkProgressLevelBg
from "%rGui/components/pannableArea.nut" import horizontalPannableAreaCtor
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPricePurchaseLow
from "%rGui/rewards/rewardPlateComp.nut" import getRewardPlateSize


let progressIconSize = [evenPx(54), hdpxi(58)]
let defPassIconSize = [hdpx(298), hdpx(181)]
let tabSize = [hdpx(140), hdpx(140)]
const bpLineFillColor = 0xFF191919
const bpBorderColor = 0xFF7C7C7C
const bottomPanelIconSize = hdpxi(60)
let bottomPanelH = saBorders[1] + bottomPanelIconSize

let sideTabWidth = saBorders[0] + tabSize[0]
let vGradientGapSize = [hdpx(4), FLEX]
let contentH = saSize[1] - bottomPanelH - hdpx(40)
let rewardPannableWidthTabs = sw(100) - (sideTabWidth + vGradientGapSize[0])
const rewardPannableWidthFull = sw(100)

let rewardPannableTabs = horizontalPannableAreaCtor(rewardPannableWidthTabs, [hdpx(40), saBorders[0]])
let rewardPannableFull = horizontalPannableAreaCtor(rewardPannableWidthFull, [saBorders[0], saBorders[0]])

function mkLevelLine(points, stagePoints, ovr = {}) {
  let percent =  1.0 * clamp(points, 0, stagePoints ) / stagePoints
  return {
    size = FLEX
    valign = ALIGN_CENTER
    children = mkProgressLevelBg({
      size = FLEX
      fillColor = bpLineFillColor
      borderColor = bpBorderColor
      children = {
        size = [ pw(100 * percent), FLEX ]
        rendObj = ROBJ_SOLID
        color = 0xFF36C574
      }
    }.__update(ovr))
  }
}

let bpCurProgressbar = @(pointsCurStage, pointsPerStage, ovr = {}) @() {
  watch = [pointsCurStage, pointsPerStage]
  size = FLEX
  children = mkLevelLine(pointsCurStage.get(), pointsPerStage.get(), ovr)
}

let fullLineBP = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0xFF36C574
}

let bpProgress = @(children) mkProgressLevelBg({
  size = FLEX
  fillColor = bpLineFillColor
  borderColor = bpBorderColor
  children
})


let bpProgressText  = @(pointsCurStage, pointsPerStage, ovr = {}) @() {
  watch = [pointsCurStage, pointsPerStage]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = "/".concat(pointsCurStage.get(), pointsPerStage.get())
}.__update(fontVeryTiny, ovr)

let mkRewardsPannable = @(content, scrollHandler, isFullScreenWidth)
  (isFullScreenWidth ? rewardPannableFull : rewardPannableTabs)(
      content,
      isFullScreenWidth
        ? { size = const [rewardPannableWidthFull, SIZE_TO_CONTENT], clipChilden = false }
        : { size = [rewardPannableWidthTabs, SIZE_TO_CONTENT], pos = const [0, 0], clipChilden = false },
      {
        size = FLEX_H
        behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
        scrollHandler = scrollHandler
      })

function mkPassIcon(watch, getImage, getIsActive, fallback, ovr = {}) {
  let size = ovr?.size ?? defPassIconSize
  return @() {
    watch
    size
    rendObj = ROBJ_IMAGE
    vplace = ALIGN_CENTER
    image = Picture($"{getImage()}:{size[0]}:{size[1]}:P")
    fallbackImage = Picture($"{fallback}:{size[0]}:{size[1]}:P")
    keepAspect = true
    opacity = getIsActive() ? 1 : 0.5
  }.__update(ovr)
}

let emptyBuyLevelBlock = { size = [SIZE_TO_CONTENT, purchBtnHeight] }

function mkBuyLevelBlock(canBuyLevel, viewInfo, levelPrice, isLevelPurchaseInProgress, buyLevelMsg, context) {
  if (!canBuyLevel)
    return emptyBuyLevelBlock
  return function() {
    let price = levelPrice.get()
    let cardWidth = getRewardPlateSize(viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
    return {
      watch = levelPrice
      size = [SIZE_TO_CONTENT, purchBtnHeight]
      children = price == null || price.price <= 0 ? null
        : mkSpinnerHideBlock(isLevelPurchaseInProgress,
            textButtonPricePurchaseLow(utf8ToUpper(loc("battlepass/buyLevel")),
              mkCurrencyComp(price.price, price.currency),
              @() buyLevelMsg(price, context),
              { hotkeys = ["^J:X"]
                ovr = { size = [SIZE_TO_CONTENT, purchBtnHeight]
                        minWidth = cardWidth
                        contentPadding = [0, hdpx(20)]
                      }
              }),
            { hplace = ALIGN_CENTER, size = [SIZE_TO_CONTENT, purchBtnHeight] })
    }
  }
}

return {
  bpCurProgressbar
  bpProgressText

  bpProgressbarEmpty = bpProgress(null)
  bpProgressbarFull = bpProgress(fullLineBP)

  progressIconSize

  tabSize
  tabIconSize = hdpx(90)
  sideTabWidth
  vGradientGapSize
  contentH
  bottomPanelH
  bottomPanelIconSize
  mkRewardsPannable
  mkBuyLevelBlock
  mkPassIcon
}