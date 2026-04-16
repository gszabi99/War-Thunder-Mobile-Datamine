from "%globalsDarg/darg_library.nut" import *
let { gradTranspDoubleSideX, mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkAdsButton } = require("%rGui/components/adsButton.nut")
let { mkDebriefingStats } = require("%rGui/debriefing/mkDebriefingStats.nut")
let { mkMissionResultTitle, missionResultTitleAnimTime } = require("%rGui/debriefing/missionResultTitle.nut")
let achievementsBlock = require("%rGui/debriefing/achievementsBlock.nut")
let { mkTotalRewardCountsScores } = require("%rGui/debriefing/totalRewardCounts.nut")

let rewardsAnimStartTime = 0.5

let scoreBgPanel = {
  rendObj = ROBJ_IMAGE
  image = mkColoredGradientY(0x80000000, 0x00000000, 12)
  padding = const [hdpx(10), 0, hdpx(10), 0]
  flow = FLOW_VERTICAL
}

function mkDebriefingWndTabScores(debrData, _params) {
  if (debrData == null)
    return null

  let achievementsAnimStartTime = missionResultTitleAnimTime / 2
  let { achievementsAnimTime, achievementsComp } = achievementsBlock(debrData, achievementsAnimStartTime)
  let statsAnimStartTime = achievementsAnimStartTime + achievementsAnimTime
  let { statsAnimEndTime, debriefingStats, usedItems } = mkDebriefingStats(debrData, statsAnimStartTime)

  let { totalRewardCountsComp, totalRewardsShowTime, btnTryPremium
  } = mkTotalRewardCountsScores(debrData, rewardsAnimStartTime)

  let timeShow = max(
    statsAnimEndTime,
    rewardsAnimStartTime + totalRewardsShowTime,
  )

  if (achievementsComp == null && totalRewardCountsComp == null && debriefingStats == null)
    return null

  let comp = {
    size = flex()
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkMissionResultTitle(debrData, true)
      achievementsComp
      scoreBgPanel.__merge(
        {
          size = flex()
          gap = hdpx(10)
          children = [
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              padding = const [0, hdpx(40)]
              halign = ALIGN_CENTER
              gap = hdpx(40)
              children = [
                totalRewardCountsComp == null ? null
                  : totalRewardCountsComp
                debriefingStats == null ? null
                  : debriefingStats
              ]
            }
            {
              size = [hdpx(1000), hdpx(9)]
              hplace = ALIGN_CENTER
              rendObj = ROBJ_IMAGE
              image = gradTranspDoubleSideX
              color = 0xFF808080
            }
            {
              size = flex()
              children = [
                usedItems == null ? null
                  : usedItems.__merge(
                    {
                      hplace = ALIGN_CENTER,
                      vplace = ALIGN_TOP,
                    })
                {
                  size = flex()
                  flow = FLOW_HORIZONTAL
                  valign = ALIGN_BOTTOM
                  children = [
                    mkAdsButton(debrData)
                    {size = flex()}
                    btnTryPremium
                  ]}
              ]
            }
          ]
        }
      )
    ]
  }

  return {
    comp
    timeShow
    forceStopAnim = false
  }
}

return mkDebriefingWndTabScores
