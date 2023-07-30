from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene, moveSceneToTop } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkGamercard, gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { shopCategoriesCfg } = require("shopCommon.nut")
let { isShopOpened, curCategoryId, goodsByCategory, shopOpenCount } = require("%rGui/shop/shopState.nut")
let { actualSchRewardByCategory } = require("schRewardsState.nut")
let { mkShopTabs, tabW } = require("%rGui/shop/shopWndTabs.nut")
let { mkShopPage } = require("%rGui/shop/shopWndPage.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("unseenPurchasesState.nut")
let { isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")

let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let gapFromGamercard = hdpx(40)
let gapFromTabs = hdpx(47)
let shopPageW = saSize[0] - gapFromTabs - tabW
let shopPageH = saSize[1] - gapFromGamercard - gamercardHeight
let leftGradientBlock = hdpx(113)

let close = @() isShopOpened(false)
isPurchEffectVisible.subscribe(function(v) {
  if (v && isShopOpened.value)
    close()
})

let curCategoriesCfg = Computed(@() shopCategoriesCfg
  .filter(@(c) c.id in actualSchRewardByCategory.value
    || c.id in goodsByCategory.value))

let pageWidth = saSize[0] + saBorders[0] - tabW - gapFromTabs
let pageMask = mkBitmapPicture((pageWidth / 10).tointeger(), 2,
  function(params, bmp) {
    let { w, h } = params
    let gradStart = w.tofloat() * (pageWidth - 2 * saBorders[0]) / pageWidth
    let gradStart2 = (leftGradientBlock/10).tointeger()
    for(local x = 0; x < w; x++) {
      let v = x < gradStart2 ? lerpClamped(0, gradStart2 , 0, 1.0, x)
        : x > gradStart ? lerpClamped(gradStart, w - 1, 1.0, 0, x)
        : 1
      let part = (v * v * 0xFF + 0.5).tointeger()
      let color = Color(part, part, part, part)
      for(local y = 0; y < h; y++)
        bmp.setPixel(x, y, color)
    }
  })
let pageScrollHandler = ScrollHandler()
curCategoryId.subscribe(@(_) pageScrollHandler.scrollToX(0))

let pannable = @(ovr) {
  size = flex()
  behavior = Behaviors.Pannable
  scrollHandler = ScrollHandler()
  xmbNode = XmbContainer({
    canFocus = @() false
    scrollSpeed = 5.0
    isViewport = true
    scrollToEdge = true
  })
}.__update(ovr)

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "item" && g.gType != "currency" && g.gType != "premium")
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

let shopScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = gapFromGamercard
  onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
  onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
  children = [
    mkGamercard(close, true)
    {
      size = [saSize[0] + saBorders[0], flex()]
      flow = FLOW_HORIZONTAL
      gap = gapFromTabs
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
          size = flex()
          flow = FLOW_HORIZONTAL
          clipChildren = true
          rendObj = ROBJ_MASK
          image = pageMask
          children = [
            {
              size = [leftGradientBlock, flex()]
            }
            @() pannable({
              padding = [0, saBorders[0], 0, 0]
              scrollHandler = pageScrollHandler
              children = mkShopPage(shopPageW, shopPageH)
            })
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
})

registerScene("shopWnd", shopScene, close, isShopOpened)
shopOpenCount.subscribe(@(_) moveSceneToTop("shopWnd"))
