from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getSubsPresentation } = require("%appGlobals/config/subsPresentation.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeader } = require("%rGui/components/modalWnd.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { allow_subscriptions } = require("%appGlobals/permissions.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { textButtonPurchase, textButtonBattle } = require("%rGui/components/textButton.nut")
let { urlLikeButton } = require("%rGui/components/urlText.nut")
let { openShopWnd, subsByCategory } = require("%rGui/shop/shopState.nut")
let { openSubsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { SC_PREMIUM } = require("%rGui/shop/shopCommon.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { havePremium, premiumEndsAt, isSubsWasActive } = require("%rGui/state/profilePremium.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { register_command } = require("console")
let { premiumRowsCfg, vipRowsCfg, mkBonusRow, textColor } = require("%rGui/shop/goodsPreview/subscriptionDescComp.nut")

let premIconW = hdpxi(182)
let premIconH = hdpxi(126)
let subsIconW = premIconW * 2
let subsIconH = premIconH * 2
let TIME_RESHOWING_WND = 7 * TIME_DAY_IN_SECONDS

let WND_UID = "notPremWnd"
let SAVE_TIME_LAST_PREM_WND_SHOW = "timeLastPremWndShow"

function close() {
  removeModalWindow(WND_UID)
  get_local_custom_settings_blk()[SAVE_TIME_LAST_PREM_WND_SHOW] = serverTime.get()
}

function openSubsWnd() {
  close()
  if (allow_subscriptions.get())
    foreach (sList in subsByCategory.get())
      if (sList.len() > 0) {
        openSubsPreview(sList.top().id, "missing_prem_acc")
        return
      }
  openShopWnd(SC_PREMIUM)
}

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

let mkInfoText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  text
  color = textColor
  parSpacing = hdpx(10)
}.__update(fontSmall, ovr)

let mkBonusRows = function(rowsCfg, cfgWatch) {
  let rowsToShow = rowsCfg.filter(@(a) a?.isBattleAdv)
  let hiddenAdvCount = rowsCfg.len() - rowsToShow.len() + vipRowsCfg.len()
  return @() {
    watch = cfgWatch
    size = [hdpx(900), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = rowsToShow.map(@(a) mkBonusRow(a, cfgWatch.get()))
      .append(urlLikeButton(
        loc("subscription/desc/advantage", { count = hiddenAdvCount }),
        openSubsWnd,
        { ovr = { color = textColor }.__update(fontSmall) }))
  }}

let premDesc = @() {
  watch = [infoText, allow_subscriptions]
  margin = const [hdpx(20), 0, hdpx(50), 0]
  children = allow_subscriptions.get() ? mkBonusRows(premiumRowsCfg, premiumBonusesCfg)
    : infoText.get() != null ? mkInfoText(infoText.get())
    : null
}

let premIcon = @() {
  watch = allow_subscriptions
  rendObj = ROBJ_IMAGE
  size = allow_subscriptions.get() ? [subsIconW, subsIconH] : [premIconW, premIconH]
  vplace = ALIGN_CENTER
  margin = const [hdpx(20), 0, hdpx(50), 0]
  image = allow_subscriptions.get()
    ? Picture($"{getSubsPresentation("vip").image}:{subsIconW}:{subsIconH}:P")
    : Picture($"ui/gameuiskin#premium_active_big.avif:{premIconW}:{premIconH}:P")
  keepAspect = true
}

let modalHeader = @() {
  watch = allow_subscriptions
  size = FLEX_H
  children = modalWndHeader(loc(allow_subscriptions.get() ? "subscription/desc/inactive" : "premBuyWnd/header"))
}

let buttons = @(toBattle) @() {
  watch = allow_subscriptions
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  children = [
    textButtonPurchase(
      utf8ToUpper(allow_subscriptions.get() ? loc("subscription/viewSubsPlans") : loc("premBuyWnd/activeBtn")),
      openSubsWnd,
      { hotkeys = ["^J:Y"] })
    textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
      function() {
        close()
        toBattle()
      },
      { hotkeys = ["^J:X"] })
  ]
}

let window = @(toBattle) {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = const [0, hdpx(48), hdpx(48), hdpx(48)]
  children = [
    modalHeader
    @() {
      watch = allow_subscriptions
      halign = ALIGN_CENTER
      flow = allow_subscriptions.get() ? FLOW_HORIZONTAL : FLOW_VERTICAL
      children = allow_subscriptions.get() ? [ premDesc, premIcon ]
        : [ premIcon, premDesc ]
    }
    buttons(toBattle)
  ]
}

let showNoPremWnd = @(toBattle) addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  onClick = close
  children = modalWndBg.__merge(window(toBattle))
  animations = wndSwitchAnim
}))

function showNoPremMessageIfNeed(toBattle) {
  if (havePremium.get()) {
    toBattle()
    return
  }

  if((serverTime.get() - (get_local_custom_settings_blk()?[SAVE_TIME_LAST_PREM_WND_SHOW] ?? 0) >= TIME_RESHOWING_WND)
      && (premiumEndsAt.get() || isSubsWasActive.get())) {
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

