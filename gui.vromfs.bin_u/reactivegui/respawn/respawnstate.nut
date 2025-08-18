from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[RESPAWN] ")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { setSelectedUnitInfo, getAvailableRespawnBases, getFullRespawnBasesList,
  getWasReadySlotsMask, getSpareSlotsMask, getDisabledSlotsMask, selectRespawnBase
} = require("guiRespawn")
let { onSpectatorMode } = require("guiSpectator")
let { is_bit_set } = require("%sqstd/math.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { isInRespawn, respawnUnitInfo, isRespawnStarted, respawnsLeft, respawnUnitItems,
  hasRespawnSeparateSlots, curUnitsAvgCostWp, respawnUnitSkins
} = require("%appGlobals/clientState/respawnStateBase.nut")
let { getUnitTags, getUnitType, getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { AIR, TANK } = require("%appGlobals/unitConst.nut")
let { isInBattle, isSingleMissionOverrided } = require("%appGlobals/clientState/clientState.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getDefaultBulletsForSpawn } = require("%rGui/weaponry/bulletsCalc.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { SPARE } = require("%appGlobals/itemsState.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam, eachBlock } = require("%sqstd/datablock.nut")
let { register_command } = require("console")
let { isEqual } = require("%sqstd/underscore.nut")
let { curLevelTags } = require("%rGui/unitCustom/unitSkins/levelSkinTags.nut")
let { getSkinCustomTags } = require("%rGui/unit/unitSettings.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { sendPlayerActivityToServer } = require("%rGui/respawn/playerActivity.nut")
let { getUnitSlotsPresetNonUpdatable, getUnitBeltsNonUpdatable } = require("%rGui/unitMods/unitModsSlotsState.nut")

let unitListScrollHandler = ScrollHandler()
let sparesNum = mkWatched(persist, "sparesNum", servProfile.value?.items[SPARE].count ?? 0)
let isRespawnAttached = Watched(false)
let readySlotsMask = Watched(0)
let spareSlotsMask = Watched(0)
let disabledSlotsMask = Watched(0)
let playerSelectedSlotIdx = mkWatched(persist, "playerSelectedSlotIdx", -1)
let spawnUnitName = mkWatched(persist, "spawnUnitName", null)
let selSlotContentGenId = Watched(0)
let isBailoutDeserter = Watched(false)
isRespawnStarted.subscribe(@(v) v ? null : spawnUnitName.set(null))

const SEEN_SHELLS = "SeenShells"

let seenShells = mkWatched(persist, SEEN_SHELLS, {})

let selectedSkins = Watched({})

let unitTypesRequireWeaponryChoice = [AIR, TANK]
  .reduce(@(res, v) res.$rawset(v, true), {})

let getWeapon = @(weapons) weapons.findindex(@(v) v) ?? weapons.findindex(@(_) true)
let mkSlot =  @(id, info, defMods, readyMask = 0, spareMask = 0)
  { id, name = info?.name ?? {}, weapon = getWeapon(info?.weapons ?? {}), skin = info?.skin ?? "",
    canSpawn = is_bit_set(readyMask, id),
    isSpawnBySpare = is_bit_set(spareMask, id),
    bullets = loadUnitBulletsChoice(info?.name)?.commonWeapons.primary.fromUnitTags ?? {}
    mods = info?.items ?? defMods
    isCollectible = info?.isCollectible ?? false
    isPremium = info?.isPremium ?? false
    isUpgraded = info?.isUpgraded ?? false
    modPresetCfg = info?.modPresetCfg ?? {}
    costWp = info?.costWp ?? 0
    modCostPart = info?.modCostPart ?? 0.0
    level = info?.level ?? -1
    rank = info?.rank ?? 0
    mRank = info?.mRank ?? 0
    unitClass = info?.unitClass ?? ""
    country = getUnitTagsCfg(info?.name)?.operatorCountry ?? info?.country ?? respawnUnitInfo.get()?.country ?? ""
    isCurrent = info?.isCurrent ?? false
    skins = info?.skins ?? {}
    hasDailyBonus = info?.hasDailyBonus ?? false
  }

let canUseSpare = Computed(@() (respawnUnitItems.get()?.spare ?? 0) > 0)

let respawnSlots = Computed(function() {
  let res = []
  if (respawnUnitInfo.get() == null)
    return res
  let rMask = (readySlotsMask.get() | spareSlotsMask.get()) & ~disabledSlotsMask.get()
  let sMask = spareSlotsMask.get()
  let defMods = respawnUnitItems.get()
  res.append(mkSlot(0, respawnUnitInfo.get(), defMods, rMask, sMask))
  if (!isSingleMissionOverrided.get()) {
    foreach (idx, sUnit in respawnUnitInfo.get()?.platoonUnits ?? [])
      res.append(mkSlot(idx + 1, sUnit, defMods, rMask, sMask))
    foreach (sUnit in respawnUnitInfo.get()?.lockedUnits ?? [])
      res.append(mkSlot(res.len(), sUnit, defMods).__update({ reqLevel = sUnit?.reqLevel ?? 0, isLocked = true }))
  }
  if (!hasRespawnSeparateSlots.get()) {
    let { level = -1, isCollectible = false, isPremium = false, isUpgraded = false } = respawnUnitInfo.get()
    let skins = respawnUnitSkins.get() ?? {}
    res.each(function(s) {
      s.level = level
      s.isCollectible = isCollectible
      s.isPremium = isPremium
      s.isUpgraded = isUpgraded
      s.skins = skins
    })
  }
  return res
})

let hasUnseenShellsBySlot = Computed(@() respawnSlots.get().map(function (slot) {
  if (!slot?.isLocked) {
    return slot.bullets.map(@(v, id) (id != "")
      && ((v?.reqLevel ?? 0) != 0)
      && (slot.level >= (v?.reqLevel ?? 0))
      && !(seenShells.get()?[slot.name][id] ?? false))
  }
  return {}
}))

function saveSeenShells(unitName, ids) {
  let filtered = ids.filter(@(id) hasUnseenShellsBySlot.get().findvalue(@(item) (item?[id] ?? false)))
  let unitSeen = clone seenShells.get()?[unitName] ?? {}
  foreach (id in filtered)
    unitSeen[id] <- true
  if (isEqual(unitSeen, seenShells.get()?[unitName]))
    return
  seenShells.mutate(@(v) v[unitName] <- unitSeen)

  let globalBlk = get_local_custom_settings_blk()
  let shellsBlk = globalBlk.addBlock(SEEN_SHELLS)

  let unitBlk = shellsBlk.addBlock(unitName)
  foreach (id, val in unitSeen)
    unitBlk[id] = val
  eventbus_send("saveProfile", {})
}

function loadSeenShells() {
  if (!isSettingsAvailable.get())
    return seenShells.set({})
  let blk = get_local_custom_settings_blk()
  let shellsBlk = blk?[SEEN_SHELLS]
  if (!isDataBlock(shellsBlk)) {
    seenShells.set({})
    return
  }
  let res = {}
  eachBlock(shellsBlk, function(unitBlk, name) {
    let items = {}
    eachParam(unitBlk, @(value, item) items[item] <- value)
    res[name] <- items
  })
  seenShells.set(res)
}

if (seenShells.get().len() == 0)
  loadSeenShells()

isSettingsAvailable.subscribe(@(_) loadSeenShells())

let hasAvailableSlot = Computed(@() respawnsLeft.get() != 0 && respawnSlots.get().findvalue(@(s) s.canSpawn) != null)
let needRespawnSlotsAndWeaponry = Computed(@() respawnSlots.get().len() > 1
  || (respawnSlots.get().len() == 1 && (unitTypesRequireWeaponryChoice?[getUnitType(respawnSlots.get()[0].name)] ?? false)))
let needAutospawn = keepref(Computed(@() isInRespawn.get() && isRespawnAttached.get()
  && hasAvailableSlot.get() && !needRespawnSlotsAndWeaponry.get()))
let needSpectatorMode = keepref(Computed(@() isInRespawn.get() && !hasAvailableSlot.get()))
needSpectatorMode.subscribe(onSpectatorMode)

let selSlot = Computed(function() {
  let slot = respawnSlots.get()?[playerSelectedSlotIdx.get()]
  if (slot?.canSpawn ?? false)
    return slot
  return respawnSlots.get().findvalue(@(s) s.isCurrent && s.canSpawn)
    ?? respawnSlots.get().findvalue(@(s) s.canSpawn)
})

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

eventbus_subscribe("on_mission_changed", @(...) updateRespawnBases())
isRespawnAttached.subscribe(function(v) {
  if (!v)
    return
  updateRespawnBases()
  selectRespawnBase(curRespBase.get())
})
curRespBase.subscribe(@(v) isRespawnAttached.get() ? selectRespawnBase(v) : null)
isInBattle.subscribe( function (v) {
  isBailoutDeserter.set(false)
  if (v)
    sparesNum.set(servProfile.value?.items[SPARE].count ?? 0)
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
    }

  let spawnSkin = selectedSkins.get()?[name] ?? skin

  let weaponPreset = getUnitSlotsPresetNonUpdatable(name, mods)
    .reduce(@(res, v, k) res.$rawset(k.tostring(), v), {})

  eventbus_send("requestRespawn", {
    name
    weapon
    respBaseId
    idInCountry = id
    skin = spawnSkin
    weaponPreset
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
updateAutospawnTimer(needAutospawn.value)
needAutospawn.subscribe(updateAutospawnTimer)

function updateMasks() {
  readySlotsMask(getWasReadySlotsMask())
  spareSlotsMask.set(getSpareSlotsMask())
  disabledSlotsMask.set(getDisabledSlotsMask())
}
function onEnterRespawn() {
  updateMasks()
  setInterval(1.0, updateMasks)
}
isInRespawn.subscribe(function(v) {
  if (v)
    onEnterRespawn()
  else
    clearTimer(updateMasks)
})
if (isInRespawn.get())
  onEnterRespawn()

isInRespawn.subscribe(function(v) {
  if (v && !hasAvailableSlot.get())
    logR($"On init respawn screen slots not available. respawns_left = {respawnsLeft.get()}, hasUnitToSpawn = {respawnUnitInfo.get() != null}")
})

register_command(function() {
  seenShells.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_SHELLS)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_shells")

register_command(function() {
  loadSeenShells()
}, "debug.load_seen_shells")


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
  saveSeenShells
  hasUnseenShellsBySlot
  selSlotContentGenId
  isBailoutDeserter
  hasSkins
  needRespawnSlotsAndWeaponry

  respawn
  cancelRespawn

  chooseAutoSkin
  selectedSkins

  unitListScrollHandler
  hasRespawnSeparateSlots
  curUnitsAvgCostWp
}