from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer, deferOnce
from "%sqstd/math.nut" import ceil
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%rGui/battlePass/passPkg.nut" import contentH
from "%rGui/components/gradientDefComps.nut" import headerHeightInSafeArea, headerMargin
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/tabs.nut" import tabExtraWidth
from "%rGui/event/eventState.nut" import curEvent, specialEvents
from "%rGui/navState.nut" import registerScene
from "%rGui/shop/eventShopState.nut" import getShopIdForEventId
from "%rGui/shop/shopCommon.nut" import shopCategoriesCfg
from "%rGui/shop/shopState.nut" import isShopOpened, shopOpenCount, saveSeenGoodsCurrent, pageScrollHandler,
  onTabChange, hasGoodsCategoryNonUpdatable, hasUnseenGoodsByShop, curShopId, closeShopWnd, setShopCategory,
  isShopAttached, shopCurCategories, subsByCategory, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
  personalGoodsByShop, mkShopActualSchRewardsByCategoryFor, getCurShopGoodsByCategoryFor
from "%rGui/shop/shopWndConst.nut" import tabW, shopGap, titleH, titleGap, goodsH, goodsPerRow, goodsGap, categoryGap
from "%rGui/shop/shopWndPage.nut" import mkShopPage, mkShopGamercard
from "%rGui/shop/shopWndTabs.nut" import mkShopTabs
from "%rGui/shop/unseenPurchasesState.nut" import addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler,
  markPurchasesSeen
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/unitPurchaseEffectScene.nut" import isPurchEffectVisible


let shopContentW = saSize[0] + saBorders[0] - tabW
let shopContentH = saSize[1] + saBorders[1] - headerHeightInSafeArea

local lastScrollPosY = 0
let resetScrollPos = @() lastScrollPosY = 0

isShopOpened.subscribe(@(v) v ? null : resetScrollPos())
isPurchEffectVisible.subscribe(@(v) v && isShopOpened.get() ? closeShopWnd() : null)

let pannable = @(ovr) {
  size = FLEX
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
  closeShopWnd()
}

let pannableArea = verticalPannableAreaCtor(shopContentH, [headerMargin, saBorders[1]])

function mkShopContent(contentW, pannableAreaCtor, shopIdW = null, close = closeShopWnd) {
  shopIdW = shopIdW ?? curShopId
  let categoryIdW = Computed(@() shopCurCategories.get()?[shopIdW.get()])
  let ctx = {
    shopIdW
    categoryIdW
    goodsByCategory = Computed(@() goodsByShop.get()?[shopIdW.get()])
    soonGoodsByCategory = Computed(@() soonGoodsByShop.get()?[shopIdW.get()])
    schRewardsByCategory = mkShopActualSchRewardsByCategoryFor(shopIdW)
    soonPGoodsByCategory = Computed(@() soonPersonalGoodsByShop.get()?[shopIdW.get()])
    personalGoodsByCategory = Computed(@() personalGoodsByShop.get()?[shopIdW.get()])
    subsByCategory = getCurShopGoodsByCategoryFor(subsByCategory, shopIdW)
    onCategoryTabChange = @(id) onTabChange(id, shopIdW.get())
    setCategory = @(catId) setShopCategory(catId, shopIdW.get())
    close
  }
  let { goodsByCategory, soonGoodsByCategory, schRewardsByCategory,
    soonPGoodsByCategory, personalGoodsByCategory, onCategoryTabChange, setCategory
  } = ctx
  let shopSubsByCategory = ctx.subsByCategory 

  let curCategoriesCfg = Computed(@() shopCategoriesCfg
    .filter(@(c) c.id in schRewardsByCategory.get()
      || c.id in goodsByCategory.get()
      || c.id in soonGoodsByCategory.get()
      || c.id in soonPGoodsByCategory.get()
      || c.id in personalGoodsByCategory.get()
      || c.id in shopSubsByCategory.get()))
  let distances = Computed(function() {
    let allGoodsLists = goodsByCategory.get()
    let soonGoods = soonGoodsByCategory.get()
    let soonPGoods = soonPGoodsByCategory.get()
    let allRewards = schRewardsByCategory.get()
    let allPersonal = personalGoodsByCategory.get()
    let allSubs = shopSubsByCategory.get()
    local top = 0
    local totalRows = 0
    local totalHeaders = 0
    let res = {}
    foreach (cfg in curCategoriesCfg.get()) {
      let { id = "" } = cfg
      let goodsRewardLen = (allGoodsLists?[id] ?? []).len() + (allRewards?[id] == null ? 0 : 1) + (allPersonal?[id].len() ?? 0)
         + (allSubs?[id].len() ?? 0) + (soonGoods?[id].len() ?? 0) + (soonPGoods?[id].len() ?? 0)
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

  distances.subscribe(@(v) v.len() == 0 ? close(shopIdW.get()) : null)
  if (distances.get().len() == 0) {
    let curId = shopIdW.get()
    deferOnce(@() close(curId))
  }

  function tryDoActionForCurrentScroll(action) {
    let currentY = pageScrollHandler?.elem.getScrollOffsY()
    if (currentY == null)
      return
    let bottomBoundary = pageScrollHandler?.elem.getContentHeight() ?? 0
    let isBottom = currentY + (pageScrollHandler?.elem.getHeight() ?? 0) >= bottomBoundary
    local idx = null
    if (isBottom)
      idx = distances.get().findindex(@(v) v.top > currentY)
    if (!isBottom || idx == null)
      idx = distances.get().findindex(@(v) currentY >= v.top && currentY <= v.bottom)
    if (idx != categoryIdW.get() && idx != null)
      action(idx)
  }

  let scrollToCurCategory = @() categoryIdW.get() not in distances.get() ? null
    : pageScrollHandler.scrollToY(distances.get()[categoryIdW.get()].scrollTo)
  let scrollToCurCategoryDelayed = @(_) deferOnce(scrollToCurCategory)
  let onPageScroll = @(_) tryDoActionForCurrentScroll(onCategoryTabChange)
  let onChangeCategory = @(_) tryDoActionForCurrentScroll(scrollToCurCategoryDelayed)
  let hasUnseenGoodsByCategory = Computed(@() hasUnseenGoodsByShop.get()?[shopIdW.get()])

  return {
    key = distances
    size = [saSize[0] + tabExtraWidth, FLEX]
    pos = [-tabExtraWidth, 0]
    flow = FLOW_HORIZONTAL
    function onAttach() {
      if (!hasGoodsCategoryNonUpdatable(categoryIdW.get()))
        setCategory(shopCategoriesCfg.findvalue(@(c) hasGoodsCategoryNonUpdatable(c.id))?.id)

      pageScrollHandler.scrollToY(lastScrollPosY)
      resetScrollPos()
      pageScrollHandler.subscribe(onPageScroll)
      categoryIdW.subscribe(onChangeCategory)
      shopIdW.subscribe(scrollToCurCategoryDelayed)
      scrollToCurCategory()
    }
    function onDetach() {
      pageScrollHandler.unsubscribe(onPageScroll)
      categoryIdW.unsubscribe(onChangeCategory)
      shopIdW.unsubscribe(scrollToCurCategoryDelayed)
    }
    children = [
      {
        size = [tabW + tabExtraWidth, FLEX]
        children = @() pannable({
          watch = [curCategoriesCfg, curCampaign]
          children = mkShopTabs(curCategoriesCfg.get(), categoryIdW, curCampaign.get(), hasUnseenGoodsByCategory, onCategoryTabChange)
        })
      }
      pannableAreaCtor(mkShopPage(curCategoriesCfg, distances, ctx),
        {},
        {
          size = FLEX_V
          minWidth = contentW
          padding = [0, 0, 0, shopGap]
          behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
          flow = FLOW_VERTICAL
          scrollHandler = pageScrollHandler
          onScroll = @(elem) lastScrollPosY = elem.getScrollOffsY() ?? 0
        })
    ]
  }
}



let eventShopTabPannableArea = verticalPannableAreaCtor(contentH, [headerMargin, headerMargin])

function eventShopTabContent() {
  let curTabShopId = Computed(@() getShopIdForEventId(curEvent.get(), specialEvents.get(),
    goodsByShop.get(), soonGoodsByShop.get(), soonPersonalGoodsByShop.get(), personalGoodsByShop.get()))
  let shopId = curTabShopId.get()
  return {
    key = {}
    padding = [0, saBorders[0], 0, saBorders[0]]
    size = FLEX
    function onDetach() {
      if (shopId != null)
        saveSeenGoodsCurrent(shopId)
    }
    children = @() {
      watch = curTabShopId
      size = FLEX
      children = curTabShopId.get() == null ? null
        : mkShopContent(shopContentW, eventShopTabPannableArea, curTabShopId, @(_) null)
    }
  }
}

let shopScene = @() bgShaded.__merge({
  key = isShopOpened
  size = FLEX
  padding = [saBorders[1], saBorders[0], 0, saBorders[0]]
  flow = FLOW_VERTICAL
  function onAttach() {
    isShopAttached.set(true)
    addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
  }
  function onDetach() {
    isShopAttached.set(false)
    removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
  }
  children = [
    mkShopGamercard(onClose)
    mkShopContent(shopContentW, pannableArea)
  ]
  animations = wndSwitchAnim
})

registerScene("shopWnd_common", shopScene, @() closeShopWnd("common"), Computed(@() shopOpenCount.get()?["common"] ?? 0))

return eventShopTabContent
