from "%globalsDarg/darg_library.nut" import *
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB,
  progressUnlockByTab, progressUnlockBySection, curTabParams
} = require("questsState.nut")
let { questsWndPage, mkQuest, mkAchievement, unseenMarkMargin } = require("questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { eventSeason, eventEndsAt, isEventActive, specialEventsOrdered, openEventWnd, getSpecialEventName
} = require("%rGui/event/eventState.nut")
let { openBattlePassWnd, hasBpRewardsToReceive, isBpSeasonActive
} = require("%rGui/battlePass/battlePassState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkQuestsHeaderBtn } = require("questsPkg.nut")
let { doesLocTextExist } = require("dagor.localize")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { shopGoods, openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_FEATURED } = require("%rGui/shop/shopCommon.nut")


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

function linkToStoreBtnCtor(id) {
  let eventName = Computed(@() questsCfg.get()?[id][0] ?? "")
  let eventIcon = Computed(@() $"ui/gameuiskin#icon_event_{eventName.get()}_quests.svg")
  let hasGoods = Computed(@() eventName.get() != ""
    && shopGoods.get().findindex(@(item) item?.meta.eventId == eventName.get()) != null)

  return @() {
    watch = hasGoods
    children = !hasGoods.get() ? null
      : mkQuestsHeaderBtn(loc("mainmenu/btnShop"), eventIcon, @() openShopWnd(SC_FEATURED))
  }
}

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
      }.__update(fontTinyAccented)
      @() {
        watch = [eventEndsAt, serverTime]
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_RIGHT
        rendObj = ROBJ_TEXT
        text = !eventEndsAt.value || (eventEndsAt.value - serverTime.value < 0) ? null
          : secondsToHoursLoc(eventEndsAt.value - serverTime.value)
      }.__update(fontTinyAccented)
    ]
  }
}

function mkSpecialEventTabContent(idx) {
  let endsAt = Computed(@() specialEventsOrdered.get()?[idx].endsAt)
  let locId = Computed(@() $"events/name/{specialEventsOrdered.get()?[idx].eventName}")
  let image = Computed(@() $"ui/gameuiskin#icon_event_{specialEventsOrdered.get()?[idx].eventName}_quests_wnd.svg")

  return {
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
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
          }.__update(fontTinyAccented)
          @() {
            watch = [serverTime, endsAt]
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_RIGHT
            rendObj = ROBJ_TEXT
            text = !endsAt.get() || (endsAt.get() - serverTime.get() < 0) ? null
              : secondsToHoursLoc(endsAt.get() - serverTime.get())
          }.__update(fontTinyAccented)
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
    content = questsWndPage(Computed(@() questsCfg.value?[id] ?? []), mkQuest, id, @() linkToStoreBtnCtor(id))
    isVisible = Computed(@() questsCfg.value?[id].findindex(@(s) questsBySection.value[s].len() > 0) != null)
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
    tabContent = eventTabContent()
    isVisible = Computed(@() isEventActive.value
      && questsCfg.value[EVENT_TAB].findindex(@(s) questsBySection.value[s].len() > 0) != null)
  }
  mkSpecialQuestsTab(0)
  mkSpecialQuestsTab(1)
  mkSpecialQuestsTab(2)
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
]

foreach(tab in tabs)
  if ("unseen" not in tab)
    tab.unseen <- mkUnseen(tab.id)

let gamercardQuestBtns = @() {
  watch = curTabParams
  size = flex()
  children = mkCurrenciesBtns(curTabParams.get()?.currencies ?? [])
}

mkOptionsScene("questsWnd", tabs, isQuestsOpen, curTabId, gamercardQuestBtns)
