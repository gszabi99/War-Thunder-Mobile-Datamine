from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "%sqstd/math.nut" import sqrt, lerp
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut" import mkCutBg


function mkAnimGrowLines(cfg, ovr = {}) {
  let { start, end, drawers } = cfg
  local initTime = -1
  local isFinished = false
  local commands = []
  return {
    key = cfg
    size = FLEX
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(4)
    color = selectColor
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

function mkAGLinesCfgOrdered(lines, speed, delay = 0, size = const [sw(100), sh(100)]) {
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

let mkLinesVectorCommands = @(lineSteps, size = const [sw(100), sh(100)])
  lineSteps.reduce(function(res, stepList) {
    foreach (line in stepList)
      res.append([VECTOR_LINE].extend(linePxToVector(line, size)))
    return res
  }, [])

let mkStaticLines = @(lineSteps, ovr = {}) {
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(4)
  color = selectColor
  commands = mkLinesVectorCommands(lineSteps)
}.__update(ovr)

let getDirFromAtoB = @(r1, r2) r2.b < r1.t ? DIR_UP
  : r2.l > r1.r  ? DIR_RIGHT
  : r2.r < r1.l ? DIR_LEFT
  : DIR_DOWN

let rectToRectAnimCtors = {
  [DIR_UP] = function rtrUp(r1, r2) {
    let { t, b, r, l } = r1
    let midX1 = (r + l) / 2
    let midX2 = (r2.r + r2.l) / 2
    return [
      
      [
        [midX1, b, l, b],
        [midX1, b, r, b],
      ],
      [
        [l, b, l, t],
        [r, b, r, t],
      ],
      [
        [l, t, midX1, t],
        [r, t, midX1, t],
      ],
      
      [[midX1, t, midX1, r2.b]],
      
      [
        [midX1, r2.b, r2.l, r2.b],
        [midX1, r2.b, r2.r, r2.b],
      ],
      [
        [r2.l, r2.b, r2.l, r2.t],
        [r2.r, r2.b, r2.r, r2.t],
      ],
      [
        [r2.l, r2.t, midX2, r2.t],
        [r2.r, r2.t, midX2, r2.t],
      ]
    ]
  },

  [DIR_DOWN] = function rtrUp(r1, r2) {
    let { t, b, r, l } = r1
    let midX1 = (r + l) / 2
    let midX2 = (r2.r + r2.l) / 2
    return [
      
      [
        [midX1, t, l, t],
        [midX1, t, r, t],
      ],
      [
        [l, t, l, b],
        [r, t, r, b],
      ],
      [
        [l, b, midX1, b],
        [r, b, midX1, b],
      ],
      
      [[midX1, b, midX1, r2.t]],
      
      [
        [midX1, r2.t, r2.l, r2.t],
        [midX1, r2.t, r2.r, r2.t],
      ],
      [
        [r2.l, r2.t, r2.l, r2.b],
        [r2.r, r2.t, r2.r, r2.b],
      ],
      [
        [r2.l, r2.b, midX2, r2.b],
        [r2.r, r2.b, midX2, r2.b],
      ]
    ]
  },

  [DIR_LEFT] = function rtrUp(r1, r2) {
    let { t, b, r, l } = r1
    let midY1 = (t + b) / 2
    let midY2 = (r2.t + r2.b) / 2
    return [
      
      [
        [r, midY1, r, t],
        [r, midY1, r, b],
      ],
      [
        [r, t, l, t],
        [r, b, l, b],
      ],
      [
        [l, t, l, midY1],
        [l, b, l, midY1],
      ],
      
      [[l, midY1, r2.r, midY1]],
      
      [
        [r2.r, midY1, r2.r, r2.t],
        [r2.r, midY1, r2.r, r2.b],
      ],
      [
        [r2.r, r2.t, r2.l, r2.t],
        [r2.r, r2.b, r2.l, r2.b],
      ],
      [
        [r2.l, r2.t, r2.l, midY2],
        [r2.l, r2.b, r2.l, midY2],
      ]
    ]
  },

  [DIR_RIGHT] = function rtrUp(r1, r2) {
    let { t, b, r, l } = r1
    let midY1 = (t + b) / 2
    let midY2 = (r2.t + r2.b) / 2
    return [
      
      [
        [l, midY1, l, t],
        [l, midY1, l, b],
      ],
      [
        [l, t, r, t],
        [l, b, r, b],
      ],
      [
        [r, t, r, midY1],
        [r, b, r, midY1],
      ],
      
      [[r, midY1, r2.l, midY1]],
      
      [
        [r2.l, midY1, r2.l, r2.t],
        [r2.l, midY1, r2.l, r2.b],
      ],
      [
        [r2.l, r2.t, r2.r, r2.t],
        [r2.l, r2.b, r2.r, r2.b],
      ],
      [
        [r2.r, r2.t, r2.r, midY2],
        [r2.r, r2.b, r2.r, midY2],
      ]
    ]
  },
}

let animLinesFromRectToWnd = @(rect, wndAABBW) function() {
  let res = { watch = wndAABBW }
  if (wndAABBW.get() == null)
    return res

  let lines = rectToRectAnimCtors?[getDirFromAtoB(rect, wndAABBW.get())](rect, wndAABBW.get()) ?? []
  return res.__update({
    size = FLEX
    children = mkAnimGrowLines(mkAGLinesCfgOrdered(lines, hdpx(3000)))
  })
}

let mkAnimGrowLinesFromRectToWnd = @(tgtRect, wndAABBW, wndPos, wnd) [
  mkCutBg([tgtRect])
  {
    pos = wndPos
    transform = {}
    safeAreaMargin = saBordersRv
    behavior = Behaviors.BoundToArea
    children = wnd
  }
  animLinesFromRectToWnd(tgtRect, wndAABBW)
]

return {
  mkAnimGrowLines
  mkAGLinesCfgOrdered
  mkStaticLines

  mkAnimGrowLinesFromRectToWnd
}