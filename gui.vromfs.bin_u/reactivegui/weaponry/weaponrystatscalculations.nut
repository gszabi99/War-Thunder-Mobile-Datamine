from "%globalsDarg/darg_library.nut" import *
let DataBlock = require("DataBlock")

local explosiveBlk = null
function getExplosiveBlk() {
  if (explosiveBlk == null) {
    explosiveBlk = DataBlock()
    explosiveBlk.load("gameData/damage_model/explosive.blk")
  }
  return explosiveBlk
}

function getTntEquivalentMass(explosiveType, explosiveMass) {
  if (explosiveType == "tnt" || explosiveMass <= 0)
    return 0
  return explosiveMass.tofloat() * (getExplosiveBlk()?.explosiveTypes[explosiveType].strengthEquivalent ?? 0)
}

return {
  getTntEquivalentMass
}