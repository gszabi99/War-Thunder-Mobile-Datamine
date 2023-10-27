from "%globalsDarg/darg_library.nut" import *
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, PROMO_TAB, progressUnlock } = require("questsState.nut")
let questsWndPage = require("questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { eventSeasonName, eventEndsAt, isEventActive } = require("%rGui/event/eventState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")


let function isUnseen(sections, hasUnseen) {
  foreach (section in sections)
    if (hasUnseen?[section])
      return UNSEEN_HIGH
  return SEEN
}

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

let tabs = [
  {
    id = COMMON_TAB
    locId = "quests/common"
    image = "ui/gameuiskin#quest_common_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[COMMON_TAB]))
    unseen = Computed(@() isUnseen(questsCfg.value[COMMON_TAB], hasUnseenQuestsBySection.value))
    isVisible = Computed(@() questsCfg.value[COMMON_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = EVENT_TAB
    image = "ui/gameuiskin#quest_events_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[EVENT_TAB]), progressUnlock)
    tabContent = eventTabContent
    tabHeight = hdpx(160)
    unseen = Computed(@() progressUnlock.value?.hasReward ? UNSEEN_HIGH
      : isUnseen(questsCfg.value[EVENT_TAB], hasUnseenQuestsBySection.value))
    isVisible = Computed(@() isEventActive.value
      && questsCfg.value[EVENT_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = PROMO_TAB
    locId = "quests/promo"
    image = "ui/gameuiskin#quest_promo_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[PROMO_TAB]))
    unseen = Computed(@() isUnseen(questsCfg.value[PROMO_TAB], hasUnseenQuestsBySection.value))
    isVisible = Computed(@() questsCfg.value[PROMO_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
]

let gamercardQuestBtns = @() {
  watch = isEventActive
  size = flex()
  children = mkCurrenciesBtns(isEventActive.value ? [WARBOND, WP, GOLD] : [WP, GOLD])
}

mkOptionsScene("questsWnd", tabs, isQuestsOpen, curTabId, gamercardQuestBtns)
