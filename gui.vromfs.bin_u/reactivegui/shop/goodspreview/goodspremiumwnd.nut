from "%globalsDarg/darg_library.nut" import *
let { G_PREMIUM } = require("%appGlobals/rewardType.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { textButtonPurchase } = require("%rGui/components/textButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { previewGoods, GPT_PREMIUM , closeGoodsPreview, previewType} = require("%rGui/shop/goodsPreviewState.nut")
let { buyPlatformGoods } = require("%rGui/shop/platformGoods.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let premDescWndUid = "prem_desc_wnd_uid"

let isOpened = keepref(Computed(@() previewType.get() == GPT_PREMIUM))
let premiumDescriptionWndBg = 0xDC000000
let premiumDescriptionWidth = sw(50)
let premiumDescriptionHeaderHeight = sh(8)
let premiumDescriptionHeaderBg = 0x0A585858
let premiumDescriptionDecorativeLineBg = 0xFFD4D4D4
let insideIndent = hdpxi(12)
let iconSize = hdpx(300)

let premiumBonusesCfg = Computed(@() serverConfigs.get()?.gameProfile.premiumBonuses)
let bonusMultText = @(v) $"{v}x"
let infoText = Computed(function() {
  if (premiumBonusesCfg.get() == null)
    return null
  let expMul = bonusMultText(premiumBonusesCfg.get()?.expMul ?? 1.0)
  return loc("charServer/entitlement/PremiumAccount/desc", {
    bonusPlayerExp = expMul
    bonusWp = bonusMultText(premiumBonusesCfg.get()?.wpMul ?? 1.0)
    bonusUnitExp = expMul
    bonusGold = bonusMultText(premiumBonusesCfg.get()?.goldMul ?? 1.0)
  })
})


let decorativeLine = {
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = premiumDescriptionDecorativeLineBg
  size = [ premiumDescriptionWidth, hdpx(6) ]
}

let premiumDescriptionHeader = @() {
  watch = previewGoods
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = premiumDescriptionHeaderBg
  size = [ premiumDescriptionWidth, premiumDescriptionHeaderHeight ]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc($"charServer/entitlement/PremiumAccount/header",
      {
        days = previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_PREMIUM)?.count
          ?? previewGoods.get()?.premiumDays 
          ?? 0
      })
  }.__update(fontMedium)
}


let pricePlate = @() {
  watch = previewGoods
  size = FLEX_H
  padding = const [ hdpx(24), 0 ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = textButtonPurchase(utf8ToUpper(previewGoods.get()?.priceExt.priceText ?? ""),
    @() buyPlatformGoods(previewGoods.get().id), fontMedium)
}

let premiumDescription = {
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = [ premiumDescriptionWidth, SIZE_TO_CONTENT ]
    children = [
      decorativeLine
      premiumDescriptionHeader
      {
        rendObj = ROBJ_9RECT
        image = gradTranspDoubleSideX
        padding = [ insideIndent, 0 ]
        size = FLEX_H
        texOffs = [0 , gradDoubleTexOffset]
        screenOffs = [0, hdpx(250)]
        color = premiumDescriptionWndBg
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            size = FLEX_H
            gap = insideIndent * 2
            children = [
              {
                rendObj = ROBJ_IMAGE
                image = Picture("ui/gameuiskin/premium_active_big.avif")
                keepAspect = KEEP_ASPECT_FIT
                size = [iconSize, iconSize]
                minHeight = sh(30)
              }
              @() {
                watch = infoText
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                size = const [ hdpx(700), SIZE_TO_CONTENT ]
                text = infoText.get()
                color = 0xFFC0C0C0
              }.__update(fontSmall)
            ]
          }
          pricePlate
        ]
      }
      decorativeLine
    ]
  }

let backBtn = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = backButton(closeGoodsPreview)
}

let premiumDescriptionWnd = {
  key = premDescWndUid
  rendObj = ROBJ_SOLID
  size = flex()
  color = premiumDescriptionWndBg
  padding = saBordersRv
  behavior = Behaviors.Button
  hotkeys = [[btnBEscUp, { action = closeGoodsPreview }]]
  onClick = closeGoodsPreview
  children = [
    backBtn
    premiumDescription
  ]
}
let openImpl = @() addModalWindow(premiumDescriptionWnd)

if(isOpened.get())
  openImpl()

isOpened.subscribe( @(v) v ? openImpl() : removeModalWindow(premDescWndUid))