from "%globalsDarg/darg_library.nut" import *
let { respawnBases, availRespBases, playerSelectedRespBase, curRespBase, selSlot
} = require("respawnState.nut")
let { localTeam } = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { VISIBLE_ON_MAP, getRespawnBasePos = null, is_respawnbase_selectable = null } = require("guiRespawn")

let baseSize = evenPx(50)
let circleSize = evenPx(70)

let zoneIcons = [
  "ui/gameuiskin#objective_tank.svg",
  "ui/gameuiskin#objective_fighter.svg"
]

let visibleRespawnBases = Computed(@() respawnBases.value.filter(@(rb) (rb.flags & VISIBLE_ON_MAP) != 0))

let mkRespBase = @(rb) @() {
  watch = [curRespBase, localTeam, selSlot]
  size = [0, 0]
  pos = [pw(100.0 * rb.mapPos[0]), ph(100.0 * rb.mapPos[1])]
  rendObj = ROBJ_SOLID
  color = curRespBase.value == rb.id ? 0xFFFFFFFF : 0x80800000
  behavior = getRespawnBasePos == null ? null : Behaviors.RtPropUpdate
  update = getRespawnBasePos == null ? null
    : function() {
        let newPos = getRespawnBasePos(rb.id)
        return {
          pos = [pw(100.0 * newPos[0]), ph(100.0 * newPos[1])]
        }
      }
  children = [
    (curRespBase.value != rb.id && curRespBase.value > 0) || (rb.team != localTeam.value) || (is_respawnbase_selectable!=null && !is_respawnbase_selectable(rb.id)) ? null
      : {
          size = [circleSize, circleSize]
          rendObj = ROBJ_IMAGE
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          image = Picture($"ui/gameuiskin#spawn_selected.svg:{circleSize}:{circleSize}:P")
        }
    {
      size = [baseSize, baseSize]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"{(rb?.iconType ?? 0) < 0 ? rb.mapIcon : zoneIcons[rb?.iconType ?? 0]}:{baseSize}:{baseSize}:P")
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
}