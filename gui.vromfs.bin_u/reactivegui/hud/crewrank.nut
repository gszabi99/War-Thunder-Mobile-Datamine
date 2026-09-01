from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%globalsDarg/fontScale.nut" import scaleFontWithTransform
from "%rGui/hud/crewState.nut" import crewState
from "%rGui/missionState.nut" import isGtBattleRoyale
from "%rGui/style/hudColors.nut" import hudGrassColor


let iconSize = evenPx(50)
let blockSize = [evenPx(140), evenPx(60)]
let crewRankIconsList = [
  "ui/gameuiskin#slot_rank_01.svg"
  "ui/gameuiskin#slot_rank_06.svg"
  "ui/gameuiskin#slot_rank_11.svg"
  "ui/gameuiskin#slot_rank_20.svg"
  "ui/gameuiskin#slot_rank_21.svg"
]

let isVisibleCrewRank = Computed(@() isInBattle.get() && isGtBattleRoyale.get())
let crewSkillPercent = keepref(Computed(@() crewState.get()?.crewSkillPercent ?? 0))
let getCrewRankIcon = @(level) crewRankIconsList[clamp(level, 0, 100).tointeger() * (crewRankIconsList.len() - 1) / 100]

function mkCrewRank(level, scale) {
  let font = scaleFontWithTransform(fontVeryTinyShaded, scale, [0, 1])
  let size = scaleEven(iconSize, scale)

  return {
    size = blockSize
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    valign = ALIGN_CENTER
    children = [
      {
        size
        rendObj = ROBJ_IMAGE
        color = hudGrassColor
        image = Picture($"{getCrewRankIcon(level)}:{size}:P")
        keepAspect = true
      }
      {
        rendObj = ROBJ_TEXT
        text = $"{level} %"
      }.__update(font)
    ]
  }
}

let crewRankCtr = @(scale) @() {
  watch = crewSkillPercent
  children = mkCrewRank(crewSkillPercent.get(), scale)
}

let crewRankEditView = {
  size = blockSize
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = iconSize
      rendObj = ROBJ_IMAGE
      color = hudGrassColor
      image = Picture($"{getCrewRankIcon(100)}:{iconSize}:{iconSize}:P")
      keepAspect = true
    }
    {
      rendObj = ROBJ_TEXT
      text = "100 %"
    }.__update(fontVeryTinyShaded)
  ]
}

return {
  crewRankCtr
  crewRankEditView
  isVisibleCrewRank
}
