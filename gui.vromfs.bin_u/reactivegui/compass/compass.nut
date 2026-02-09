from "%globalsDarg/darg_library.nut" import *

let { CompassValue, azimuthMarkersTrigger, azimuthMarkers } = require("%rGui/compass/compassState.nut")
let { borderColor, borderWidth } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { fabs } = require("math")

let lineStyle = {
  fillColor = 0
  lineWidth = hdpx(2)
}

let compassSize = [hdpx(700), hdpx(42)]
let marksSize = hdpx(32)
let compasColor = 0xFF00FF00
let compassStep = 5

function generateCompassNumber(num, width, height, color) {
  return {
    size = [width, height]
    flow = FLOW_VERTICAL
    children = [
      {
        rendObj = ROBJ_TEXT
        size = [width, 0.5 * height]
        halign = ALIGN_CENTER
        text = num
        color
      }.__update(fontVeryVeryTinyAccentedShaded)
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = [width, 0.5 * height]
        color
        commands = [
          [VECTOR_LINE, 50, 10, 50, 100]
        ]
      }.__update(fontVeryVeryTinyAccentedShaded)
    ]
  }
}

let generateCompassDash = @(width, height, color)
  lineStyle.__merge({
    size = [width, height]
    rendObj = ROBJ_VECTOR_CANVAS
    color
    commands = [
      [VECTOR_LINE, 50, 70, 50, 100]
    ]
  })

function mkLine(total_width, width, height, color) {
  let children = []
  for (local i = 0; i <= 2.0 * 360.0 / compassStep; ++i) {
    local num = (i * compassStep) % 360
    if (num == 0)
      num = "N"
    else if (num == 90)
      num = "E"
    else if (num == 180)
      num = "S"
    else if (num == 270)
      num = "W"
    else
      num = num.tointeger()
    children.append(generateCompassNumber(num, width, height, color))
    children.append(generateCompassDash(width, height, color))
  }
  let getOffset = @() 0.5 * (total_width - width) + CompassValue.get() * width * 2.0 / compassStep - 2.0 * 360.0 * width / compassStep
  return {
    behavior = Behaviors.RtPropUpdate
    update = @() {
      transform = {
        translate = [getOffset(), 0]
      }
    }
    size = [SIZE_TO_CONTENT, height]
    flow = FLOW_HORIZONTAL
    children = children
  }
}

let mkLines = @(size, color) {
  size
  clipChildren = true
  children = mkLine(size[0], size[1], size[1], color)
}

let compassArrow = lineStyle.__merge({
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [
    [VECTOR_LINE, 0, 100, 50, 0],
    [VECTOR_LINE, 50, 0, 100, 100]
  ]
})

function mkAzimuthMark(size, is_selected, is_detected, is_enemy, color) {
  let frameSizeW = size[0] * 1.5
  let frameSizeH = size[1] * 1.5
  let commands = []
  if (is_selected)
    commands.append(
      [VECTOR_LINE, 0, 0, 100, 0],
      [VECTOR_LINE, 100, 0, 100, 100],
      [VECTOR_LINE, 100, 100, 0, 100],
      [VECTOR_LINE, 0, 100, 0, 0]
    )
  else if (is_detected)
    commands.append(
      [VECTOR_LINE, 100, 0, 100, 100],
      [VECTOR_LINE, 0, 100, 0, 0]
    )
  if (!is_enemy) {
    let yOffset = is_selected ? 110 : 95
    let xOffset = is_selected ? 0 : 10
    commands.append([VECTOR_LINE, xOffset, yOffset, 100.0 - xOffset, yOffset])
  }

  let frame = {
    size = [frameSizeW, frameSizeH]
    pos = [(size[0] - frameSizeW) * 0.5, (size[1] - frameSizeH) * 0.5 ]
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(2)
    color
    fillColor = 0
    commands
  }

  return {
    size
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(3)
    color
    fillColor = 0
    commands = [
      [VECTOR_LINE, 0, 100, 50, 0],
      [VECTOR_LINE, 50, 0, 100, 100],
      [VECTOR_LINE, 100, 100, 0, 100]
    ]
    children = frame
  }
}

function mkAircraftMark(markData, size, color) {
  let compassAngle = (CompassValue.get() > 0 ? 360 : 0) - CompassValue.get()
  local delta = markData.azimuthWorldDeg - compassAngle
  let sign = (delta > 0) ? 1 : -1
  delta = fabs(delta) > 180 ? delta - sign * 360 : delta

  let offset = 2 * delta * size[1] / compassStep
  let halfImageSize = size[1] / 2
  let posX = min(max(size[0] / 2 + offset, -halfImageSize), size[0]) - halfImageSize
  return @() {
    watch = CompassValue
    color = color
    pos = [posX, 0]
    children = mkAzimuthMark([size[1] * 0.7, size[1]], markData.isSelected, markData.isDetected, markData.isEnemy, color)
  }
}

function mkAircraftMarks(size, color) {
  let markers = []
  foreach (_id, azimuthMarker in azimuthMarkers) {
    if (!azimuthMarker)
      continue
    else if (azimuthMarker.ageRel > 1.0)
      continue
    markers.append(mkAircraftMark(azimuthMarker, size, color))
  }
  return markers
}

let mkAircraftComponent = @(size, pos, color) @() {
  watch = azimuthMarkersTrigger
  size
  pos = [0, pos]
  children = mkAircraftMarks(size, color)
}

function mkCompass(scale) {
  let width = scaleEven(compassSize[0], scale)
  let height = scaleEven(compassSize[1], scale)
  let markHeight = scaleEven(marksSize, scale)
  let top = height + hdpx(5)
  return @() {
    halign = ALIGN_CENTER
    gap = hdpx(5)
    children = [
      mkLines([width, height], compasColor)
      compassArrow.__merge({ pos = [0, top], size = array(2, 0.3 * markHeight), compasColor })
      mkAircraftComponent([width, markHeight], top + markHeight, compasColor)
    ]
  }
}

let mkCompassEditView = {
  size = compassSize
  rendObj = ROBJ_BOX
  borderWidth
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("hud/compass")
  }.__update(fontSmall)
}

return {
  mkCompass
  mkCompassEditView
}
