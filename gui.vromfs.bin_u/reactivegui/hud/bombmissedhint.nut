from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")

let { hitCameraRenderSize } = require("%rGui/hud/hitCamera/hitCameraConfig.nut")
let { fakeHitCameraResultPlate } = require("hitCamera/hitCameraResultPlate.nut")
let eventbus = require("eventbus")

let showBombMiss = Watched(false)
let resetShowBombMiss = @() showBombMiss(false)

eventbus.subscribe("onBombMiss", function(_) {
  showBombMiss(true)
  resetTimeout(3, resetShowBombMiss)
 })

return @()
  {
    watch = showBombMiss
    hplace = ALIGN_RIGHT
    pos = [0, hitCameraRenderSize[1]]
    size = hitCameraRenderSize
    children = showBombMiss.value ? fakeHitCameraResultPlate(loc("hitcamera/result/targetNotHit")): null
  }
