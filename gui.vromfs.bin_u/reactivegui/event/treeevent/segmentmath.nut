from "%globalsDarg/darg_library.nut" import *
from "math" import sqrt


let sqr = @(v) v * v

function getDistToSegment(x1, y1, x2, y2, px, py) {
  if (x1 == x2 && y1 == y2)
    return sqrt(sqr(px - x1) + sqr(py - y1))

  let dx = x2 - x1
  let dy = y2 - y1

  
  local t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
  t = clamp(t, 0.0, 1.0)

  
  let cx = x1 + t * dx
  let cy = y1 + t * dy
  return sqrt(sqr(px - cx) + sqr(py - cy))
}

function getClosestSegment(points, x, y) {
  local dist = 0
  local idx = -1
  let last = points.len() - 1
  for (local i = 0; i < last; i++) {
    let d = getDistToSegment(points[i][0], points[i][1], points[i + 1][0], points[i + 1][1], x, y)
    if (idx == -1 || d < dist) {
      dist = d
      idx = i
    }
  }
  return { dist, idx }
}

function getLineEndPoints(line, allPoints) {
  let { from, to, fromPos = null, toPos = null } = line
  return {
    from = fromPos ?? allPoints?[from].pos
    to = toPos ?? allPoints?[to].pos
  }
}

function mkLineSplinePoints(line, allPoints) {
  let { midpoints = [] } = line
  let ends = getLineEndPoints(line, allPoints)
  let res = clone midpoints
  if (ends.from != null)
    res.insert(0, ends.from)
  if (ends.to != null)
    res.append(ends.to)
  return res
}

return {
  getDistToSegment
  getClosestSegment
  mkLineSplinePoints
  getLineEndPoints
}
