from "%globalsDarg/darg_library.nut" import *
let { tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { progressBarRewardSize, rewardProgressBarCtor, statsAnimation } = require("rewardsComps.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { receiveUnlockRewards, unlockRewardsInProgress } = require("%rGui/unlocks/unlocks.nut")


let questBarHeight = hdpx(28)
let progressBarHeight = hdpx(30)
let starIconSize = hdpxi(60)
let borderWidth = hdpx(3)
let bgColor = 0x80000000
let questBarColor = 0xFF2EC181
let progressBarColor = 0xFF5AA0E9
let progressBarColorLight = 0xFFDEECFA
let barBorderColor = 0xFF606060
let subtleRedColor = 0xC8800000
let BAR_COLOR_SHOW = 0.4
let BAR_COLOR_BLINK = 1.0

let bgGradient = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#gradient_button.svg:0:P")
  color = 0x00505050
}

let function mkQuestBar(quest) {
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
        fillColor = questBarColor
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        text = $"{current}/{required}"
        padding = [0, hdpx(15), 0, 0]
      }.__update(fontVeryTinyShaded)
    ]
  }
}

let function mkStages(progressUnlock) {
  let { hasReward = false, stage, stages, current = 0, name } = progressUnlock
  let stagesTotal = stages.len()
  let curStageIdx = stages.findindex(@(s) s.progress >= current)
  let required = stages?[curStageIdx].progress
  let isRewardInProgress = Computed(@() name in unlockRewardsInProgress.value)

  return {
    size = [flex(), progressBarRewardSize]
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = array(stagesTotal).map(function(_, idx) {
      let prevProgress = stages?[idx - 1].progress ?? 0
      let stageCompletion = clamp((current.tofloat() - prevProgress) / (stages[idx].progress - prevProgress), 0.0, 1.0)
      let isUnlocked = stageCompletion == 1.0
      let claimReward = isUnlocked && hasReward && (idx + 1) >= stage
          ? @() receiveUnlockRewards(name, stage, { stage, finalStage = idx + 1 })
        : null

      let rewardPreview = Computed(function() {
        let rewardId = stages[idx].rewards.keys()?[0]
        return getRewardsViewInfo(serverConfigs.value.userstatRewards?[rewardId])?[0] ?? {}
      })

      return {
        size = [pw(100 / stagesTotal), flex()]
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

let mkProgressBar = @(progressUnlock) {
  rendObj = ROBJ_BOX
  size = [flex(), progressBarHeight]
  fillColor = bgColor
  children = [
    mkStages(progressUnlock)
    {
      size = [starIconSize, starIconSize]
      vplace = ALIGN_CENTER
      pos = [hdpx(-40), hdpx(-7)]
      rendObj = ROBJ_IMAGE
      image = Picture("ui/gameuiskin#quest_experience_icon.avif:0:P")
      transform = {}
      animations = [statsAnimation]
    }
  ]
}

return {
  mkQuestBar
  mkProgressBar

  progressBarHeight
}
