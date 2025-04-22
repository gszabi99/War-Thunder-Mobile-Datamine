from "%globalsDarg/darg_library.nut" import *

let DataBlock = require("DataBlock")
let { eachBlock } = require("%sqstd/datablock.nut")
let { Point2 } = require("dagor.math")
let { lerp } = require("%sqstd/math.nut")
let { calculate_tank_bullet_parameters } = require("unitCalculcation")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let RICOCHET_PROBABILITIES = [1.0]

local ricochetDataByPreset = null

let resetData = @() ricochetDataByPreset = null

let isPoint2 = @(p) type(p) == "instance" && p instanceof Point2

function getDmgModelBlk() {
  let blk = DataBlock()
  blk.load("config/damageModel.blk")
  return blk
}

function getExplosiveBlk() {
  let blk = DataBlock()
  blk.load("gameData/damage_model/explosive.blk")
  return blk
}


function getAngleByProbabilityFromP2blk(blk, x) {
  for (local i = 0; i < blk.paramCount() - 1; ++i) {
    let p1 = blk.getParamValue(i)
    let p2 = blk.getParamValue(i + 1)
    if (!isPoint2(p1) || !isPoint2(p2))
      continue
    let angle1 = p1.x
    let probability1 = p1.y
    let angle2 = p2.x
    let probability2 = p2.y
    if ((probability1 <= x && x <= probability2) || (probability2 <= x && x <= probability1)) {
      if (probability1 == probability2) {
        
        
        if (x == 1)
          return max(angle1, angle2)
        else
          return min(angle1, angle2)
      }
      return lerp(probability1, probability2, angle1, angle2, x)
    }
  }
  return -1
}


function getMaxProbabilityFromP2blk(blk) {
  local result = -1
  for (local i = 0; i < blk.paramCount(); ++i) {
    let p = blk.getParamValue(i)
    if (isPoint2(p))
      result = max(result, p.y)
  }
  return result
}

function getRichochetPresetBlk(presetData) {
  if (presetData == null)
    return null
  
  
  for (local i = 0; i < presetData.blockCount(); ++i) {
    let presetBlock = presetData.getBlock(i)
    if (presetBlock?.caliberToArmor == 1)
      return presetBlock
  }
  
  
  for (local i = 0; i < presetData.blockCount(); ++i) {
    let presetBlock = presetData.getBlock(i)
    if (!("caliberToArmor" in presetBlock))
      return presetBlock
  }
  
  
  return presetData
}

function getRicochetDataByPreset(presetDataBlk) {
  let res = {
    angleProbabilityMap = []
  }
  let ricochetPresetBlk = getRichochetPresetBlk(presetDataBlk)
  if (ricochetPresetBlk != null) {
    local addMaxProbability = false
    for (local i = 0; i < RICOCHET_PROBABILITIES.len(); ++i) {
      let probability = RICOCHET_PROBABILITIES[i]
      let angle = getAngleByProbabilityFromP2blk(ricochetPresetBlk, probability)
      if (angle != -1) {
        res.angleProbabilityMap.append({
          probability = probability
          angle = 90.0 - angle
        })
      }
      else
        addMaxProbability = true
    }

    
    
    if (addMaxProbability) {
      let maxProbability = getMaxProbabilityFromP2blk(ricochetPresetBlk)
      let angleAtMaxProbability = getAngleByProbabilityFromP2blk(ricochetPresetBlk, maxProbability)
      if (maxProbability != -1 && angleAtMaxProbability != -1) {
        res.angleProbabilityMap.append({
          probability = maxProbability
          angle = 90.0 - angleAtMaxProbability
        })
      }
    }
  }
  return res
}

function initRicochetDataOnce() {
  if (ricochetDataByPreset)
    return

  ricochetDataByPreset = {}
  let blk = getDmgModelBlk()
  if (!blk)
    return

  let ricBlk = blk?.ricochetPresets
  if (!ricBlk) {
    assert(false, "ERROR: Can't load ricochetPresets from damageModel.blk")
    return
  }

  for (local i = 0; i < ricBlk.blockCount(); i++) {
    let presetDataBlk = ricBlk.getBlock(i)
    let presetName = presetDataBlk.getBlockName()
    ricochetDataByPreset[presetName] <- getRicochetDataByPreset(presetDataBlk)
  }
}

function getRicochetData(presetName) {
  initRicochetDataOnce()
  return ricochetDataByPreset?[presetName]
}

let getRicochetGuaranteedAngle = @(presetName) getRicochetData(presetName)?.angleProbabilityMap
  .findvalue(@(v) v.probability == 1.0).angle ?? -1

let calcArmorPiercingData = memoize(function getAnglePenetrationData(unitName, weaponBlkName, modName) {
  let isDefault = modName == ""
  let blkPathOrModName = isDefault
    ? weaponBlkName
    : modName
  let { armorPiercing = [], armorPiercingDist = []
  } = calculate_tank_bullet_parameters(unitName, blkPathOrModName, isDefault, false)?[0]
  return { armorPiercing, armorPiercingDist }
})

function getArmorPiercingByDistance(unitName, weaponBlkName, modName, distance) {
  let { armorPiercing, armorPiercingDist } = calcArmorPiercingData(unitName, weaponBlkName, modName)
  let idx = armorPiercingDist.findindex(@(d) d == distance)
  local res = armorPiercing?[idx][0]
  if (res != null)
    return res

  local pMin
  local pMax
  for (local i = 0; i < armorPiercing.len(); i++) {
    let v = {
      armor = armorPiercing[i]?[0] ?? 0,
      dist  = armorPiercingDist[i],
    }
    if (v.dist <= distance)
      pMin = v
    else if (pMin == null)
      pMin = v.__merge({ dist = 0 })
    pMax = v
    if (v.dist >= distance)
      break
  }
  if (pMin == null || pMax == null)
    return null
  pMax.dist = max(pMax.dist, distance)
  return lerp(pMin.dist, pMax.dist, pMin.armor, pMax.armor, distance)
}

local tntStrengthEquivalent = null
function getTntStrengthEquivalent(explosiveType) {
  if (tntStrengthEquivalent == null) {
    tntStrengthEquivalent = {}
    let blk = getExplosiveBlk()
    if (blk?.explosiveTypes instanceof DataBlock)
      eachBlock(blk.explosiveTypes, function(b) {
        tntStrengthEquivalent[b.getBlockName()] <- b?.strengthEquivalent ?? 0
      })
    else
      logerr("Can't load explosiveTypes from explosive.blk")
  }
  return tntStrengthEquivalent?[explosiveType] ?? 0
}

isLoggedIn.subscribe(@(v) v ? null : resetData())

return {
  getArmorPiercingByDistance
  getRicochetGuaranteedAngle
  getTntStrengthEquivalent
}
