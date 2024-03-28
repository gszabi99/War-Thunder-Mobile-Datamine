from "%globalsDarg/darg_library.nut" import *
let { respawnBases, availRespBases, playerSelectedRespBase, curRespBase
} = require("respawnState.nut")
let { localTeam } = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { VISIBLE_ON_MAP, getRespawnBasePos } = require("guiRespawn")

let baseSize = hdpxi(50)
let circleSize = hdpx(70)

let zoneIcons = [
  "ui/gameuiskin#objective_tank.svg",
  "ui/gameuiskin#objective_fighter.svg"
]

let visibleRespawnBases = Computed(@() respawnBases.value.filter(@(rb) (rb.flags & VISIBLE_ON_MAP) != 0))
let mapSizePx = Watched([0, 0])

let mkRespBase = @(rb) @() {
  watch = [curRespBase, localTeam]
  size = [0, 0]
  translate = mapSizePx.value.map(@(v, axis) v * rb.mapPos[axis])
  rendObj = ROBJ_SOLID
  color = curRespBase.value == rb.id ? 0xFFFFFFFF : 0x80800000
  behavior = Behaviors.RtPropUpdate
  function update() {
    let newPos = getRespawnBasePos(rb.id)
    return {
      transform = {
          translate = mapSizePx.value.map(@(v, axis) v * newPos[axis])
          rotate = rb.rotate
      }
    }
  }
  children = [
    (curRespBase.value != rb.id && curRespBase.value > 0) || (rb.team != localTeam.value) ? null
      : {
          size = [circleSize, circleSize]
          rendObj = ROBJ_IMAGE
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          image = Picture($"ui/gameuiskin#spawn_selected.svg:{circleSize}:{circleSize}")
        }
    {
      size = [baseSize, baseSize]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"{rb.iconType < 0 ? rb.mapIcon : zoneIcons[rb.iconType]}:{hdpxi(100)}:{hdpxi(100)}")
      color = rb.team == localTeam.value ? teamBlueColor : teamRedColor
    }.__update(rb.team != localTeam.value ? {}
      : {
          behavior = Behaviors.Button
          function onClick() {
            if (curRespBase.value == rb.id)
              playerSelectedRespBase(-1)
            else if (rb.id in availRespBases.value)
              playerSelectedRespBase(rb.id)
          }
          clickableInfo = loc(curRespBase.value != rb.id ? "mainmenu/btnSelect" : "mainmenu/btnCancel")
        })
  ]
}

return @() {
  rendObj = ROBJ_TACTICAL_MAP
  watch = visibleRespawnBases
  size = flex()
  clipChildren = true
  children = visibleRespawnBases.value.map(mkRespBase)
  function onAttach(elem) {
    mapSizePx([elem.getWidth(), elem.getHeight()])
  }
}