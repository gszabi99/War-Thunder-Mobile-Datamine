from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { deferOnce } = require("dagor.workcycle")
let { respawnBases, availRespBases, playerSelectedRespBase, curRespBase, selSlotContentGenId, selSlot
} = require("respawnState.nut")
let { localTeam } = require("%rGui/missionState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { VISIBLE_ON_MAP, getRespawnBasePos, is_respawnbase_selectable } = require("guiRespawn")
let { sendPlayerActivityToServer } = require("playerActivity.nut")
let { tacticalMapMarkersLayer } = require("%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut")

let baseSize = evenPx(50)
let circleSize = evenPx(70)

let zoneIcons = [
  "ui/gameuiskin#objective_tank.svg",
  "ui/gameuiskin#objective_fighter.svg"
]

let visibleRespawnBases = Computed(@() respawnBases.value.filter(@(rb) (rb.flags & VISIBLE_ON_MAP) != 0))
let mapSizePx = Watched([0, 0])
let mapRootKey = {}


let mkRespBase = @(rb) @() {
  watch = [curRespBase, localTeam, selSlot]
  size = 0
  translate = mapSizePx.value.map(@(v, axis) round(v * rb.mapPos[axis]))
  rendObj = ROBJ_SOLID
  color = curRespBase.value == rb.id ? 0xFFFFFFFF : 0x80800000
  behavior = Behaviors.RtPropUpdate
  function update() {
    let newPos = getRespawnBasePos(rb.id)
    return {
      transform = {
          translate = mapSizePx.value.map(@(v, axis) round(v * newPos[axis]))
          rotate = rb.rotate
      }
    }
  }
  children = [
    (curRespBase.value != rb.id && curRespBase.value >= 0) || (rb.team != localTeam.value) || !is_respawnbase_selectable(rb.id) ? null
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
      
      image = Picture($"{rb.iconType < 0 ? rb.mapIcon : zoneIcons[rb.iconType]}:{baseSize * 2}:{baseSize * 2}:P")
      color = rb.team == localTeam.value ? teamBlueColor : teamRedColor
    }.__update(rb.team != localTeam.value ? {}
      : {
          behavior = Behaviors.Button
          function onClick() {
            sendPlayerActivityToServer()
            if (curRespBase.value == rb.id)
              playerSelectedRespBase(-1)
            else if (rb.id in availRespBases.value)
              playerSelectedRespBase(rb.id)
          }
          clickableInfo = loc(curRespBase.value != rb.id ? "mainmenu/btnSelect" : "mainmenu/btnCancel")
        })
  ]
}

let respawnBasesLayer = @() {
  watch = visibleRespawnBases
  size = flex()
  children = visibleRespawnBases.get().map(mkRespBase)
}

function refreshMapSize() {
  let aabb = gui_scene.getCompAABBbyKey(mapRootKey)
  if (aabb == null)
    return

  let size = [aabb.r-aabb.l, aabb.b-aabb.t]
  if (size[0] > 0 && size[1] > 0)
    mapSizePx.set(size)
}

selSlotContentGenId.subscribe(@(_) deferOnce(refreshMapSize))

return {
  rendObj = ROBJ_TACTICAL_MAP
  key = mapRootKey
  size = flex()
  clipChildren = true
  children = [
    tacticalMapMarkersLayer
    respawnBasesLayer
  ]
  function onAttach(elem) {
    mapSizePx([elem.getWidth(), elem.getHeight()])
    deferOnce(refreshMapSize)
  }
}