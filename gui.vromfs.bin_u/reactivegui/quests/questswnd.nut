from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "dagor.workcycle" import deferOnce
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/battlePass/battlePassState.nut" import isBpSeasonActive
from "%rGui/battlePass/eventPassState.nut" import eventsPassList, getEventPassName, mkHasEpRewardsToReceive
from "%rGui/battlePass/operationPassState.nut" import hasOPRewardsToReceive, OP_EVENT_ID
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/selectedLine.nut" import selLineSize
from "%rGui/event/eventLocName.nut" import getSpecialEventLocName, getSpecialEventRewardUnitName
from "%rGui/event/eventState.nut" import eventSeason, eventEndsAt, isEventActive, specialEventsOrdered,
  getSpecialEventName, MAIN_EVENT_ID, curEvent, subEventsList
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
import "%rGui/options/mkChildrenOptions.nut" as mkChildrenOptions
import "%rGui/options/mkOptionsTabs.nut" as mkOptionsTabs
from "%rGui/options/optionsStyle.nut" import contentWidth, contentWidthFull, tabW, tabPadding, minContentOffset
from "%rGui/quests/questsState.nut" import hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  isQuestsAttached, COMMON_TAB, EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB, PERSONAL_TAB, progressUnlockByTab,
  progressUnlockBySection, tabIdToOpen
from "%rGui/quests/questsWndPage.nut" import questsWndPage, mkQuest, mkAchievement
from "%rGui/shop/shopState.nut" import allShopGoods
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unseenPriority.nut" import SEEN, UNSEEN_HIGH
from "%rGui/components/timerBlock.nut" import mkTimer


const iconSize = hdpxi(100)
const iconColor = 0xFFFFFFFF
const tabGap = hdpx(10)

let maxTabTextWidth = tabW - iconSize - tabGap - selLineSize - tabPadding[1] * 2
let mkTabsVerticalPannableArea = verticalPannableAreaCtor(sh(100) - hdpx(180), [hdpx(30), saBorders[1]])

let personalTabImageByCamp = {
  air = "ui/gameuiskin#icon_personal_air.svg"
  ships = "ui/gameuiskin#icon_personal_ship.svg"
  tanks = "ui/gameuiskin#icon_personal_tank.svg"
}

let iconPersonal = Computed(@() personalTabImageByCamp?[curCampaign.get()])
let iconSeason = Computed(@() getEventPresentation(eventSeason.get()).image)
let imageSizeMul = Computed(@() getEventPresentation(eventSeason.get()).imageSizeMul)
let imageTabOffset = Computed(@() getEventPresentation(eventSeason.get()).imageTabOffset)
let isCommonQuestsVisible = Computed(@() curEvent.get() == MAIN_EVENT_ID || curEvent.get() == "")

let mkUnseen = @(tabId, hasReward) Computed(function() {
  if (hasReward.get() || progressUnlockByTab.get()?[tabId].hasReward)
    return UNSEEN_HIGH
  let hasUnseen = hasUnseenQuestsBySection.get()
  return questsCfg.get()?[tabId].findvalue(@(s) !!hasUnseen?[s] || !!progressUnlockBySection.get()?[s].hasReward) != null
    ? UNSEEN_HIGH
    : SEEN
})

function mkSpecialEventHasReward(idx) {
  let id = getSpecialEventName(idx + 1)
  let eventName = Computed(@() specialEventsOrdered.get().findvalue(@(v) v.eventId == id)?.eventName ?? "")
  let isEventPassQuests = Computed(@() eventsPassList.get().findindex(@(v) v.eventName == eventName.get()) != null)
  let hasEpRewardsToReceive = mkHasEpRewardsToReceive(
    Computed(@() isEventPassQuests.get() ? getEventPassName(eventName.get()) : null))
  return Computed(@() isEventPassQuests.get() ? hasEpRewardsToReceive.get() : false)
}

function eventTabContent(){
  let eventSeasonName = Computed(function() {
    local locId = $"events/name/{eventSeason.get()}"
    if (!doesLocTextExist(locId))
      locId = "events/name/default"
    return loc(locId)
  })

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = eventSeasonName
        size = FLEX_H
        halign = ALIGN_RIGHT
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = eventSeasonName.get()
      }.__update(fontTinyAccented)
      mkTimer(eventEndsAt, {hplace = ALIGN_RIGHT})
    ]
  }
}

let mkTabText = @(text) @() text.get() == null ? { watch = text }
  : {
      watch = text
      size = FLEX_H
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXT
      text = text.get()
    }.__update(fontTinyAccented)

function splitByCenterSpace(text) {
  if (text == null || calc_str_box(text, fontTinyAccented)[0] <= maxTabTextWidth)
    return [text, null]

  let len = text.len();
  let center = len / 2

  let right = text.indexof(" ", center)
  if (right == center)
    return [text.slice(0, center), text.slice(center + 1)]

  let leftBound = right == null ? 0 : 2 * center - right
  local left = null
  local pos = text.indexof(" ", leftBound)
  while (pos != null && pos < center) {
    left = pos
    pos = text.indexof(" ", pos + 1)
  }
  return left != null ? [text.slice(0, left), text.slice(left + 1)]
    : right != null ? [text.slice(0, right), text.slice(right + 1)]
    : [text, null]
}

function mkSpecialEventTabContent(idx) {
  let endsAt = Computed(@() specialEventsOrdered.get()?[idx].endsAt)
  let eventNameTexts = Computed(function() {
    let { eventName = null, eventId = null } = specialEventsOrdered.get()?[idx]
    let { stages = [] } = progressUnlockByTab.get()?[eventId]
    let rewardUnitName = getSpecialEventRewardUnitName(stages, serverConfigs.get(), allShopGoods.get())
    return splitByCenterSpace(getSpecialEventLocName(eventName, rewardUnitName))
  })
  let eventNameFirstRow = Computed(@() eventNameTexts.get()?[0])
  let eventNameSecondRow = Computed(@() eventNameTexts.get()?[1])
  let image = Computed(@() getEventPresentation(specialEventsOrdered.get()?[idx].eventName).icon)

  return {
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = tabGap
    children = [
      @() {
        watch = image
        size = const [iconSize, iconSize]
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture($"{image.get()}:{iconSize}:{iconSize}:P")
        color = iconColor
        keepAspect = KEEP_ASPECT_FIT
      }
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = [
          mkTabText(eventNameFirstRow)
          mkTabText(eventNameSecondRow)
          mkTimer(endsAt, {hplace = ALIGN_RIGHT})
        ]
      }
    ]
  }
}

function mkSpecialQuestsTab(idx) {
  let id = getSpecialEventName(idx + 1)
  return {
    id
    tabContent = mkSpecialEventTabContent(idx)
    isFullWidth = true
    contentCtor = @(isFullScreenWidth) questsWndPage(Computed(@() questsCfg.get()?[id] ?? []), mkQuest, id, isFullScreenWidth)
    isVisible = Computed(@() shouldShowEventMechanics.get()
      && (curEvent.get() == id || subEventsList.get()?[id] == curEvent.get())
      && questsCfg.get()?[id].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    hasReward = mkSpecialEventHasReward(idx)
  }
}

let tabs = [
  {
    id = COMMON_TAB
    locId = "quests/common"
    image = iconSeason
    imageSizeMul = imageSizeMul
    imageTabOffset = imageTabOffset
    isFullWidth = true
    contentCtor = @(isFullScreenWidth) questsWndPage(Computed(@() questsCfg.get()[COMMON_TAB]), mkQuest, COMMON_TAB, isFullScreenWidth)
    isVisible = Computed(@() shouldShowEventMechanics.get()
      && curEvent.get() == MAIN_EVENT_ID
      && questsCfg.get()[COMMON_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null
      && isBpSeasonActive.get())
  }
  {
    id = EVENT_TAB
    image = iconSeason
    imageSizeMul = imageSizeMul
    imageTabOffset = imageTabOffset
    isFullWidth = true
    contentCtor = @(isFullScreenWidth) questsWndPage(Computed(@() questsCfg.get()[EVENT_TAB]), mkQuest, EVENT_TAB, isFullScreenWidth)
    tabContent = eventTabContent()
    isVisible = Computed(@() shouldShowEventMechanics.get()
      && curEvent.get() == MAIN_EVENT_ID
      && isEventActive.get()
      && questsCfg.get()[EVENT_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    ovr = { key = "main_event_tab" } 
  }
  mkSpecialQuestsTab(0)
  mkSpecialQuestsTab(1)
  mkSpecialQuestsTab(2)
  mkSpecialQuestsTab(3)
  mkSpecialQuestsTab(4)
  mkSpecialQuestsTab(5)
  {
    id = PERSONAL_TAB
    locId = "quests/personal"
    image = iconPersonal
    isFullWidth = true
    contentCtor = @(isFullScreenWidth) questsWndPage(Computed(@() questsCfg.get()[PERSONAL_TAB]), mkQuest, PERSONAL_TAB, isFullScreenWidth)
    isVisible = Computed(@() shouldShowEventMechanics.get()
      && curEvent.get() == OP_EVENT_ID
      && questsCfg.get()[PERSONAL_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    hasReward = hasOPRewardsToReceive
  }
  {
    id = ACHIEVEMENTS_TAB
    locId = "quests/achievements"
    image = "ui/gameuiskin#prizes_icon.svg"
    imageSizeMul = 0.8
    isFullWidth = true
    contentCtor = @(isFullScreenWidth) questsWndPage(Computed(@() questsCfg.get()[ACHIEVEMENTS_TAB]), mkAchievement, ACHIEVEMENTS_TAB, isFullScreenWidth)
    isVisible = Computed(@() isCommonQuestsVisible.get()
      && questsCfg.get()[ACHIEVEMENTS_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
  }
  {
    id = PROMO_TAB
    locId = "quests/promo"
    image = "ui/gameuiskin#quest_promo_icon.svg"
    imageSizeMul = 0.9
    isFullWidth = true
    contentCtor = @(isFullScreenWidth) questsWndPage(Computed(@() questsCfg.get()[PROMO_TAB]), mkQuest, PROMO_TAB, isFullScreenWidth)
    isVisible = Computed(@() isCommonQuestsVisible.get()
      && questsCfg.get()[PROMO_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
  }
]

foreach(tab in tabs)
  if ("unseen" not in tab)
    tab.unseen <- mkUnseen(tab.id, tab?.hasReward ?? Watched(false))

let tabsVisibleWatches = tabs.map(@(t) t?.isVisible).filter(@(w) w != null)
let clearTabIdToOpen = @() deferOnce(@() tabIdToOpen.set(null))

function questsWndCtor() {
  let isFullScreenWidth = Watched(false)
  let updateFullScreenWidth = @() isFullScreenWidth.set(
    tabsVisibleWatches.reduce(@(visibleCount, w) visibleCount + (w.get() ? 1 : 0), 0) <= 1)
  let onTabVisibleChange = @(_) updateFullScreenWidth()
  updateFullScreenWidth()

  function findTabIdxById(pageId) {
    if (pageId != null) {
      let idxById = tabs.findindex(@(v) v?.id == pageId)
      if (idxById != null && (tabs[idxById]?.isVisible.get() ?? true))
        return idxById
      return tabs.findindex(@(v) v?.id == ACHIEVEMENTS_TAB)
    }

    return tabs.findindex(@(v) (v?.isVisible.get() ?? true)) ?? 0
  }
  let curTabIdx = mkWatched(persist, "quests_curTabIdx", findTabIdxById(tabIdToOpen.get()))
  let openTabIdx = tabIdToOpen.get() == null ? null : findTabIdxById(tabIdToOpen.get())
  if (openTabIdx != null)
    curTabIdx.set(openTabIdx)
  else if (tabs?[curTabIdx.get()] == null || !(tabs?[curTabIdx.get()].isVisible.get() ?? true))
    curTabIdx.set(findTabIdxById(null))
  clearTabIdToOpen()
  let updateCurTabId = @() curTabId.set(tabs?[curTabIdx.get()].id)
  updateCurTabId()
  curTabIdx.subscribe(@(_) updateCurTabId())

  let scrollHandler = ScrollHandler()

  function setTabById(id) {
    if (id == null)
      return
    let idx = findTabIdxById(id)
    if (idx != null && (tabs[idx]?.isVisible.get() ?? true))
      curTabIdx.set(idx)
    clearTabIdToOpen()
  }

  function curOptionsContent() {
    let tab = tabs?[curTabIdx.get()]
    let { isFullWidth = false } = tab
    let watch = [curTabIdx, isFullScreenWidth]
    return (tab?.content ?? tab?.contentCtor)
      ? {
          watch
          size = [isFullWidth ? contentWidthFull : contentWidth, flex()]
          children = {
            hplace = ALIGN_CENTER
            key = tab
            size = FLEX
            flow = FLOW_VERTICAL
            children = tab?.content ?? tab?.contentCtor(isFullScreenWidth)
            animations = wndSwitchAnim
          }
        }
      : {
          watch
          size = FLEX
          children = tab?.children ? mkChildrenOptions(tab?.children) : { size = FLEX }
        }
  }

  let tabsList = mkTabsVerticalPannableArea(
    mkOptionsTabs(tabs, curTabIdx),
      { size = [ tabW + minContentOffset, flex() ] },
      { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })

  let tabsListBlock = @() {
    watch = isFullScreenWidth
    size = isFullScreenWidth.get() ? [0, flex()] : [tabW + minContentOffset, flex()]
    children = isFullScreenWidth.get() ? null : tabsList
  }

  return {
    pos = [-selLineSize, 0]
    key = setTabById
    function onAttach() {
      tabIdToOpen.subscribe(setTabById)
      foreach (w in tabsVisibleWatches)
        w.subscribe(onTabVisibleChange)
      updateFullScreenWidth()
      isQuestsAttached.set(true)
    }
    function onDetach() {
      tabIdToOpen.unsubscribe(setTabById)
      foreach (w in tabsVisibleWatches)
        w.unsubscribe(onTabVisibleChange)
      isQuestsAttached.set(false)
    }
    size = const [FLEX, flex()]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children = [
      tabsListBlock
      curOptionsContent
    ]
  }
}

return questsWndCtor
