from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_send
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/gameModes/gameModes.nut" import allGameModes
from "%appGlobals/itemsState.nut" import itemsCfgByCampaignOrdered, orderByItems, SPARE
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign, setCampaign
from "%appGlobals/pServer/pServerApi.nut" import buy_lootbox, lootboxInProgress
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/permissions.nut" import has_leaderboard
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/battlePass/passPkg.nut" import contentH, bottomPanelH
from "%rGui/components/buttonStyles.nut" import defButtonHeight, defButtonMinWidth
from "%rGui/components/currencyStyles.nut" import gamercardGap, CS_GAMERCARD
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/textButton.nut" import buttonsHGap
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/event/eventPkg.nut" import lootboxInfo, mkLootboxImageWithTimer, mkPurchaseBtns, leaderbordBtn
from "%rGui/event/eventState.nut" import unseenLootboxes, unseenLootboxesShowOnce, markCurLootboxSeen, bestCampLevel,
  curEventLootboxes, curEvent, MAIN_EVENT_ID, isCurEventActive, isEventSceneAttached, specialEventGamercardItems,
  campToBack, closeEventShellCleanup, curEventEndsAt
from "%rGui/mainMenu/balanceComps.nut" import mkItemsBalance
from "%rGui/mainMenu/chooseCampaignWnd.nut" import onCampaignChange
from "%rGui/mainMenu/toBattleButton.nut" import mkToBattleButtonWithSquadManagement
import "%rGui/queue/queuePenaltyWnd.nut" as tryOpenQueuePenaltyWnd
from "%rGui/rewards/rewardPlateComp.nut" import REWARD_STYLE_MEDIUM
from "%rGui/seasonScene/seasonSceneState.nut" import closeSeasonScene
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_EVENT, PURCH_TYPE_LOOTBOX, mkBqPurchaseInfo
from "%rGui/shop/lootboxPreviewContent.nut" import lootboxImageWithTimer, lootboxContentBlock, lootboxHeader,
  mkJackpotProgress, mkJackpotProgressBar, smallChestIcon
from "%rGui/shop/lootboxPreviewState.nut" import isEventWndLootboxOpen, openEventWndLootbox, closeEventWndLootbox,
  eventWndLootbox, getStepsToNextFixed
from "%rGui/shop/msgBoxPurchase.nut" import showNoBalanceMsgIfNeed
from "%rGui/shop/shopCommon.nut" import SC_CONSUMABLES
from "%rGui/shop/shopState.nut" import openShopWnd
import "%rGui/squad/squadPanel.nut" as squadPanel
from "%rGui/style/gradients.nut" import gradTranspDoubleSideX, gradDoubleTexOffset
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/tutorial/tutorialMissions.nut" import needFirstBattleTutorForCampaign
from "%rGui/components/timerBlock.nut" import mkTimerBlock


let { boxSize, boxGap } = REWARD_STYLE_MEDIUM


const MAX_LOOTBOXES_AMOUNT = 3
const contentGap = hdpx(30)
let rewardsBlockWidth = saSize[0] - 2 * defButtonMinWidth - 2 * contentGap

const wndHeaderHeight = hdpx(110)

function onPurchase(lootbox, price, currencyId, count = 1) {
  if (lootboxInProgress.get())
    return
  let { name, timeRange = null, reqPlayerLevel = 0 } = lootbox
  let { start = 0, end = 0 } = timeRange
  let errMsg = bestCampLevel.get() < reqPlayerLevel
      ? loc("lootbox/availableAfterLevel", { level = colorize("@mark", reqPlayerLevel) })
    : start > serverTime.get()
      ? loc("lootbox/availableAfter", { time = secondsToHoursLoc(start - serverTime.get()) })
    : end > 0 && end < serverTime.get() ? loc("lootbox/noLongerAvailable")
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

const progressHeight = hdpx(80)
let mkProgress = @(stepsToFixed) @() {
  size = const [SIZE_TO_CONTENT, progressHeight]
  watch = stepsToFixed
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = stepsToFixed.get()[1] - stepsToFixed.get()[0] <= 0 ? null
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
            text = stepsToFixed.get()[1] - stepsToFixed.get()[0]
          }.__update(fontTinyShaded)
        ])
        mkJackpotProgressBar(stepsToFixed.get()[0], stepsToFixed.get()[1], { margin = const [hdpx(20), 0, hdpx(10), 0] })
      ]
}

function mkLootboxBlock(lootbox, blockSize) {
  let { name } = lootbox
  let stateFlags = Watched(0)

  let hasUnseen = Computed(@() name in unseenLootboxes.get()?[curEvent.get()] || unseenLootboxesShowOnce.get()?[name])
  let unseenMark = @() {
    watch = hasUnseen
    size = 0
    pos = const [-hdpx(210), -hdpx(140)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = hasUnseen.get() ? priorityUnseenMark : null
  }
  let lootboxImage = mkLootboxImageWithTimer(lootbox, blockSize)

  let stepsToFixed = Computed(@() getStepsToNextFixed(lootbox, serverConfigs.get(), servProfile.get()))
  let info = lootboxInfo(lootbox, stateFlags)

  return @() {
    key = $"lootbox_{name}" 
    watch = stateFlags
    onElemState = @(sf) stateFlags.set(sf)
    size = [blockSize, sh(55)]
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    function onClick() {
      openEventWndLootbox(name)
      markCurLootboxSeen(name)
    }
    sound = { click  = "click" }
    clickableInfo = loc("mainmenu/btnSelect")
    children = [
      {
        vplace = ALIGN_CENTER
        pos = const [0, hdpx(40)]
        transform = { scale = (stateFlags.get() & S_HOVER) != 0 ? [0.9, 0.9] : [1, 1] }
        transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = Linear }]
        children = [lootboxImage, unseenMark]
      }
      {
        vplace = ALIGN_CENTER
        pos = const [0, -hdpx(200)]
        children = info
      }
      {
        vplace = ALIGN_CENTER
        pos = const [0, hdpx(270)]
        children = mkProgress(stepsToFixed)
      }
    ]
  }
}

function onClose() {
  if (isEventWndLootboxOpen.get())
    closeEventWndLootbox()
  else {
    closeEventShellCleanup()
    closeSeasonScene()
  }
}

isCurEventActive.subscribe(function(isActive) {
  if (isActive)
    return
  if (isEventWndLootboxOpen.get())
    closeEventWndLootbox()
  else {
    closeEventShellCleanup()
    closeSeasonScene()
  }
})

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
    getEventPresentation(eventName).hasConsumablePlate ? consumablesPlate(battleCampaign, itemsByGameMode) : null
  ]
}

let mkToBattleButton = @(gameMode, modeName, campaign) mkToBattleButtonWithSquadManagement(
  function() {
    sendNewbieBqEvent("pressToBattleEventButton", { status = "online_battle", params = modeName })
    if (tryOpenQueuePenaltyWnd(campaign, gameMode, { id = "queueToGameMode", modeId = gameMode.gameModeId }))
      return
    eventbus_send("queueToGameMode", { modeId = gameMode.gameModeId })
  },
  gameMode)

let pannableArea = verticalPannableAreaCtor(sh(100) - wndHeaderHeight - saBorders[1] - bottomPanelH,
  [saBorders[1], saBorders[1]])
let scrollHandler = ScrollHandler()

let scrollArrowsBlock = {
  size = FLEX_V
  pos = [boxSize*2-boxGap , 0]
  children = mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall)
}

function mkLootboxPreviewContent() {
  let progressInfo = mkJackpotProgress(
    Computed(@() getStepsToNextFixed(eventWndLootbox.get(), serverConfigs.get(), servProfile.get())))
  return {
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = contentGap
    children = [
      {
        size = [rewardsBlockWidth, FLEX]
        children = [
          pannableArea(lootboxContentBlock(eventWndLootbox, rewardsBlockWidth, { size = FLEX_H}),
          {},
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
          scrollArrowsBlock
        ]
      }
      @() {
        watch = eventWndLootbox
        size = const [flex(), ph(100)]
        halign = ALIGN_CENTER
        children = eventWndLootbox.get() == null ? null
          : [
              {
                pos = const [0, ph(20)]
                children = lootboxImageWithTimer(eventWndLootbox.get())
              }
              lootboxHeader(eventWndLootbox.get())
              {
                vplace = ALIGN_BOTTOM
                pos = [0, -(defButtonHeight + hdpx(50))]
                children = progressInfo
              }
              @() {
                vplace = ALIGN_BOTTOM
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
  let blockSize = Computed(@() min(saSize[0] / clamp(curEventLootboxes.get().len(), 1, MAX_LOOTBOXES_AMOUNT), hdpx(700)))
  let battleInfo = Computed(@() allGameModes.get().findvalue(@(v) v?.eventId == curEvent.get()))
  let battleCampaign = Computed(@() battleInfo.get()?.campaign ?? curCampaign.get())
  let itemsByGameMode = Computed(@() {
    [SPARE] = battleInfo.get()?.mission_decl.allowSpare ?? true
  })
  return @() {
    watch = [isEventWndLootboxOpen, battleInfo, battleCampaign, itemsByGameMode]
    size = FLEX
    padding = [0, saBordersRv[1], saBordersRv[0], saBordersRv[1]]
    flow = FLOW_VERTICAL
    children = isEventWndLootboxOpen.get() ? mkLootboxPreviewContent()
      : [
          mkTimerBlock(curEventEndsAt)
          {
            size = FLEX
            children = [
              {
                size = FLEX
                children = @() {
                  watch = [curEventLootboxes, blockSize]
                  size = FLEX
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
                    vplace = ALIGN_BOTTOM
                    flow = FLOW_HORIZONTAL
                    gap = buttonsHGap
                    children = [
                      @() {
                        watch = [has_leaderboard, curEvent]
                        size = [SIZE_TO_CONTENT, defButtonHeight]
                        children = !has_leaderboard.get() || curEvent.get() != MAIN_EVENT_ID ? null : leaderbordBtn
                      }
                    ]
                  }
                  
                  !battleInfo.get() ? null : {
                    hplace = ALIGN_CENTER
                    vplace = ALIGN_BOTTOM
                    halign = ALIGN_CENTER
                    valign = ALIGN_BOTTOM
                    children = squadPanel
                  }
                  
                  !battleInfo.get() ? null : @() {
                    watch = curEvent
                    hplace = ALIGN_RIGHT
                    vplace = ALIGN_BOTTOM
                    halign = ALIGN_RIGHT
                    valign = ALIGN_BOTTOM
                    flow = FLOW_VERTICAL
                    gap = hdpx(10)
                    children = [
                      toBattleHint(battleCampaign.get(), itemsByGameMode.get(), curEvent.get())
                      mkToBattleButton(battleInfo.get(), curEvent.get(), battleCampaign.get())
                    ]
                  }
                ]
                animations = wndSwitchAnim
              }
            ]
          }
        ]
  }
}


let wndKey = {}

let mkEventWnd = @() {
  watch = [curCampaign, campToBack]
  key = wndKey
  size = [FLEX, contentH]
  function onAttach() {
    isEventSceneAttached.set(true)
    if(campToBack.get() != curCampaign.get() && campToBack.get() != null) {
      setCampaign(campToBack.get())
      campToBack.set(null)
    }
  }
  onDetach = @() isEventSceneAttached.set(false)
  children = eventWndContent()
  animations = wndSwitchAnim
}

return mkEventWnd
