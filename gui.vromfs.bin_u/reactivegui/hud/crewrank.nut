from "%globalsDarg/darg_library.nut" import *
let { scaleFontWithTransform } = require("%globalsDarg/fontScale.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isGtBattleRoyale } = require("%rGui/missionState.nut")
let { crewState } = require("%rGui/hud/crewState.nut")


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
  let size = scaleArr(iconSize, scale)

  return {
    size = blockSize
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    valign = ALIGN_CENTER
    children = [
      {
        size
        rendObj = ROBJ_IMAGE
        color = 0xFF65BC82
        image = Picture($"{getCrewRankIcon(level)}:{size}:{size}:P")
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
      color = 0xFF65BC82
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
