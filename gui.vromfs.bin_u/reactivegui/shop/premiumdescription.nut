from "%globalsDarg/darg_library.nut" import *
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")


let premDescWndUid = "prem_desc_wnd_uid"

let isPremiumDescriptionWndVisible = Watched(false)
let premiumDescriptionWidth = sw(50)

let premiumBonusesCfg = Computed(@() serverConfigs.get()?.gameProfile.premiumBonuses)
let bonusMultText = @(v) $"{v}x"
let infoText = Computed(function() {
  if (premiumBonusesCfg.get() == null)
    return null
  let expMul = bonusMultText(premiumBonusesCfg.get()?.expMul || 1.0)
  return loc("charServer/entitlement/PremiumAccount/desc", {
    bonusPlayerExp = expMul
    bonusWp = bonusMultText(premiumBonusesCfg.get()?.wpMul || 1.0)
    bonusUnitExp = expMul
    bonusGold = bonusMultText(premiumBonusesCfg.get()?.goldMul || 1.0)
  })
})

let closePremiumDescriptionWnd = @() isPremiumDescriptionWndVisible.set(false)

let premiumDescription = {
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  size = [ premiumDescriptionWidth, SIZE_TO_CONTENT ]
  children = [
    modalWndHeader(loc("charServer/entitlement/PremiumAccount"))
    {
      padding = hdpx(48)
      size = FLEX_H
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(250)]
      flow = FLOW_HORIZONTAL
      gap = hdpx(48)
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_IMAGE
          image = Picture("ui/gameuiskin/shop_premium_slot.avif:0:P")
          keepAspect = KEEP_ASPECT_FIT
          size = flex()
          minHeight = sh(30)
          margin = const [0, hdpx(32), 0, 0]
        }
        @() {
          watch = infoText
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = const [ pw(70), SIZE_TO_CONTENT ]
          text = infoText.get()
          opacity = 0.8
          parSpacing = hdpx(24)
        }.__update(fontSmall)
      ]
    }
  ]
}

let backBtn = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = backButton(closePremiumDescriptionWnd)
}

let premiumDescriptionWnd = {
  size = flex()
  padding = saBordersRv
  behavior = Behaviors.Button
  onClick = @() closePremiumDescriptionWnd()
  children = [
    backBtn
    modalWndBg.__merge({ children = premiumDescription })
  ]
}

let premiumDescriptionWndWithBg = bgShadedDark.__merge({
  size = flex()
  onClick = closePremiumDescriptionWnd()
  children = premiumDescriptionWnd
})

isPremiumDescriptionWndVisible.subscribe(function(isOpened) {
  if (isOpened) {
    addModalWindow(premiumDescriptionWndWithBg.__merge({
      key = premDescWndUid
      hotkeys = [[btnBEscUp, { action = closePremiumDescriptionWnd }]]
      onClick = @() closePremiumDescriptionWnd()
    }))
    return
  }
  removeModalWindow(premDescWndUid)
})

return @() isPremiumDescriptionWndVisible.set(true)
