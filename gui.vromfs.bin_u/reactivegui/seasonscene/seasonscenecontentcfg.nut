from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { PASS_SCENE, QUESTS_TAB, EVENT_SHOP_TAB, LOOTBOX_TAB, BATTLE_TAB,
  questTabsByEventId, isSeasonTabVisible, seasonShopId
} = require("%rGui/seasonScene/seasonSceneState.nut")
let { passSceneWnd } = require("%rGui/battlePass/passScene.nut")
let { visibleTabs, BATTLE_PASS, OPERATION_PASS, closePassScene, passPageId, seenPasses, isPassGoodsUnseen
} = require("%rGui/battlePass/passState.nut")
let { hasBpRewardsToReceive, battlePassGoods, bpFreeRewardsUnlock, bpPaidRewardsUnlock, bpProgressUnlock
} = require("%rGui/battlePass/battlePassState.nut")
let { hasOPRewardsToReceive, operationPassGoods, OP_EVENT_ID, OPFreeRewardsUnlock,
  OPPaidRewardsUnlock, OPProgressUnlock
} = require("%rGui/battlePass/operationPassState.nut")
let { hasEpRewardsToReceive, hasEpRewardsToReceiveByTableId, eventsPassList, allEventPassGoods,
  eventFreeRewardsUnlock, eventPaidRewardsUnlock, eventProgressUnlock
} = require("%rGui/battlePass/eventPassState.nut")
let { curEventCurrencies, MAIN_EVENT_ID, specialEvents, unseenLootboxes, unseenLootboxesShowOnce,
  subEventsByMain
} = require("%rGui/event/eventState.nut")
let gmEventWnd = require("%rGui/event/gmEventWnd.nut")
let { openedGmEventId } = require("%rGui/event/gmEventState.nut")
let { isEventWndLootboxOpen, closeEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { hasUnseenGoodsByShop, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop, personalGoodsByShop,
  shopCurCategories
} = require("%rGui/shop/shopState.nut")
let { getShopIdForEventId } = require("%rGui/shop/eventShopState.nut")
let eventShopTabContent = require("%rGui/shop/shopWnd.nut")
let { mkShopHeaderRight } = require("%rGui/shop/shopWndPage.nut")
let questsWndCtor = require("%rGui/quests/questsWnd.nut")
let { questsCfg, curTabParams, progressUnlockByTab, hasUnseenQuestsBySection, progressUnlockBySection
} = require("%rGui/quests/questsState.nut")
let { getAllUnlockCurrencies } = require("%rGui/unlocks/unlocks.nut")
let { userstatStatsTables } = require("%rGui/unlocks/userstat.nut")
let eventWnd = require("%rGui/event/eventWnd.nut")


let contentCfgDefaults = {
  icon = "ui/gameuiskin#icon_primary_attention.svg" 
  label = ""
  isVisible = Watched(true)
  currencies = null 
  content = null
  onTabClose = null 
  onBack = null 
  mkHasUnseen = null 
}

let getQuestTabs = @(eventId, subEventsByMainV)
  ((clone questTabsByEventId?[eventId]) ?? [eventId]) 
    .extend(subEventsByMainV?[eventId] ?? [])

let hasQuestsUnseen = @(tabsList, questsCfgV, prUnlockByTab, hasUnseenBySection, prUnlockBySection)
  null != tabsList.findindex(@(tabId)
    !!prUnlockByTab?[tabId]?.hasReward
      || questsCfgV?[tabId].findvalue(@(s) !!hasUnseenBySection?[s]
          || !!prUnlockBySection?[s]?.hasReward) != null)

let sceneContentCfg = {
  [PASS_SCENE] = {
    icon = "ui/gameuiskin#icon_bp.svg"
    label = "pass"
    defaultSubId = Computed(@() visibleTabs.get().len() > 0 ? visibleTabs.get()?[0] : BATTLE_PASS)
    currencies = Computed(function() {
      let resTbl = {}
      if (passPageId.get() == BATTLE_PASS)
        resTbl.__update(
          getAllUnlockCurrencies(bpFreeRewardsUnlock.get(), serverConfigs.get(), userstatStatsTables.get())
          getAllUnlockCurrencies(bpPaidRewardsUnlock.get(), serverConfigs.get(), userstatStatsTables.get())
          getAllUnlockCurrencies(bpProgressUnlock.get(), serverConfigs.get(), userstatStatsTables.get()))
      else if (passPageId.get() == OPERATION_PASS)
        resTbl.__update(
          getAllUnlockCurrencies(OPFreeRewardsUnlock.get(), serverConfigs.get(), userstatStatsTables.get())
          getAllUnlockCurrencies(OPPaidRewardsUnlock.get(), serverConfigs.get(), userstatStatsTables.get())
          getAllUnlockCurrencies(OPProgressUnlock.get(), serverConfigs.get(), userstatStatsTables.get()))
      else
        resTbl.__update(
          getAllUnlockCurrencies(eventFreeRewardsUnlock.get(), serverConfigs.get(), userstatStatsTables.get())
          getAllUnlockCurrencies(eventPaidRewardsUnlock.get(), serverConfigs.get(), userstatStatsTables.get())
          getAllUnlockCurrencies(eventProgressUnlock.get(), serverConfigs.get(), userstatStatsTables.get()))
      return resTbl.keys()
    })
    content = @() passSceneWnd
    onTabClose = closePassScene
    mkHasUnseen = @(eventId) Computed(function() {
      if (eventId.get() == MAIN_EVENT_ID
          && (hasBpRewardsToReceive.get() || isPassGoodsUnseen(battlePassGoods.get(), seenPasses.get())))
        return true
      if (eventId.get() == OP_EVENT_ID
          && (hasOPRewardsToReceive.get() || isPassGoodsUnseen(operationPassGoods.get(), seenPasses.get())))
        return true
      let list = [ eventId.get() ].extend(subEventsByMain.get()?[eventId.get()] ?? [])
      foreach (e in list) {
        let { eventName = null } = specialEvents.get()?[e]
        if (eventName != null
            && (hasEpRewardsToReceive(eventName, eventsPassList.get(), hasEpRewardsToReceiveByTableId.get())
              || isPassGoodsUnseen(allEventPassGoods.get()?[eventName] ?? {}, seenPasses.get())))
          return true
      }
      return false
    })
  },
  [QUESTS_TAB] = {
    icon = "ui/gameuiskin#quests.svg"
    label = "tasks"
    currencies = Computed(@() curTabParams.get()?.currencies)
    content = questsWndCtor
    mkHasUnseen = @(eventId) Computed(@() hasQuestsUnseen(getQuestTabs(eventId.get(), subEventsByMain.get()),
      questsCfg.get(), progressUnlockByTab.get(), hasUnseenQuestsBySection.get(), progressUnlockBySection.get()))
  },
  [EVENT_SHOP_TAB] = {
    icon = "ui/gameuiskin#icon_shop.svg"
    label = "topmenu/store"
    currencies = curEventCurrencies
    headerRightCtor = @() mkShopHeaderRight(seasonShopId, Computed(@() shopCurCategories.get()?[seasonShopId.get()]))
    content = eventShopTabContent
    mkHasUnseen = @(eventId) Computed(function() {
      let sId = getShopIdForEventId(eventId.get(), specialEvents.get(),
        goodsByShop.get(), soonGoodsByShop.get(), soonPersonalGoodsByShop.get(), personalGoodsByShop.get())
      return sId != null && (hasUnseenGoodsByShop.get()?[sId].findvalue(@(c) c) ?? false)
    })
  },
  [LOOTBOX_TAB] = {
    key = "quest_header_btn"
    icon = "ui/gameuiskin#events_chest_icon.svg"
    label = "trophies"
    currencies = curEventCurrencies
    content = @() eventWnd
    function onBack() {
      if (!isEventWndLootboxOpen.get())
        return false
      closeEventWndLootbox()
      return true
    }
    mkHasUnseen = @(eventId) Computed(@() (unseenLootboxes.get()?[eventId.get()].len() ?? 0) > 0
      || unseenLootboxesShowOnce.get().findindex(@(v) v == eventId.get()) != null)
  },
  [BATTLE_TAB] = {
    icon = Computed(@() getEventPresentation(openedGmEventId.get()).icon)
    label = "mainmenu/toBattle/short"
    content = @() gmEventWnd
  }
}
  .map(@(c, id) contentCfgDefaults.__merge(c, { isVisible = isSeasonTabVisible[id].watched }))

return sceneContentCfg