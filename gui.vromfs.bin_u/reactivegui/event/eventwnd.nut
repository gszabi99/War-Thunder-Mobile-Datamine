from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { registerScene, setSceneBg, setSceneBgFallback } = require("%rGui/navState.nut")
let { eventWndOpenCounter, closeEventWnd, curEventEndsAt,
  unseenLootboxes, unseenLootboxesShowOnce, markCurLootboxSeen,
  bestCampLevel, curEventLootboxes, curEventLoc,
  curEvent, MAIN_EVENT_ID, curEventSeason, isCurEventActive,
  curEventBg, curEventName, specialEventsWithTree
} = require("eventState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkTimeUntil } = require("%rGui/quests/questsPkg.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { lootboxInfo, mkLootboxImageWithTimer, mkPurchaseBtns, lootboxHeight, leaderbordBtn, questsBtn
} = require("eventPkg.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { buy_lootbox, lootboxInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { openNewsWndTagged } = require("%rGui/news/newsState.nut")
let { infoEllipseButton } = require("%rGui/components/infoButton.nut")
let { has_leaderboard } = require("%appGlobals/permissions.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { lootboxImageWithTimer, lootboxContentBlock, lootboxHeader, mkJackpotProgress, mkJackpotProgressBar,
  smallChestIcon
} = require("%rGui/shop/lootboxPreviewContent.nut")
let { isEventWndLootboxOpen, openEventWndLootbox, closeEventWndLootbox, eventWndLootbox,
  getStepsToNextFixed
} = require("%rGui/shop/lootboxPreviewState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardPlateComp.nut")
let { boxSize, boxGap } = REWARD_STYLE_MEDIUM
let { customEventLootboxScale } = require("%appGlobals/config/lootboxPresentation.nut")
let { eventBgFallback } = require("%appGlobals/config/eventSeasonPresentation.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")
let { itemsCfgByCampaignOrdered, orderByItems, SPARE } = require("%appGlobals/itemsState.nut")
let { specialEventGamercardItems } = require("%rGui/event/eventState.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let { gamercardGap, CS_GAMERCARD } = require("%rGui/components/currencyStyles.nut")
let { onCampaignChange } = require("%rGui/mainMenu/chooseCampaignWnd.nut")
let { curCampaign, setCampaign } = require("%appGlobals/pServer/campaign.nut")
let { needFirstBattleTutorForCampaign } = require("%rGui/tutorial/tutorialMissions.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")


let campToBack = mkWatched(persist, "campToBack", null)

let MAX_LOOTBOXES_AMOUNT = 3
let headerGap = hdpx(30)
let contentGap = hdpx(30)
let rewardsBlockWidth = saSize[0] - 2 * defButtonMinWidth - 2 * contentGap

let wndHeaderHeight = hdpx(110)

let sizeMulBySlot = {
  ["0"] = 0.6,
  ["1"] = 0.8,
  ["2"] = 0.9,
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
          { size = const [hdpx(10), 0] }
          {
            rendObj = ROBJ_TEXT
            text = loc("events/fixedReward")
          }.__update(fontTinyShaded)
          {
            rendObj = ROBJ_TEXT
            text = stepsToFixed.value[1] - stepsToFixed.value[0]
          }.__update(fontTinyShaded)
        ])
        mkJackpotProgressBar(stepsToFixed.value[0], stepsToFixed.value[1], { margin = const [hdpx(20), 0, hdpx(10), 0] })
      ]
}

function mkLootboxBlock(lootbox, blockSize) {
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let sizeMul = customEventLootboxScale?[name] ?? sizeMulBySlot?[lootbox.meta?.event_slot] ?? 1.0
  let stateFlags = Watched(0)
  let lootboxImage = mkLootboxImageWithTimer(name, blockSize, timeRange, reqPlayerLevel, sizeMul)
  let stepsToFixed = Computed(@() getStepsToNextFixed(lootbox, serverConfigs.value, servProfile.value))
  let info = lootboxInfo(lootbox, stateFlags)

  return @() {
    key = $"lootbox_{name}" 
    watch = stateFlags
    onElemState = @(sf) stateFlags(sf)
    size = [blockSize, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    function onClick() {
      openEventWndLootbox(name)
      markCurLootboxSeen(name)
    }
    sound = { click  = "click" }
    clickableInfo = loc("mainmenu/btnSelect")
    children = [
      info

      @() {
        watch = [unseenLootboxes, unseenLootboxesShowOnce, curEventName]
        size = 0
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
  campToBack.set(null)
  if (isEventWndLootboxOpen.value)
    closeEventWndLootbox()
  else {
    unseenLootboxesShowOnce.set(unseenLootboxesShowOnce.get().filter(@(event) event != curEventName.get()))
    closeEventWnd()
  }
}

isCurEventActive.subscribe(function(isActive) {
  if (isActive)
    return
  if (isEventWndLootboxOpen.value)
    closeEventWndLootbox()
  closeEventWnd()
})

function mkCurrencies() {
  let currensiesByLootbox = eventWndLootbox.get()?.currencyId
    ? [eventWndLootbox.get().currencyId]
    : curEventLootboxes.get()
        .reduce(@(res, l) res.$rawset(l.currencyId, true), {})
        .keys()
  return {
    watch = [curEventLootboxes, eventWndLootbox]
    children = currensiesByLootbox.len() < 1 ? null
      : {
        pos = [saBorders[0] * 0.5, 0]
        padding = [saBorders[0] * 0.025, saBorders[0] * 0.5]
        rendObj = ROBJ_9RECT
        image = gradTranspDoubleSideX
        color = 0x70000000
        children = mkCurrenciesBtns(currensiesByLootbox).__update({ size = SIZE_TO_CONTENT })
      }
  }
}

let consumablesPlate = @(battleCampaign, itemsByGameMode) @(){
  watch = [itemsCfgByCampaignOrdered, specialEventGamercardItems]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = specialEventGamercardItems.get().map(@(v) mkItemsBalance(v.itemId, null, CS_GAMERCARD))
    .extend(itemsCfgByCampaignOrdered.get()[battleCampaign].filter(@(v) itemsByGameMode?[v.name] ?? true)
      .reduce(@(res, l) res.$rawset(l.name, true), {})
      .keys()
      .sort(@(a, b) (orderByItems?[a] ?? 0) <=> (orderByItems?[b] ?? 0))
        .map(@(id) mkItemsBalance(id, function(){
          if(curCampaign.get() != battleCampaign){
            if(needFirstBattleTutorForCampaign(battleCampaign))
              onCampaignChange(battleCampaign, onClose)
            else {
              campToBack.set(curCampaign.get())
              setCampaign(battleCampaign)
              openShopWnd(SC_CONSUMABLES)
            }
          }
          else
            openShopWnd(SC_CONSUMABLES)
        }, CS_GAMERCARD)))
}

let toBattleHint = @(battleCampaign, itemsByGameMode, eventName) battleCampaign == null ? null : {
  hplace = ALIGN_RIGHT
  pos = [saBorders[0] * 0.5, 0]
  flow = FLOW_VERTICAL
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  padding = [saBorders[0] * 0.2, saBorders[0] * 0.5]
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, saBorders[0]]
  color = 0x70000000
  halign = ALIGN_RIGHT
  children = [
    {
      size = [defButtonMinWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("events/toBattle")
    }.__update(fontTinyAccented)
    gmEventPresentation(eventName).hasConsumablePlate ? consumablesPlate(battleCampaign, itemsByGameMode) : null
  ]
}

let mkToBattleButton = @(modeId, modeName, campaign) mkToBattleButtonWithSquadManagement(function() {
  sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = modeName })
  if (tryOpenQueuePenaltyWnd(campaign, { id = "queueToGameMode", modeId }))
    return
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
            infoEllipseButton(@() openNewsWndTagged($"event_{curEventName.value}_{curEventSeason.value}"))
          ]
        }

        @() {
          watch = [serverTime, curEventEndsAt]
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          children = !curEventEndsAt.value || (curEventEndsAt.value - serverTime.value < 0) ? null
            : mkTimeUntil(secondsToHoursLoc(curEventEndsAt.value - serverTime.value),
                "quests/untilTheEnd",
                { key = "event_time", margin = const [hdpx(20), 0, hdpx(60), 0] }.__update(fontTinyAccented))
        }
      ]
    }
    { size = flex() }
    mkCurrencies
  ]
}

let pannableArea = verticalPannableAreaCtor(sh(100) - wndHeaderHeight - saBorders[1],
  [saBorders[1], saBorders[1]])
let scrollHandler = ScrollHandler()

let scrollArrowsBlock = {
  size = FLEX_V
  pos = [boxSize*2-boxGap , 0]
  children = mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
}

function mkLootboxPreviewContent() {
  let progressInfo = mkJackpotProgress(
    Computed(@() getStepsToNextFixed(eventWndLootbox.value, serverConfigs.value, servProfile.value)))
  return {
    size = flex()
    padding = const [hdpx(40), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    gap = contentGap
    children = [
      {
        size = [rewardsBlockWidth, flex()]
        children = [
          pannableArea(lootboxContentBlock(eventWndLootbox, rewardsBlockWidth, { size = FLEX_H}),
          {},
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
          scrollArrowsBlock
        ]
      }
      @() {
        watch = eventWndLootbox
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = eventWndLootbox.get() == null ? null
          : [
              lootboxHeader(eventWndLootbox.get())
              lootboxImageWithTimer(eventWndLootbox.get())
              { size = flex() }
              progressInfo
              { size = const [0, hdpx(50)] }
              @() {
                watch = [eventWndLootbox, lootboxInProgress]
                size = [SIZE_TO_CONTENT, defButtonHeight]
                children = lootboxInProgress.get() ? null : mkPurchaseBtns(eventWndLootbox.get(), onPurchase)
              }
            ]
      }
    ]
    animations = wndSwitchAnim
  }
}

function eventWndContent() {
  let blockSize = Computed(@() min(saSize[0] / clamp(curEventLootboxes.value.len(), 1, MAX_LOOTBOXES_AMOUNT), hdpx(700)))
  let battleInfo = Computed(@() allGameModes.get().findvalue(@(v) v?.eventId == curEventName.get()))
  let modeId = Computed(@() battleInfo.get()?.gameModeId)
  let battleCampaign = Computed(@() battleInfo.get()?.campaign)
  let itemsByGameMode = Computed(@() {
    [SPARE] = battleInfo.get()?.mission_decl.allowSpare ?? true
  })
  return @() {
    watch = [isEventWndLootboxOpen, modeId, battleCampaign, itemsByGameMode]
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    children = [eventGamercard]
      .extend(isEventWndLootboxOpen.value
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
                    margin = const [0, 0, hdpx(120), 0]
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
                  size = FLEX_H
                  vplace = ALIGN_BOTTOM
                  children = [
                    
                    @() {
                      watch = [specialEventsWithTree, curEventName]
                      vplace = ALIGN_BOTTOM
                      flow = FLOW_HORIZONTAL
                      gap = buttonsHGap
                      children = [
                        curEventName.get() in specialEventsWithTree.get() ? null
                          : questsBtn
                        @() {
                          watch = [has_leaderboard, curEvent]
                          size = [SIZE_TO_CONTENT, defButtonHeight]
                          children = !has_leaderboard.get() || curEvent.get() != MAIN_EVENT_ID ? null : leaderbordBtn
                        }
                      ]
                    }
                    
                    !modeId.get() ? null : {
                      hplace = ALIGN_CENTER
                      vplace = ALIGN_BOTTOM
                      halign = ALIGN_CENTER
                      valign = ALIGN_BOTTOM
                      children = squadPanel
                    }
                    
                    !modeId.get() ? null : @() {
                      watch = curEventName
                      hplace = ALIGN_RIGHT
                      vplace = ALIGN_BOTTOM
                      halign = ALIGN_RIGHT
                      valign = ALIGN_BOTTOM
                      flow = FLOW_VERTICAL
                      gap = hdpx(10)
                      children = [
                        toBattleHint(battleCampaign.get(), itemsByGameMode.get(), curEventName.get())
                        mkToBattleButton(modeId.get(), curEventName.get(), battleCampaign.get())
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
  watch = [curCampaign, campToBack]
  key = wndKey
  size = flex()
  function onAttach(){
    if(campToBack.get() != curCampaign.get() && campToBack.get() != null){
      setCampaign(campToBack.get())
      campToBack.set(null)
    }
  }
  children = eventWndContent()
  animations = wndSwitchAnim
}

let sceneId = "eventWnd"
registerScene(sceneId, eventWnd, closeEventWnd, eventWndOpenCounter)
setSceneBgFallback(sceneId, eventBgFallback)
setSceneBg(sceneId, curEventBg.get())
curEventBg.subscribe(@(v) setSceneBg(sceneId, v))
