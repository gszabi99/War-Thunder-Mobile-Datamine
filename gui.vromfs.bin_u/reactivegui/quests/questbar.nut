from "%globalsDarg/darg_library.nut" import *
let { tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { progressBarRewardSize, rewardProgressBarCtor } = require("rewardsComps.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let questBarHeight = hdpx(28)
let progressBarHeight = hdpx(30)
let progressBarMargin = hdpx(40)
let starIconSize = hdpxi(60)
let borderWidth = hdpx(3)
let bgColor = 0x80000000
let questBarColor = 0xFF2EC181
let progressBarColor = 0xFF5AA0E9
let barBorderColor = 0xFF606060
let subtleRedColor = 0xC8800000
let questCompletedText = loc("quests/completed")
let BAR_COLOR_SHOW = 0.4
let BAR_COLOR_BLINK = 1.0

let bgGradient = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#gradient_button.svg:O:P")
  color = 0x00505050
}

let function mkQuestBar(quest) {
  let isQuestCompleted = quest?.isCompleted ?? false
  let stepsFinished = quest?.current ?? 0
  let stepsTotal = quest?.required ?? 1
  let questCompletion = stepsFinished.tofloat() / stepsTotal
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
        text = isQuestCompleted ? questCompletedText : $"{stepsFinished}/{stepsTotal}"
        padding = [0, hdpx(15), 0, 0]
      }.__update(fontVeryTinyShaded)
    ]
  }
}

let function mkStages(progressUnlock) {
  let stage = progressUnlock.stage
  let stages = progressUnlock.stages
  let stagesTotal = stages.len()
  let stepsFinished = progressUnlock.current ?? 0
  let stepsToNext = progressUnlock.required ?? 1

  return {
    size = [flex(), progressBarRewardSize]
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = array(stagesTotal).map(function(_, idx) {
      let prevProgress = stages?[idx - 1].progress ?? 0
      let stageCompletion = clamp((stepsFinished.tofloat() - prevProgress) / (stages[idx].progress - prevProgress), 0.0, 1.0)

      let rewardPreview = Computed(function() {
        let rewardId = stages[idx].rewards.keys()?[0]
        return !rewardId ? [] : getRewardsViewInfo(serverConfigs.value.userstatRewards?[rewardId])
      })

      return @() {
        watch = rewardPreview
        size = [pw(100 / stagesTotal), flex()]
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = flex()
            valign = ALIGN_CENTER
            children = [
              {
                size = [pw(100 * stageCompletion), progressBarHeight]
                pos = [0, hdpx(1)]
                rendObj = ROBJ_BOX
                fillColor = progressBarColor
                children = bgGradient
              }
              idx != stage ? null
                : {
                    rendObj = ROBJ_TEXT
                    vplace = ALIGN_CENTER
                    hplace = ALIGN_CENTER
                    text = $"{stepsFinished}/{stepsToNext}"
                  }.__update(fontVeryTinyShaded)
            ]
          }

          rewardPreview.value.len() == 0 ? null
            : rewardProgressBarCtor(rewardPreview.value, stageCompletion == 1.0)
        ]
      }
    })
  }
}

let mkProgressBar = @(progressUnlock) {
  rendObj = ROBJ_BOX
  size = [flex(), progressBarHeight]
  margin = [0, 0, progressBarMargin, 0]
  fillColor = bgColor
  children = [
    mkStages(progressUnlock)
    {
      size = [starIconSize, starIconSize]
      vplace = ALIGN_CENTER
      pos = [-starIconSize * 0.6, hdpx(-7)]
      rendObj = ROBJ_IMAGE
      image = Picture("ui/gameuiskin#quest_experience_icon.avif:O:P")
    }
  ]
}

return {
  mkQuestBar
  mkProgressBar

  progressBarHeight
  progressBarMargin
}
