from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_PREMIUM
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/textButton.nut" import textButtonPurchase
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/shop/goodsPreviewState.nut" import previewGoods, GPT_PREMIUM, closeGoodsPreview, previewType
from "%rGui/shop/platformGoods.nut" import buyPlatformGoods
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset


const premDescWndUid = "prem_desc_wnd_uid"

let isOpened = keepref(Computed(@() previewType.get() == GPT_PREMIUM))
const premiumDescriptionWndBg = 0xDC000000
const premiumDescriptionWidth = sw(50)
const premiumDescriptionHeaderHeight = sh(8)
const premiumDescriptionHeaderBg = 0x0A585858
const premiumDescriptionDecorativeLineBg = 0xFFD4D4D4
const insideIndent = hdpxi(12)
const iconSize = hdpx(300)

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
  size = const [ premiumDescriptionWidth, hdpx(6) ]
}

let premiumDescriptionHeader = @() {
  watch = previewGoods
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = premiumDescriptionHeaderBg
  size = const [ premiumDescriptionWidth, premiumDescriptionHeaderHeight ]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc($"charServer/entitlement/PremiumAccount/header",
      {
        days = previewGoods.get()?.rewards.findvalue(@(r) r.gType == G_PREMIUM)?.count ?? 0
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
    size = const [ premiumDescriptionWidth, SIZE_TO_CONTENT ]
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
                size = const [iconSize, iconSize]
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
  size = [FLEX, gamercardHeight]
  valign = ALIGN_CENTER
  children = backButton(closeGoodsPreview)
}

let premiumDescriptionWnd = {
  key = premDescWndUid
  rendObj = ROBJ_SOLID
  size = FLEX
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