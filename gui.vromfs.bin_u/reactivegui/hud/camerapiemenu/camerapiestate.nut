from "%globalsDarg/darg_library.nut" import *
from "camera_control" import FlightCameraType, getCameraViewType, isCameraViewAvailable
from "dagor.math" import Point2
from "dagor.workcycle" import deferOnce
from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut
from "%rGui/controls/disabledControls.nut" import enabledControls, isAllControlsEnabled
from "%rGui/hud/hudTouchButtonStyle.nut" import imageDisabledColor
from "%rGui/hud/pieMenu.nut" import getPieMenuSelectedIdx
from "%rGui/hudState.nut" import playerUnitName, isUnitDelayed, isUnitAlive, isPlayingReplay
from "%rGui/missionState.nut" import notGtRace
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudDarkOliveColor


let { TPS, VIRTUAL_FPS, BOMBERVIEW, TURRET } = FlightCameraType

let selectedViewIconColor = hudDarkOliveColor

let actions = [
  { shortcut = "ID_CAMERA_TPS", icon = "icon_pie_tps_view.svg", view = TPS }
  { shortcut = "ID_CAMERA_VIRTUAL_FPS", icon = "icon_pie_virtual_fps_view.svg", view = VIRTUAL_FPS }
  { shortcut = "ID_CAMERA_BOMBVIEW", icon = "icon_pie_bomber_view.svg", view = BOMBERVIEW, isAllowed = notGtRace }
  { shortcut = "ID_CAMERA_GUNNER", icon = "icon_pie_turret_view.svg", view = TURRET, isAllowed = notGtRace }
]

let mkLabel = @(actionId) loc($"hotkeys/{actionId}")

let mkPieCfgItem = @(a) a.__merge({
  action = @() toggleShortcut(a.shortcut)
  isVisibleByUnit = @() isCameraViewAvailable(a.view)
  mkView = @(isEnabled) {
    label = mkLabel(a.shortcut),
    icon = a.icon,
    iconColor = !isEnabled ? imageDisabledColor
      :(getCameraViewType() == a.view) ? selectedViewIconColor
      : hudWhiteColor
  }
})

let cameraPieCfgBase = actions.map(@(action) mkPieCfgItem(action))
let isCameraPieStickActive = Watched(false)
let cameraPieStickDelta = Watched(Point2(0, 0))
let cameraPieCfg = Watched([])
let visibleByUnit = Watched([])
let isCameraPieAvailable = Computed(@() !isPlayingReplay.get() && visibleByUnit.get().contains(true))
let isCameraPieItemsEnabled = Computed(@() null != cameraPieCfgBase.findvalue(@(c, id)
  visibleByUnit.get()?[id] && (enabledControls.get()?[c?.shortcut] ?? isAllControlsEnabled.get()))
)

let updateVisibleByUnit = @() visibleByUnit.set(!isUnitAlive.get() || isUnitDelayed.get() ? []
  : cameraPieCfgBase.map(@(c) (c?.isAllowed.get() ?? true) && (c?.isVisibleByUnit() ?? true)))
updateVisibleByUnit()
let subsUpdateVisibleByUnit = @(_) deferOnce(updateVisibleByUnit)
playerUnitName.subscribe(subsUpdateVisibleByUnit)
isUnitDelayed.subscribe(subsUpdateVisibleByUnit)
isUnitAlive.subscribe(subsUpdateVisibleByUnit)
foreach (a in cameraPieCfgBase)
  a?.isAllowed.subscribe(subsUpdateVisibleByUnit)

function updatePieCfg() {
  if (!isCameraPieStickActive.get())
    return
  cameraPieCfg.set(cameraPieCfgBase
    .map(function(v, id) {
      if (!visibleByUnit.get()?[id])
        return null
      let isEnabled = (enabledControls.get()?[v.shortcut] ?? isAllControlsEnabled.get())
      return v.mkView(isEnabled)?.__update({ id })
    })
    .filter(@(v) v != null))
}
updatePieCfg()
isCameraPieStickActive.subscribe(@(_) updatePieCfg())
isCameraPieStickActive.subscribe(@(_) updateVisibleByUnit())
visibleByUnit.subscribe(@(_) updatePieCfg())
enabledControls.subscribe(@(_) updatePieCfg())
isAllControlsEnabled.subscribe(@(_) updatePieCfg())

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
  isCameraPieItemsEnabled
  isCameraPieAvailable
  isCameraPieStickActive
  cameraPieStickDelta
  cameraPieSelectedIdx
}
