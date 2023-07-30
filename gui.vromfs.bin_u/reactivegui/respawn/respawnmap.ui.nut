from "%globalsDarg/darg_library.nut" import *
let { respawnBases, availRespBases, playerSelectedRespBase, curRespBase
} = require("respawnState.nut")
let { localTeam } = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { VISIBLE_ON_MAP } = require("guiRespawn")

let baseSize = hdpxi(50)
let circleSize = hdpx(50)

let visibleRespawnBases = Computed(@() respawnBases.value.filter(@(rb) (rb.flags & VISIBLE_ON_MAP) != 0))

let mkRespBase = @(rb) @() {
  watch = [curRespBase, localTeam]
  size = [0, 0]
  pos = [pw(100.0 * rb.mapPos[0]), ph(100.0 * rb.mapPos[1])]
  rendObj = ROBJ_SOLID
  color = curRespBase.value == rb.id ? 0xFFFFFFFF : 0x80800000

  children = [
    curRespBase.value != rb.id ? null
      : {
          size = [circleSize, circleSize]
          rendObj = ROBJ_IMAGE
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          image = Picture($"ui/gameuiskin#map_respawn_selection.svg:{circleSize}:{circleSize}")
        }
    {
      size = [baseSize, baseSize]
      pos = [0.38 * baseSize, 0]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"ui/gameuiskin#map_respawn_marker.svg:{hdpxi(100)}:{hdpxi(100)}")
      color = curRespBase.value == rb.id ? 0xFFFFFFFF
        : rb.team == localTeam.value ? teamBlueColor
        : teamRedColor
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
  watch = visibleRespawnBases
  size = flex()
  rendObj = ROBJ_TACTICAL_MAP
  children = visibleRespawnBases.value.map(mkRespBase)
}