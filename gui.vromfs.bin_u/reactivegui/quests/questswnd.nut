from "%globalsDarg/darg_library.nut" import *
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, isEventActive,
  COMMON_TAB, EVENT_TAB, PROMO_TAB } = require("questsState.nut")
let questsWndPage = require("questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { activeUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { WP, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")

let function isUnseen(sections, hasUnseen) {
  foreach (section in sections)
    if (hasUnseen?[section])
      return UNSEEN_HIGH
  return SEEN
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
    locId = "mainmenu/events"
    image = "ui/gameuiskin#quest_events_icon.svg"
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[EVENT_TAB]),
      Computed(@() activeUnlocks.value.findvalue(@(unlock) "event_progress" in unlock?.meta)))
    unseen = Computed(@() isUnseen(questsCfg.value[EVENT_TAB], hasUnseenQuestsBySection.value))
    isVisible = Computed(@() questsCfg.value[EVENT_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
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

mkOptionsScene("questsWnd", tabs, isQuestsOpen, null, gamercardQuestBtns)
