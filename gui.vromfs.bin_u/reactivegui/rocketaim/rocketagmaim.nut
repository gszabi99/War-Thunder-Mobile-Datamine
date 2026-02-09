from "%globalsDarg/darg_library.nut" import *
let {TrackerX, TrackerY, TrackerSize, GuidanceLockState, GuidanceLockStateBlinked, TrackerVisible,
  PointIsTarget} = require("%rGui/rocketAim/rocketAgmAimState.nut")
let { GuidanceLockResult } = require("guidanceConstants")

let trackerColor = 0xFF00FF00

let maxTrackerSize = 15

let trackerPositionUpdate = @() {
  transform = {
    translate = [
      TrackerX.get(),
      TrackerY.get()
    ]
  }
}

let rocketAgmTracker = @() function() {
  if (!TrackerVisible.get())
    return {
      watch = TrackerVisible
    }

  let minMarkWidth = hdpx(20) / sw(1);
  local width = min(maxTrackerSize, TrackerSize.get()) / sw(1)
  local height = min(maxTrackerSize, TrackerSize.get()) / sh(1)

  if (width < minMarkWidth) {
    height = minMarkWidth / sh(1) * sw(1)
    width = minMarkWidth
  }

  let squareMark = [
    [VECTOR_RECTANGLE, -width * 0.5, -height * 0.5, width, height],
  ]

  let trackingMark = [
    [VECTOR_RECTANGLE, -0.5 * width, -0.5 * height, width, height],
    [VECTOR_LINE, 0, -0.165 * height, 0, -0.5*height],
    [VECTOR_LINE, 0, 0.165 * height, 0, 0.5*height],
    [VECTOR_LINE, -0.165 * width, 0, -0.5*width, 0],
    [VECTOR_LINE, 0.165 * width, 0, 0.5*width, 0]
  ]

  let gs = GuidanceLockState.get()
  let gsb = GuidanceLockStateBlinked.get()

  let isBlinking = (gsb != gs && gsb == GuidanceLockResult.RESULT_INVALID)
  let isTrack = (gs == GuidanceLockResult.RESULT_TRACKING)

  return {
    behavior = Behaviors.RtPropUpdate
    watch = [GuidanceLockState, GuidanceLockStateBlinked, TrackerVisible, TrackerSize]
    halign = ALIGN_LEFT
    valign = ALIGN_TOP
    size = const [sw(100), sh(100)]
    pos = [-saBorders[0], -saBorders[1]]
    rendObj = ROBJ_VECTOR_CANVAS
    color = trackerColor
    fillColor = Color(0, 0, 0, 0)
    lineWidth = hdpx(2 * 0.25)
    commands = !isBlinking && isTrack ? (PointIsTarget.get() ? squareMark : trackingMark) : null
    update = trackerPositionUpdate
  }
}

let rocketAgmAim = @() {
  size = flex()
  children = [
    rocketAgmTracker()
  ]
}

return { rocketAgmAim }