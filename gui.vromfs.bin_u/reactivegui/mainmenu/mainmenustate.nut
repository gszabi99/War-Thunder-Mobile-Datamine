from "%globalsDarg/darg_library.nut" import *
let { get_cam_angles = @() null, set_camera_angle = @(_) null, reset_camera_pos_dir } = require("hangar")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { scenesOrder } = require("%rGui/navState.nut")

let isMainMenuAttached = Watched(false)
let isMainMenuTopScene = Computed(@() isMainMenuAttached.get() && !scenesOrder.get().len())
let isInMenuNoModals = Computed(@() isMainMenuTopScene.get() && !hasModalWindows.get())
let isUnitsWndAttached = Watched(false)
let isUnitsWndOpened = mkWatched(persist, "isOpened", false)
let cameraAngle = Watched(null)

isMainMenuAttached.subscribe(@(v)
  !v ? cameraAngle.set(get_cam_angles())
    : cameraAngle.get() != null ? set_camera_angle(cameraAngle.get())
    : reset_camera_pos_dir()
)

curCampaign.subscribe(@(_) cameraAngle.set(null))

return {
  isMainMenuAttached
  isInMenuNoModals
  isMainMenuTopScene
  isUnitsWndAttached
  isUnitsWndOpened
}