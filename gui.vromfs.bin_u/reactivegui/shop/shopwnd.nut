from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { defer } = require("dagor.workcycle")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene, moveSceneToTop } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { shopCategoriesCfg } = require("shopCommon.nut")
let { isShopOpened, curCategoryId, goodsByCategory, shopOpenCount, saveSeenGoodsCurrent,
  pageScrollHandler, onTabChange, hasGoodsCategoryNonUpdatable, subsByCategory
} = require("%rGui/shop/shopState.nut")
let { actualSchRewardByCategory } = require("schRewardsState.nut")
let { personalGoodsByShopCategory } = require("personalGoodsState.nut")
let { mkShopTabs } = require("%rGui/shop/shopWndTabs.nut")
let { mkShopPage, mkShopGamercard } = require("%rGui/shop/shopWndPage.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("unseenPurchasesState.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { fullTabW, shopGap, titleH, titleGap, goodsH, goodsPerRow, goodsGap, categoryGap } = require("shopWndConst.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")


let gapFromGamercard = hdpx(20)
let marginTopFromGamercard = hdpx(20)
let shopContentGradient = marginTopFromGamercard + hdpx(8)
let shopContentW = saSize[0] + saBorders[0] - fullTabW
let shopContentH = saSize[1] + saBorders[1] - gapFromGamercard - gamercardHeight

local lastScrollPosY = 0
let resetScrollPos = @() lastScrollPosY = 0
let close = @() isShopOpened.set(false)
isShopOpened.subscribe(@(v) v ? null : resetScrollPos())
isPurchEffectVisible.subscribe(@(v) v && isShopOpened.get() ? close() : null)

let pannable = @(ovr) {
  size = flex()
  behavior = Behaviors.Pannable
  touchMarginPriority = TOUCH_BACKGROUND
  scrollHandler = ScrollHandler()
  xmbNode = XmbContainer({ scrollToEdge = true })
}.__update(ovr)

let isPurchNoNeedResultWindow = @(purch) (purch?.source == "purchaseInternal" || purch?.source == "scheduledReward")
  && null == purch.goods.findvalue(@(g) g.gType != "item" && g.gType != "currency" && g.gType != "premium")
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

function onClose() {
  saveSeenGoodsCurrent()
  close()
}

let pannableArea = verticalPannableAreaCtor(shopContentH, [shopContentGradient, saBorders[1] + shopContentGradient])

function mkShopContent() {
  let curCategoriesCfg = Computed(@() shopCategoriesCfg
    .filter(@(c) c.id in actualSchRewardByCategory.get()
      || c.id in goodsByCategory.get()
      || c.id in personalGoodsByShopCategory.get()
      || c.id in subsByCategory.get()))
  let distances = Computed(function() {
    let allGoodsLists = goodsByCategory.get()
    let allRewards = actualSchRewardByCategory.get()
    let allPersonal = personalGoodsByShopCategory.get()
    let allSubs = subsByCategory.get()
    local top = 0
    local totalRows = 0
    local totalHeaders = 0
    let res = {}
    foreach (cfg in curCategoriesCfg.get()) {
      let { id = "" } = cfg
      let goodsRewardLen = (allGoodsLists?[id] ?? []).len() + (allRewards?[id] == null ? 0 : 1) + (allPersonal?[id].len() ?? 0)
         + (allSubs?[id].len() ?? 0)
      let rows = ceil(1.0 * goodsRewardLen / goodsPerRow)
      let bottom = top + titleH + titleGap + rows * goodsH + (rows - 1) * goodsGap + categoryGap
      let additionalTriggerSpace = categoryGap + goodsH / 3
      res[id] <- {
        top = top <= 0 ? 0 : top - additionalTriggerSpace
        scrollTo = top
        bottom = bottom - 1 - additionalTriggerSpace
        rowsBefore = totalRows
        headersBefore = totalHeaders
      }
      top = bottom
      if (goodsRewardLen > 0) {
        totalRows += rows
        totalHeaders++
      }
    }
    return res
  })

  function tryDoActionForCurrentScroll(action) {
    let currentY = pageScrollHandler?.elem.getScrollOffsY()
    if (currentY == null)
      return
    let idx = distances.get().findindex(@(v) currentY >= v.top && currentY <= v.bottom)
    if (idx != curCategoryId.get() && idx != null)
      action(idx)
  }

  let scrollToCurCategory = @() curCategoryId.get() not in distances.get() ? null
    : pageScrollHandler.scrollToY(distances.get()[curCategoryId.get()].scrollTo)
  let onPageScroll = @(_) tryDoActionForCurrentScroll(@(idx) onTabChange(idx))
  let onChangeCategory = @(_) tryDoActionForCurrentScroll(@(_) scrollToCurCategory())

  return {
    key = distances
    size = [shopContentW + fullTabW, flex()]
    flow = FLOW_HORIZONTAL
    clipChildren = true
    function onAttach() {
      if (!hasGoodsCategoryNonUpdatable(curCategoryId.get()))
        curCategoryId.set(shopCategoriesCfg.findvalue(@(c) hasGoodsCategoryNonUpdatable(c.id))?.id)

      pageScrollHandler.scrollToY(lastScrollPosY)
      resetScrollPos()
      pageScrollHandler.subscribe(onPageScroll)
      curCategoryId.subscribe(onChangeCategory)
      scrollToCurCategory()
    }
    function onDetach() {
      pageScrollHandler.unsubscribe(onPageScroll)
      curCategoryId.unsubscribe(onChangeCategory)
    }
    children = [
      {
        margin = [marginTopFromGamercard, 0, 0, 0]
        size = [fullTabW, flex()]
        children = @() pannable({
          watch = [curCategoriesCfg, curCampaign]
          children = mkShopTabs(curCategoriesCfg.get(), curCategoryId, curCampaign.get())
        })
      }
      pannableArea(mkShopPage(curCategoriesCfg, distances),
        { pos = [0, 0] },
        {
          size = FLEX_V
          minWidth = shopContentW
          padding = [0, 0, 0, shopGap]
          behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
          flow = FLOW_VERTICAL
          scrollHandler = pageScrollHandler
          onScroll = @(elem) lastScrollPosY = elem.getScrollOffsY() ?? 0
        })
    ]
  }
}

let shopScene = @() bgShaded.__merge({
  key = isShopOpened
  size = flex()
  padding = [saBorders[1], saBorders[0], 0, saBorders[0]]
  flow = FLOW_VERTICAL
  gap = gapFromGamercard
  onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
  onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
  children = [
    mkShopGamercard(onClose)
    mkShopContent()
  ]
  animations = wndSwitchAnim
})

registerScene("shopWnd", shopScene, close, isShopOpened)
shopOpenCount.subscribe(@(_) moveSceneToTop("shopWnd"))
