from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { G_CURRENCY } = require("%appGlobals/rewardType.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { get_premium_daily_bonus, isPremBonusInProgress, registerHandler
} = require("%appGlobals/pServer/pServerApi.nut")
let { getSubsPresentation } = require("%appGlobals/config/subsPresentation.nut")
let { hasPremDailyBonus, canReceivePremDailyBonus, hasPremiumSubs } = require("%rGui/state/profilePremium.nut")

let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { textButtonPrimary, textButtonPurchase, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonMinWidth, defButtonHeight } = buttonStyles
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { bgShadedDark } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { btnBEscUp, btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate, mkRewardReceivedMark
} = require("%rGui/rewards/rewardPlateComp.nut")
let { openSubsPreview } = require("goodsPreviewState.nut")


let WND_UID = "premDailyBonusWnd"
let isOpened = mkWatched(persist, "isOpened", false)

let wndGap = hdpx(40)
let iconSize = [(REWARD_STYLE_MEDIUM.boxSize * 1.4 + 0.5).tointeger(), REWARD_STYLE_MEDIUM.boxSize]

let close = @() isOpened.set(false)

registerHandler("closePremDailyBonusWnd", @(res) res?.error == null ? close() : null)

let reward = @() {
  watch = [serverConfigs, hasPremDailyBonus]
  children = [
    mkRewardPlate(
      { id = GOLD, rType = G_CURRENCY, count = serverConfigs.get()?.gameProfile.premiumBonuses.dailyGold ?? 0, slots = 1 },
      REWARD_STYLE_MEDIUM)
    hasPremDailyBonus.get() ? null
      : mkRewardReceivedMark(REWARD_STYLE_MEDIUM)
  ]
}

let rewardBlock = @() {
  watch = [hasPremiumSubs, canReceivePremDailyBonus]
  size = [defButtonMinWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = wndGap
  children = [
    reward
    !hasPremiumSubs.get() ? null
      : canReceivePremDailyBonus.get()
        ? mkSpinnerHideBlock(isPremBonusInProgress,
            textButtonPrimary(utf8ToUpper(loc("msgbox/btn_get")),
              @() get_premium_daily_bonus("closePremDailyBonusWnd"),
              { hotkeys = [btnAUp] }),
            { size = [flex(), defButtonHeight], halign = ALIGN_CENTER, valign = ALIGN_CENTER })
      : {
          size = [flex(), defButtonHeight]
          rendObj = ROBJ_TEXTAREA
          text = loc("RewardReceived")
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
        }.__update(fontSmall)
  ]
}

let promoBlock = {
  size = [defButtonMinWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = wndGap
  children = [
    {
      size = iconSize
      rendObj = ROBJ_IMAGE
      image = Picture($"{getSubsPresentation("vip").icon}:0:P")
      keepAspect = true
    }
    textButtonPurchase(utf8ToUpper(loc("subscription/activate")),
      @() openSubsPreview("vip"),
      { hotkeys = [btnAUp] })
  ]
}

let window = @() modalWndBg.__merge({
  watch = hasPremiumSubs
  size = [2 *defButtonMinWidth + 3 * wndGap, SIZE_TO_CONTENT]
  padding = [0, 0, wndGap, 0]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = wndGap
  children = [
    modalWndHeaderWithClose(loc("premDailyBonus/header"), close)
    hasPremiumSubs.get() ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          margin = [0, wndGap]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text = loc("subscrition/activateForDailyGold")
        }.__update(fontSmall)
    hasPremiumSubs.get() ? rewardBlock
      : {
          flow = FLOW_HORIZONTAL
          gap = wndGap
          children = [
            rewardBlock
            promoBlock
          ]
        }
  ]
})

let openImpl = @() addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  hotkeys = [[btnBEscUp, { action = close, description = loc("mainmenu/btnClose") }]]
  onClick = close
  children = window
  animations = wndSwitchAnim
}))

if (isOpened.get())
  openImpl()
isOpened.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @() isOpened.set(true)