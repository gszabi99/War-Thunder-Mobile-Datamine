from "%globalsDarg/darg_library.nut" import *
let { Point2 } = require("dagor.math")
let { deferOnce } = require("dagor.workcycle")
let { FlightCameraType = { TPS = 1, VIRTUAL_FPS = 12, BOMBERVIEW = 11, TURRET = 9 },
  getCameraViewType = @() 1, isCameraViewAvailable = @(_) false } = require("camera_control")
let { TPS, VIRTUAL_FPS, BOMBERVIEW, TURRET } = FlightCameraType
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { getPieMenuSelectedIdx } = require("%rGui/hud/pieMenu.nut")
let { playerUnitName, isUnitDelayed, isUnitAlive } = require("%rGui/hudState.nut")

let selectedViewIconColor = 0x99996203

let actions = [
  {shortcut = "ID_CAMERA_TPS", icon = "icon_pie_tps_view.svg", view = TPS}
  {shortcut = "ID_CAMERA_VIRTUAL_FPS", icon = "icon_pie_virtual_fps_view.svg", view = VIRTUAL_FPS}
  {shortcut = "ID_CAMERA_BOMBVIEW", icon = "icon_pie_bomber_view.svg", view = BOMBERVIEW}
  {shortcut = "ID_CAMERA_GUNNER", icon = "icon_pie_turret_view.svg", view = TURRET}
]

let mkLabel = @(actionId) loc($"hotkeys/{actionId}")

let mkPieCfgItem = @(a) {
  action = @() toggleShortcut(a.shortcut)
  isVisibleByUnit = @() isCameraViewAvailable(a.view)
  mkView = @() {
    label = mkLabel(a.shortcut),
    icon = a.icon,
    iconColor = (getCameraViewType() == a.view) ? selectedViewIconColor : 0xFFFFFFFF
  }
}

let cameraPieCfgBase = actions.map(@(action) mkPieCfgItem(action))
let isCameraPieStickActive = Watched(false)
let cameraPieStickDelta = Watched(Point2(0, 0))
let cameraPieCfg = Watched([])
let visibleByUnit = Watched([])
let isCameraPieAvailable = Computed(@() visibleByUnit.get().contains(true))

let updateVisibleByUnit = @() visibleByUnit.set(!isUnitAlive.get() || isUnitDelayed.get() ? []
  : cameraPieCfgBase.map(@(c) c?.isVisibleByUnit() ?? true))
updateVisibleByUnit()
playerUnitName.subscribe(@(_) deferOnce(updateVisibleByUnit))
isUnitDelayed.subscribe(@(_) deferOnce(updateVisibleByUnit))
isUnitAlive.subscribe(@(_) deferOnce(updateVisibleByUnit))

function updatePieCfg() {
  if (!isCameraPieStickActive.get())
    return
  cameraPieCfg.set(cameraPieCfgBase
    .map(function(v, id) {
      if (!visibleByUnit.get()?[id])
        return null
      return v.mkView()?.__update({ id })
    })
    .filter(@(v) v != null))
}
updatePieCfg()
isCameraPieStickActive.subscribe(@(_) updatePieCfg())
isCameraPieStickActive.subscribe(@(_) updateVisibleByUnit())
visibleByUnit.subscribe(@(_) updatePieCfg())

let cameraPieSelectedIdx = Computed(@() getPieMenuSelectedIdx(cameraPieCfg.get().len(), cameraPieStickDelta.get()))

isCameraPieStickActive.subscribe(function(isActive) {
  if (isActive)
    return
  let { id = null } = cameraPieCfg.get()?[cameraPieSelectedIdx.get()]
  cameraPieStickDelta.set(Point2(0, 0))
  cameraPieCfgBase?[id].action()
})

return {
  cameraPieCfg
  isCameraPieAvailable
  isCameraPieStickActive
  cameraPieStickDelta
  cameraPieSelectedIdx
}
