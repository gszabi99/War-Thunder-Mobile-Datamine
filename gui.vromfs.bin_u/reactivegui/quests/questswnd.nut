from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkGradientCtorDoubleSideX, gradTexSize } = require("%rGui/style/gradients.nut")
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB, PERSONAL_TAB,
  progressUnlockByTab, progressUnlockBySection, curTabParams
} = require("%rGui/quests/questsState.nut")
let { questsWndPage, mkQuest, mkAchievement, unseenMarkMargin } = require("%rGui/quests/questsWndPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { eventSeason, eventEndsAt, isEventActive, specialEventsOrdered, openEventWnd, getSpecialEventName,
   specialEventsLootboxesState } = require("%rGui/event/eventState.nut")
let { hasBpRewardsToReceive, isBpSeasonActive
} = require("%rGui/battlePass/battlePassState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkQuestsHeaderBtn, linkToEventWidth } = require("%rGui/quests/questsPkg.nut")
let { doesLocTextExist } = require("dagor.localize")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { shopGoods, openShopWnd } = require("%rGui/shop/shopState.nut")
let { defaultShopCategory } = require("%rGui/shop/shopCommon.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { progressBarRewardSize } = require("%rGui/quests/rewardsComps.nut")
let { eventsPassList, getEventPassName, hasEpRewardsToReceive } = require("%rGui/battlePass/eventPassState.nut")
let { hasOPRewardsToReceive } = require("%rGui/battlePass/operationPassState.nut")
let { openPassScene, BATTLE_PASS, OPERATION_PASS } = require("%rGui/battlePass/passState.nut")

let iconSize = hdpxi(100)
let iconColor = 0xFFFFFFFF

let personalTabImageByCamp = {
  air = "ui/gameuiskin#icon_personal_air.svg"
  ships_new = "ui/gameuiskin#icon_personal_ship.svg"
  tanks_new = "ui/gameuiskin#icon_personal_tank.svg"
}

let iconPersonal = Computed(@() personalTabImageByCamp?[curCampaign.get()])
let iconSeason = Computed(@() $"ui/gameuiskin#banner_event_{eventSeason.get()}.avif")
let imageSizeMul = Computed(@() getEventPresentation(eventSeason.get()).imageSizeMul)
let imageTabOffset = Computed(@() getEventPresentation(eventSeason.get()).imageTabOffset)

let mkUnseen = @(tabId, hasReward) Computed(function() {
  if (hasReward.get() || progressUnlockByTab.get()?[tabId].hasReward)
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
    @() openPassScene(BATTLE_PASS),
    @() {
      watch = hasBpRewardsToReceive
      margin = unseenMarkMargin
      children = hasBpRewardsToReceive.get() ? priorityUnseenMark : null
    },
    imageSizeMul.get())
}

let imageMask = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideX(0, 0x80000000, 0.25))

let linkToOperationPassBtnCtor = @() {
  size = FLEX_H
  minHeight = progressBarRewardSize
  flow = FLOW_HORIZONTAL
  children = [
    mkQuestsHeaderBtn(loc("mainmenu/rewardsList"),
      iconPersonal,
      @() openPassScene(OPERATION_PASS),
      @() {
        watch = hasOPRewardsToReceive
        margin = unseenMarkMargin
        children = hasOPRewardsToReceive.get() ? priorityUnseenMark : null
      }
    )
    {
      size = FLEX_H
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = {
        size = FLEX_H
        rendObj = ROBJ_IMAGE
        image = imageMask()
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        padding = hdpx(24)
        children = {
          rendObj = ROBJ_TEXT
          text = loc("quests/personalUpdateInfo")
        }.__update(fontSmall)
      }
    }
  ]
}

function mkLinkToStoreBtnInfo(idx) {
  let lootboxInfo = Computed(@() specialEventsLootboxesState.get().withLootboxes.findvalue(@(v) v.idx == idx))
  let id = getSpecialEventName(idx + 1)
  let eventName = Computed(@() specialEventsOrdered.get().findvalue(@(v) v.eventId == id)?.eventName ?? "")
  let eventIcon = Computed(@() lootboxInfo.get()
    ? getEventPresentation(lootboxInfo.get().eventName).icon
    : getEventPresentation(eventName.get()).icon)
  let hasGoods = Computed(@() eventName.get() != ""
    && shopGoods.get().findindex(@(item) item?.meta.eventId == eventName.get()) != null)
  let isEventPassQuests = Computed(@() eventsPassList.get().findindex(@(v) v.eventName == eventName.get()) != null)
  let hasComponent = Computed(@() isEventPassQuests.get() || hasGoods.get() || lootboxInfo.get())
  return {
    width = Computed(@() hasComponent.get() ? linkToEventWidth : 0)
    hasComponent
    comp = @() {
      minHeight = !isEventPassQuests.get() && !hasGoods.get() && !lootboxInfo.get() && !progressUnlockByTab.get()?[id] ? 0 : progressBarRewardSize
      watch = [hasGoods, lootboxInfo, isEventPassQuests, progressUnlockByTab]
      children = isEventPassQuests.get()
          ? mkQuestsHeaderBtn(loc("mainmenu/rewardsList"),
              eventIcon,
              @() openPassScene(getEventPassName(eventName.get())),
              @() {
                watch = hasEpRewardsToReceive
                margin = unseenMarkMargin
                children = hasEpRewardsToReceive.get() ? priorityUnseenMark : null
              })
        : hasGoods.get()
          ? mkQuestsHeaderBtn(loc("mainmenu/btnShop"), eventIcon, @() openShopWnd(defaultShopCategory))
        : lootboxInfo.get()
          ? mkQuestsHeaderBtn(loc("mainmenu/rewardsList"), eventIcon, @() openEventWnd(lootboxInfo.get().eventId))
        : null
      }
    hasReward = Computed(@() isEventPassQuests.get() ? hasEpRewardsToReceive.get() : false)
  }
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
      @() {
        watch = [eventEndsAt, serverTime]
        size = FLEX_H
        halign = ALIGN_RIGHT
        rendObj = ROBJ_TEXT
        text = !eventEndsAt.get() || (eventEndsAt.get() - serverTime.get() < 0) ? null
          : secondsToHoursLoc(eventEndsAt.get() - serverTime.get())
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
  let { comp, width, hasComponent, hasReward } = mkLinkToStoreBtnInfo(idx)
  return {
    id
    tabContent = mkSpecialEventTabContent(idx)
    isFullWidth = true
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()?[id] ?? []), mkQuest, id, comp, width, hasComponent)
    isVisible = Computed(@() questsCfg.get()?[id].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    hasReward
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
    isVisible = Computed(@() isEventActive.get()
      && questsCfg.get()[EVENT_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    ovr = { key = "main_event_tab" } 
  }
  mkSpecialQuestsTab(0)
  mkSpecialQuestsTab(1)
  mkSpecialQuestsTab(2)
  mkSpecialQuestsTab(3)
  mkSpecialQuestsTab(4)
  {
    id = PERSONAL_TAB
    locId = "quests/personal"
    image = iconPersonal
    isFullWidth = true
    contentCtor = @() questsWndPage(Computed(@() questsCfg.get()[PERSONAL_TAB]), mkQuest, PERSONAL_TAB, linkToOperationPassBtnCtor)
    isVisible = Computed(@() questsCfg.get()[PERSONAL_TAB].findindex(@(s) questsBySection.get()[s].len() > 0) != null)
    hasReward = hasOPRewardsToReceive
  }
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
    tab.unseen <- mkUnseen(tab.id, tab?.hasReward ?? Watched(false))

let gamercardQuestBtns = @() {
  watch = curTabParams
  size = flex()
  children = mkCurrenciesBtns(curTabParams.get()?.currencies ?? [])
}

mkOptionsScene("questsWnd", tabs, isQuestsOpen, curTabId, gamercardQuestBtns)
