from "%globalsDarg/darg_library.nut" import *
let { curSectionId, curTabId, questsBySection, seenQuests, saveSeenQuestsCurSection, sectionsCfg,
  inactiveEventUnlocks, isCurSectionInactive, PROGRESS_STAT } = require("questsState.nut")
let { textButtonSecondary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { receiveUnlockRewards, unlockRewardsInProgress, unlockTables } = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { newMark, mkSectionBtn, sectionBtnHeight, sectionBtnMaxWidth, sectionBtnGap, mkTimeUntil,
  allQuestsCompleted, linkToEventBtn, mkAdsBtn } = require("questsPkg.nut")
let { mkRewardsPreview, questItemsGap, statusIconSize } = require("rewardsComps.nut")
let { mkQuestBar, mkProgressBar, progressBarHeight } = require("questBar.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize, gradientHeightBottom } = require("%rGui/options/mkOptionsScene.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let { defer } = require("dagor.workcycle")
let { sendBqQuestsTask } = require("bqQuests.nut")
let { WARBOND } = require("%appGlobals/currenciesState.nut")


let bgColor = 0x80000000
let unseenMarkMargin = hdpx(20)
let progressBarMargin = hdpx(30)

let btnSize = [saRatio < 2 ? hdpx(230) : hdpx(300), hdpx(90)]
let childOvr = saRatio < 2 ? fontSmallShaded : null
let btnStyle = { ovr = { size = btnSize, minWidth = 0 }, childOvr }
let btnStyleSound = { ovr = { size = btnSize, minWidth = 0, sound = { click  = "meta_get_unlock" } }, childOvr }
let contentWidth = saSize[0] - tabW - minContentOffset

let scrollHandler = ScrollHandler()
curSectionId.subscribe(@(_) scrollHandler.scrollToY(0))

let isPurchNoNeedResultWindow = @(purch) purch?.source == "userstatReward"
  && null == purch.goods.findvalue(@(g) g.id != "warbond" || (g.id == "warbond" && g.count >= 100))
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

let topBlockHeight = max(sectionBtnHeight, progressBarHeight + progressBarMargin)
let mkVerticalPannableAreaNoBlocks = verticalPannableAreaCtor(sh(100) - topAreaSize,
  [questItemsGap, gradientHeightBottom])
let mkVerticalPannableAreaOneBlock = verticalPannableAreaCtor(sh(100) - topAreaSize - topBlockHeight,
  [questItemsGap, gradientHeightBottom])
let mkVerticalPannableAreaTwoBlocks = verticalPannableAreaCtor(sh(100) - topAreaSize - topBlockHeight * 2,
  [questItemsGap, gradientHeightBottom])
let pannableCtors = [mkVerticalPannableAreaNoBlocks, mkVerticalPannableAreaOneBlock, mkVerticalPannableAreaTwoBlocks]

let newMarkSize = calc_comp_size(newMark)

let function receiveReward(item, warbondDelta) {
  receiveUnlockRewards(item.name, 1, { stage = 1 })
  sendBqQuestsTask(item, warbondDelta)
}

let function mkQuestText(item) {
  let locId = item.meta?.lang_id ?? item.name
  let header = loc(locId)
  let text = loc($"{locId}/desc")
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    children = [
      {
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        maxWidth = pw(100)
        text = header
      }.__update(fontSmall)

      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = pw(100)
        text
      }.__update(fontTiny)
    ]
  }
}

let function mkAchievementText(item) {
  let locId = item.meta?.lang_id ?? item.name
  let text = loc($"{locId}/desc")
  return {
    minHeight = hdpx(80)
    size = [flex(), SIZE_TO_CONTENT]
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = pw(100)
      vplace = ALIGN_CENTER
      text
    }.__update(fontTinyAccented)
  }
}

let function mkBtn(item, warbondDelta) {
  let { name, progressCorrectionStep = 0 } = item
  let isRewardInProgress = Computed(@() name in unlockRewardsInProgress.value)

  return @() {
    watch = isRewardInProgress
    size = btnSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = isRewardInProgress.value ? spinner
      : item?.hasReward
        ? textButtonSecondary(
            utf8ToUpper(loc("btn/receive")),
            @() receiveReward(item, warbondDelta),
            btnStyleSound)
      : item?.isFinished
        ? {
            size = btnSize
            rendObj = ROBJ_TEXT
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            text = utf8ToUpper(loc("ui/received"))
          }.__update(fontSmallAccentedShaded)
      : progressCorrectionStep > 0 ? mkAdsBtn(item)
      : textButtonCommon(
          utf8ToUpper(loc("btn/receive")),
          @() anim_start($"unfilledBarEffect_{name}"),
          btnStyle)
  }
}

let function mkItem(item, textCtor) {
  let rewards = item?.stages?[0].rewards ?? {}
  let questProgress = item.stages[0]?.updStats
    .findvalue(@(v) v.name == PROGRESS_STAT).value.tointeger()
  let progressReward = !questProgress ? [] : [{
    count = questProgress
    rType = "stat"
    id = PROGRESS_STAT
    slots = 1
  }]

  let isUnseen = Computed(@() !item.hasReward
    && item.name not in seenQuests.value
    && item.name not in inactiveEventUnlocks.value)

  let rewardsPreview = Computed(function() {
    local res = []
    foreach (id, count in rewards) {
      let reward = serverConfigs.value.userstatRewards?[id]
      res.extend(getRewardsViewInfo(reward, count))
    }
    return progressReward.extend(res.sort(sortRewardsViewInfo))
  })

  let headerPadding = Computed(@() item.hasReward ? unseenMarkMargin * 2
  : isUnseen.value ? newMarkSize[0]
  : 0)

  return {
    rendObj = ROBJ_SOLID
    color = bgColor
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      @() {
        watch = isUnseen
        size = [flex(), SIZE_TO_CONTENT]
        children = item.hasReward
            ? {
                margin = unseenMarkMargin
                children = priorityUnseenMark
              }
          : isUnseen.value ? newMark
          : null
      }

      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [hdpx(10), hdpx(30), hdpx(15), hdpx(30)]
        flow = FLOW_HORIZONTAL
        gap = questItemsGap
        vplace = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
          @() {
            watch = headerPadding
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = hdpx(8)
            children = [
              textCtor(item).__update({padding = [0, 0, 0, headerPadding.value] })
              mkQuestBar(item)
            ]
          }

          @() {
            watch = rewardsPreview
            flow = FLOW_HORIZONTAL
            gap = questItemsGap
            halign = ALIGN_RIGHT
            children = rewardsPreview.value.len() > 0 ? mkRewardsPreview(rewardsPreview.value, item?.isFinished) : null
          }

          @() {
            watch = rewardsPreview
            children = mkBtn(item, rewardsPreview.value.findvalue(@(r) r.id == WARBOND)?.count ?? 0)
          }
        ]
      }
    ]
  }
}

let sectionPart = 0.9
let gapPart = 1 - sectionPart

let function mkSectionTabs(sections) {
  let sLen = sections.len()
  let btnWidth = min(sectionBtnMaxWidth, contentWidth / sLen * sectionPart)

  let sectionsFont = Computed(function() {
    foreach (id in sections)
      if (calc_str_box(sectionsCfg.value?[id].text ?? "", fontSmallShaded)[0] > btnWidth - statusIconSize - sectionBtnGap * 2)
        return fontTinyShaded
    return fontSmallShaded
  })

  return @() {
    watch = [unlockTables, sectionsFont]
    size = [contentWidth, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = contentWidth * gapPart / (sLen - 1)
    children = sections.map(@(id) mkSectionBtn(id, btnWidth, sectionsFont.value, unlockTables.value?[id] == false))
  }
}

let function questTimerUntilStart() {
  let firstDayStartedAt = userstatStats.value?.stats.day1["$startedAt"]
  let curSectionDay = inactiveEventUnlocks.value
    .findvalue(@(u) u.table == curSectionId.value)?.meta.event_day
    .tointeger()

  local relativeStartTime = null
  if (curSectionDay != null && firstDayStartedAt != null) {
    local firstDayStartTime = firstDayStartedAt - serverTime.value
    relativeStartTime = firstDayStartTime + (curSectionDay - 1) * TIME_DAY_IN_SECONDS
  }

  return {
    watch = [serverTime, curSectionId, userstatStats, inactiveEventUnlocks]
    size = flex()
    margin = [hdpx(100), 0, 0, 0]
    children = relativeStartTime <= 0 ? null
      : mkTimeUntil(secondsToHoursLoc(relativeStartTime), "quests/untilTheStart", fontMedium)
  }
}

let function questsWndPage(sections, itemCtor, tabId, progressUnlock = Watched(null)) {
  let itemsSort = @(a, b) b.hasReward <=> a.hasReward
    || a.isFinished <=> b.isFinished
    || a.name in seenQuests.value <=> b.name in seenQuests.value
    || a.name <=> b.name

  let blocksOnTop = Computed(function() {
    local n = 0
    if (progressUnlock.value)
      n++
    if (sections.value.len() > 1)
      n++
    return n
  })

  return {
    key = sections
    size = flex()
    function onAttach() {
      curSectionId(sections.value?[0])
      addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    }
    function onDetach() {
      curSectionId(null)
      curTabId(null)
      removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    }
    children = [
      @() {
        watch = [sections, questsBySection]
        size = flex()
        flow = FLOW_VERTICAL
        children = [
          sections.value.findindex(@(s) questsBySection.value[s].len() > 0) == null ? allQuestsCompleted : null

          @() !progressUnlock.value ? { watch = progressUnlock }
            : {
                watch = progressUnlock
                size = [flex(), SIZE_TO_CONTENT]
                margin = [0, 0, progressBarMargin, 0]
                flow = FLOW_HORIZONTAL
                gap = isWidescreen ? hdpx(60) : hdpx(45)
                valign = ALIGN_CENTER
                children = [
                  linkToEventBtn()
                  mkProgressBar(progressUnlock.value?.__merge({ tabId }))
                ]
              }

          sections.value.len() > 1 ? mkSectionTabs(sections.value) : null

          @() {
            watch = isCurSectionInactive
            size = [contentWidth, SIZE_TO_CONTENT]
            children = isCurSectionInactive.value ? questTimerUntilStart : null
          }

          @() {
            watch = [isCurSectionInactive, blocksOnTop]
            size = flex()
            children = isCurSectionInactive.value ? null : [
              pannableCtors[blocksOnTop.value](
                @() {
                  watch = [curSectionId, seenQuests, questsBySection]
                  size = [flex(), SIZE_TO_CONTENT]
                  flow = FLOW_VERTICAL
                  gap = hdpx(20)
                  children = questsBySection.value?[curSectionId.value ?? sections.value?[0]]
                    .values()
                    .sort(itemsSort)
                    .map(@(item) itemCtor(item, tabId))
                  onDetach = @() saveSeenQuestsCurSection()
                },
                { pos = [0, blocksOnTop.value == 0 ? -questItemsGap : 0] },
                { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
              mkScrollArrow(scrollHandler, MR_B)
            ]
          }
        ]
      }
    ]
  }
}

return {
  questsWndPage
  mkQuest = @(item, tabId) mkItem(item.__merge({ tabId }), mkQuestText)
  mkAchievement = @(item, tabId) mkItem(item.__merge({ tabId }), mkAchievementText)
}
