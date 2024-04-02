from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene, setSceneBg, setSceneBgFallback } = require("%rGui/navState.nut")
let { eventWndOpenCounter, closeEventWnd, curEventEndsAt,
  unseenLootboxes, unseenLootboxesShowOnce, markCurLootboxSeen,
  bestCampLevel, curEventLootboxes, curEventLoc,
  curEvent, MAIN_EVENT_ID, curEventCurrencies, curEventSeason, isCurEventActive,
  eventBgFallback, curEventBg, curEventName
} = require("eventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkTimeUntil } = require("%rGui/quests/questsPkg.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { lootboxInfo, progressBar, mkLootboxImageWithTimer, mkPurchaseBtns, lootboxHeight,
 smallChestIcon, leaderbordBtn, questsBtn } = require("eventPkg.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { buy_lootbox, lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { openNewsWndTagged } = require("%rGui/news/newsState.nut")
let { infoRhombButton } = require("%rGui/components/infoButton.nut")
let { has_leaderboard } = require("%appGlobals/permissions.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { lootboxImageWithTimer, lootboxContentBlock, lootboxHeader } = require("%rGui/shop/lootboxPreviewContent.nut")
let { isEmbeddedLootboxPreviewOpen, openEmbeddedLootboxPreview, closeLootboxPreview, previewLootbox
} = require("%rGui/shop/lootboxPreviewState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { getLootboxSizeMul } = require("%rGui/unlocks/rewardsView/lootboxPresentation.nut")
let { eventbus_send } = require("eventbus")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")


let MAX_LOOTBOXES_AMOUNT = 3
let headerGap = hdpx(30)
let contentGap = hdpx(40)
let rewardsBlockWidth = saSize[0] - 2 * defButtonMinWidth - 2 * contentGap

function getStepsToNextFixed(lootbox, sConfigs, sProfile) {
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

function onPurchase(lootbox, price, currencyId, count = 1) {
  if (lootboxInProgress.get())
    return
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let { start = 0, end = 0 } = timeRange
  let errMsg = bestCampLevel.value < reqPlayerLevel
      ? loc("lootbox/availableAfterLevel", { level = colorize("@mark", reqPlayerLevel) })
    : start > serverTime.value
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.value) })
    : end > 0 && end < serverTime.value ? loc("lootbox/noLongerAvailable")
    : null
  if (errMsg != null) {
    openMsgBox({ text = errMsg })
    return
  }

  if (!showNoBalanceMsgIfNeed(price, currencyId, mkBqPurchaseInfo(PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, name)))
    buy_lootbox(name, currencyId, price.tointeger(), count.tointeger())
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
  halign = ALIGN_CENTER
  children = stepsToFixed.value[1] - stepsToFixed.value[0] <= 0 ? null
    : [
        mkRow([
          smallChestIcon
          { size = [hdpx(10), 0] }
          {
            rendObj = ROBJ_TEXT
            text = loc("events/jackpot")
          }.__update(fontTinyShaded)
          {
            rendObj = ROBJ_TEXT
            text = stepsToFixed.value[1] - stepsToFixed.value[0]
          }.__update(fontTinyShaded)
        ])
        progressBar(stepsToFixed.value[0], stepsToFixed.value[1], { margin = [hdpx(20), 0, hdpx(10), 0] })
      ]
}

let mkProgressFull = @(stepsToFixed) @() {
  watch = stepsToFixed
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
      { size = [hdpx(10), 0] }
      smallChestIcon
    ])
  ]
}

function mkLootboxBlock(lootbox, blockSize) {
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let sizeMul = getLootboxSizeMul(lootbox.meta?.event)
  let stateFlags = Watched(0)
  let lootboxImage = mkLootboxImageWithTimer(name, blockSize, timeRange, reqPlayerLevel, sizeMul)
  let stepsToFixed = Computed(@() getStepsToNextFixed(lootbox, serverConfigs.value, servProfile.value))

  return @() {
    watch = stateFlags
    onElemState = @(sf) stateFlags(sf)
    size = [blockSize, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    function onClick() {
      openEmbeddedLootboxPreview(name)
      markCurLootboxSeen(name)
    }
    sound = { click  = "click" }
    clickableInfo = loc("mainmenu/btnSelect")
    children = [
      lootboxInfo(lootbox, stateFlags.value)

      @() {
        watch = [unseenLootboxes, unseenLootboxesShowOnce, curEventName]
        size = [0, 0]
        transform = { translate = [-0.8 * lootboxHeight * sizeMul, max(0, lootboxHeight * (1.0 - sizeMul) / 2)] }
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = name in unseenLootboxes.value?[curEventName.value] || unseenLootboxesShowOnce.value?[name]
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

function onClose() {
  if (isEmbeddedLootboxPreviewOpen.value)
    closeLootboxPreview()
  else {
    unseenLootboxesShowOnce.set(unseenLootboxesShowOnce.get().filter(@(event) event != curEventName.get()))
    closeEventWnd()
  }
}

isCurEventActive.subscribe(function(isActive) {
  if (isActive)
    return
  if (isEmbeddedLootboxPreviewOpen.value)
    closeLootboxPreview()
  closeEventWnd()
})

function mkCurrencies() {
  let baseCurrencies = [WP, GOLD].filter(@(v) curEventCurrencies.value.findindex(@(c) c == v) == null)
  let res = [].extend(curEventCurrencies.value, baseCurrencies)
  return {
    watch = [curEventCurrencies, curEvent]
    children = mkCurrenciesBtns(res, curEvent.get())
  }
}

let toBattleHint = {
  hplace = ALIGN_RIGHT
  pos = [saBorders[0] * 0.5, 0]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  padding = [saBorders[0] * 0.2, saBorders[0] * 0.5]
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, saBorders[0]]
  color = 0x70000000
  children = {
    size = [defButtonMinWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = loc("events/toBattle")
  }.__update(fontTinyAccented)
}

let mkToBattleButton = @(modeId, modeName) mkToBattleButtonWithSquadManagement(function() {
  sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = modeName })
  eventbus_send("queueToGameMode", { modeId })
})

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
              watch = curEventLoc
              rendObj = ROBJ_TEXT
              text = curEventLoc.value
            }.__update(fontBig)

            infoRhombButton(@() openNewsWndTagged($"event_{curEventName.value}_{curEventSeason.value}"))
          ]
        }

        @() {
          watch = [serverTime, curEventEndsAt]
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          children = !curEventEndsAt.value || (curEventEndsAt.value - serverTime.value < 0) ? null
            : mkTimeUntil(secondsToHoursLoc(curEventEndsAt.value - serverTime.value),
                "quests/untilTheEnd",
                { margin = [hdpx(20), 0, hdpx(60), 0] }.__update(fontTinyAccented))
        }
      ]
    }
    { size = flex() }
    mkCurrencies
  ]
}

function mkLootboxPreviewContent() {
  let progressInfo = mkProgressFull(
    Computed(@() getStepsToNextFixed(previewLootbox.value, serverConfigs.value, servProfile.value)))
  return @() {
    watch = previewLootbox
    size = flex()
    padding = [hdpx(40), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    gap = contentGap
    children = previewLootbox.get() == null ? null
      : [
          lootboxContentBlock(previewLootbox.get(), rewardsBlockWidth)
          {
            size = flex()
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = [
              lootboxHeader(previewLootbox.get())
              lootboxImageWithTimer(previewLootbox.get())
              { size = flex() }
              progressInfo
              { size = [0, hdpx(50)] }
              @() {
                watch = [previewLootbox, lootboxInProgress]
                size = [SIZE_TO_CONTENT, defButtonHeight]
                children = lootboxInProgress.get() ? null : mkPurchaseBtns(previewLootbox.get(), onPurchase)
              }
            ]
          }
        ]
    animations = wndSwitchAnim
  }
}

function eventWndContent() {
  let blockSize = Computed(@() min(saSize[0] / clamp(curEventLootboxes.value.len(), 1, MAX_LOOTBOXES_AMOUNT), hdpx(700)))
  let modeId = Computed(@() allGameModes.get().findindex(@(v) v.tag == curEventName.get()))
  return @() {
    watch = [isEmbeddedLootboxPreviewOpen, modeId]
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    children = [eventGamercard]
      .extend(isEmbeddedLootboxPreviewOpen.value
        ? [ mkLootboxPreviewContent() ]
        : [
            {
              size = flex()
              children = [
                {
                  hplace = ALIGN_CENTER
                  rendObj = ROBJ_TEXT
                  text = loc("events/tapToSelect")
                  animations = wndSwitchAnim
                }.__update(fontMediumShaded)
                {
                  size = flex()
                  children = @() {
                    watch = [curEventLootboxes, blockSize]
                    size = flex()
                    margin = [0, 0, hdpx(120), 0]
                    flow = FLOW_HORIZONTAL
                    hplace = ALIGN_CENTER
                    halign = ALIGN_CENTER
                    valign = ALIGN_CENTER
                    children = curEventLootboxes.get().map(@(v) mkLootboxBlock(v, blockSize.get()))
                    animations = wndSwitchAnim
                  }
                }
                {
                  key = {}
                  size = [flex(), SIZE_TO_CONTENT]
                  vplace = ALIGN_BOTTOM
                  children = [
                    // Left
                    {
                      vplace = ALIGN_BOTTOM
                      flow = FLOW_HORIZONTAL
                      gap = buttonsHGap
                      children = [
                        questsBtn
                        @() {
                          watch = [has_leaderboard, curEvent]
                          size = [SIZE_TO_CONTENT, defButtonHeight]
                          children = !has_leaderboard.get() || curEvent.get() != MAIN_EVENT_ID ? null : leaderbordBtn
                        }
                      ]
                    }
                    // Center
                    !modeId.get() ? null : {
                      hplace = ALIGN_CENTER
                      vplace = ALIGN_BOTTOM
                      halign = ALIGN_CENTER
                      valign = ALIGN_BOTTOM
                      children = squadPanel
                    }
                    // Right
                    !modeId.get() ? null : @() {
                      watch = curEventName
                      hplace = ALIGN_RIGHT
                      vplace = ALIGN_BOTTOM
                      halign = ALIGN_RIGHT
                      valign = ALIGN_BOTTOM
                      flow = FLOW_VERTICAL
                      gap = hdpx(10)
                      children = [
                        toBattleHint
                        mkToBattleButton(modeId.get(), curEventName.get())
                      ]
                    }
                  ]
                  animations = wndSwitchAnim
                }
              ]
            }
          ])
  }
}

let wndKey = {}
let eventWnd = @() {
  key = wndKey
  size = flex()
  children = eventWndContent()
  animations = wndSwitchAnim
}

let sceneId = "eventWnd"
registerScene(sceneId, eventWnd, closeEventWnd, eventWndOpenCounter)
setSceneBgFallback(sceneId, eventBgFallback)
setSceneBg(sceneId, curEventBg.get())
curEventBg.subscribe(@(v) setSceneBg(sceneId, v))
