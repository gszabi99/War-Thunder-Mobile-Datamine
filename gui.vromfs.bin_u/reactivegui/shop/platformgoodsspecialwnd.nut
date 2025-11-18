from "%globalsDarg/darg_library.nut" import *
let { G_CURRENCY, G_PREMIUM } = require("%appGlobals/rewardType.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let buyPlatformGoodsIOS = require("%rGui/shop/byPlatform/goodsIos.nut").buyPlatformGoods
let buyPlatformGoodsGaijin = require("%rGui/shop/byPlatform/goodsGaijin.nut").buyPlatformGoodsFromOtherPlatform
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")

let goodsToPaySpecialWnd = mkWatched(persist, "iosPaymentWaysWnd", null)
let WND_UID = "iosPaymentWaysWnd"
let borderRadius = hdpx(10)
let btnH = hdpx(120)
let btnPadding = hdpx(20)
let boxSize = hdpx(80)
let iconSize = hdpx(60)

let btnsList = [
  {
    isPriorityBtn = true
    borderWidth = 2
    borderColor = 0xFF65DD3E
    fillColor = 0xFF143D19
    image = "gaijin_logo_snail.svg"
    textKey = "onlineShop/goToGaijin"
    purchase = @() buyPlatformGoodsGaijin(goodsToPaySpecialWnd.get())
  },
  {
    isPriorityBtn = false
    fillColor = 0xFF253744
    textKey = "onlineShop/goToApple"
    purchase = @() buyPlatformGoodsIOS(goodsToPaySpecialWnd.get())
  }
]

function getBonusDesc(goodId) {
  let goods = campConfigs.get()?.allGoods[goodId]
  let relatedGoods = campConfigs.get()?.allGoods[goods?.relatedGaijinId]
  if (!goods || !relatedGoods)
    return ""

  if ("rewards" in goods) {
    let { gType, id } = goods.rewards[0]
    if (gType != relatedGoods.rewards[0].gType
        || id != relatedGoods.rewards[0].id)
      return ""
    let amount = relatedGoods.rewards[0].count - goods.rewards[0].count
    if (amount > 0)
      if (gType == G_CURRENCY)
        return loc($"onlineShop/gaijinBonus/{id}", { amount })
      else if (gType == G_PREMIUM)
        return loc("onlineShop/gaijinBonus/premium", { amount })
    return ""
  }

  
  if (goods.currencies?.gold)
    return loc("onlineShop/gaijinBonus/gold")
  if (goods.premiumDays > 0) {
    let amount = relatedGoods.premiumDays - goods.premiumDays
    if (amount != 0)
      return loc("onlineShop/gaijinBonus/premium", { amount })
  }
  return ""
}

let close = @() goodsToPaySpecialWnd.set(null)

let header = modalWndHeader(loc("onlineShop/choosePayMethod"))

function mkBtn(params){
  let { isPriorityBtn, borderWidth = 0, borderColor = 0, fillColor = 0xFF253744,
    image = null, textKey, purchase } = params
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [flex(), btnH]
    rendObj = ROBJ_BOX
    borderRadius
    borderWidth
    borderColor
    fillColor
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    padding = btnPadding
    function onClick() {
      purchase()
      close()
    }
    children = [
      !image ? null
        : {
            size = [boxSize, boxSize]
            rendObj = ROBJ_BOX
            borderRadius
            fillColor = 0xFF000000
            hplace = ALIGN_LEFT
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = {
              size = [iconSize, iconSize]
              rendObj = ROBJ_IMAGE
              image = Picture($"ui/gameuiskin#{image}:{iconSize}:{iconSize}:P")
            }
          }
      {
        flow = FLOW_VERTICAL
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        gap = hdpx(10)
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc(textKey)
          }.__update(fontTiny)
          !isPriorityBtn ? null
            : @() {
                watch = goodsToPaySpecialWnd
                rendObj = ROBJ_TEXT
                color = 0xFF65DD3E
                text = getBonusDesc(goodsToPaySpecialWnd.get())
              }.__update(fontVeryTinyAccented)
        ]
      }
    ]
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
  }
}

let content = modalWndBg.__merge({
  size = const [hdpx(800), SIZE_TO_CONTENT]
  padding = const [0,hdpx(40), hdpx(40),hdpx(40)]
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  halign = ALIGN_CENTER
  children = [
    header
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = btnsList.map(mkBtn)
    }
  ]
})

let paymentsWaysWnd = bgShaded.__merge({
  key = WND_UID
  size = flex()
  children = content
  onClick = close
  animations = wndSwitchAnim
})


if (goodsToPaySpecialWnd.get())
  addModalWindow(paymentsWaysWnd)
goodsToPaySpecialWnd.subscribe(@(v) v ? addModalWindow(paymentsWaysWnd) : removeModalWindow(WND_UID))

return goodsToPaySpecialWnd
