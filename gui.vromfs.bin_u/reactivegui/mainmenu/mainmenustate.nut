from "%globalsDarg/darg_library.nut" import *
from "hangar" import get_cam_angles, set_camera_angle, reset_camera_pos_dir
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%rGui/components/modalWindows.nut" import hasModalWindows
from "%rGui/navState.nut" import scenesOrder


let isMainMenuAttached = Watched(false)
let isMainMenuTopScene = Computed(@() isMainMenuAttached.get() && !scenesOrder.get().len())
let isInMenuNoModals = Computed(@() isMainMenuTopScene.get() && !hasModalWindows.get())
let isUnitsWndAttached = Watched(false)
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
}