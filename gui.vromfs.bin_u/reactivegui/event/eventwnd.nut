from "%globalsDarg/darg_library.nut" import *
let { abs } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isEventWndOpen, closeEventWnd, curLootbox, curLootboxIndex, closeLootboxWnd, eventRewards
 } = require("eventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { timeUntilTheEnd } = require("%rGui/quests/questsComps.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { lootboxInfo, progressBar, mkLootboxWndBtn, mkLootboxImage, mkPurchaseBtns, mkSmokeBg,
  hideAnimation, revealAnimation, slideTransition } = require("eventComps.nut")
let { eventLootboxes } = require("eventLootboxes.nut")
let { mkGoodsTimeTimeProgress } = require("%rGui/shop/goodsView/sharedParts.nut")
let { gamercardHeight, mkLeftBlock, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD, WARBOND, EVENT_KEY } = require("%appGlobals/currenciesState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { buy_lootbox, lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")


// TODO: add real time and real GUARANTEED_AFTER
let fakeTime = 100000
let GUARANTEED_AFTER = 5
let MAX_LOOTBOXES_AMOUNT = 4
let blockSize = min(saSize[0] / MAX_LOOTBOXES_AMOUNT, hdpx(500))

let spinner = mkSpinner(hdpx(100))

let function onPurchase(id, price, currencyId, text, count = 1) {
  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, text) }),
    { price, currencyId },
    @() buy_lootbox(id, currencyId, price.tointeger(), count.tointeger()),
    mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, id))
}

let function mkLootboxBlock(lootbox, idx) {
  let { name, adRewardId = null } = lootbox
  let isCurrent = Computed(@() curLootbox.value == name)
  let isActive = Computed(@() isCurrent.value || !curLootbox.value)
  let middleIdx = Computed(@() (eventLootboxes.value.len() - 1.0) / 2)
  let translateX = Computed(@() blockSize * (
    isActive.value && !isCurrent.value ? 0
      : isCurrent.value ? (middleIdx.value - idx)
      : 0.6 / (idx - curLootboxIndex.value) / max(abs(idx - middleIdx.value), 0.5)))
  let needAdtimeProgress = Computed(@() !lootboxInProgress.value
    && adRewardId != null
    && curLootbox.value == name
    && !eventRewards.value?[adRewardId].isReady)

  isActive.subscribe(@(v) anim_start(v ? $"lootbox_reveal_{name}" : $"lootbox_hide_{name}"))

  return @() {
    watch = [isCurrent, isActive, translateX]
    size = [blockSize, flex()]
    pos = [blockSize * idx, 0]
    opacity = isActive.value ? 1.0 : 0.0
    animations = [].extend(
      hideAnimation($"lootbox_hide_{name}"),
      revealAnimation($"lootbox_reveal_{name}"))
    transform = { translate = [translateX.value, 0] }
    transitions = slideTransition
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      lootboxInfo(lootbox.rewards)
      {
        children = [
          mkLootboxImage(name, lootbox?.size)
          @() {
            watch = [needAdtimeProgress, eventRewards, lootboxInProgress]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            children = [
              lootboxInProgress.value ? spinner : null
              !needAdtimeProgress.value ? null
                : mkGoodsTimeTimeProgress(eventRewards.value?[adRewardId])
            ]
          }
        ]
      }
    ].extend(isCurrent.value
        ? [
            { size = [0, hdpx(50)] }
            mkPurchaseBtns(lootbox, onPurchase)
          ]
      : [
          // TODO: add lootbox SVG
          {
            rendObj = ROBJ_TEXT
            text = !lootbox?.hasGuaranteed ? ""
              : "".concat(utf8ToUpper(loc("events/guaranteedPrize")), " ", GUARANTEED_AFTER)
          }.__update(fontVeryTiny)
          progressBar(lootbox?.stepsFinished, lootbox?.stepsTotal, { margin = [hdpx(20), 0, hdpx(10), 0] })
          mkLootboxWndBtn(@() curLootbox(name), lootbox?.adRewardId != null, lootbox.currencyId)
        ])
  }
}

let eventGamercard = @() {
  watch = curLootbox
  size = [saSize[0], gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkLeftBlock(!curLootbox.value ? closeEventWnd : closeLootboxWnd)
    { size = flex() }
    mkCurrenciesBtns([WARBOND, EVENT_KEY, WP, GOLD])
  ]
}

let eventWnd = {
  key = {}
  size = flex()
  children = [
    mkSmokeBg(isEventWndOpen)
    {
      padding = saBordersRv
      flow = FLOW_VERTICAL
      children = [
        eventGamercard
        timeUntilTheEnd(secondsToHoursLoc(fakeTime), { hplace = ALIGN_CENTER, margin = [hdpx(20), 0, hdpx(60), 0] })
        @() {
          size = [eventLootboxes.value.len() * blockSize, flex()]
          hplace = ALIGN_CENTER
          watch = eventLootboxes
          children = eventLootboxes.value.map(@(v, idx) mkLootboxBlock(v, idx))
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("eventWnd", eventWnd, closeEventWnd, isEventWndOpen)
