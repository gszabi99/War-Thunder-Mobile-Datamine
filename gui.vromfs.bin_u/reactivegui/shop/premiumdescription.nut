from "%globalsDarg/darg_library.nut" import *
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")


let premDescWndUid = "prem_desc_wnd_uid"

let isPremiumDescriptionWndVisible = Watched(false)
let premiumDescriptionWndBg = 0xDC000000
let premiumDescriptionWidth = sw(50)
let premiumDescriptionHeaderHeight = sh(8)
let premiumDescriptionHeaderBg = 0x0A585858
let premiumDescriptionDecorativeLineBg = 0xFFD4D4D4

let premiumBonusesCfg = Computed(@() serverConfigs.value?.gameProfile.premiumBonuses)
let bonusMultText = @(v) $"{v}x"
let infoText = Computed(function() {
  if (premiumBonusesCfg.value == null)
    return null
  let expMul = bonusMultText(premiumBonusesCfg.value?.expMul || 1.0)
  return loc("charServer/entitlement/PremiumAccount/desc", {
    bonusPlayerExp = expMul
    bonusWp = bonusMultText(premiumBonusesCfg.value?.wpMul || 1.0)
    bonusUnitExp = expMul
  })
})

let closePremiumDescriptionWnd = @() isPremiumDescriptionWndVisible(false)

let decorativeLine = {
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = premiumDescriptionDecorativeLineBg
  size = [ premiumDescriptionWidth, hdpx(6) ]
}

let premiumDescriptionHeader = {
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = premiumDescriptionHeaderBg
  size = [ premiumDescriptionWidth, premiumDescriptionHeaderHeight ]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = { rendObj = ROBJ_TEXT, text = loc("charServer/entitlement/PremiumAccount") }.__update(fontMedium)
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
      padding = [ hdpx(24), 0 ]
      size = [ flex(), SIZE_TO_CONTENT ]
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(250)]
      color = premiumDescriptionWndBg
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_IMAGE
          image = Picture("ui/gameuiskin/shop_premium_slot.avif")
          keepAspect = KEEP_ASPECT_FIT
          size = flex()
          minHeight = sh(30)
          margin = [0, hdpx(32), 0, 0]
        }
        @() {
          watch = infoText
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [ pw(70), SIZE_TO_CONTENT ]
          text = infoText.value
          opacity = 0.8
          parSpacing = hdpx(24)
        }.__update(fontSmall)
      ]
    }
    decorativeLine
  ]
}

let backBtn = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = backButton(closePremiumDescriptionWnd)
}

let premiumDescriptionWnd = {
  rendObj = ROBJ_SOLID
  size = flex()
  color = premiumDescriptionWndBg
  padding = saBordersRv
  behavior = Behaviors.Button
  onClick = @() closePremiumDescriptionWnd()
  children = [
    backBtn
    premiumDescription
  ]
}

isPremiumDescriptionWndVisible.subscribe(function(isOpened) {
  if (isOpened) {
    addModalWindow(premiumDescriptionWnd.__merge({
      key = premDescWndUid
      hotkeys = [[btnBEscUp, { action = closePremiumDescriptionWnd }]]
      onClick = @() closePremiumDescriptionWnd()
    }))
    return
  }
  removeModalWindow(premDescWndUid)
})

return @() isPremiumDescriptionWndVisible(true)
