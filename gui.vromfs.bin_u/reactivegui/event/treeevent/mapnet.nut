from "%globalsDarg/darg_library.nut" import *


const lineWidth = hdpxi(4)

function mkNet(mapSize, cellSize) {
  if (cellSize <= 0)
    return []
  let count = mapSize.map(@(v) v / cellSize)
  let percent = mapSize.map(@(v) 100.0 * cellSize / v)
  return array(count[0])
    .map(@(_, i) [VECTOR_LINE, (i + 1) * percent[0], 0, (i + 1) * percent[0], 100])
    .extend(array(count[1])
      .map(@(_, i) [VECTOR_LINE, 0, (i + 1) * percent[1], 100, (i + 1) * percent[1]]))
}

let mapNet = @(mapSize, cellSize) @() {
  watch = [mapSize, cellSize]
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth
  color = 0xFF53250d
  opacity = 0.4
  commands = mkNet(mapSize.get(), cellSize.get())
}

return mapNet
