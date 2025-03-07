from "%globalsDarg/darg_library.nut" import *
let { tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { progressBarRewardSize, questItemsGap, rewardProgressBarCtor, statsAnimation
} = require("rewardsComps.nut")
let { getUnlockRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { receiveUnlockRewards, unlockInProgress } = require("%rGui/unlocks/unlocks.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { minContentOffset, tabW } = require("%rGui/options/optionsStyle.nut")
let { mkBalanceDiffAnims } = require("%rGui/mainMenu/balanceAnimations.nut")
let { headerLineGap } = require("questsPkg.nut")
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
let minStageProgressWidth = hdpx(100)
let progressBarWidthFull = sw(100) - saBorders[0] * 2 - tabW - minContentOffset
let firstProgressWider = starIconOffset

let animHighlightTrigger = "quest_progress_bar_trigger"
let animHighlight = [
  { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2],
    duration = 0.6, easing = CosineFull, trigger = animHighlightTrigger }
]

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
let pannableArea = horizontalPannableAreaCtor(progressBarWidthFull, [fadeWidth, fadeWidth])

function getCurStageIdx(unlock) {
  let { stages = [], current = 0 } = unlock
  return stages.findindex(@(s) s.progress >= current)
}

function calcStageCompletion(stages, idx, current) {
  let prevProgress = stages?[idx - 1].progress ?? 0
  return clamp((current.tofloat() - prevProgress) / (stages[idx].progress - prevProgress), 0.0, 1.0)
}

let questBarProgressValue = @(current, required, prevCurrent) {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  text = $"{current}/{required}"
  children = @() {
    watch = prevCurrent
    size = [0, 0] //to not affect parent size
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = current == prevCurrent.get() ? null
      : {
          zOrder = Layers.Upper
          hplace = ALIGN_RIGHT
          vplace = ALIGN_CENTER
          children = {
            flow = FLOW_HORIZONTAL
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = [
              {
                size = [starIconSize, starIconSize]
                rendObj = ROBJ_IMAGE
                image = Picture("ui/gameuiskin#quest_experience_icon.avif:0:P")
              }
              {
                rendObj = ROBJ_TEXT
                text = $"+{current - prevCurrent.get()}"
              }.__update(fontVeryTinyShaded)
            ]
          }
          transform = {}
          animations = mkBalanceDiffAnims(function() {
            anim_start(animHighlightTrigger)
            prevCurrent.set(current)
          })
        }
  }
  transform = {}
  animations = animHighlight
}.__update(fontVeryTinyShaded, isWidescreen ? {} : { fontSize = fontVeryTinyShaded.fontSize * 0.85 })

function mkStages(progressUnlock, progressWidth, tabId, curSectionId, prevCurrent) {
  let curStageIdx = getCurStageIdx(progressUnlock)
  let { hasReward = false, stage, stages, current = 0, name } = progressUnlock
  let required = stages?[curStageIdx].progress
  let isRewardInProgress = Computed(@() name in unlockInProgress.value)

  return {
    size = [SIZE_TO_CONTENT, progressBarRewardSize]
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = array(stages.len()).map(function(_, idx) {
      let stageCompletion = calcStageCompletion(stages, idx, current)
      let isUnlocked = stageCompletion == 1.0

      let rewardPreview = Computed(@()
        getUnlockRewardsViewInfo(stages[idx], serverConfigs.value)
          .sort(sortRewardsViewInfo)?[0])

      let claimReward = isUnlocked && hasReward && (idx + 1) >= stage
          ? function() {
              receiveUnlockRewards(name, stage, { stage, finalStage = idx + 1 })
              sendBqQuestsStage(progressUnlock.__merge({ tabId, sectionId = curSectionId.get() }),
                rewardPreview.value?.count ?? 0, rewardPreview.value?.id)
            }
        : null

      return {
        size = [SIZE_TO_CONTENT, flex()]
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = [progressWidth + (idx == 0 ? firstProgressWider : 0), flex()]
            valign = ALIGN_CENTER
            children = [
              {
                size = [flex(), progressBarHeight]
                children = [
                  {
                    rendObj = ROBJ_SOLID
                    size = flex()
                    color = bgColor
                  }
                  {
                    key = progressUnlock?.name
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
                    key = progressUnlock?.name
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
              idx != curStageIdx ? null : questBarProgressValue(current, required, prevCurrent)
            ]
          }
          @() {
            watch = [rewardPreview, isRewardInProgress]
            key = $"quest_bar_stage_{idx}" //need for tutorial
            children = (rewardPreview.value?.len() ?? 0 )== 0 ? null
              : rewardProgressBarCtor(rewardPreview.value, isUnlocked, claimReward, isRewardInProgress.value)
          }
        ]
      }
    })
  }
}

function rewardWidth(r) {
  let { slots = 1 } = r
  return progressBarRewardSize * slots + questItemsGap * (slots - 1)
}

function mkQuestListProgressBar(progressUnlock, tabId, curSectionId, headerChildWidth) {
  let progressBarWidth = Computed(@() progressBarWidthFull - starIconOffset
    - (headerChildWidth.get() == 0 ? 0 : headerChildWidth.get() + headerLineGap))
  let stageRewards = Computed(@() (progressUnlock.get()?.stages ?? [])
    .map(@(s) getUnlockRewardsViewInfo(s, serverConfigs.get()).sort(sortRewardsViewInfo)?[0]))
  let rewardsFullWidth = Computed(@() stageRewards.get().reduce(@(res, r) res + rewardWidth(r), 0))
  let minWidth = Computed(@() rewardsFullWidth.get() + stageRewards.get().len() * minStageProgressWidth + firstProgressWider)
  let hasScroll = Computed(@() progressBarWidth.get() < minWidth.get())
  let prevCurrent = Watched(progressUnlock.get()?.current ?? 0)
  return @() progressUnlock.get() == null ? { watch = progressUnlock }
    : {
        watch = [progressUnlock, hasScroll, headerChildWidth, progressBarWidth, minWidth, rewardsFullWidth]
        size = [flex(), progressBarHeight]
        padding = [0, 0, 0, starIconOffset]
        children = [
          !hasScroll.get()
            ? mkStages(progressUnlock.get(),
                (progressBarWidth.get() - rewardsFullWidth.get() - firstProgressWider) / (progressUnlock.get()?.stages.len() || 1),
                tabId, curSectionId, prevCurrent)
            : {
                key = hasScroll
                size = [progressBarWidth.get() + fadeWidth * 2, progressBarHeight]
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                function onAttach() {
                  let curStageIdx = getCurStageIdx(progressUnlock.get())
                  if (curStageIdx == null)
                    return
                  local x = 0
                  for (local i = 0; i < curStageIdx; i++)
                    x += minStageProgressWidth + rewardWidth(stageRewards.get()?[i])
                  scrollHandler.scrollToX(max(0, x - progressBarRewardSize / 4))
                }
                children = [
                  pannableArea(mkStages(progressUnlock.get(), minStageProgressWidth, tabId, curSectionId, prevCurrent),
                    { pos = [0, 0], size = [flex(), SIZE_TO_CONTENT], vplace = ALIGN_CENTER, clipChildren = false },
                    {
                      size = [flex(), SIZE_TO_CONTENT]
                      behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
                      scrollHandler
                    })
                  {
                    size = [minWidth.get(), SIZE_TO_CONTENT]
                    hplace = ALIGN_CENTER
                    vplace = ALIGN_CENTER
                    children = mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
                  }
                ]
              }
          {
            key = progressUnlock?.name
            size = [starIconSize, starIconSize]
            vplace = ALIGN_CENTER
            pos = [-starIconOffset, hdpx(-7)]
            rendObj = ROBJ_IMAGE
            image = Picture("ui/gameuiskin#quest_experience_icon.avif:0:P")
            transform = {}
            animations = animHighlight.append(statsAnimation)
          }
        ]
      }
}

return {
  mkQuestBar
  mkQuestListProgressBar

  progressBarHeight

  calcStageCompletion
}
