from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene, moveSceneToTop } = require("%rGui/navState.nut")
let { isEventWndOpen, closeEventWnd, eventEndsAt,
  unseenLootboxes, unseenLootboxesShowOnce, markCurLootboxSeen, eventSeasonName, eventSeason,
  eventWndShowAnimation, eventWndOpenCount } = require("eventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkTimeUntil } = require("%rGui/quests/questsComps.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { lootboxInfo, progressBar, mkLootboxImageWithTimer, mkPurchaseBtns, mkSmokeBg, lootboxHeight,
 smallChestIcon, lootboxInfoSize, leaderbordBtn, questsBtn } = require("eventPkg.nut")
let { eventLootboxes } = require("eventLootboxes.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD, WARBOND, EVENT_KEY } = require("%appGlobals/currenciesState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { buy_lootbox } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { isEmbeddedBuyCurrencyWndOpen } = require("buyEventCurrenciesState.nut")
let { buyEventCurrenciesHeader, mkEventCurrenciesGoods, buyEventCurrenciesGamercard
} = require("buyEventCurrenciesComps.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { backButton, backButtonWidth } = require("%rGui/components/backButton.nut")
let { openNewsWndTagged } = require("%rGui/news/newsState.nut")
let { infoRhombButton } = require("%rGui/components/infoButton.nut")
let { has_leaderboard } = require("%appGlobals/permissions.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let lootboxPreviewContent = require("%rGui/shop/lootboxPreviewContent.nut")
let { isEmbeddedLootboxPreviewOpen, openEmbeddedLootboxPreview, closeLootboxPreview, previewLootbox
} = require("%rGui/shop/lootboxPreviewState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let MAX_LOOTBOXES_AMOUNT = 3
let headerGap = hdpx(30)

let aTimeOpacity = 0.8
let opacityAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = aTimeOpacity, easing = OutQuad, trigger = "eventContentReveal" }
]

isEmbeddedBuyCurrencyWndOpen.subscribe(@(_) anim_start("eventContentReveal"))

let function getStepsToNextFixed(lootbox, sConfigs, sProfile) {
  let { rewardsCfg = null } = sConfigs
  let stepsFinished = sProfile?.lootboxStats[lootbox?.name].opened ?? 0
  local stepsToNext = 0
  foreach (steps, id in (lootbox?.fixedRewards ?? {}))
    if (steps.tointeger() > stepsFinished
        && (steps.tointeger() < stepsToNext || stepsToNext == 0)
        && id in rewardsCfg
        && !isRewardEmpty(rewardsCfg[id], sProfile))
      stepsToNext = steps.tointeger()
  return [stepsFinished, stepsToNext]
}

let function onPurchase(lootbox, price, currencyId, text, count = 1) {
  let { name, timeRange = null } = lootbox
  let { start = 0, end = 0 } = timeRange
  let errMsg = start > serverTime.value
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.value) })
    : end > 0 && end < serverTime.value ? loc("lootbox/noLongerAvailable")
    : null
  if (errMsg != null) {
    openMsgBox({ text = errMsg })
    return
  }

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, text) }),
    { price, currencyId },
    @() buy_lootbox(name, currencyId, price.tointeger(), count.tointeger()),
    mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, name))
}

let mkRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(8)
  valign = ALIGN_CENTER
  children
}

let progressHeight = hdpx(80)
let mkProgress = @(stepsToFixed) @() {
  size = [SIZE_TO_CONTENT, progressHeight]
  watch = stepsToFixed
  flow = FLOW_VERTICAL
  children = stepsToFixed.value[1] - stepsToFixed.value[0] <= 0 ? null : [
    mkRow([
      smallChestIcon
      { size = [0, 0] }
      {
        rendObj = ROBJ_TEXT
        text = loc("events/jackpot")
      }.__update(fontTiny)
      {
        rendObj = ROBJ_TEXT
        text = stepsToFixed.value[1] - stepsToFixed.value[0]
      }.__update(fontTiny)
    ])
    progressBar(stepsToFixed.value[0], stepsToFixed.value[1], { margin = [hdpx(20), 0, hdpx(10), 0] })
  ]
}

let mkProgressFull = @(stepsToFixed) @() {
  watch = stepsToFixed
  pos = [backButtonWidth + headerGap, hdpx(20)]
  flow = FLOW_VERTICAL
  children = stepsToFixed.value[1] - stepsToFixed.value[0] <= 0 ? null : [
    mkRow([
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("events/jackpot"))
      }.__update(fontVeryTinyAccented)
      {
        rendObj = ROBJ_TEXT
        text = stepsToFixed.value[1] - stepsToFixed.value[0]
      }.__update(fontVeryTinyAccented)
    ])
    progressBar(stepsToFixed.value[0], stepsToFixed.value[1], { margin = [hdpx(10), 0] })
    mkRow([
      {
        maxWidth = hdpx(400)
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("events/guaranteedReward")
      }.__update(fontVeryTiny)
      smallChestIcon
    ])
  ]
}

let function mkLootboxBlock(lootbox, blockSize) {
  let { name, sizeMul, timeRange = null } = lootbox
  let stateFlags = Watched(0)
  let lootboxImage = mkLootboxImageWithTimer(name, blockSize, timeRange, sizeMul)
  let stepsToFixed = Computed(@() getStepsToNextFixed(lootbox, serverConfigs.value, servProfile.value))

  return @() {
    watch = stateFlags
    onElemState = @(sf) stateFlags(sf)
    size = [blockSize, lootboxInfoSize[1] + lootboxHeight + progressHeight]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    function onClick() {
      openEmbeddedLootboxPreview(name)
      markCurLootboxSeen(name)
    }
    sound = { click  = "click" }
    children = [
      lootboxInfo(lootbox, stateFlags.value)

      @() {
        watch = [unseenLootboxes, unseenLootboxesShowOnce]
        size = [lootboxInfoSize[0], 0]
        hplace = ALIGN_CENTER
        children = name in unseenLootboxes.value || unseenLootboxesShowOnce.value?[name]
            ? priorityUnseenMark
          : null
      }

      {
        transform = { scale = (stateFlags.value & S_HOVER) != 0 ? [0.9, 0.9] : [1, 1] }
        transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = Linear }]
        children = lootboxImage
      }

      mkProgress(stepsToFixed)
    ]
  }
}

let function onClose() {
  if (isEmbeddedLootboxPreviewOpen.value)
    closeLootboxPreview()
  else {
    eventWndShowAnimation(true)
    closeEventWnd()
    unseenLootboxesShowOnce({})
  }
}

let eventGamercard = {
  size = [saSize[0], gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = headerGap
  children = [
    backButton(onClose)
    {
      flow = FLOW_VERTICAL
      gap = hdpx(-10)
      vplace = ALIGN_TOP
      valign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = headerGap
          valign = ALIGN_BOTTOM
          children = [
            @() {
              watch = eventSeasonName
              rendObj = ROBJ_TEXT
              text = eventSeasonName.value
            }.__update(fontBig)

            infoRhombButton(function() {
              eventWndShowAnimation(true)
              openNewsWndTagged(eventSeason.value)
            })
          ]
        }

        @() {
          watch = [serverTime, eventEndsAt]
          children = !eventEndsAt.value || (eventEndsAt.value - serverTime.value < 0) ? null
            : mkTimeUntil(secondsToHoursLoc(eventEndsAt.value - serverTime.value),
                "quests/untilTheEnd",
                { margin = [hdpx(20), 0, hdpx(60), 0] }.__update(fontTinyAccented))
        }
      ]
    }
    { size = flex() }
    mkCurrenciesBtns([WARBOND, EVENT_KEY, WP, GOLD])
  ]
}

let function eventWndContent() {
  let blockSize = Computed(@() min(saSize[0] / min(eventLootboxes.value.len(), MAX_LOOTBOXES_AMOUNT), hdpx(700)))
  let stepsToFixed = Computed(@() getStepsToNextFixed(previewLootbox.value, serverConfigs.value, servProfile.value))

  return @() {
    watch = [isEmbeddedBuyCurrencyWndOpen, isEmbeddedLootboxPreviewOpen]
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    children = isEmbeddedBuyCurrencyWndOpen.value
        ? [
            buyEventCurrenciesGamercard
            {
              size = flex()
              flow = FLOW_VERTICAL
              valign = ALIGN_CENTER
              children = [
                buyEventCurrenciesHeader
                mkEventCurrenciesGoods
              ]
            }
          ]
      : [eventGamercard].extend(isEmbeddedLootboxPreviewOpen.value
          ?
            [
              {
                size = flex()
                flow = FLOW_VERTICAL
                halign = ALIGN_CENTER
                children = [
                  {
                    key = {}
                    size = flex()
                    children = [
                      mkProgressFull(stepsToFixed)
                      lootboxPreviewContent
                    ]
                    animations = wndSwitchAnim
                  }
                  @() {
                    watch = previewLootbox
                    children = mkPurchaseBtns(previewLootbox.value, onPurchase)
                  }
                ]
              }
            ]
        : [
            @() {
              watch = [eventLootboxes, blockSize]
              size = flex()
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = eventLootboxes.value.map(@(v) mkLootboxBlock(v, blockSize.value))
              animations = wndSwitchAnim
            }

            {
              key = {}
              size = [flex(), SIZE_TO_CONTENT]
              valign = ALIGN_CENTER
              flow = FLOW_HORIZONTAL
              gap = headerGap
              children = [
                questsBtn

                @() {
                  watch = has_leaderboard
                  size = [SIZE_TO_CONTENT, defButtonHeight]
                  children = !has_leaderboard.value ? null : leaderbordBtn
                }

                { size = flex() }

                {
                  rendObj = ROBJ_TEXT
                  text = loc("events/tapToSelect")
                }.__update(fontMedium)
              ]
              animations = wndSwitchAnim
            }
          ])
    animations = opacityAnim
  }
}

let eventWnd = @() {
  watch = eventWndShowAnimation
  key = {}
  size = flex()
  children = [
    mkSmokeBg(isEventWndOpen)
    eventWndContent()
  ]
  animations = eventWndShowAnimation.value ? wndSwitchAnim : null
  onAttach = @() eventWndShowAnimation(false)
}

registerScene("eventWnd", eventWnd, closeEventWnd, isEventWndOpen)
eventWndOpenCount.subscribe(@(_) moveSceneToTop("eventWnd"))
