from "%globalsDarg/darg_library.nut" import *
let { abs } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene, moveSceneToTop } = require("%rGui/navState.nut")
let { isEventWndOpen, closeEventWnd, curLootbox, curLootboxIndex, closeLootboxWnd, eventRewards, eventEndsAt,
  unseenLootboxes, unseenLootboxesShowOnce, openLootboxPreviewWnd, openLootboxWnd, eventSeasonName, eventSeason,
  eventWndShowAnimation, eventWndOpenCount } = require("eventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkTimeUntil } = require("%rGui/quests/questsComps.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { lootboxInfo, progressBar, mkLootboxWndBtn, mkLootboxImageWithTimer, mkClickable, mkPurchaseBtns, mkSmokeBg,
  hideAnimation, revealAnimation, slideTransition, smallChestIcon, lootboxInfoSize
} = require("eventPkg.nut")
let { eventLootboxes } = require("eventLootboxes.nut")
let { mkGoodsTimeTimeProgress } = require("%rGui/shop/goodsView/sharedParts.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD, WARBOND, EVENT_KEY } = require("%appGlobals/currenciesState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { buy_lootbox, lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
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
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { openLbWnd } = require("%rGui/leaderboard/lbState.nut")
let lootboxPreviewContent = require("%rGui/shop/lootboxPreviewContent.nut")
let { isEmbeddedLootboxPreviewOpen, closeLootboxPreview, previewLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let MAX_LOOTBOXES_AMOUNT = 3
let headerGap = hdpx(30)

let aTimeOpacity = 0.8
let opacityAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = aTimeOpacity, easing = OutQuad, trigger = "eventContentReveal" }
]

isEmbeddedBuyCurrencyWndOpen.subscribe(@(_) anim_start("eventContentReveal"))

let spinner = mkSpinner(hdpx(100))

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

let mkProgress = @(stepsToFixed) @() {
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

let function mkLootboxBlock(lootbox, idx, blockSize) {
  let { name, adRewardId = null, sizeMul, timeRange = null } = lootbox
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
  let lootboxImage = mkLootboxImageWithTimer(name, blockSize, timeRange, sizeMul)

  let stepsToFixed = Computed(@() getStepsToNextFixed(lootbox, serverConfigs.value, servProfile.value))

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
      mkClickable(lootboxInfo(lootbox), @() openLootboxPreviewWnd(name))
      {
        children = [
          @() {
            watch = isActive
            children = isActive.value
                ? mkClickable(lootboxImage, @() openLootboxWnd(name))
              : lootboxImage
          }

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

          @() {
            watch = [unseenLootboxes, unseenLootboxesShowOnce]
            size = [lootboxInfoSize[0], 0]
            hplace = ALIGN_CENTER
            children = name in unseenLootboxes.value || unseenLootboxesShowOnce.value?[name]
                ? priorityUnseenMark
              : null
          }

          {
            size = [lootboxInfoSize[0], 0]
            pos = [hdpx(15), hdpx(-10)]
            hplace = ALIGN_CENTER
            halign = ALIGN_RIGHT
            children = infoRhombButton(@() openLootboxPreviewWnd(name), { size = [hdpx(65), hdpx(65)] })
          }
        ]
      }
      { size = flex() }
    ].extend(isCurrent.value
        ? [mkPurchaseBtns(lootbox, onPurchase)]
      : [
          mkProgress(stepsToFixed)
          mkLootboxWndBtn(@() isActive.value ? openLootboxWnd(name) : null, lootbox?.adRewardId != null, lootbox.currencyId)
        ])
  }
}

let function onClose() {
  if (isEmbeddedLootboxPreviewOpen.value)
    closeLootboxPreview()
  else if (!curLootbox.value) {
    eventWndShowAnimation(true)
    closeEventWnd()
    unseenLootboxesShowOnce({})
  }
  else
    closeLootboxWnd()
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
    gap = hdpx(20)
    children = isEmbeddedBuyCurrencyWndOpen.value
        ? [
            buyEventCurrenciesGamercard
            buyEventCurrenciesHeader
            mkEventCurrenciesGoods
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
                    size = flex()
                    children = [
                      mkProgressFull(stepsToFixed)
                      lootboxPreviewContent
                    ]
                  }
                  @() {
                    watch = previewLootbox
                    children = mkPurchaseBtns(previewLootbox.value, onPurchase)
                  }
                ]
                animations = wndSwitchAnim
              }
            ]
        : [
            @() {
              watch = has_leaderboard
              size = [SIZE_TO_CONTENT, defButtonHeight]
              children = !has_leaderboard.value ? null
                : textButtonCommon(loc("mainmenu/titleLeaderboards"), openLbWnd)
              animations = wndSwitchAnim
            }
            @() {
              watch = [eventLootboxes, blockSize]
              size = [eventLootboxes.value.len() * blockSize.value, flex()]
              hplace = ALIGN_CENTER
              children = eventLootboxes.value.map(@(v, idx) mkLootboxBlock(v, idx, blockSize.value))
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
  onDetach = closeLootboxPreview
}

registerScene("eventWnd", eventWnd, closeEventWnd, isEventWndOpen)
eventWndOpenCount.subscribe(@(_) moveSceneToTop("eventWnd"))
