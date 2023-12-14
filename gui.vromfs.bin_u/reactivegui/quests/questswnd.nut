from "%globalsDarg/darg_library.nut" import *
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, MINI_EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB, progressUnlockByTab,
  progressUnlockBySection
} = require("questsState.nut")
let { questsWndPage, mkQuest, mkAchievement, unseenMarkMargin } = require("questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { eventSeason, eventSeasonName, miniEventSeasonName, eventEndsAt, miniEventEndsAt, isEventActive, isMiniEventActive,
  openEventWnd
} = require("%rGui/event/eventState.nut")
let { openBattlePassWnd, hasBpRewardsToReceive } = require("%rGui/battlePass/battlePassState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkQuestsHeaderBtn } = require("questsPkg.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let iconSeason = Computed(@() $"ui/gameuiskin#banner_event_{eventSeason.get()}.avif")

let mkUnseen = @(tabId) Computed(function() {
  if (progressUnlockByTab.get()?[tabId].hasReward)
    return UNSEEN_HIGH
  let hasUnseen = hasUnseenQuestsBySection.value
  return questsCfg.value?[tabId].findvalue(@(s) !!hasUnseen?[s] || !!progressUnlockBySection.get()?[s].hasReward) != null
    ? UNSEEN_HIGH
    : SEEN
})

let linkToEventBtnCtor = @() mkQuestsHeaderBtn(loc("mainmenu/rewardsList"),
  iconSeason,
  @() openEventWnd())

let linkToBattlePassBtnCtor = @() mkQuestsHeaderBtn(loc("mainmenu/rewardsList"),
  iconSeason,
  openBattlePassWnd,
  @() {
    watch = hasBpRewardsToReceive
    margin = unseenMarkMargin
    children = hasBpRewardsToReceive.get() ? priorityUnseenMark : null
  })

let eventTabContent = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    @() {
      watch = eventSeasonName
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = eventSeasonName.value
    }.__update(fontSmall)
    @() {
      watch = [eventEndsAt, serverTime]
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXT
      text = !eventEndsAt.value || (eventEndsAt.value - serverTime.value < 0) ? null
        : secondsToHoursLoc(eventEndsAt.value - serverTime.value)
    }.__update(fontSmall)
  ]
}

let miniEventTabContent = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    @() {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = miniEventSeasonName
    }.__update(fontSmall)
    @() {
      watch = [miniEventEndsAt, serverTime]
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      rendObj = ROBJ_TEXT
      text = !miniEventEndsAt.value || (miniEventEndsAt.value - serverTime.value < 0) ? null
        : secondsToHoursLoc(miniEventEndsAt.value - serverTime.value)
    }.__update(fontSmall)
  ]
}

let tabs = [
  {
    id = COMMON_TAB
    locId = "quests/common"
    image = iconSeason
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[COMMON_TAB]), mkQuest, COMMON_TAB, linkToBattlePassBtnCtor)
    isVisible = Computed(@() questsCfg.value[COMMON_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = EVENT_TAB
    image = iconSeason
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[EVENT_TAB]), mkQuest, EVENT_TAB, linkToEventBtnCtor)
    tabContent = eventTabContent
    tabHeight = hdpx(160)
    isVisible = Computed(@() isEventActive.value
      && questsCfg.value[EVENT_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = MINI_EVENT_TAB
    image = "ui/gameuiskin#quest_events_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[MINI_EVENT_TAB]), mkQuest, MINI_EVENT_TAB)
    tabContent = miniEventTabContent
    tabHeight = hdpx(160)
    isVisible = Computed(@() isMiniEventActive.value
      && questsCfg.value[MINI_EVENT_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = ACHIEVEMENTS_TAB
    locId = "quests/achievements"
    image = "ui/gameuiskin#prizes_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[ACHIEVEMENTS_TAB]), mkAchievement, ACHIEVEMENTS_TAB)
    isVisible = Computed(@() questsCfg.value[ACHIEVEMENTS_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = PROMO_TAB
    locId = "quests/promo"
    image = "ui/gameuiskin#quest_promo_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[PROMO_TAB]), mkQuest, PROMO_TAB)
    isVisible = Computed(@() questsCfg.value[PROMO_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
]

foreach(tab in tabs)
  if ("unseen" not in tab)
    tab.unseen <- mkUnseen(tab.id)

let gamercardQuestBtns = @() {
  watch = isEventActive
  size = flex()
  children = mkCurrenciesBtns(isEventActive.value ? [WARBOND, WP, GOLD] : [WP, GOLD])
}

mkOptionsScene("questsWnd", tabs, isQuestsOpen, curTabId, gamercardQuestBtns)
