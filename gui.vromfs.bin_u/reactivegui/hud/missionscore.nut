from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { localMPlayerTeam, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { scaleFontWithTransform } = require("%globalsDarg/fontScale.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")

let missionScoreIconSize = [hdpxi(40), hdpxi(40)]
let missionScoresTable = mkWatched(persist, "missionScoresTable", {})
let missionScoreBlockSize = [hdpxi(180), 2 * missionScoreIconSize[1]]

isInBattle.subscribe(@(_) missionScoresTable({}))

eventbus_subscribe("setMissionScore", function(ev) {
  missionScoresTable.mutate( @(v) ev.visible
    ? v[ev.id] <- {
      icon = ev.icon
      value = ev.value
      maxValue = ev.maxValue
      army = ev.army
    }
    : v.$rawdelete(ev.id))
})

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
          : data.army == 0 ? 0xFFFFFFFF
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
  return @() missionScoresTable.get().len() == 0 ? { watch = missionScoresTable }
    : {
      watch = missionScoresTable
      size = missionScoreBlockSize
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = mkMissionScoreListCtr(missionScoresTable.get(), scale)
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
