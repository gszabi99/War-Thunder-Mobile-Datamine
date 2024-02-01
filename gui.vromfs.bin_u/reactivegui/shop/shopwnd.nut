from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene, moveSceneToTop } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { shopCategoriesCfg } = require("shopCommon.nut")
let { isShopOpened, curCategoryId, goodsByCategory, shopOpenCount, saveSeenGoodsCurrent
} = require("%rGui/shop/shopState.nut")
let { actualSchRewardByCategory } = require("schRewardsState.nut")
let { mkShopTabs, tabW } = require("%rGui/shop/shopWndTabs.nut")
let { mkShopPage, mkShopGamercard } = require("%rGui/shop/shopWndPage.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("unseenPurchasesState.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let gapFromGamercard = hdpx(40)
let opacityGradWidth = saBorders[0]
let shopPageH = saSize[1] - gapFromGamercard - gamercardHeight
let shopPageW = saSize[0] - tabW + opacityGradWidth

let close = @() isShopOpened(false)
isPurchEffectVisible.subscribe(function(v) {
  if (v && isShopOpened.value)
    close()
})

let curCategoriesCfg = Computed(@() shopCategoriesCfg
  .filter(@(c) c.id in actualSchRewardByCategory.value
    || c.id in goodsByCategory.value))

let pageScrollHandler = ScrollHandler()
curCategoryId.subscribe(@(_) pageScrollHandler.scrollToX(0))

let pannable = @(ovr) {
  size = flex()
  behavior = Behaviors.Pannable
  scrollHandler = ScrollHandler()
  xmbNode = XmbContainer({
    canFocus = false
    scrollSpeed = 5.0
    isViewport = true
    scrollToEdge = true
  })
}.__update(ovr)

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "item" && g.gType != "currency" && g.gType != "premium")
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

function onClose() {
  saveSeenGoodsCurrent()
  close()
}

let scrollArrowsBlock = {
  size = [shopPageW + hdpx(30), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(pageScrollHandler, MR_L)
    mkScrollArrow(pageScrollHandler, MR_R)
  ]
}

let shopScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = gapFromGamercard
  onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
  onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
  children = [
    mkShopGamercard(onClose)
    {
      size = [saSize[0] + opacityGradWidth, flex()]
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [tabW, flex()]
          clipChildren = true
          children = @() pannable({
            watch = [curCategoriesCfg, curCampaign]
            children = @() mkShopTabs(curCategoriesCfg.value, curCategoryId, curCampaign.value)
          })
        }
        {
          size = [shopPageW, shopPageH]
          children = [
            horizontalPannableAreaCtor(shopPageW, [opacityGradWidth, opacityGradWidth])(
              mkShopPage(shopPageW, shopPageH),
              { pos = [0, 0], clipChildren = true },
              { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler = pageScrollHandler })
            scrollArrowsBlock
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("shopWnd", shopScene, close, isShopOpened)
shopOpenCount.subscribe(@(_) moveSceneToTop("shopWnd"))
