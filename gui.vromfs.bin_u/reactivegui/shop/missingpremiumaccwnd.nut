from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bgShadedDark, bgHeader, bgMessage } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { textButtonPurchase, textButtonBattle } = require("%rGui/components/textButton.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { havePremium, premiumEndsAt } = require("%rGui/state/profilePremium.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { register_command } = require("console")

let premIconW = hdpxi(182)
let premIconH = hdpxi(126)
let TIME_RESHOWING_WND = 7 * TIME_DAY_IN_SECONDS

let WND_UID = "notPremWnd"
let SAVE_TIME_LAST_PREM_WND_SHOW = "timeLastPremWndShow"

function close(){
  removeModalWindow(WND_UID)
  get_local_custom_settings_blk()[SAVE_TIME_LAST_PREM_WND_SHOW] = serverTime.value
}


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
    bonusGold = bonusMultText(premiumBonusesCfg.get()?.goldMul || 1.0)
  })
})

let premHeader = bgHeader.__merge({
  size = [ flex(), sh(8) ]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("premBuyWnd/header")
  }.__update(fontMedium)
})

let premDesc = @() infoText.value
  ? {
    watch = infoText
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    margin = [hdpx(20), hdpx(48), hdpx(50), hdpx(48)]
    text = infoText.value
    color = 0xC0C0C0C0
    parSpacing = hdpx(10)
  }.__update(fontTinyAccented)
  : { watch = infoText }

let premIcon = {
  rendObj = ROBJ_IMAGE
  size = [premIconW, premIconH]
  vplace = ALIGN_CENTER
  margin = [hdpx(20), 0, hdpx(50), 0]
  image = Picture($"ui/gameuiskin#premium_active_big.avif:{premIconW}:{premIconH}:P")
}

let buttons = @(toBattle){
  flow = FLOW_HORIZONTAL
  gap = hdpx(50)
  margin = [hdpx(20), hdpx(48), hdpx(48), hdpx(48)]
  children = [
    textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
      function() {
        close()
        toBattle()
      },
      { hotkeys = ["^J:X"] })
    textButtonPurchase(loc("premBuyWnd/activeBtn"),
      function(){
        close()
        openShopWnd(SC_PREMIUM)
      },
      { hotkeys = ["^J:Y"] })
  ]
}

let window = @(toBattle){
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    premHeader
    premIcon
    premDesc
    buttons(toBattle)
  ]
}

let showNoPremWnd = @(toBattle) addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  onClick = close
  children = {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [ bgMessage.__merge(window(toBattle)) ]
  }
  animations = wndSwitchAnim
}))

function showNoPremMessageIfNeed(toBattle){
  if (havePremium.value){
    toBattle()
    return
  }

  if((serverTime.value - (get_local_custom_settings_blk()?[SAVE_TIME_LAST_PREM_WND_SHOW] ?? 0) >= TIME_RESHOWING_WND)
      && premiumEndsAt.value) {
    showNoPremWnd(toBattle)
    return
  }
  toBattle()
}

register_command(
  function(){
    get_local_custom_settings_blk()[SAVE_TIME_LAST_PREM_WND_SHOW] = 0
    eventbus_send("saveProfile", {})
  },
  "ui.resetPremiumSuggestShow"
)

return showNoPremMessageIfNeed

