from "%globalsDarg/darg_library.nut" import *
let { fabs, radToDeg, atan2 } = require("%sqstd/math_ex.nut")

let isIntersect = @(b1, b2) !(b1.l >= b2.r || b2.l >= b1.r || b1.t >= b2.b || b2.t >= b1.b)
let isInScreen = @(pos, size) pos[0] >= 0 && pos[1] >= 0 && pos[0] + size[0] <= sw(100) && pos[1] + size[1] <= sh(100)
let isIntersectAny = @(b1, list) list.findvalue(@(b2) isIntersect(b1, b2)) != null

//increase box size in all 4 directions, but clamp by screen size
let incBoxSize = @(box, inc) inc == 0 ? box
  : {
      l = max(0, box.l - inc)
      t = max(0, box.t - inc)
      r = min(sw(100), box.r + inc)
      b = min(sh(100), box.b + inc)
    }

let incBoxSizeUnlimited = @(box, inc) inc == 0 ? box
  : {
      l = box.l - inc
      t = box.t - inc
      r = box.r + inc
      b = box.b + inc
    }

function cutBlock(block, cutter) {
  if (!isIntersect(block, cutter))
    return [block]

  let res = []
  if (block.l < cutter.l)
    res.append({ l = block.l, t = block.t, r = cutter.l, b = block.b })
  if (block.r > cutter.r)
    res.append({ l = cutter.r, t = block.t, r = block.r, b = block.b })

  let l = max(cutter.l, block.l)
  let r = min(cutter.r, block.r)
  if (block.t < cutter.t)
    res.append({ l, r, t = block.t, b = cutter.t })
  if (block.b > cutter.b)
    res.append({ l, r, t = cutter.b, b = block.b })

  return res
}

function createHighlight(boxes, lightCtor, darkCtor, fullArea = {}) {
  local darkBlocks = [{ l = 0, t = 0, r = sw(100), b = sh(100) }.__update(fullArea)]
  let lightBlocks = []

  foreach (box in boxes) {
    if ("l" not in box)
      continue
    lightBlocks.append(box)
    let cutted = []
    darkBlocks.each(@(block) cutted.extend(cutBlock(block, box)))
    darkBlocks = cutted
  }

  return darkBlocks.map(@(db) darkCtor(db))
    .extend(lightBlocks.map(@(lb) lightCtor(lb)))
}

function getBox(keys) {
  let kType = type(keys)
  if (kType == "function")
    return getBox(keys())

  if (kType == "array") {
    local res = null
    foreach (key in keys) {
      let aabb = gui_scene.getCompAABBbyKey(key)
      if (aabb == null)
        continue
      if (res == null) {
        res = aabb
        continue
      }
      res.l = min(res.l, aabb.l)
      res.r = max(res.r, aabb.r)
      res.t = min(res.t, aabb.t)
      res.b = max(res.b, aabb.b)
    }
    return res
  }

  return gui_scene.getCompAABBbyKey(keys)
}

function findDiapason(allowedBox, allowedRange, obstacles) {
  let diapason = [allowedRange]
  foreach (oData in obstacles) {
    let { obst, start, end } = oData
    if (!isIntersect(obst, allowedBox))
      continue
    if (start < allowedRange[0] && end > allowedRange[1])
      continue //ignore such big boxes

    local found = false
    for (local d = diapason.len() - 1; d >= 0; d--) {
      let segment = diapason[d]
      if (segment[1] < start)
        break
      if (!found && segment[0] > end)
        continue

      diapason.remove(d)
      if (!found && segment[1] > end)
        diapason.insert(d, [end + 1, segment[1]])
      found = true

      if (segment[0] < start) {
        diapason.insert(d, [segment[0], start - 1])
        break
      }
    }
  }
  return diapason
}

let findDiapasonY = @(box, obstacles)
  findDiapason(box, [box.t, box.b], obstacles.map(@(o) { obst = o, start = o.t, end = o.b }))
let findDiapasonX = @(box, obstacles)
  findDiapason(box, [box.l, box.r], obstacles.map(@(o) { obst = o, start = o.l, end = o.r }))

function getBestPos(diapason, range) { //return null -> not found
  let size = range[1] - range[0]
  local found = false
  local pos = 0
  foreach (segment in diapason) {
    if (segment[1] - segment[0] < size)
      continue

    let bestPos = clamp(range[0], segment[0], segment[1] - size)
    if (found && fabs(bestPos - range[0]) < fabs(pos - range[0]))
      continue

    found = true
    pos = bestPos
  }
  return found ? pos : null
}

//return null -> not found
let getBestPosByY = @(diapasonY, box) getBestPos(diapasonY, [box.t, box.b])
let getBestPosByX = @(diapasonX, box) getBestPos(diapasonX, [box.l, box.r])

let sizePosToBox = @(size, pos) { l = pos[0], r = pos[0] + size[0], t = pos[1], b = pos[1] + size[1] }
let hasInteractions = @(box, boxes) null != boxes.findvalue(@(b) isIntersect(b, box))

function findGoodPos(size, pos, boxes) { //move only by single axis. For tutorial it must be enough.
  let box = sizePosToBox(size, pos)
  if (!hasInteractions(box, boxes))
    return pos

  let allowedBoxX = { l = sw(5), r = sw(95), t = box.t, b = box.b }
  let posX = getBestPosByX(findDiapasonX(allowedBoxX, boxes), box)
  if (posX != null)
    return [posX, box.t]

  let allowedBoxY = { l = box.l, r = box.r, t = sh(5), b = sh(95) }
  let posY = getBestPosByY(findDiapasonY(allowedBoxY, boxes), box)
  if (posY != null)
    return [box.l, posY]

  return [box.l, box.t]
}

function getBorderBestPosX(size, allowedBox, boxes) {
  let ranges = [
    [allowedBox.l, allowedBox.l + size[0]],
    [allowedBox.r - size[0], allowedBox.r],
  ]
  let weights = ranges.map(@(_) 0)
  foreach(box in boxes) {
    if (!isIntersect(box, allowedBox))
      continue
    foreach(idx, r in ranges)
      weights[idx] += max(0, min(box.r, r[1]) - max(box.l, r[0]))
  }
  return weights[0] > weights[1] ? ranges[1][0] : ranges[0][0]
}

function findGoodPosX(size, pos, boxes) {
  let box = sizePosToBox(size, pos)
  if (!hasInteractions(box, boxes))
    return pos
  let allowedBoxX = { l = sw(5), r = sw(95), t = box.t, b = box.b }
  local posX = getBestPosByX(findDiapasonX(allowedBoxX, boxes), box)
  if (posX == null)
    posX = getBorderBestPosX(size, allowedBoxX, boxes)
  return [posX, box.t]
}

function getNotInterractPos(size, posList, boxes) {
  foreach(pos in posList) {
    let box = sizePosToBox(size, pos)
    if (!hasInteractions(box, boxes))
      return pos
  }
  return null
}

let bottomArrowPos = @(box, size) { pos = [(box.r + box.l - size[0]) / 2, box.b], rotate = 180 }
let topArrowPos = @(box, size) { pos = [(box.r + box.l - size[0]) / 2, box.t - size[1]], rotate = 0 }
let leftArrowPos = @(box, size) { pos = [box.l - size[0], (box.t + box.b - size[1]) / 2], rotate = -90 }
let rightArrowPos = @(box, size) { pos = [box.r, (box.t + box.b - size[1]) / 2], rotate = 90 }

function isInScreenAndNotIntersect(pos, size, obstacles) {
  if (!isInScreen(pos, size))
    return false
  let box = sizePosToBox(size, pos)
  return !isIntersectAny(box, obstacles)
}

let mkSimplePosNotIntersect = @(posCtor, orderCalc) {
  orderCalc
  posCalc = function(box, size, obstacles) {
    let res = posCtor(box, size)
    return isInScreenAndNotIntersect(res.pos, size, obstacles) ? res : null
  }
}
let mkSimplePosInScreen = @(posCtor, orderCalc) {
  orderCalc
  posCalc = function(box, size, _obstacles) {
    let res = posCtor(box, size)
    return isInScreen(res.pos, size) ? res : null
  }
}

let arrowPosCalcList = [
  //middleBottom
  mkSimplePosNotIntersect(bottomArrowPos, @(b) (b.t + b.b) > sh(120) ? 3 : 1)
  mkSimplePosNotIntersect(topArrowPos, @(_) 2)
  mkSimplePosNotIntersect(leftArrowPos, @(b) (b.l + b.r) < sh(80) ? 6 : 4)
  mkSimplePosNotIntersect(rightArrowPos, @(_) 5)

  //here can be more perfect arrow positioning when no other place, but no need for the current tutorials

  mkSimplePosInScreen(bottomArrowPos, @(b) (b.t + b.b) > sh(120) ? 103 : 101)
  mkSimplePosInScreen(topArrowPos, @(_) 102)
  mkSimplePosInScreen(leftArrowPos, @(b) (b.l + b.r) < sh(80) ? 106 : 104)
  mkSimplePosInScreen(rightArrowPos, @(_) 105)
]

function findGoodArrowPos(box, size, obstacles) {
  let calcSorted = arrowPosCalcList.map(@(c) { order = c.orderCalc(box), posCalc = c.posCalc })
    .sort(@(a, b) a.order <=> b.order)
  foreach (calcData in calcSorted) {
    let { pos = null, rotate = 0 } = calcData.posCalc(box, size, obstacles)
    if (pos != null)
      return { pos, rotate }
  }
  return bottomArrowPos(box, size)
}

let getBoxCenter = @(box) [0.5 * (box.l + box.r), 0.5 * (box.t + box.b)]
function getLinkArrowMiddleCfg(boxFrom, boxTo) {
  let boxFromC = getBoxCenter(boxFrom)
  let boxToC = getBoxCenter(boxTo)
  return {
    pos = [0.5 * (boxFromC[0] + boxToC[0]), 0.5 * (boxFromC[1] + boxToC[1])]
    rotate = boxToC[0] == boxFromC[0] && boxToC[1] == boxFromC[1] ? 0
      : radToDeg(atan2(boxFromC[0] - boxToC[0], boxToC[1] - boxFromC[1]))
  }
}

return {
  getBox
  incBoxSize
  incBoxSizeUnlimited
  createHighlight
  findGoodPos
  findGoodPosX
  getNotInterractPos
  findGoodArrowPos
  getLinkArrowMiddleCfg
  sizePosToBox
  hasInteractions
  isIntersect
  leftArrowPos
  rightArrowPos
}