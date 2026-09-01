from "%globalsDarg/darg_library.nut" import *
from "math" import sin, cos, PI, ceil


const lineWidth = hdpxi(4)
const roseRadiusPartPrim = 1.0
const roseRadiusPartSec = 0.8
const dashLen = hdpx(60)
const dashSpace = hdpx(40)

function mkNet(mapSize, cellSize, center) {
  if (cellSize <= 0)
    return []
  let offset = center.map(@(v) v % cellSize == 0 ? cellSize : v % cellSize)
  let count = mapSize.map(@(v, a) ceil(((v + cellSize - offset[a]) / cellSize)).tointeger())
  let percent = mapSize.map(@(v) 100.0 * cellSize / v)
  let pOffset = mapSize.map(@(v, a) 100.0 * offset[a] / v)
  return array(count[0])
    .map(@(_, i) [VECTOR_LINE, pOffset[0] + i * percent[0], 0, pOffset[0] + i * percent[0], 100])
    .extend(array(count[1])
      .map(@(_, i) [VECTOR_LINE, 0, pOffset[1] + i * percent[1], 100, pOffset[1] + i * percent[1]]))
}

function getPointOnCmdBorder(x, y, dx, dy) {
  let xMul = dx == 0 ? 0
    : dx < 0 ? -x / dx
    : (100.0 - x) / dx
  let yMul = dy == 0 ? 0
    : dy < 0 ? -y / dy
    : (100.0 - y) / dy
  let mul = min(xMul || yMul, yMul || xMul)
  return [x + dx * mul, y + dy * mul]
}

function cmdLineToBorder(x, y, dx, dy) {
  let [x2, y2] = getPointOnCmdBorder(x, y, dx, dy)
  return [VECTOR_LINE, x, y, x2, y2]
}

function cmdDashedLineToBorder(x, y, dx, dy) {
  let [x2, y2] = getPointOnCmdBorder(x, y, dx, dy)
  return [VECTOR_LINE_DASHED, x, y, x2, y2, dashLen, dashSpace]
}

function mkRoseLines(mapSize, rose) {
  let { size, pos } = rose
  let radiusBase = min(size[0], size[1]).tofloat() / 2
  let radis = mapSize.map(@(v) 100.0 * radiusBase / v)
  let center = pos.map(@(v, a) 100.0 * (v + size[a] / 2) / mapSize[a])
  let res = []
  for (local i = 0; i < 4; i++) {
    let a = PI / 4 + i * PI / 2
    let dx = radis[0] * cos(a) * roseRadiusPartPrim
    let dy = radis[1] * sin(a) * roseRadiusPartPrim
    res.append(cmdLineToBorder(center[0] + dx, center[1] + dy, dx, dy))

    foreach (a2 in [a - PI / 8, a + PI / 8]) {
      let dx2 = radis[0] * cos(a2) * roseRadiusPartSec
      let dy2 = radis[1] * sin(a2) * roseRadiusPartSec
      res.append(cmdDashedLineToBorder(center[0] + dx2, center[1] + dy2, dx2, dy2))
    }
  }
  return res
}

let getRoseCenter = @(rose) rose == null ? [0, 0] : rose.pos.map(@(v, a) v + rose.size[a] / 2)

let mapNet = @(mapSize, cellSize, bgElems) {
  size = FLEX
  rendObj = ROBJ_MASK
  image = Picture("ui/images/pirates/mapGridNoise.avif")
  children = function() {
    let rose = bgElems.get().findvalue(@(b) b.id == "compass_rose")
    return {
      watch = [mapSize, cellSize, bgElems]
      size = FLEX
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth
      color = 0xFF53250d
      opacity = 0.4
      commands = mkNet(mapSize.get(), cellSize.get(), getRoseCenter(rose))
        .extend(rose == null ? [] : mkRoseLines(mapSize.get(), rose))
    }
  }
}

return mapNet