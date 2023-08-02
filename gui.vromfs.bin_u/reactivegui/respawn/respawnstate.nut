from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[RESPAWN] ")
let { send, subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { setSelectedUnitInfo, getAvailableRespawnBases, getFullRespawnBasesList,
  getWasReadySlotsMask, getSpareSlotsMask, getDisabledSlotsMask, selectRespawnBase
} = require("guiRespawn")
let { onSpectatorMode } = require("guiSpectator")
let { is_bit_set, ceil } = require("%sqstd/math.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { isInRespawn, respawnUnitInfo, isRespawnStarted, respawnsLeft
} = require("%appGlobals/clientState/respawnStateBase.nut")
let { getUnitTags } = require("%appGlobals/unitTags.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")


let isRespawnAttached = Watched(false)
let readySlotsMask = Watched(0)
let spareSlotsMask = Watched(0)
let disabledSlotsMask = Watched(0)
let playerSelectedSlotIdx = mkWatched(persist, "playerSelectedSlotIdx", -1)
let spawnUnitName = mkWatched(persist, "spawnUnitName", null)
isRespawnStarted.subscribe(@(v) v ? null : spawnUnitName(null))

let getWeapon = @(weapons) weapons.findindex(@(v) v) ?? weapons.findindex(@(_) true)
let mkSlot = @(id, info, readyMask = 0, spareMask = 0)
  { id, name = info?.name ?? {}, weapon = getWeapon(info?.weapons ?? {}),
    canSpawn = is_bit_set(readyMask, id),
    isSpawnBySpare = is_bit_set(spareMask, id)
  }

let respawnSlots = Computed(function() {
  let res = []
  if (respawnUnitInfo.value == null)
    return res
  let rMask = (readySlotsMask.value | spareSlotsMask.value) & ~disabledSlotsMask.value
  let sMask = spareSlotsMask.value
  res.append(mkSlot(0, respawnUnitInfo.value, rMask, sMask))
  foreach (idx, sUnit in respawnUnitInfo.value?.platoonUnits ?? [])
    res.append(mkSlot(idx + 1, sUnit, rMask, sMask))
  foreach (sUnit in respawnUnitInfo.value?.lockedUnits ?? [])
    res.append(mkSlot(res.len(), sUnit).__update({ reqLevel = sUnit.reqLevel }))
  let { level } = respawnUnitInfo.value
  res.each(@(s) s.level <- level)
  return res
})

let hasAvailableSlot = Computed(@() respawnsLeft.value != 0 && respawnSlots.value.findvalue(@(s) s.canSpawn) != null)
let needAutospawn = keepref(Computed(@() isInRespawn.value && isRespawnAttached.value
  && hasAvailableSlot.value && respawnSlots.value.len() == 1))
let needSpectatorMode = keepref(Computed(@() isInRespawn.value && !hasAvailableSlot.value))
needSpectatorMode.subscribe(onSpectatorMode)

let selSlot = Computed(function() {
  let slot = respawnSlots.value?[playerSelectedSlotIdx.value]
  if (slot?.canSpawn ?? false)
    return slot
  return respawnSlots.value.findvalue(@(s) s.canSpawn)
})

let respawnBases = Watched([])

let availRespBases = Computed(function() {
  let { name = null } = selSlot.value
  if (name == null)
    return {}
  setSelectedUnitInfo(name, 0) //need to get respawnBase
  let visible = respawnBases.value
  return getAvailableRespawnBases(getUnitTags(name).keys())
    .reduce(@(res, id) res.__update({ [id] = visible.findvalue(@(b) b.id == id) }), {})
    .filter(@(b) b != null)
})
let playerSelectedRespBase = Watched(-1)
let curRespBase = Computed(@() playerSelectedRespBase.value in availRespBases.value
  ? playerSelectedRespBase.value : -1)

let updateRespawnBases = @() respawnBases(getFullRespawnBasesList())

subscribe("ChangedMissionRespawnBasesStatus", @(_) updateRespawnBases())
isRespawnAttached.subscribe(function(v) {
  if (!v)
    return
  updateRespawnBases()
  selectRespawnBase(curRespBase.value)
})
curRespBase.subscribe(@(v) isRespawnAttached.value ? selectRespawnBase(v) : null)
isInBattle.subscribe(@(v) !v ? playerSelectedRespBase(-1) : null)

let emptyBullets = { bullets0 = "", bulletCount0 = 10000 }
let MAX_SLOTS = 6
let function getDefaultBulletDataToSpawn(unitName, level, weaponName) {
  let choice = loadUnitBulletsChoice(unitName)
  let primary = choice?[weaponName].primary ?? choice?.commonWeapons.primary
  if (primary == null)
    return []
  let { fromUnitTags, bulletsOrder, total, catridge, guns } = primary
  let allowed = []
  foreach (bullet in bulletsOrder)
    if ((fromUnitTags?[bullet].reqLevel ?? 0) <= level)
      allowed.append(bullet)
  if (allowed.len() > MAX_SLOTS)
    allowed.resize(MAX_SLOTS)
  let stepSize = guns
  local leftSteps = ceil(total.tofloat() / stepSize / catridge) //need send catriges count for spawn instead of bullets count
  return allowed.map(function(name, idx) {
    let steps = ceil(leftSteps / (allowed.len() - idx)).tointeger()
    leftSteps -= steps
    return { name, count = steps * stepSize }
  })
}

let function respawn(slot, bullets) {
  if (isRespawnStarted.value)
    return
  let { id, name, weapon } = slot
  spawnUnitName(name)
  local respBaseId = curRespBase.value
  if (respBaseId == -1)
    respBaseId = chooseRandom(availRespBases.value.keys()) ?? -1

  local bulletsData = clone emptyBullets
  foreach (idx, bullet in bullets) {
    bulletsData[$"bullets{idx}"] <- bullet.name
    bulletsData[$"bulletCount{idx}"] <- bullet.count
  }

  send("requestRespawn", {
    name
    weapon
    respBaseId
    idInCountry = id
  }.__update(bulletsData))
}

let cancelRespawn = @() send("cancelRespawn", {})

let function tryAutospawn() {
  let slot = respawnSlots.value?[0]
  if (slot == null) {
    logR("Skip auto spawn because respawnUnitInfo.value is null")
    return
  }

  let { name, weapon } = slot
  let { level = 0 } = respawnUnitInfo.value
  respawn(slot, getDefaultBulletDataToSpawn(name, level, weapon))
}

let function updateAutospawnTimer(v) {
  if (v) {
    tryAutospawn()
    setInterval(5.0, tryAutospawn)
  }
  else
    clearTimer(tryAutospawn)
}
updateAutospawnTimer(needAutospawn.value)
needAutospawn.subscribe(updateAutospawnTimer)

let function updateMasks() {
  readySlotsMask(getWasReadySlotsMask())
  spareSlotsMask(getSpareSlotsMask())
  disabledSlotsMask(getDisabledSlotsMask())
}
let function onEnterRespawn() {
  updateMasks()
  setInterval(1.0, updateMasks)
}
isInRespawn.subscribe(function(v) {
  if (v)
    onEnterRespawn()
  else
    clearTimer(updateMasks)
})
if (isInRespawn.value)
  onEnterRespawn()

isInRespawn.subscribe(function(v) {
  if (v && !hasAvailableSlot.value)
    logR($"On init respawn screen slots not available. respawns_left = {respawnsLeft.value}, hasUnitToSpawn = {respawnUnitInfo.value != null}")
})

return {
  isRespawnAttached
  respawnSlots
  selSlot
  playerSelectedSlotIdx
  spawnUnitName
  respawnBases
  availRespBases
  playerSelectedRespBase
  curRespBase

  respawn
  cancelRespawn
}