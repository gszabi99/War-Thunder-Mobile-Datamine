from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "dagor.workcycle" import setInterval, clearTimer
from "eventbus" import eventbus_send, eventbus_subscribe
from "guiRespawn" import setSelectedUnitInfo, getAvailableRespawnBases, getFullRespawnBasesList, getWasReadySlotsMask,
  getSpareSlotsMask, getDisabledSlotsMask, selectRespawnBase
from "guiSpectator" import onSpectatorMode
from "math" import pow
from "mission" import get_user_custom_state, get_unit_spawn_type
from "vehicleModel" import getUnitFileName
from "%sqstd/datablock.nut" import blkOptFromPath, isDataBlock, eachParam
from "%sqstd/math.nut" import is_bit_set
from "%sqstd/rand.nut" import chooseRandom
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle, isSingleMissionOverrided
from "%appGlobals/clientState/missionState.nut" import hudCustomRules
from "%appGlobals/clientState/respawnStateBase.nut" import isInRespawn, respawnUnitInfo, isRespawnStarted,
  respawnsLeft, respawnUnitItems, curUnitsAvgCostWp, respawnUnitMods
from "%appGlobals/config/skinPresentation.nut" import getSkinPresentation
from "%appGlobals/decalBlkSerializer.nut" import decalBlkToTbl
from "%appGlobals/itemsState.nut" import SPARE
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/unitConst.nut" import AIR, TANK
from "%appGlobals/unitTags.nut" import getUnitTags, getUnitType, getUnitTagsCfg
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/hud/localMPlayer.nut" import mySpawnScore
from "%rGui/missionState.nut" import isGtRace, localTeam
from "%rGui/respawn/playerActivity.nut" import sendPlayerActivityToServer
from "%rGui/unit/unitSettings.nut" import getSkinCustomTags, getDecalsPresets
from "%rGui/unitCustom/unitDecals/unitDecalsState.nut" import decalsPenalty
from "%rGui/unitCustom/unitSkins/levelSkinTags.nut" import curLevelTags
from "%rGui/unitMods/unitModsSlotsState.nut" import getUnitSlotsPresetNonUpdatable, getUnitBeltsNonUpdatable
from "%rGui/unitMods/unseenBullets.nut" import seenShells, SEEN_SHELLS
from "%rGui/weaponry/bulletsCalc.nut" import getDefaultBulletsForSpawn
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice


let logR = log_with_prefix("[RESPAWN] ")

let unitListScrollHandler = ScrollHandler()
let sparesNum = mkWatched(persist, "sparesNum", servProfile.get()?.items[SPARE].count ?? 0)
let isRespawnAttached = Watched(false)
let readySlotsMask = Watched(0)
let spareSlotsMask = Watched(0)
let disabledSlotsMask = Watched(0)
let playerSelectedSlotIdx = mkWatched(persist, "playerSelectedSlotIdx", -1)
let spawnUnitName = mkWatched(persist, "spawnUnitName", null)
let selSlotContentGenId = Watched(0)
let isBailoutDeserter = Watched(false)
let numSpawnByType = Watched({})

isRespawnStarted.subscribe(@(v) v ? null : spawnUnitName.set(null))

let selectedSkins = Watched({})

let unitTypesRequireWeaponryChoice = [AIR, TANK]
  .reduce(@(res, v) res.$rawset(v, true), {})

let getWeapon = @(weapons) weapons.findindex(@(v) v) ?? weapons.findindex(@(_) true)
let mkSlot =  @(id, info, defMods, readyMask = 0, spareMask = 0)
  { id, name = info?.name ?? {}, weapon = getWeapon(info?.weapons ?? {}), skin = info?.skin ?? "",
    canSpawn = is_bit_set(readyMask, id),
    isSpawnBySpare = is_bit_set(spareMask, id),
    bullets = loadUnitBulletsChoice(info?.name)?.commonWeapons.primary.fromUnitTags ?? {}
    mods = info?.modifications ?? defMods
    isCollectible = info?.isCollectible ?? false
    isPremium = info?.isPremium ?? false
    isUpgraded = info?.isUpgraded ?? false
    modPresetCfg = info?.modPresetCfg ?? {}
    costWp = info?.costWp ?? 0
    modCostPart = info?.modCostPart ?? 0.0
    modCostWeights = info?.modCostWeights ?? []
    level = info?.level ?? -1
    rank = info?.rank ?? 0
    mRank = info?.mRank ?? 0
    unitClass = info?.unitClass ?? ""
    country = getUnitTagsCfg(info?.name)?.operatorCountry ?? info?.country ?? respawnUnitInfo.get()?.country ?? ""
    isCurrent = info?.isCurrent ?? false
    skins = info?.skins ?? {}
    isFake = info?.isFake ?? false
    rewardedMasteryTier = info?.rewardedMasteryTier ?? 0
  }

let canUseSpare = Computed(@() (respawnUnitItems.get()?.spare ?? 0) > 0)

let respawnSlots = Computed(function() {
  let res = []
  if (respawnUnitInfo.get() == null)
    return res
  let rMask = (readySlotsMask.get() | spareSlotsMask.get()) & ~disabledSlotsMask.get()
  let sMask = spareSlotsMask.get()
  let defMods = respawnUnitMods.get()
  res.append(mkSlot(0, respawnUnitInfo.get(), defMods, rMask, sMask))
  if (!isSingleMissionOverrided.get()) {
    foreach (idx, sUnit in respawnUnitInfo.get()?.platoonUnits ?? [])
      res.append(mkSlot(idx + 1, sUnit, defMods, rMask, sMask))
    foreach (sUnit in respawnUnitInfo.get()?.lockedUnits ?? [])
      res.append(mkSlot(res.len(), sUnit, defMods).__update({ reqLevel = sUnit?.reqLevel ?? 0, isLocked = true }))
  }
  return res
})

let selSlot = Computed(function() {
  let slot = respawnSlots.get()?[playerSelectedSlotIdx.get()]
  if (slot?.canSpawn ?? false)
    return slot
  return respawnSlots.get().findvalue(@(s) s.isCurrent && s.canSpawn)
    ?? respawnSlots.get().findvalue(@(s) s.canSpawn)
})

let hasUnseenShellsBySlot = Computed(@() respawnSlots.get().map(@(slot) slot?.isLocked ? {}
  : slot.bullets.map(@(v, id) (id != "")
      && ((v?.reqLevel ?? 0) != 0)
      && (slot.level >= (v?.reqLevel ?? 0))
      && !(seenShells.get()?[slot.name][id] ?? false))))

let isUseSpawnScore = Computed(@() !!hudCustomRules.get()?.useSpawnScore)

let spawnScoreCosts = Computed(function() {
  let { useSpawnScore = false, spawnCost = {}, spawnPow = 1.0 } = hudCustomRules.get()
  if (!useSpawnScore)
    return {}
  return spawnCost.map(function(cost, name) {
    let spawns = numSpawnByType.get()?[get_unit_spawn_type(name)] ?? 0
    if (spawns <= 0)
      return cost
    return (cost * pow(1 + spawns, spawnPow)).tointeger()
  })
})

function markShellsSeenInBattle(unitName, idsExt) {
  let unseen = hasUnseenShellsBySlot.get()?[selSlot.get().id]
  let ids = idsExt.filter(@(bName) unseen?[bName])
  if (ids.len() == 0)
    return
  seenShells.mutate(function(v) {
    let unitSeen = getSubTable(v, unitName)
    foreach (id in ids)
      unitSeen[id] <- true
  })
  let blk = get_local_custom_settings_blk()
    .addBlock(SEEN_SHELLS)
    .addBlock(unitName)
  foreach (id in ids)
    blk[id] = true
  eventbus_send("saveProfile", {})
}

let hasAvailableSlot = Computed(function() {
  let { useSpawnScore = false } = hudCustomRules.get()
  if (!useSpawnScore)
    return respawnsLeft.get() != 0 && respawnSlots.get().findvalue(@(s) s.canSpawn) != null
  let costs = spawnScoreCosts.get()
  return null != respawnSlots.get().findvalue(@(s) s.canSpawn && (costs?[s.name] ?? 0) <= mySpawnScore.get())
})

let needRespawnSlotsAndWeaponry = Computed(@() respawnSlots.get().len() > 1
  || (respawnSlots.get().len() == 1 && !isGtRace.get() &&
    (unitTypesRequireWeaponryChoice?[getUnitType(respawnSlots.get()[0].name)] ?? false)))
let needAutospawn = keepref(Computed(@() isInRespawn.get() && isRespawnAttached.get()
  && hasAvailableSlot.get() && !needRespawnSlotsAndWeaponry.get()))
let needSpectatorMode = keepref(Computed(@() isInRespawn.get() && !hasAvailableSlot.get()))
needSpectatorMode.subscribe(onSpectatorMode)

let hasSkins = Computed(@() (selSlot.get()?.skins.len() ?? 0) > 0)

let selSlotUnitType = Computed(@() "name" not in selSlot.get() ? null
  : getUnitType(selSlot.get().name))

let respawnBases = Watched([])

let availRespBases = Computed(function() {
  let { name = null } = selSlot.get()
  if (name == null)
    return {}
  setSelectedUnitInfo(name, 0) 
  let visible = respawnBases.get()
  let ret = getAvailableRespawnBases(getUnitTags(name).keys())
    .reduce(@(res, id) res.__update({ [id] = visible.findvalue(@(b) b.id == id) }), {})
    .filter(@(b) b != null)
  logR($"got {ret.len()} available respawns, filtered out from {visible.len()}")
  return ret;
})
let playerSelectedRespBase = Watched(-1)
let curRespBase = Computed(@() playerSelectedRespBase.get() in availRespBases.get()
  ? playerSelectedRespBase.get() : -1)

let updateRespawnBases = @() respawnBases.set(getFullRespawnBasesList())
updateRespawnBases()

eventbus_subscribe("on_mission_changed", @(...) updateRespawnBases())

function getNumSpawnByType() {
  let numSpawnByTypeBlk = get_user_custom_state(-1, false)?.numSpawnByType
  if (!isDataBlock(numSpawnByTypeBlk))
    return {}
  let res = {}
  eachParam(numSpawnByTypeBlk, @(v, k) res[k] <- v)
  return res
}

function updateNumSpawnByType() {
  let v = getNumSpawnByType()
  if (!isEqual(numSpawnByType.get(), v))
    numSpawnByType.set(v)
}


isRespawnAttached.subscribe(function(v) {
  if (!v)
    return
  updateRespawnBases()
  selectRespawnBase(curRespBase.get())
  updateNumSpawnByType()
})
localTeam.subscribe(function(_) {
  if (!isRespawnAttached.get())
    return
  updateRespawnBases()
  playerSelectedRespBase.set(-1)
  selectRespawnBase(curRespBase.get())
})
curRespBase.subscribe(@(v) isRespawnAttached.get() ? selectRespawnBase(v) : null)
isInBattle.subscribe( function (v) {
  isBailoutDeserter.set(false)
  if (v)
    sparesNum.set(servProfile.get()?.items[SPARE].count ?? 0)
  else {
    playerSelectedRespBase.set(-1)
    selectedSkins.set({})
    playerSelectedSlotIdx.set(-1)
  }
})

let emptyBullets = { bullets0 = "", bulletCount0 = 10000 }

function chooseAutoSkin(unitName, skins, defSkin) {
  if ((skins?.len() ?? 0) == 0)
    return defSkin
  let tags = curLevelTags.get()
  let customTags = getSkinCustomTags(respawnUnitInfo.get()?.name ?? unitName)
  let allowedSkins = skins.__merge({ [""] = true })
    .filter(@(_, s) (customTags?[s] ?? getSkinPresentation(unitName, s).tag) in tags)
  return allowedSkins.len() == 0 ? defSkin : chooseRandom(allowedSkins.keys())
}

function respawn(slot, bullets) {
  if (isRespawnStarted.get() || slot == null)
    return
  let { id, name, weapon, skin, mods } = slot
  spawnUnitName.set(name)
  local respBaseId = curRespBase.get()
  if (respBaseId == -1)
    respBaseId = chooseRandom(availRespBases.get().keys()) ?? -1

  local bulletsData = clone emptyBullets
  if (getUnitType(name) == AIR) {
    local idx = 0
    foreach (weaponId, bName in getUnitBeltsNonUpdatable(name, mods)) {
      bulletsData[$"bulletsWeapon{idx}"] <- weaponId
      bulletsData[$"bullets{idx}"] <- bName
      bulletsData[$"bulletCount{idx}"] <- 10000
      idx++
    }
  } else
    foreach (idx, bullet in bullets) {
      bulletsData[$"bullets{idx}"] <- bullet.name
      bulletsData[$"bulletCount{idx}"] <- bullet.count
      bulletsData[$"bulletTriggerGroup{idx}"] <- bullet?.triggerGroup
    }

  let spawnSkin = selectedSkins.get()?[name] ?? skin

  let weaponPreset = getUnitSlotsPresetNonUpdatable(name, mods)
    .reduce(@(res, v, k) res.$rawset(k.tostring(), v), {})

  local skinDecalsTable = getDecalsPresets(name)?[spawnSkin] ?? {}

  if ((decalsPenalty.get() - serverTime.get()) > 0) {
    let unitBlk = blkOptFromPath(getUnitFileName(name))
    let { defaultDecals = {}, upgradedDecals = {} } = unitBlk

    let res = {}
    foreach(skinName, decalBlk in defaultDecals)
      res[skinName == "default" ? "" : skinName] <- decalBlkToTbl(decalBlk)
    foreach(skinName, decalBlk in upgradedDecals)
      res[skinName == "default" ? "" : skinName] <- decalBlkToTbl(decalBlk)

    skinDecalsTable = res?[spawnSkin] ?? {}
  }

  eventbus_send("requestRespawn", {
    name
    weapon
    respBaseId
    idInCountry = id
    skin = spawnSkin
    weaponPreset
    skinDecalsTable
  }.__update(bulletsData))
}

function cancelRespawn() {
  sendPlayerActivityToServer()
  eventbus_send("cancelRespawn", {})
}

function tryAutospawn() {
  let slot = respawnSlots.get()?[0]
  if (slot == null) {
    logR("Skip auto spawn because respawnUnitInfo.get() is null")
    return
  }

  let { name, mods } = slot
  let { level = 0 } = respawnUnitInfo.get()
  respawn(slot, getDefaultBulletsForSpawn(name, level, mods))
}

function updateAutospawnTimer(v) {
  if (v) {
    tryAutospawn()
    setInterval(5.0, tryAutospawn)
  }
  else
    clearTimer(tryAutospawn)
}
updateAutospawnTimer(needAutospawn.get())
needAutospawn.subscribe(updateAutospawnTimer)

function updateMasks() {
  readySlotsMask.set(getWasReadySlotsMask())
  spareSlotsMask.set(getSpareSlotsMask())
  disabledSlotsMask.set(getDisabledSlotsMask())
}
function onEnterRespawn() {
  updateMasks()
  setInterval(1.0, updateMasks)
}
isInRespawn.subscribe(function(v) {
  clearTimer(updateMasks)
  if (v)
    onEnterRespawn()
})
if (isInRespawn.get())
  onEnterRespawn()

isInRespawn.subscribe(function(v) {
  if (v && !hasAvailableSlot.get())
    logR($"On init respawn screen slots not available. respawns_left = {respawnsLeft.get()}, hasUnitToSpawn = {respawnUnitInfo.get() != null}")
})


return {
  canUseSpare
  isRespawnAttached
  respawnSlots
  selSlot
  selSlotUnitType
  playerSelectedSlotIdx
  spawnUnitName
  respawnBases
  availRespBases
  playerSelectedRespBase
  curRespBase
  sparesNum
  markShellsSeenInBattle
  hasUnseenShellsBySlot
  selSlotContentGenId
  isBailoutDeserter
  hasSkins
  needRespawnSlotsAndWeaponry

  isUseSpawnScore
  spawnScoreCosts

  respawn
  cancelRespawn

  chooseAutoSkin
  selectedSkins

  unitListScrollHandler
  curUnitsAvgCostWp
}