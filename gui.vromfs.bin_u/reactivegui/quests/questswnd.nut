from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkGradientCtorDoubleSideX, gradTexSize } = require("%rGui/style/gradients.nut")
let { isQuestsOpen, hasUnseenQuestsBySection, questsCfg, questsBySection, curTabId,
  COMMON_TAB, EVENT_TAB, PROMO_TAB, ACHIEVEMENTS_TAB, PERSONAL_TAB,
  progressUnlockByTab, progressUnlockBySection, curTabParams
} = require("%rGui/quests/questsState.nut")
let { questsWndPage, mkQuest, mkAchievement, unseenMarkMargin } = require("%rGui/quests/questsWndPage.nut")
let { tabW, tabPadding } = require("%rGui/options/optionsStyle.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { eventSeason, eventEndsAt, isEventActive, specialEventsOrdered, openEventWnd, getSpecialEventName,
   specialEventsLootboxesState } = require("%rGui/event/eventState.nut")
let { getSpecialEventLocName, getSpecialEventRewardUnitName } = require("%rGui/event/specialEventLocName.nut")
let { hasBpRewardsToReceive, isBpSeasonActive
} = require("%rGui/battlePass/battlePassState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { mkQuestsHeaderBtn, linkToEventWidth } = require("%rGui/quests/questsPkg.nut")
let { doesLocTextExist } = require("dagor.localize")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { selLineSize } = require("%rGui/components/selectedLine.nut")
let { shopGoods, openShopWnd, allShopGoods } = require("%rGui/shop/shopState.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { progressBarRewardSize } = require("%rGui/quests/rewardsComps.nut")
let { eventsPassList, getEventPassName, mkHasEpRewardsToReceive } = require("%rGui/battlePass/eventPassState.nut")
let { hasOPRewardsToReceive } = require("%rGui/battlePass/operationPassState.nut")
let { openPassScene, BATTLE_PASS, OPERATION_PASS } = require("%rGui/battlePass/passState.nut")
let { registerUnlocksSceneToUpdate } = require("%rGui/unlocks/userstat.nut")

let iconSize = hdpxi(100)
let iconColor = 0xFFFFFFFF
let tabGap = hdpx(10)

let maxTabTextWidth = tabW - iconSize - tabGap - selLineSize - tabPadding[1] * 2

let personalTabImageByCamp = {
  air = "ui/gameuiskin#icon_personal_air.svg"
  ships_new = "ui/gameuiskin#icon_personal_ship.svg"
  tanks_new = "ui/gameuiskin#icon_personal_tank.svg"
}

let iconPersonal = Computed(@() personalTabImageByCamp?[curCampaign.get()])
let iconSeason = Computed(@() getEventPresentation(eventSeason.get()).image)
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
  let hasEpRewardsToReceive = mkHasEpRewardsToReceive(
    Computed(@() isEventPassQuests.get() ? getEventPassName(eventName.get()) : null))
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
          ? mkQuestsHeaderBtn(loc("mainmenu/btnShop"), eventIcon, @() openShopWnd(null, null, "events"))
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
  let timeLeft = Computed(@() !endsAt.get() || (endsAt.get() - serverTime.get() < 0) ? null
    : secondsToHoursLoc(endsAt.get() - serverTime.get()))

  return {
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = tabGap
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
          mkTabText(eventNameFirstRow)
          mkTabText(eventNameSecondRow)
          mkTabText(timeLeft)
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

let sceneId = "questsWnd"
mkOptionsScene(sceneId, tabs, isQuestsOpen, curTabId, gamercardQuestBtns)
registerUnlocksSceneToUpdate(sceneId)