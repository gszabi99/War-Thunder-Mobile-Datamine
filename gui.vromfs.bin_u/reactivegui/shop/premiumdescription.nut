from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeader
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/style/backgrounds.nut" import bgShadedDark
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/gradients.nut" import gradDoubleTexOffset


const premDescWndUid = "prem_desc_wnd_uid"

let isPremiumDescriptionWndVisible = Watched(false)
const premiumDescriptionWidth = sw(70)

let premiumBonusesCfg = Computed(@() serverConfigs.get()?.gameProfile.premiumBonuses)
let bonusMultText = @(v) $"{v}x"
let infoText = Computed(function() {
  if (premiumBonusesCfg.get() == null)
    return null
  let expMul = bonusMultText(premiumBonusesCfg.get()?.expMul ?? 1.0)
  return loc("charServer/entitlement/PremiumAccount/desc", {
    bonusPlayerExp = expMul
    slotExpMul = expMul
    decalsSlots = "+2"
    bonusWp = bonusMultText(premiumBonusesCfg.get()?.wpMul ?? 1.0)
    bonusUnitExp = expMul
    bonusGold = bonusMultText(premiumBonusesCfg.get()?.goldMul ?? 1.0)
  })
})

let closePremiumDescriptionWnd = @() isPremiumDescriptionWndVisible.set(false)

let premiumDescription = {
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  size = const [ premiumDescriptionWidth, SIZE_TO_CONTENT ]
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
          size = FLEX
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
  size = [FLEX, gamercardHeight]
  valign = ALIGN_CENTER
  children = backButton(closePremiumDescriptionWnd)
}

let premiumDescriptionWnd = {
  size = FLEX
  padding = saBordersRv
  behavior = Behaviors.Button
  onClick = @() closePremiumDescriptionWnd()
  children = [
    backBtn
    modalWndBg.__merge({ children = premiumDescription })
  ]
}

let premiumDescriptionWndWithBg = bgShadedDark.__merge({
  size = FLEX
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
