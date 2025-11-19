let { Point2, Point3, Point4 } = require("dagor.math")
let DataBlock = require("DataBlock")
let { copyParamsToTable } = require("%sqstd/datablock.nut")

let pointToArrayMap = {
  [Point2] = @(v) [v.x, v.y],
  [Point3] = @(v) [v.x, v.y, v.z],
  [Point4] = @(v) [v.x, v.y, v.z, v.w]
}

let arrayToPointMap = {
  [2] = @(v) Point2(v[0], v[1]),
  [3] = @(v) Point3(v[0], v[1], v[2]),
  [4] = @(v) Point4(v[0], v[1], v[2], v[3])
}

let pointToArray = @(value) type(value) == "instance"
  ? (pointToArrayMap?[value.getclass()](value) ?? value)
  : value

let arrayToPoint = @(value) type(value) == "array"
  ? (arrayToPointMap?[value.len()](value) ?? value)
  : value

function decalTblToBlk(table) {
  let skinDecalsBlk = DataBlock()
  foreach (key, val in table)
    skinDecalsBlk[key] = arrayToPoint(val)
  return skinDecalsBlk
}

let decalBlkToTbl = @(skinDecalsBlk) copyParamsToTable(skinDecalsBlk).map(@(val) pointToArray(val))

return {
  decalBlkToTbl
  decalTblToBlk
}
