from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { GOLD } = require("%appGlobals/currenciesState.nut")
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
let questsWndCtor = require("%rGui/quests/questsWnd.nut")
let { questsCfg, questsBySection, curTabParams, curTabId,
  progressUnlockByTab, hasUnseenQuestsBySection, progressUnlockBySection
} = require("%rGui/quests/questsState.nut")
let { COMMON_TAB, EVENT_TAB, PERSONAL_TAB, ACHIEVEMENTS_TAB, PROMO_TAB } = require("%rGui/unlocks/unlocksConst.nut")
let eventWnd = require("%rGui/event/eventWnd.nut")


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
    content = questsWndCtor
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