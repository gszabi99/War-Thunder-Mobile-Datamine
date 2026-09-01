from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "guiRespawn" import VISIBLE_ON_MAP, getRespawnBasePos, is_respawnbase_selectable
from "math" import round
from "%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut" import tacticalMapMarkersLayer
from "%rGui/missionState.nut" import localTeam
from "%rGui/respawn/playerActivity.nut" import sendPlayerActivityToServer
from "%rGui/respawn/respawnState.nut" import respawnBases, availRespBases, playerSelectedRespBase, curRespBase,
  selSlotContentGenId, selSlot
from "%rGui/style/teamColors.nut" import teamBlueColor, teamRedColor


let baseSize = evenPx(50)
let circleSize = evenPx(70)

let zoneIcons = [
  "ui/gameuiskin#objective_tank.svg",
  "ui/gameuiskin#objective_fighter.svg"
]

let visibleRespawnBases = Computed(@() respawnBases.get().filter(@(rb) (rb.flags & VISIBLE_ON_MAP) != 0))
let mapSizePx = Watched([0, 0])
let mapRootKey = {}


let mkRespBase = @(rb) @() {
  watch = [curRespBase, localTeam, selSlot]
  size = 0
  translate = mapSizePx.get().map(@(v, axis) round(v * rb.mapPos[axis]))
  rendObj = ROBJ_SOLID
  color = curRespBase.get() == rb.id ? 0xFFFFFFFF : 0x80800000
  behavior = Behaviors.RtPropUpdate
  function update() {
    let newPos = getRespawnBasePos(rb.id)
    return {
      transform = {
          translate = mapSizePx.get().map(@(v, axis) round(v * newPos[axis]))
          rotate = rb.rotate
      }
    }
  }
  children = [
    (curRespBase.get() != rb.id && curRespBase.get() >= 0) || (rb.team != localTeam.get()) || !is_respawnbase_selectable(rb.id) ? null
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
      color = rb.team == localTeam.get() ? teamBlueColor : teamRedColor
    }.__update(rb.team != localTeam.get() ? {}
      : {
          behavior = Behaviors.Button
          function onClick() {
            sendPlayerActivityToServer()
            if (curRespBase.get() == rb.id)
              playerSelectedRespBase.set(-1)
            else if (rb.id in availRespBases.get())
              playerSelectedRespBase.set(rb.id)
          }
          clickableInfo = loc(curRespBase.get() != rb.id ? "mainmenu/btnSelect" : "mainmenu/btnCancel")
        })
  ]
}

let respawnBasesLayer = @() {
  watch = visibleRespawnBases
  size = FLEX
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

let respawnMap = {
  rendObj = ROBJ_TACTICAL_MAP
  key = mapRootKey
  size = FLEX
  clipChildren = true
  children = [
    tacticalMapMarkersLayer
    respawnBasesLayer
  ]
  function onAttach(elem) {
    mapSizePx.set([elem.getWidth(), elem.getHeight()])
    deferOnce(refreshMapSize)
  }
}
return {
  respawnMap
  visibleRespawnBases
}