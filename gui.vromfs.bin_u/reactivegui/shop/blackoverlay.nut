from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")

let OVERLAY_CLOSE_TIMEOUT = 0.6 
let OVERLAY_UID = "blackOverlay"

let isOverlayOpened = mkWatched(persist, "isOverlayOpened", false)
let showOverlay = @() isOverlayOpened.set(true)
let closeOverlay = @() isOverlayOpened.set(false)

let overlayAnimation = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.5, easing = OutQuad, playFadeOut = true }
]

isOverlayOpened.subscribe(function(v) {
  removeModalWindow(OVERLAY_UID)
  if (!v)
    return
  addModalWindow({
    key = OVERLAY_UID
    size = [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    animations = overlayAnimation
  })
})

return {
  showBlackOverlay = showOverlay,
  closeBlackOverlay = @() resetTimeout(OVERLAY_CLOSE_TIMEOUT, closeOverlay)
}
