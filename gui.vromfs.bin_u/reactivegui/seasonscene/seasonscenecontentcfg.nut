from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%rGui/battlePass/battlePassWnd.nut" import battlePassContent
from "%rGui/battlePass/battlePassObsoleteState.nut" import hasBpRewardsToReceive, battlePassGoods, bpFreeRewardsUnlock,
  bpPaidRewardsUnlock, bpProgressUnlock
import "%rGui/collections/collectionScene.nut" as collectionScene
from "%rGui/collections/collectionsState.nut" import mkCollectionHasUnseen
from "%rGui/battlePass/battlePassState.nut" import curBpPages, curBpId, seenBattlePassPages, activeBattlePassesCfg,
  battlePasses
from "%rGui/battlePass/eventPassState.nut" import hasEpRewardsToReceive, hasEpRewardsToReceiveByTableId,
  eventsPassList, allEventPassGoods, eventFreeRewardsUnlock, eventPaidRewardsUnlock, eventProgressUnlock
from "%rGui/battlePass/operationPassState.nut" import hasOPRewardsToReceive, operationPassGoods, OP_EVENT_ID,
  OPFreeRewardsUnlock, OPPaidRewardsUnlock, OPProgressUnlock
from "%rGui/battlePass/passScene.nut" import passSceneWnd
from "%rGui/battlePass/passState.nut" import visibleTabs, BATTLE_PASS, OPERATION_PASS, closePassScene, passPageId,
  seenPasses, isPassGoodsUnseen
from "%rGui/event/eventState.nut" import curEventCurrencies, MAIN_EVENT_ID, specialEvents, unseenLootboxes,
  unseenLootboxesShowOnce, subEventsByMain
from "%rGui/event/eventWnd.nut" import eventWnd, hasEventWndSquadPanel
from "%rGui/event/treeEvent/treeEventWnd.nut" import treeEventMapWnd, contentOverlayShadeColor
from "%rGui/event/treeEvent/treeEventState.nut" import curEventMapCurrencies, mkEventMapHasUnseen
from "%rGui/event/gmEventState.nut" import curGmList, openedGmEventId, getGameModePresentationByMode
from "%rGui/event/gmEventWnd.nut" import gmEventWnd, hasGmEventSquadPanel
from "%rGui/leaderboard/lbWnd.nut" import lbScene
from "%rGui/quests/questsState.nut" import questsCfg, curTabParams, progressUnlockByTab, hasUnseenQuestsBySection,
  hasRewardQuestsBySection, progressUnlockBySection
import "%rGui/quests/questsWnd.nut" as questsWndCtor
from "%rGui/seasonScene/seasonSceneState.nut" import QUESTS_TAB, EVENT_SHOP_TAB, LOOTBOX_TAB, BATTLE_TAB,
  BATTLE_TAB_2, BATTLE_TAB_3, MAP_TAB, LEADERBOARD_TAB, questTabsByEventId, isSeasonTabVisible, seasonShopId,
  COLLECTION_TAB, BATTLE_TAB_MODE_IDX, PASS_OBSOLETE_SCENE, PASS_SCENE
from "%rGui/shop/eventShopState.nut" import getShopIdForEventId
from "%rGui/shop/lootboxPreviewState.nut" import isEventWndLootboxOpen, closeEventWndLootbox
from "%rGui/shop/shopState.nut" import hasUnseenGoodsByShop, goodsByShop, soonGoodsByShop, soonPersonalGoodsByShop,
  personalGoodsByShop, shopCurCategories
import "%rGui/shop/shopWnd.nut" as eventShopTabContent
from "%rGui/shop/shopWndPage.nut" import mkShopHeaderRight, gamercardShopBpPointsBalanceBtns
from "%rGui/components/currencyStyles.nut" import gamercardGap
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
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
  hasSquadPanel = null 
}

let getQuestTabs = @(eventId, subEventsByMainV)
  ((clone questTabsByEventId?[eventId]) ?? [eventId]) 
    .extend(subEventsByMainV?[eventId] ?? [])

let hasQuestsUnseen = @(tabsList, questsCfgV, prUnlockByTab, hasUnseenBySection, prUnlockBySection)
  null != tabsList.findindex(@(tabId)
    !!prUnlockByTab?[tabId]?.hasReward
      || questsCfgV?[tabId].findvalue(@(s) !!hasUnseenBySection?[s]
          || !!prUnlockBySection?[s]?.hasReward) != null)


function mkBattleModeTab(tabId) {
  let mode = Computed(@() curGmList.get()?[BATTLE_TAB_MODE_IDX[tabId]])
  let modePresentation = Computed(@() getGameModePresentationByMode(mode.get()))
  return {
    icon = Computed(@() modePresentation.get().icon ?? getEventPresentation(openedGmEventId.get()).icon)
    label = Computed(function() {
      let gm = mode.get()
      return modePresentation.get().locId ?? gm?.loc_name
        ?? (gm == null ? null
          : doesLocTextExist($"gameMode/{gm.name}") ? $"gameMode/{gm.name}" : gm.name)
    })
    content = @() gmEventWnd
    hasSquadPanel = hasGmEventSquadPanel
  }
}

let sceneContentCfg = {
  [PASS_SCENE] = {
    icon = "ui/gameuiskin#icon_bp.svg"
    label = "catalog"
    function headerRightCtor() {
      let currencies = Computed(function() {
        let resTbl = {}
        foreach (page in curBpPages.get() ?? [])
          foreach (slot in page.slots)
            foreach (g in slot.rewards)
              if ((g?.gType ?? "") == G_CURRENCY)
                resTbl[g?.id ?? ""] <- true
        return resTbl.keys()
      })
      return @() {
        watch = [currencies, curBpId]
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        gap = gamercardGap
        children = [
          curBpId.get() == null ? null
            : gamercardShopBpPointsBalanceBtns(Watched(null), Watched(null), [curBpId.get()])
          mkCurrenciesBtns(currencies.get(), const {}, const { size = SIZE_TO_CONTENT })
        ].filter(@(v) v != null)
      }
    }
    content = @() battlePassContent
    mkHasUnseen = @(eventId) Computed(function() {
      let eId = eventId.get()
      let bpId = activeBattlePassesCfg.get().findindex(@(c) c.meta?.event_id == eId)
      if (eId == null || bpId == null)
        return false

      let { pages = [] } = activeBattlePassesCfg.get()?[bpId]
      let { totalPoints = 0 } = battlePasses.get()?[bpId]
      let seenPage = seenBattlePassPages.get()?[bpId] ?? -1
      return pages.findvalue(@(p, idx) idx > seenPage && totalPoints >= p.reqPoints) != null
    })
  },
  [PASS_OBSOLETE_SCENE] = {
    key = "pass_tab_btn" 
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
    function headerRightCtor() {
      let currencies = Computed(@() curTabParams.get()?.currencies ?? [])
      let bpPoints = Computed(@() curTabParams.get()?.bpPoints ?? [])
      return @() {
        watch = [currencies, bpPoints]
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        gap = gamercardGap
        children = [
          bpPoints.get().len() == 0 ? null
            : gamercardShopBpPointsBalanceBtns(Watched(null), Watched(null), bpPoints.get())
          mkCurrenciesBtns(currencies.get(), const {}, const { size = SIZE_TO_CONTENT })
        ].filter(@(v) v != null)
      }
    }
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
    hasSquadPanel = hasEventWndSquadPanel
    function onBack() {
      if (!isEventWndLootboxOpen.get())
        return false
      closeEventWndLootbox()
      return true
    }
    mkHasUnseen = @(eventId) Computed(@() (unseenLootboxes.get()?[eventId.get()].len() ?? 0) > 0
      || unseenLootboxesShowOnce.get().findindex(@(v) v == eventId.get()) != null)
  },
  [BATTLE_TAB] = mkBattleModeTab(BATTLE_TAB),
  [BATTLE_TAB_2] = mkBattleModeTab(BATTLE_TAB_2),
  [BATTLE_TAB_3] = mkBattleModeTab(BATTLE_TAB_3),
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
  },
  [LEADERBOARD_TAB] = {
    icon = "ui/gameuiskin#prizes_icon.svg"
    label = "mainmenu/titleLeaderboards"
    content = @() lbScene
  },
  [COLLECTION_TAB] = {
    icon = "ui/gameuiskin#collection.svg"
    label = "collection"
    content = @() collectionScene
    mkHasUnseen = mkCollectionHasUnseen
  },
}
  .map(function(c, id) {
    let cfg = contentCfgDefaults.__merge(c, { isVisible = isSeasonTabVisible[id].watched })
    cfg.icon = cfg.icon instanceof Watched ? cfg.icon : Watched(cfg.icon)
    cfg.label = cfg.label instanceof Watched ? cfg.label : Watched(cfg.label)
    return cfg
  })

return sceneContentCfg
