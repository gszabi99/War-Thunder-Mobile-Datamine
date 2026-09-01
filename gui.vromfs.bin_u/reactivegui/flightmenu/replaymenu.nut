from "%globalScripts/controls/shortcutActions.nut" import toggleShortcut


let replayCamerasButtons = [
  {
    name = "(REPLAY) ATTACHED CAMERA"
    action = @() toggleShortcut("ID_REPLAY_CAMERA_FREE_ATTACHED")
  }
  {
    name = "(REPLAY) FREE PARENTED CAMERA"
    action = @() toggleShortcut("ID_REPLAY_CAMERA_FREE_PARENTED")
  }
  {
    name = "(REPLAY) FREE CAMERA"
    action = @() toggleShortcut("ID_REPLAY_CAMERA_FREE")
  }
  {
    name = "(REPLAY) HOVER CAMERA"
    action = @() toggleShortcut("ID_REPLAY_CAMERA_HOVER")
  }
]

return {
  replayCamerasButtons
}