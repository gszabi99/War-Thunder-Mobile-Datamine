from "%globalsDarg/darg_library.nut" import *
let { curSectionId, questsBySection, seenQuests, saveSeenQuestsCurSection, sectionsCfg, inactiveEventUnlocks
} = require("questsState.nut")
let { textButtonSecondary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { receiveUnlockRewards, unlockRewardsInProgress, unlockTables } = require("%rGui/unlocks/unlocks.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { newMark, mkSectionBtn, sectionBtnHeight, sectionBtnMaxWidth, sectionBtnGap, timeUntilTheEnd, allQuestsCompleted
} = require("questsComps.nut")
let { mkRewardsPreview, questItemsGap, statusIconSize } = require("rewardsComps.nut")
let { mkQuestBar, mkProgressBar, progressBarHeight, progressBarMargin } = require("questBar.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize, gradientHeightBottom } = require("%rGui/options/mkOptionsScene.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { tabExtraWidth } = require("%rGui/components/tabs.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")


let bgColor = 0x80000000
let questHeight = hdpx(150)
let unseenMarkMargin = hdpx(20)

let aspectRatio = sw(100) / sh(100)
let btnSize = [aspectRatio < 2 ? hdpx(230) : hdpx(300), hdpx(90)]
let childOvr = aspectRatio < 2 ? fontSmallShaded : null
let btnStyle = { ovr = { size = btnSize, minWidth = 0 }, childOvr }
let btnStyleSound = { ovr = { size = btnSize, minWidth = 0, sound = { click  = "meta_get_unlock" } }, childOvr }

let scrollHandler = ScrollHandler()
curSectionId.subscribe(@(_) scrollHandler.scrollToY(0))

let topBlockHeight = max(sectionBtnHeight, progressBarHeight + progressBarMargin)
let mkVerticalPannableAreaNoBlocks = verticalPannableAreaCtor(sh(100) - topAreaSize,
  [0, gradientHeightBottom])
let mkVerticalPannableAreaOneBlock = verticalPannableAreaCtor(sh(100) - topAreaSize - topBlockHeight,
  [questItemsGap, gradientHeightBottom])
let mkVerticalPannableAreaTwoBlocks = verticalPannableAreaCtor(sh(100) - topAreaSize - topBlockHeight * 2,
  [questItemsGap, gradientHeightBottom])
let pannableCtors = [mkVerticalPannableAreaNoBlocks, mkVerticalPannableAreaOneBlock, mkVerticalPannableAreaTwoBlocks]

let newMarkSize = calc_comp_size(newMark)

let receiveReward = @(questName) receiveUnlockRewards(questName, 1, { stage = 1 })

let function mkQuest(quest) {
  let header = loc(quest.name)
  let text = loc($"{quest.name}/desc")
  let rewards = quest?.stages?[0].rewards ?? {}

  let isUnseen = Computed(@() !quest.hasReward
    && quest.name not in seenQuests.value
    && quest.name not in inactiveEventUnlocks.value)

  let rewardsPreview = Computed(function() {
    local res = []
    foreach (id, count in rewards) {
      let reward = serverConfigs.value.userstatRewards?[id]
      res.extend(getRewardsViewInfo(reward, count))
    }
    return res.sort(sortRewardsViewInfo)
  })
  let isAwardInProgress = Computed(@() quest.name in unlockRewardsInProgress.value)
  let headerPadding = Computed(@() quest.hasReward ? unseenMarkMargin * 2
    : isUnseen.value ? newMarkSize[0]
    : 0)

  let mkBtn = @() {
    watch = isAwardInProgress
    size = btnSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = isAwardInProgress.value ? spinner
      : quest?.hasReward
        ? textButtonSecondary(
            utf8ToUpper(loc("btn/receive")),
            @() receiveReward(quest.name),
            btnStyleSound)
      : quest?.isFinished
        ? {
            size = btnSize
            rendObj = ROBJ_TEXT
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            text = utf8ToUpper(loc("ui/received"))
          }.__update(fontSmallAccentedShaded)
      : textButtonCommon(
          utf8ToUpper(loc("btn/receive")),
          @() anim_start($"unfilledBarEffect_{quest.name}"),
          btnStyle)
  }

  return {
    rendObj = ROBJ_SOLID
    color = bgColor
    size = [flex(), questHeight]
    children = [
      @() {
        watch = isUnseen
        size = flex()
        children = quest.hasReward
            ? {
                margin = unseenMarkMargin
                children = priorityUnseenMark
              }
          : isUnseen.value ? newMark
          : null
      }

      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [0, hdpx(30)]
        flow = FLOW_HORIZONTAL
        gap = questItemsGap
        vplace = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = hdpx(8)
            children = [
              @() {
                watch = headerPadding
                padding = [0, 0, 0, headerPadding.value]
                rendObj = ROBJ_TEXT
                behavior = Behaviors.Marquee
                maxWidth = pw(100)
                text = header
              }.__update(fontSmall)

              {
                rendObj = ROBJ_TEXT
                behavior = Behaviors.Marquee
                maxWidth = pw(100)
                text
              }.__update(fontTiny)

              mkQuestBar(quest)
            ]
          }

          @() {
            watch = rewardsPreview
            flow = FLOW_HORIZONTAL
            gap = questItemsGap
            halign = ALIGN_RIGHT
            children = rewardsPreview.value.len() > 0 ? mkRewardsPreview(rewardsPreview.value, quest?.isFinished) : null
          }

          mkBtn
        ]
      }
    ]
  }
}

let sectionsWidth = saSize[0] - tabW - minContentOffset
let sectionPart = 0.9
let gapPart = 1 - sectionPart

let function mkSectionTabs(sections) {
  let sLen = sections.len()
  let btnWidth = min(sectionBtnMaxWidth, sectionsWidth / sLen * sectionPart)

  let sectionsFont = Computed(function() {
    foreach (id in sections)
      if (calc_str_box(sectionsCfg.value?[id].text, fontSmallShaded)[0] > btnWidth - statusIconSize - sectionBtnGap * 2)
        return fontTinyShaded
    return fontSmallShaded
  })

  return @() {
    watch = [unlockTables, sectionsFont]
    size = [sectionsWidth, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = min(hdpx(100), sectionsWidth * gapPart * (sLen + 1) / (sLen * sLen))
    children = sections.map(@(id) mkSectionBtn(id, btnWidth, sectionsFont.value, unlockTables.value?[id] == false))
  }
}

let function questsWndPage(sections, progressUnlock = Watched(null)) {
  let endsAt = Computed(@() userstatStats.value?.stats[sectionsCfg.value?[curSectionId.value].timerId]["$endsAt"])

  let questsSort = @(a, b) b.hasReward <=> a.hasReward
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
    children = [
      @() {
        watch = [serverTime, endsAt]
        size = flex()
        children = !endsAt.value || (endsAt.value - serverTime.value < 0) ? null
          : timeUntilTheEnd(secondsToHoursLoc(endsAt.value - serverTime.value),
            { pos = [- tabW - minContentOffset, 0], margin = [0, 0, 0, tabExtraWidth] })
      }
      @() {
        watch = [progressUnlock, blocksOnTop, sections, questsBySection]
        size = flex()
        flow = FLOW_VERTICAL
        children = [
          sections.value.findindex(@(s) questsBySection.value[s].len() > 0) == null ? allQuestsCompleted : null
          progressUnlock.value ? mkProgressBar(progressUnlock.value) : null
          sections.value.len() > 1 ? mkSectionTabs(sections.value) : null
          {
            size = flex()
            children = [
              pannableCtors[blocksOnTop.value](@() {
                watch = [curSectionId, seenQuests, questsBySection]
                size = [flex(), SIZE_TO_CONTENT]
                flow = FLOW_VERTICAL
                gap = hdpx(20)
                children = questsBySection.value?[curSectionId.value ?? sections.value?[0]]
                  .values()
                  .sort(questsSort)
                  .map(@(quest) mkQuest(quest))
                onAttach = @() curSectionId(sections.value?[0])
                function onDetach() {
                  saveSeenQuestsCurSection()
                  curSectionId(null)
                }
              }, { pos = [0, 0] }, { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
              mkScrollArrow(scrollHandler, MR_B)
            ]
          }
        ]
      }
    ]
  }
}

return questsWndPage
