from "%globalsDarg/darg_library.nut" import *
let { tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { progressBarRewardSize, rewardProgressBarCtor, statsAnimation } = require("rewardsComps.nut")
let { getUnlockRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { receiveUnlockRewards, unlockInProgress } = require("%rGui/unlocks/unlocks.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { linkToEventWidth, headerLineGap } = require("questsPkg.nut")
let { sendBqQuestsStage } = require("bqQuests.nut")


let questBarHeight = hdpx(28)
let progressBarHeight = hdpx(30)
let starIconSize = hdpxi(60)
let starIconOffset = hdpx(40)
let borderWidth = hdpx(3)
let bgColor = 0x80000000
let questBarColor = 0xFF2EC181
let completedBarColor = 0xFF505050
let progressBarColor = 0xFF5AA0E9
let progressBarColorLight = 0xFFDEECFA
let barBorderColor = 0xFF606060
let subtleRedColor = 0xC8800000
let BAR_COLOR_SHOW = 0.4
let BAR_COLOR_BLINK = 1.0

let fadeWidth = hdpx(10)
let minStageWidth = progressBarRewardSize + hdpx(82)
let progressBarWidth = sw(100) - saBorders[0] * 2 - tabW - minContentOffset - headerLineGap - linkToEventWidth - starIconOffset

let bgGradient = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#gradient_button.svg:0:P")
  color = 0x00505050
}

function mkQuestBar(quest) {
  let current = quest?.current ?? 0
  let required = quest?.required ?? 1
  let questCompletion = current.tofloat() / required
  let trigger = $"unfilledBarEffect_{quest.name}"

  return {
    key = quest.name
    rendObj = ROBJ_BOX
    size = [flex(), questBarHeight]
    fillColor = bgColor
    borderWidth
    borderColor = barBorderColor
    animations = [
      {
        prop = AnimProp.fillColor, duration = BAR_COLOR_SHOW,
        easing = InOutQuad, from = bgColor, to = tagRedColor, trigger
      }
      {
        prop = AnimProp.fillColor, duration = BAR_COLOR_BLINK, delay = BAR_COLOR_SHOW,
        easing = CosineFull, from = tagRedColor, to = subtleRedColor, trigger
      }
      {
        prop = AnimProp.fillColor, duration = BAR_COLOR_SHOW, delay = BAR_COLOR_SHOW + BAR_COLOR_BLINK,
        easing = InOutQuad, from = tagRedColor, to = bgColor, trigger
      }
    ]
    children = [
      {
        rendObj = ROBJ_BOX
        size = [pw(100 * questCompletion), questBarHeight]
        fillColor = quest?.isFinished
          ? completedBarColor
          : questBarColor
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        text = quest?.isFinished ? loc("ui/received") : $"{current}/{required}"
        padding = [0, hdpx(15), 0, 0]
      }.__update(fontVeryTinyShaded)
    ]
  }
}

let scrollHandler = ScrollHandler()
let pannableArea = horizontalPannableAreaCtor(progressBarWidth, [fadeWidth, fadeWidth])

function mkStages(progressUnlock, stageWidth, curStageIdx) {
  let { hasReward = false, stage, stages, current = 0, name } = progressUnlock
  let required = stages?[curStageIdx].progress
  let isRewardInProgress = Computed(@() name in unlockInProgress.value)

  return {
    size = [SIZE_TO_CONTENT, progressBarRewardSize]
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = array(stages.len()).map(function(_, idx) {
      let prevProgress = stages?[idx - 1].progress ?? 0
      let stageCompletion = clamp((current.tofloat() - prevProgress) / (stages[idx].progress - prevProgress), 0.0, 1.0)
      let isUnlocked = stageCompletion == 1.0

      let rewardPreview = Computed(@()
        getUnlockRewardsViewInfo(stages[idx], serverConfigs.value)
          .sort(sortRewardsViewInfo)?[0])

      let claimReward = isUnlocked && hasReward && (idx + 1) >= stage
          ? function() {
              receiveUnlockRewards(name, stage, { stage, finalStage = idx + 1 })
              sendBqQuestsStage(progressUnlock, rewardPreview.value?.count ?? 0, rewardPreview.value?.id)
            }
        : null

      return {
        size = [stageWidth, flex()]
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = flex()
            valign = ALIGN_CENTER
            children = [
              {
                size = [flex(), progressBarHeight]
                children = [
                  {
                    key = progressUnlock?.sectionId
                    rendObj = ROBJ_SOLID
                    size = flex()
                    color = progressBarColorLight
                    transform = {
                      scale = [stageCompletion, 1.0]
                      pivot = [0, 0]
                    }
                    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
                  }
                  {
                    key = progressUnlock?.sectionId
                    rendObj = ROBJ_SOLID
                    size = flex()
                    color = progressBarColor
                    transform = {
                      scale = [stageCompletion, 1.0]
                      pivot = [0, 0]
                    }
                    transitions = [{ prop = AnimProp.scale, duration = 1.0, easing = InOutQuad }]
                    children = bgGradient
                  }
                ]
              }
              idx != curStageIdx ? null
                : {
                    rendObj = ROBJ_TEXT
                    vplace = ALIGN_CENTER
                    hplace = ALIGN_CENTER
                    text = $"{current}/{required}"
                  }.__update(fontVeryTinyShaded, isWidescreen ? {} : { fontSize = fontVeryTinyShaded.fontSize * 0.85 })
            ]
          }
          @() {
            watch = [rewardPreview, isRewardInProgress]
            children = rewardPreview.value.len() == 0 ? null
              : rewardProgressBarCtor(rewardPreview.value, isUnlocked, claimReward, isRewardInProgress.value)
          }
        ]
      }
    })
  }
}

function mkProgressBar(progressUnlock) {
  let { stages, current = 0 } = progressUnlock
  let curStageIdx = stages.findindex(@(s) s.progress >= current)
  let hasScroll = stages.len() * minStageWidth > progressBarWidth
  let stageWidth = hasScroll ? minStageWidth : progressBarWidth / stages.len()
  let stagesContent = mkStages(progressUnlock, stageWidth, curStageIdx)
  return {
    size = [flex(), progressBarHeight]
    padding = [0, 0, 0, starIconOffset]
    children = [
      {
        size = flex()
        rendObj = ROBJ_BOX
        fillColor = bgColor
      }
      !hasScroll ? stagesContent
        : {
            key = {}
            size = [progressBarWidth + fadeWidth * 2, progressBarHeight]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            onAttach = curStageIdx == null ? null : @() scrollHandler.scrollToX(curStageIdx * minStageWidth)
            children = [
              pannableArea(stagesContent,
                { pos = [0, 0], size = [flex(), SIZE_TO_CONTENT], vplace = ALIGN_CENTER, clipChildren = false },
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
                  scrollHandler
                })
              {
                size = [progressBarWidth + minStageWidth, SIZE_TO_CONTENT]
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                children = [
                  mkScrollArrow(scrollHandler, MR_L, scrollArrowImageSmall)
                  mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
                ]
              }
            ]
          }
      {
        key = progressUnlock?.sectionId
        size = [starIconSize, starIconSize]
        vplace = ALIGN_CENTER
        pos = [-starIconOffset, hdpx(-7)]
        rendObj = ROBJ_IMAGE
        image = Picture("ui/gameuiskin#quest_experience_icon.avif:0:P")
        transform = {}
        animations = [statsAnimation]
      }
    ]
  }
}

return {
  mkQuestBar
  mkProgressBar

  progressBarHeight
}
