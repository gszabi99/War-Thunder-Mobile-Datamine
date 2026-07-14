from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { PASS_SCENE, QUESTS_TAB, LOOTBOX_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let { passSceneWnd } = require("%rGui/battlePass/passScene.nut")
let { visibleTabs, BATTLE_PASS, OPERATION_PASS, closePassScene, passPageId, seenPasses, isPassGoodsUnseen
} = require("%rGui/battlePass/passState.nut")
let { bpSeasonName, bpSeasonEndTime, hasBpRewardsToReceive, battlePassGoods
} = require("%rGui/battlePass/battlePassState.nut")
let { opSeasonEndTime, opSeasonName, hasOPRewardsToReceive, operationPassGoods
} = require("%rGui/battlePass/operationPassState.nut")
let { epSeasonEndTime, eventTitle, hasEpRewardsToReceive, hasEpRewardsToReceiveByTableId,
  eventsPassList, allEventPassGoods
} = require("%rGui/battlePass/eventPassState.nut")
let { isCurEventActive, curEventLootboxes, closeEventWnd, curEventCurrencies, MAIN_EVENT_ID,
  curEvent, closeEventShellCleanup, shouldShowEventMechanics, curEventEndsAt, specialEvents,
  unseenLootboxes, unseenLootboxesShowOnce
} = require("%rGui/event/eventState.nut")
let { curEventLoc } = require("%rGui/event/eventLocName.nut")
let { isEventWndLootboxOpen, closeEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let questsTabs = require("%rGui/quests/questsWnd.nut")
let { tabIdToOpen, questsCfg, questsBySection, curTabParams, curTabId,
  progressUnlockByTab, hasUnseenQuestsBySection, progressUnlockBySection
} = require("%rGui/quests/questsState.nut")
let { COMMON_TAB, EVENT_TAB, PERSONAL_TAB, ACHIEVEMENTS_TAB, PROMO_TAB } = require("%rGui/unlocks/unlocksConst.nut")
let { contentWidth, contentWidthFull, tabW, minContentOffset } = require("%rGui/options/optionsStyle.nut")
let { selLineSize } = require("%rGui/components/selectedLine.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let mkOptionsTabs = require("%rGui/options/mkOptionsTabs.nut")
let mkChildrenOptions = require("%rGui/options/mkChildrenOptions.nut")
let eventWnd = require("%rGui/event/eventWnd.nut")
let { contentH } = require("%rGui/battlePass/battlePassPkg.nut")


let mkTabsVerticalPannableArea = verticalPannableAreaCtor(sh(100) - hdpx(180), [hdpx(30), saBorders[1]])

function questsContentCtor() {
  function findTabIdxById(pageId) {
    if (pageId != null) {
      let idxById = questsTabs.findindex(@(v) v?.id == pageId)
      if (idxById != null && (questsTabs[idxById]?.isVisible.get() ?? true))
        return idxById
      return questsTabs.findindex(@(v) v?.id == ACHIEVEMENTS_TAB)
    }

    return questsTabs.findindex(@(v) (v?.isVisible.get() ?? true)) ?? 0
  }
  let curTabIdx = Watched(findTabIdxById(tabIdToOpen.get()))
  let updateCurTabId = @() curTabId.set(questsTabs?[curTabIdx.get()].id)
  updateCurTabId()
  curTabIdx.subscribe(@(_) updateCurTabId())

  let scrollHandler = ScrollHandler()

  function setTabById(id) {
    let idx = findTabIdxById(id)
    if (idx != null && (questsTabs[idx]?.isVisible.get() ?? true))
      curTabIdx.set(idx)
  }

  function curOptionsContent() {
    let tab = questsTabs?[curTabIdx.get()]
    let { isFullWidth = false } = tab
    return (tab?.content ?? tab?.contentCtor)
      ? {
          watch = curTabIdx
          size = [isFullWidth ? contentWidthFull : contentWidth, contentH]
          children = {
            hplace = ALIGN_CENTER
            key = tab
            size = [FLEX, contentH]
            flow = FLOW_VERTICAL
            children = tab?.content ?? tab?.contentCtor()
            animations = wndSwitchAnim
          }
        }
      : {
          watch = curTabIdx
          size = FLEX
          children = tab?.children ? mkChildrenOptions(tab?.children) : { size = FLEX }
        }
  }

  let tabsList = mkTabsVerticalPannableArea(
    mkOptionsTabs(questsTabs, curTabIdx),
      { size = [ tabW + minContentOffset, contentH ] },
      { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })

  return {
    pos = [-selLineSize, 0]
    key = setTabById
    onAttach = @() tabIdToOpen.subscribe(setTabById)
    onDetach = @() tabIdToOpen.unsubscribe(setTabById)
    size = [FLEX, contentH]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children = [
      tabsList
      curOptionsContent
    ]
  }
}

let defHeaderTitle = Computed(@() curEvent.get() == MAIN_EVENT_ID ? bpSeasonName.get() : curEventLoc.get())
let defHeaderEndTime = Computed(@() curEvent.get() == MAIN_EVENT_ID ? bpSeasonEndTime.get() : curEventEndsAt.get())

let contentCfgDefaults = {
  icon = "ui/gameuiskin#icon_primary_attention.svg"
  label = ""
  isVisible = Watched(true)
  headerTitle = defHeaderTitle
  headerEndTime = defHeaderEndTime
  currencies = null 
  content = null
  onTabClose = null 
  onBack = null 
  mkHasUnseen = null 
}

let questTabsByEventId = {
  [""] = [ACHIEVEMENTS_TAB, PROMO_TAB],
  [MAIN_EVENT_ID] = [COMMON_TAB, EVENT_TAB, PERSONAL_TAB, ACHIEVEMENTS_TAB, PROMO_TAB]
}

let hasQuestsUnseen = @(tabsList, questsCfgV, prUnlockByTab, hasUnseenBySection, prUnlockBySection)
  null != tabsList.findindex(@(tabId)
    !!prUnlockByTab?[tabId]?.hasReward
      || questsCfgV?[tabId].findvalue(@(s) !!hasUnseenBySection?[s]
          || !!prUnlockBySection?[s]?.hasReward) != null)

let sceneContentCfg = {
  [PASS_SCENE] = {
    icon = "ui/gameuiskin#icon_bp.svg"
    label = "pass"
    isVisible = Computed(@() shouldShowEventMechanics.get() && visibleTabs.get().len() > 0)
    defaultSubId = Computed(@() visibleTabs.get().len() > 0 ? visibleTabs.get()?[0] : BATTLE_PASS)
    headerTitle = Computed(@() passPageId.get() == BATTLE_PASS ? bpSeasonName.get()
      : passPageId.get() == OPERATION_PASS ? opSeasonName.get()
      : loc(eventTitle.get())
    )
    headerEndTime = Computed(@() passPageId.get() == BATTLE_PASS ? bpSeasonEndTime.get()
      : passPageId.get() == OPERATION_PASS ? opSeasonEndTime.get()
      : epSeasonEndTime.get()
    )
    currencies = Computed(@() passPageId.get() == BATTLE_PASS || passPageId.get() == OPERATION_PASS
      ? [GOLD]
      : curEventCurrencies.get())
    content = @() passSceneWnd
    onTabClose = closePassScene
    mkHasUnseen = @(eventId) Computed(@() eventId.get() == MAIN_EVENT_ID
        ? (hasBpRewardsToReceive.get()
            || hasOPRewardsToReceive.get()
            || isPassGoodsUnseen(battlePassGoods.get(), seenPasses.get())
            || isPassGoodsUnseen(operationPassGoods.get(), seenPasses.get()))
      : eventId.get() in specialEvents.get()
        && (hasEpRewardsToReceive(specialEvents.get()[eventId.get()].eventName,
            eventsPassList.get(), hasEpRewardsToReceiveByTableId.get())
          || isPassGoodsUnseen(allEventPassGoods.get()?[specialEvents.get()[eventId.get()].eventName] ?? {},
              seenPasses.get())))
  },
  [QUESTS_TAB] = {
    icon = "ui/gameuiskin#quests.svg"
    label = "tasks"
    isVisible = Computed(function() {
      let tabsList = questTabsByEventId?[curEvent.get()] ?? [curEvent.get()]
      foreach (tabId in tabsList)
        if (questsCfg.get()?[tabId].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
          return true
      return false
    })
    headerTitle = Computed(@() curTabId.get() == PERSONAL_TAB ? opSeasonName.get() : defHeaderTitle.get())
    headerEndTime = Computed(@() curTabId.get() == PERSONAL_TAB ? opSeasonEndTime.get() : defHeaderEndTime.get())
    currencies = Computed(@() curTabParams.get()?.currencies)
    content = questsContentCtor
    function onTabClose() {
      closeEventShellCleanup()
      closeEventWnd()
      eventbus_send("seasonSceneClosed", { tab = QUESTS_TAB })
    }
    mkHasUnseen = @(eventId) Computed(@() hasQuestsUnseen(questTabsByEventId?[eventId.get()] ?? [eventId.get()],
      questsCfg.get(), progressUnlockByTab.get(), hasUnseenQuestsBySection.get(), progressUnlockBySection.get()))
  },
  [LOOTBOX_TAB] = {
    icon = "ui/gameuiskin#events_chest_icon.svg"
    label = "trophies"
    isVisible = Computed(@() shouldShowEventMechanics.get() && isCurEventActive.get() && curEventLootboxes.get().len() > 0)
    currencies = curEventCurrencies
    content = @() eventWnd
    function onTabClose() {
      closeEventShellCleanup()
      closeEventWnd()
      eventbus_send("seasonSceneClosed", { tab = LOOTBOX_TAB })
    }
    function onBack() {
      if (!isEventWndLootboxOpen.get())
        return false
      closeEventWndLootbox()
      return true
    }
    mkHasUnseen = @(eventId) Computed(@() (unseenLootboxes.get()?[eventId.get()].len() ?? 0) > 0
      || unseenLootboxesShowOnce.get().findindex(@(v) v == eventId.get()) != null)
  },
}
  .map(@(c) contentCfgDefaults.__merge(c))

return sceneContentCfg