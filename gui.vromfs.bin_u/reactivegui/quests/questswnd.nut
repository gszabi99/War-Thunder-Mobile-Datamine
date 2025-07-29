from "%globalsDarg/darg_library.nut" import *
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB,
  progressUnlockByTab, progressUnlockBySection, curTabParams
} = require("questsState.nut")
let { questsWndPage, mkQuest, mkAchievement, unseenMarkMargin } = require("questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { eventSeason, eventEndsAt, isEventActive, specialEventsOrdered, openEventWnd, getSpecialEventName,
   specialEventsLootboxesState } = require("%rGui/event/eventState.nut")
let { openBattlePassWnd, hasBpRewardsToReceive, isBpSeasonActive
} = require("%rGui/battlePass/battlePassState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkQuestsHeaderBtn, linkToEventWidth } = require("questsPkg.nut")
let { doesLocTextExist } = require("dagor.localize")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { shopGoods, openShopWnd } = require("%rGui/shop/shopState.nut")
let { defaultShopCategory } = require("%rGui/shop/shopCommon.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { progressBarRewardSize } = require("rewardsComps.nut")

let iconSize = hdpxi(100)
let iconColor = 0xFFFFFFFF

let iconSeason = Computed(@() $"ui/gameuiskin#banner_event_{eventSeason.get()}.avif")
let imageSizeMul = Computed(@() getEventPresentation(eventSeason.get()).imageSizeMul)
let imageTabOffset = Computed(@() getEventPresentation(eventSeason.get()).imageTabOffset)

let mkUnseen = @(tabId) Computed(function() {
  if (progressUnlockByTab.get()?[tabId].hasReward)
    return UNSEEN_HIGH
  let hasUnseen = hasUnseenQuestsBySection.get()
  return questsCfg.get()?[tabId].findvalue(@(s) !!hasUnseen?[s] || !!progressUnlockBySection.get()?[s].hasReward) != null
    ? UNSEEN_HIGH
    : SEEN
})

let linkToEventBtnCtor = @() {
  minHeight = progressBarRewardSize
  watch = imageSizeMul
  children = mkQuestsHeaderBtn(loc("mainmenu/rewardsList"),
    iconSeason,
    @() openEventWnd(), null, imageSizeMul.get())
}

let linkToBattlePassBtnCtor = @() {
  minHeight = progressBarRewardSize
  watch = imageSizeMul
  children = mkQuestsHeaderBtn(loc("mainmenu/rewardsList"),
    iconSeason,
    openBattlePassWnd,
    @() {
      watch = hasBpRewardsToReceive
      margin = unseenMarkMargin
      children = hasBpRewardsToReceive.get() ? priorityUnseenMark : null
    },
    imageSizeMul.get())
}

function mkLinkToStoreBtnInfo(idx) {
  let lootboxInfo = Computed(@() specialEventsLootboxesState.get().withLootboxes.findvalue(@(v) v.idx == idx))
  let id = getSpecialEventName(idx + 1)
  let eventName = Computed(@() specialEventsLootboxesState.get().withoutLootboxes.findvalue(@(v) v.eventId == id)?.eventName ?? "")
  let eventIcon = Computed(@() lootboxInfo.get()
    ? getEventPresentation(lootboxInfo.get().eventName).icon
    : getEventPresentation(eventName.get()).icon)
  let hasGoods = Computed(@() eventName.get() != ""
    && shopGoods.get().findindex(@(item) item?.meta.eventId == eventName.get()) != null)

  return {
    width = Computed(@() hasGoods.get() || lootboxInfo.get() ? linkToEventWidth : 0)
    comp = @() {
      minHeight = progressBarRewardSize
      watch = [hasGoods, lootboxInfo]
      children = hasGoods.get()
          ? mkQuestsHeaderBtn(loc("mainmenu/btnShop"), eventIcon, @() openShopWnd(defaultShopCategory))
        : lootboxInfo.get()
          ? mkQuestsHeaderBtn(loc("mainmenu/rewardsList"), eventIcon, @() openEventWnd(lootboxInfo.get().eventId))
        : null
      }
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
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      @() {
        watch = eventSeasonName
        size = FLEX_H
        halign = ALIGN_RIGHT
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = eventSeasonName.value
      }.__update(fontTinyAccented)
      @() {
        watch = [eventEndsAt, serverTime]
        size = FLEX_H
        halign = ALIGN_RIGHT
        rendObj = ROBJ_TEXT
        text = !eventEndsAt.value || (eventEndsAt.value - serverTime.get() < 0) ? null
          : secondsToHoursLoc(eventEndsAt.value - serverTime.get())
      }.__update(fontTinyAccented)
    ]
  }
}

function mkSpecialEventTabContent(idx) {
  let endsAt = Computed(@() specialEventsOrdered.get()?[idx].endsAt)
  let locId = Computed(@() $"events/name/{specialEventsOrdered.get()?[idx].eventName}")
  let image = Computed(@() getEventPresentation(specialEventsOrdered.get()?[idx].eventName).icon)

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
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = [
          @() {
            watch = locId
            size = FLEX_H
            halign = ALIGN_RIGHT
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc(locId.get())
          }.__update(fontTinyAccented)
          @() {
            watch = [serverTime, endsAt]
            size = FLEX_H
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
  let { comp, width } = mkLinkToStoreBtnInfo(idx)
  return {
    id
    tabContent = mkSpecialEventTabContent(idx)
    isFullWidth = true
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()?[id] ?? []), mkQuest, id, comp, width)
    isVisible = Computed(@() questsCfg.get()?[id].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
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
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()[COMMON_TAB]), mkQuest, COMMON_TAB, linkToBattlePassBtnCtor)
    isVisible = Computed(@() questsCfg.get()[COMMON_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null
      && isBpSeasonActive.get())
  }
  {
    id = EVENT_TAB
    image = iconSeason
    imageSizeMul = imageSizeMul
    imageTabOffset = imageTabOffset
    isFullWidth = true
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()[EVENT_TAB]), mkQuest, EVENT_TAB, linkToEventBtnCtor)
    tabContent = eventTabContent()
    isVisible = Computed(@() isEventActive.value
      && questsCfg.get()[EVENT_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    ovr = { key = "main_event_tab" } 
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
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()[ACHIEVEMENTS_TAB]), mkAchievement, ACHIEVEMENTS_TAB)
    isVisible = Computed(@() questsCfg.get()[ACHIEVEMENTS_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
  }
  {
    id = PROMO_TAB
    locId = "quests/promo"
    image = "ui/gameuiskin#quest_promo_icon.svg"
    imageSizeMul = 0.9
    isFullWidth = true
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()[PROMO_TAB]), mkQuest, PROMO_TAB)
    isVisible = Computed(@() questsCfg.get()[PROMO_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
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
