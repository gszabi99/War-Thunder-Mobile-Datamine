from "%globalsDarg/darg_library.nut" import *
let { fabs } = require("%sqstd/math.nut")
let { loadUnitSlotsParams } = require("%rGui/weaponry/loadUnitBullets.nut")


function getEquippedWeapon(wPreset, slotIdx, weaponsList, unitMods = null) {
  let id = wPreset?[slotIdx]
  local res = weaponsList?[id]
  let { reqModification = "" } = res
  if (reqModification != "" && reqModification not in unitMods)
    res = null
  return res ?? ((id == null || slotIdx == 0)  ? weaponsList.findvalue(@(w) w.isDefault) : null)
}

function removeFromSide(res, isLeft, notUseForDisbalance) {
  let start = isLeft ? 1 : res.len() / 2 + 1
  let end = isLeft ? res.len() / 2 : res.len() - 1
  for (local i = start; i <= end; i++)
    if (!notUseForDisbalance?[i] && (res[i]?.mass ?? 0) > 0) {
      let { mass } = res[i]
      res[i] = null
      return mass
    }
  return 0
}

function removeNotDisbalance(res, notUseForDisbalance) {
  for (local i = 1; i < res.len(); i++)
    if (notUseForDisbalance?[i] && (res[i]?.mass ?? 0) > 0) {
      let { mass } = res[i]
      res[i] = null
      return mass
    }
  return 0
}

let hasConflictWeapons = @(equipped, banPresets) banPresets.len() != 0
  && null != equipped.findvalue(@(name, idx) banPresets?[idx][name] ?? false)

function getEqippedWithoutOverload(unitName, eqWeaponsBySlots) {
  let { maxDisbalance = 0, maxloadMass = 0, maxloadMassLeftConsoles = 0, maxloadMassRightConsoles = 0,
    notUseForDisbalance = {}
  } = loadUnitSlotsParams(unitName)

  let res = []
  let equipped = {}
  foreach(index, w in eqWeaponsBySlots) {
    let { name = "", banPresets = {} } = w
    if (hasConflictWeapons(equipped, banPresets)) {
      res.append(null)
      continue
    }
    res.append(w)
    if (name != "")
      equipped[index] <- name
  }

  if (maxDisbalance <= 0 && maxloadMass <= 0 && maxloadMassLeftConsoles <= 0 && maxloadMassRightConsoles <= 0)
    return res

  local massTotal = 0.0
  local massLeft = 0.0
  local massRight = 0.0
  let centerIdx = eqWeaponsBySlots.len() / 2
  foreach(index, preset in res) {
    let { mass = 0 } = preset
    if (mass <= 0)
      continue
    massTotal += mass
    if (notUseForDisbalance?[index] ?? (index == 0))
      continue
    if (index <= centerIdx)
      massLeft += mass
    else
      massRight += mass
  }

  local total = res.len()
  while(total--) {
    if (massLeft > maxloadMassLeftConsoles) {
      let mass = removeFromSide(res, true, notUseForDisbalance)
      massTotal -= mass
      massLeft -= mass
      continue
    }

    if (massRight > maxloadMassRightConsoles) {
      let mass = removeFromSide(res, false, notUseForDisbalance)
      massTotal -= mass
      massRight -= mass
      continue
    }

    let disbalance = fabs(massLeft - massRight)
    if (disbalance > maxDisbalance) {
      let mass = removeFromSide(res, massLeft > massRight, notUseForDisbalance)
      massTotal -= mass
      if (massLeft > massRight)
        massLeft -= mass
      else
        massRight -= mass
      continue
    }

    if (massTotal > maxloadMass) {
      local mass = removeNotDisbalance(res, notUseForDisbalance)
      if (mass != 0) {
        massTotal -= mass
        continue
      }
      mass = removeFromSide(res, massLeft > massRight, notUseForDisbalance)
      massTotal -= mass
      if (massLeft > massRight)
        massLeft -= mass
      else
        massRight -= mass
      continue
    }

    break
  }

  return res
}

return {
  getEqippedWithoutOverload
  getEquippedWeapon
  hasConflictWeapons
}