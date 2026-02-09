from "%globalsDarg/darg_library.nut" import *
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { scaleFontWithTransform } = require("%globalsDarg/fontScale.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { hudWhiteColor } = require("%rGui/style/hudColors.nut")
let { missionScoresTable } = require("%rGui/hud/missionScoreState.nut")


let hiddenScores = ["flags_count_t1", "flags_count_t2"].totable()
let missionScoreIconSize = [hdpxi(40), hdpxi(40)]

let missionScoreBlockSize = [hdpxi(180), 2 * missionScoreIconSize[1]]

function scoreLineCtr(data, scale) {
  let font = scaleFontWithTransform(fontVeryTinyShaded, scale, [0, 1])
  let size = scaleArr(missionScoreIconSize, scale)
  return @() {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      @() {
        watch = localMPlayerTeam
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        size
        color = data.army == localMPlayerTeam.get() ? teamBlueColor
          : data.army == 0 ? hudWhiteColor
          : teamRedColor
        image = Picture($"ui/gameuiskin#{data.icon}:{missionScoreIconSize[0]}:{missionScoreIconSize[1]}:P")
      }
      {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        text = data.maxValue > 0 ? $"{data.value}/{data.maxValue}" : $"{data.value}"
      }.__merge(font)
    ]
  }
}

function mkMissionScoreListCtr(scoresTbl, scale) {
  local res = []
  foreach(score in scoresTbl) {
    res.append(scoreLineCtr(score, scale))
  }
  return res
}

function missionScoreCtr(scale) {
  let mScoresTableFiltered = Computed(@() missionScoresTable.get().filter(@(v) v.id not in hiddenScores))
  return @() mScoresTableFiltered.get().len() == 0 ? { watch = mScoresTableFiltered }
    : {
      watch = mScoresTableFiltered
      size = missionScoreBlockSize
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = mkMissionScoreListCtr(mScoresTableFiltered.get(), scale)
    }
}

let missionScoreEditView = {
  rendObj = ROBJ_BOX
  size = missionScoreBlockSize
  borderWidth = hdpx(3)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = "XX  XX"
    }.__update(fontSmall)
    {
      rendObj = ROBJ_TEXT
      text = "Mission Score"
    }.__update(fontTinyShaded)
  ]
}

return {
  missionScoreCtr
  missionScoreEditView
}
