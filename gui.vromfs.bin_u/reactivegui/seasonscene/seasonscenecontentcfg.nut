from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/battlePass/battlePassState.nut" import hasBpRewardsToReceive, battlePassGoods, bpFreeRewardsUnlock,
  bpPaidRewardsUnlock, bpProgressUnlock
from "%rGui/battlePass/eventPassState.nut" import hasEpRewardsToReceive, hasEpRewardsToReceiveByTableId,
  eventsPassList, allEventPassGoods, eventFreeRewardsUnlock, eventPaidRewardsUnlock, eventProgressUnlock
from "%rGui/battlePass/operationPassState.nut" import hasOPRewardsToReceive, operationPassGoods, OP_EVENT_ID,
  OPFreeRewardsUnlock, OPPaidRewardsUnlock, OPProgressUnlock
from "%rGui/battlePass/passScene.nut" import passSceneWnd
from "%rGui/battlePass/passState.nut" import visibleTabs, BATTLE_PASS, OPERATION_PASS, closePassScene, passPageId,
  seenPasses, isPassGoodsUnseen
from "%rGui/event/eventState.nut" import curEventCurrencies, MAIN_EVENT_ID, specialEvents, unseenLootboxes,
  unseenLootboxesShowOnce, subEventsByMain
import "%rGui/event/eventWnd.nut" as eventWnd
from "%rGui/event/treeEvent/treeEventWnd.nut" import treeEventMapWnd, contentOverlayShadeColor
from "%rGui/event/treeEvent/treeEventState.nut" import curEventMapCurrencies, mkEventMapHasUnseen
from "%rGui/event/gmEventState.nut" import openedGmEventId
import "%rGui/event/gmEventWnd.nut" as gmEventWnd
from "%rGui/quests/questsState.nut" import questsCfg, curTabParams, progressUnlockByTab, hasUnseenQuestsBySection,
  hasRewardQuestsBySection, progressUnlockBySection
import "%rGui/quests/questsWnd.nut" as questsWndCtor
from "%rGui/seasonScene/seasonSceneState.nut" import PASS_SCENE, QUESTS_TAB, EVENT_SHOP_TAB, LOOTBOX_TAB, BATTLE_TAB,
  MAP_TAB, questTabsByEventId, isSeasonTabVisible, seasonShopId
from "%rGui/shop/eventShopState.nut" import getShopIdForEventId
from "%rGui/shop/lootboxPreviewState.nut" import isEventWndLootboxOpen, closeEventWndLootbox
from "%rGui/shop/shopState.nut" import hasUnseenGoodsByShop, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
  personalGoodsByShop, shopCurCategories
import "%rGui/shop/shopWnd.nut" as eventShopTabContent
from "%rGui/shop/shopWndPage.nut" import mkShopHeaderRight
from "%rGui/unlocks/unlocks.nut" import getAllUnlockCurrencies
from "%rGui/unlocks/userstat.nut" import userstatStatsTables


let contentCfgDefaults = {
  icon = "ui/gameuiskin#icon_primary_attention.svg" 
  label = ""
  isVisible = Watched(true)
  currencies = null 
  content = null
  onTabClose = null 
  onBack = null 
  mkHasUnseen = null 
  sceneShadeColor = null 
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
    mkHasUnseen = @(eventId) Computed(function() {
      let bySection = eventId.get() in questTabsByEventId
        ? hasUnseenQuestsBySection.get()
        : hasRewardQuestsBySection.get()
      return hasQuestsUnseen(getQuestTabs(eventId.get(), subEventsByMain.get()),
        questsCfg.get(), progressUnlockByTab.get(), bySection, progressUnlockBySection.get())
    })
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
  },
  [MAP_TAB] = {
    icon = "ui/gameuiskin#data_mark_geo.svg"
    label = "mainmenu/treeEvent"
    currencies = Computed(function() {
      let res = clone curEventCurrencies.get()
      foreach (c in curEventMapCurrencies.get())
        if (!res.contains(c))
          res.append(c)
      return res
    })
    content = @() treeEventMapWnd
    sceneShadeColor = contentOverlayShadeColor
    mkHasUnseen = mkEventMapHasUnseen
  }
}
  .map(@(c, id) contentCfgDefaults.__merge(c, { isVisible = isSeasonTabVisible[id].watched }))

return sceneContentCfg