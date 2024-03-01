from "%globalsDarg/darg_library.nut" import *
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, MINI_EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB, SPECIAL_EVENT_1_TAB,
  progressUnlockByTab, progressUnlockBySection, curTabParams
} = require("questsState.nut")
let { questsWndPage, mkQuest, mkAchievement, unseenMarkMargin } = require("questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { eventSeason, miniEventSeasonName, eventEndsAt, miniEventEndsAt, isEventActive, isMiniEventActive,
  specialEvents, openEventWnd
} = require("%rGui/event/eventState.nut")
let { openBattlePassWnd, hasBpRewardsToReceive, isBpSeasonActive
} = require("%rGui/battlePass/battlePassState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkQuestsHeaderBtn } = require("questsPkg.nut")
let { doesLocTextExist } = require("dagor.localize")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let iconSize = hdpxi(100)
let iconColor = 0xFFFFFFFF

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

function eventTabContent(){
  let eventSeasonName = Computed(function() {
    local locId = $"events/name/{eventSeason.value}"
    if (!doesLocTextExist(locId))
      locId = "events/name/default"
    return loc(locId)
  })

  return {
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

function mkSpecialEventTabContent(idx) {
  let endsAt = Computed(@() specialEvents.value?[idx].endsAt)
  let locId = Computed(@() $"events/name/{specialEvents.value?[idx].eventName}")
  let image = Computed(@() $"ui/gameuiskin#icon_event_{specialEvents.value?[idx].eventName}_quests_wnd.svg")

  return {
    size = flex()
    flow = FLOW_HORIZONTAL
    children = [
      @() {
        watch = image
        size = [iconSize, iconSize]
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture($"{image.get()}:{iconSize}:{iconSize}:P")
        color = iconColor
        keepAspect = KEEP_ASPECT_FIT
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          @() {
            watch = locId
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_RIGHT
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc(locId.get())
          }.__update(fontSmall)
          @() {
            watch = [serverTime, endsAt]
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_RIGHT
            rendObj = ROBJ_TEXT
            text = !endsAt.get() || (endsAt.get() - serverTime.get() < 0) ? null
              : secondsToHoursLoc(endsAt.get() - serverTime.get())
          }.__update(fontSmall)
        ]
      }
    ]
  }
}

let tabs = [
  {
    id = COMMON_TAB
    locId = "quests/common"
    image = iconSeason
    imageSizeMul = 1.2
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[COMMON_TAB]), mkQuest, COMMON_TAB, linkToBattlePassBtnCtor)
    isVisible = Computed(@() questsCfg.value[COMMON_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null
      && isBpSeasonActive.get())
  }
  {
    id = EVENT_TAB
    image = iconSeason
    imageSizeMul = 1.2
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[EVENT_TAB]), mkQuest, EVENT_TAB, linkToEventBtnCtor)
    tabContent = eventTabContent
    tabHeight = hdpx(160)
    isVisible = Computed(@() isEventActive.value
      && questsCfg.value[EVENT_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = MINI_EVENT_TAB
    image = "ui/gameuiskin#icon_event_grenade_quests_wnd.svg"
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
    imageSizeMul = 0.8
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[ACHIEVEMENTS_TAB]), mkAchievement, ACHIEVEMENTS_TAB)
    isVisible = Computed(@() questsCfg.value[ACHIEVEMENTS_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = PROMO_TAB
    locId = "quests/promo"
    image = "ui/gameuiskin#quest_promo_icon.svg"
    imageSizeMul = 0.9
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value[PROMO_TAB]), mkQuest, PROMO_TAB)
    isVisible = Computed(@() questsCfg.value[PROMO_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  {
    id = SPECIAL_EVENT_1_TAB
    tabContent = mkSpecialEventTabContent(SPECIAL_EVENT_1_TAB)
    isFullWidth = true
    content = questsWndPage(Computed(@() questsCfg.value?[SPECIAL_EVENT_1_TAB] ?? []), mkQuest, SPECIAL_EVENT_1_TAB)
    isVisible = Computed(@() questsCfg.value?[SPECIAL_EVENT_1_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
]

foreach(tab in tabs)
  if ("unseen" not in tab)
    tab.unseen <- mkUnseen(tab.id)

let gamercardQuestBtns = @() {
  watch = curTabParams
  size = flex()
  children = mkCurrenciesBtns(curTabParams.get()?.currencies ?? [], curTabParams.get()?.tabId)
}

mkOptionsScene("questsWnd", tabs, isQuestsOpen, curTabId, gamercardQuestBtns)
