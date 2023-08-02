from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { sqrt, lerp } = require("%sqstd/math.nut")

let function mkAnimGrowLines(cfg, ovr = {}) {
  let { start, end, drawers } = cfg
  local initTime = -1
  local isFinished = false
  local commands = []
  return {
    key = cfg
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(4)
    color = 0xFF51C1DC
    commands
    behavior = Behaviors.RtPropUpdate
    function update() {
      if (isFinished)
        return null
      if (initTime == -1)
        initTime = get_time_msec()
      let time = get_time_msec() - initTime
      if (time < start)
        return null
      if (time >= end)
        isFinished = true
      commands = drawers.map(@(ctor) ctor(time))
        .filter(@(v) v != null)

      return { commands }
    }
  }.__update(ovr)
}

let lineLengthSq = @(line) (line[0] - line[2]) * (line[0] - line[2]) + (line[1] - line[3]) * (line[1] - line[3])
let linePxToVector = @(line, size) line.map(@(v, i) 100.0 * v / size[i % 2])
let lerpVectorLine = @(vLine, start, end, cur)
  [ vLine[0], vLine[1], vLine[2],
    lerp(start, end, vLine[1], vLine[3], cur),
    lerp(start, end, vLine[2], vLine[4], cur),
  ]

let function mkAGLinesCfgOrdered(lines, speed, delay = 0, size = [sw(100), sh(100)]) {
  let drawers = []
  local totalTime = 1000.0 * delay
  foreach (stepList in lines) {
    let maxLengthSq = stepList.reduce(@(res, line) max(res, lineLengthSq(line)), 0)
    if (maxLengthSq == 0)
      continue
    let stepTime = 1000.0 * sqrt(maxLengthSq) / speed
    let start = totalTime
    let end = totalTime + stepTime
    totalTime = end
    foreach (line in stepList) {
      let vLine = linePxToVector(line, size)
      vLine.insert(0, VECTOR_LINE)
      drawers.append(@(time) time <= start ? null
        : time >= end ? vLine
        : lerpVectorLine(vLine, start, end, time))
    }
  }
  return {
    start = 1000.0 * delay
    end = totalTime
    drawers
  }
}

return {
  mkAnimGrowLines
  mkAGLinesCfgOrdered
}