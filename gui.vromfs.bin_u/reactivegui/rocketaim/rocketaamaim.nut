from "%globalsDarg/darg_library.nut" import *

let { GimbalSize, GimbalVisible, GuidanceLockState, TrackerSize, TrackerVisible, GuidanceLockSnr,
  AamSightOpacity, TrackerX, TrackerY, GimbalX, GimbalY } = require("%rGui/rocketAim/rocketAamAimState.nut")
let { crosshairLineWidth } = require("%rGui/hud/sight.nut")
let { GuidanceLockResult } = require("guidanceConstants")

let trackColor = 0xFF00FF00
let searchColor = Color(230, 0, 0, 240)

let gimbalPositionUpdate = @() {
  transform = {
    translate = [
      GimbalX.get(),
      GimbalY.get()
    ]
  }
}

let trackerPositionUpdate = @() {
  transform = {
    translate = [
      TrackerX.get(),
      TrackerY.get()
    ]
  }
}

let gimbalLines = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = 0
  lineWidth = crosshairLineWidth
  commands = [[VECTOR_ELLIPSE, 0, 0, 100, 100]]
}

let aamAimGimbal = @() function() {
  if (!GimbalVisible.get())
    return { watch = GimbalVisible }

  let colorGimbal =
      (GuidanceLockSnr.get() > 1.0) || (GuidanceLockSnr.get() < 0.0 && GuidanceLockState.get() >= GuidanceLockResult.RESULT_TRACKING)
      ? searchColor : trackColor

  let lines = gimbalLines.__merge({
    color = colorGimbal
    opacity = AamSightOpacity.get()
  })

  return {
    behavior = Behaviors.RtPropUpdate
    watch = [GimbalVisible, GuidanceLockState, GimbalSize, GuidanceLockSnr, AamSightOpacity]
    size = [GimbalSize.get(), GimbalSize.get()]
    pos = [-saBorders[0], -saBorders[1]]
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP

    children = lines
    update = gimbalPositionUpdate
  }
}

let trackerLines = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = 0
  lineWidth = crosshairLineWidth
  commands = [[VECTOR_ELLIPSE, 0, 0, 100, 100]]
}

let aamAimTracker = @() function() {
  if (!TrackerVisible.get())
    return { watch = TrackerVisible }

  let colorTracker =
    (GuidanceLockSnr.get() > 1.0) || (GuidanceLockSnr.get() < 0.0 && GuidanceLockState.get() >= GuidanceLockResult.RESULT_TRACKING)
    ? searchColor : trackColor

  let lines = trackerLines.__merge({
    color = colorTracker
    opacity = AamSightOpacity.get()
  })

  return {
    behavior = Behaviors.RtPropUpdate
    watch = [TrackerVisible, GuidanceLockState, TrackerSize, GuidanceLockSnr, AamSightOpacity]
    size = [TrackerSize.get(), TrackerSize.get()]
    pos = [-saBorders[0], -saBorders[1]]
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    update = trackerPositionUpdate
    children = lines
  }
}

let rocketAamAim = @() {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    aamAimGimbal()
    aamAimTracker()
  ]
}


return { rocketAamAim }