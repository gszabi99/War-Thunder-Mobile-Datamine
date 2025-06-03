from "%globalsDarg/darg_library.nut" import *
let { getUnitFileName } = require("vehicleModel")
let { blkOptFromPath } = require("%sqstd/datablock.nut")
let { S_UNDEFINED, S_AIRCRAFT, S_HELICOPTER, S_TANK, S_SHIP, S_BOAT, S_SUBMARINE,
  mkTankCrewMemberDesc, mkGunnerDesc, mkPilotDesc, mkEngineDesc, mkTransmissionDesc, mkDriveTurretDesc,
  mkAircraftFuelTankDesc, mkWeaponDesc, mkAmmoDesc, mkTankArmorPartDesc, mkCoalBunkerDesc, mkSensorDesc,
  mkCountermeasureDesc, mkApsSensorDesc, mkApsLauncherDesc, mkAvionicsDesc, mkCommanderPanoramicSightDesc,
  mkFireDirecirOrRangefinderDesc, mkFireControlRoomOrBridgeDesc, mkPowerSystemDesc, mkFireControlSystemDesc,
  mkHydraulicsSystemDesc, mkElectronicEquipmentDesc, mkSimpleDescByPartType
} = require("%globalScripts/modeXrayLib.nut")
let { AIR, HELICOPTER, TANK, SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")
let sharedWatches = require("sharedWatches.nut")
let { getUnitStats } = require("%rGui/dmViewer/modeXrayAttr.nut")
let { getCommonWeapons, getUnitWeaponsList, getWeaponNameByBlkPath, getWeaponDescTextByWeaponInfoBlk,
  isCaliberCannon, toStr_speed, toStr_horsePowers, toStr_thrustKgf, toStr_distance
} = require("%rGui/dmViewer/modeXrayWeaponry.nut")


let unitTypeToSimpleUnitTypeMap = {
  [AIR] = S_AIRCRAFT,
  [HELICOPTER] = S_HELICOPTER,
  [TANK] = S_TANK,
  [SHIP] = S_SHIP,
  [BOAT] = S_BOAT,
  [SUBMARINE] = S_SUBMARINE,
}

let getSimpleUnitType = @(unit) unitTypeToSimpleUnitTypeMap?[unit?.unitType] ?? S_UNDEFINED

let xrayDescCtorsMap = {
  
  commander = mkTankCrewMemberDesc
  driver = mkTankCrewMemberDesc
  loader = mkTankCrewMemberDesc
  machine_gunner = mkTankCrewMemberDesc
  gunner = mkGunnerDesc
  pilot = mkPilotDesc
  
  engine = mkEngineDesc
  transmission = mkTransmissionDesc
  drive_turret_h = mkDriveTurretDesc
  drive_turret_v = mkDriveTurretDesc
  tank = mkAircraftFuelTankDesc
  
  main_caliber_turret = mkWeaponDesc
  auxiliary_caliber_turret = mkWeaponDesc
  aa_turret = mkWeaponDesc
  mg = mkWeaponDesc
  gun = mkWeaponDesc
  mgun = mkWeaponDesc
  cannon = mkWeaponDesc
  mask = mkWeaponDesc
  gun_mask = mkWeaponDesc
  gun_barrel = mkWeaponDesc
  cannon_breech = mkWeaponDesc
  tt = mkWeaponDesc
  torpedo = mkWeaponDesc
  main_caliber_gun = mkWeaponDesc
  auxiliary_caliber_gun = mkWeaponDesc
  depth_charge = mkWeaponDesc
  mine = mkWeaponDesc
  aa_gun = mkWeaponDesc
  
  elevator = mkAmmoDesc
  ammo_turret = mkAmmoDesc
  ammo_body = mkAmmoDesc
  ammunition_storage = mkAmmoDesc
  ammunition_storage_shells = mkAmmoDesc
  ammunition_storage_charges = mkAmmoDesc
  ammunition_storage_aux = mkAmmoDesc
  
  firewall_armor = mkTankArmorPartDesc
  composite_armor_hull = mkTankArmorPartDesc
  composite_armor_turret = mkTankArmorPartDesc
  ex_era_hull = mkTankArmorPartDesc
  ex_era_turret = mkTankArmorPartDesc
  coal_bunker = mkCoalBunkerDesc
  
  radar = mkSensorDesc
  antenna_target_location = mkSensorDesc
  antenna_target_tagging = mkSensorDesc
  antenna_target_tagging_mount = mkSensorDesc
  optic_gun = mkSensorDesc
  countermeasure = mkCountermeasureDesc
  aps_sensor = mkApsSensorDesc
  aps_launcher = mkApsLauncherDesc
  ex_aps_launcher = mkApsLauncherDesc
  
  electronic_block = mkAvionicsDesc
  optic_block = mkAvionicsDesc
  cockpit_countrol = mkAvionicsDesc
  ircm = mkAvionicsDesc
  
  commander_panoramic_sight = mkCommanderPanoramicSightDesc
  fire_director = mkFireDirecirOrRangefinderDesc
  rangefinder = mkFireDirecirOrRangefinderDesc
  fire_control_room = mkFireControlRoomOrBridgeDesc
  bridge = mkFireControlRoomOrBridgeDesc
  power_system = mkPowerSystemDesc
  fire_control_system = mkFireControlSystemDesc
  turret_hydraulics = mkHydraulicsSystemDesc
  electronic_equipment = mkElectronicEquipmentDesc
  
  autoloader = mkSimpleDescByPartType
  driver_controls = mkSimpleDescByPartType
  gun_trunnion = mkSimpleDescByPartType
}

let showStellEquivForArmorClassesList = [ "ships_coal_bunker" ]
function collectArmorClassToSteelMuls() {
  let res = {}
  let armorClassesBlk = blkOptFromPath("gameData/damage_model/armor_classes.blk")
  let steelArmorQuality = armorClassesBlk?.ship_structural_steel.armorQuality ?? 0
  if (steelArmorQuality == 0)
    return res
  foreach (armorClass in showStellEquivForArmorClassesList)
    res[armorClass] <- (armorClassesBlk?[armorClass].armorQuality ?? 0) / steelArmorQuality
  return res
}

function getUnitFmBlk(commonData) {
  let { unitDataCache, unitName, unitBlk } = commonData
  if ("fmBlk" not in unitDataCache) {
    let unitPath = getUnitFileName(unitName)
    let nodes = unitPath.split("/")
    if (nodes.len())
      nodes.pop()
    nodes.append(unitBlk?.fmFile ?? $"fm/{unitName}")
    let fmPath = "/".join(nodes, true)
    unitDataCache.fmBlk <- blkOptFromPath(fmPath)
  }
  return unitDataCache.fmBlk
}

function getTankMainWeaponStats(commonData) {
  let { weapons = {}, mainWeaponCaliber = 0 } = getUnitStats(commonData)
  let name = weapons.findindex(@(v) v?.caliber == mainWeaponCaliber)
  return weapons?[name].__merge({ name })
}

function getTankMainTurretSpeed(commonData, needYaw) {
  let mainWeaponStats = getTankMainWeaponStats(commonData)
  let speedYawFinal = mainWeaponStats?.gunnerTurretRotationSpeed ?? 0.0
  if (needYaw)
    return speedYawFinal
  let weapBlkNameEnding = $"/{mainWeaponStats?.name}.blk"
  let weaponBlk = commonData.getUnitWeaponsList(commonData)
    .findvalue(@(b) (b?.blk ?? "").endswith(weapBlkNameEnding))
  let { speedYaw = 0.0, speedPitch = 0.0 } = weaponBlk
  return speedYaw != 0 ? (speedPitch * speedYawFinal / speedYaw) : 0.0
}
let getTankMainTurretSpeedYaw = @(commonData) getTankMainTurretSpeed(commonData, true)
let getTankMainTurretSpeedPitch = @(commonData) getTankMainTurretSpeed(commonData, false)

let getTankMainWeaponReloadTime = @(commonData) getTankMainWeaponStats(commonData)?.reloadTime ?? 0.0

function getShipWeaponReloadTime(commonData, weaponName) {
  let { shotFreq = 0 } = getUnitStats(commonData)?.weapons[weaponName]
  return shotFreq != 0 ? (1.0 / shotFreq) : 0.0
}

let notImplementedMul = @(_commonData) 1.0

let xrayCommonGetters = {
  isCaliberCannon
  getCommonWeapons
  getWeaponNameByBlkPath
  getWeaponDescTextByWeaponInfoBlk
  findAnyModEffectValueBlk = @(...) null
  isModAvailableOrFree = @(...) true

  getUnitFmBlk
  getUnitWeaponsList
  getAircraftFuelTankPartInfo = @(_commonData, _partName) null

  sharedWatches

  
  getProp_maxSpeed = @(commonData) getUnitStats(commonData)?.maxSpeedForward ?? 0.0
  getProp_horsePowers = @(commonData) (getUnitStats(commonData)?.powerToWeightRatio ?? 0.0)
    * (getUnitStats(commonData)?.mass ?? 0) / 1000.0
  getProp_maxHorsePowersRPM = @(commonData) commonData?.unitBlk.VehiclePhys.engine.maxRPM ?? 0.0
  getProp_thrust = @(_commonData) 0.0
  getProp_tankMainTurretSpeedYaw = getTankMainTurretSpeedYaw
  getProp_tankMainTurretSpeedYawTop = getTankMainTurretSpeedYaw
  getProp_tankMainTurretSpeedPitch = getTankMainTurretSpeedPitch
  getProp_tankMainTurretSpeedPitchTop = getTankMainTurretSpeedPitch
  getProp_tankReloadTime = getTankMainWeaponReloadTime
  getProp_tankReloadTimeTop = getTankMainWeaponReloadTime
  getProp_shipReloadTimeMainDef = getShipWeaponReloadTime
  getProp_shipReloadTimeMainCur = getShipWeaponReloadTime
  getProp_shipReloadTimeMainTop = getShipWeaponReloadTime
  getProp_shipReloadTimeMainBase = getShipWeaponReloadTime
  getProp_shipReloadTimeAuxDef = getShipWeaponReloadTime
  getProp_shipReloadTimeAuxCur = getShipWeaponReloadTime
  getProp_shipReloadTimeAuxTop = getShipWeaponReloadTime
  getProp_shipReloadTimeAuxBase = getShipWeaponReloadTime
  getProp_shipReloadTimeAaDef = getShipWeaponReloadTime
  getProp_shipReloadTimeAaCur = getShipWeaponReloadTime
  getProp_shipReloadTimeAaTop = getShipWeaponReloadTime
  getProp_shipReloadTimeAaBase = getShipWeaponReloadTime

  
  getMul_shipDistancePrecisionError = notImplementedMul
  getMul_shipTurretMainSpeedYaw = notImplementedMul
  getMul_shipTurretAuxSpeedYaw = notImplementedMul
  getMul_shipTurretAaSpeedYaw = notImplementedMul
  getMul_shipTurretMainSpeedPitch = notImplementedMul
  getMul_shipTurretAuxSpeedPitch = notImplementedMul
  getMul_shipTurretAaSpeedPitch = notImplementedMul

  
  toStr_speed
  toStr_horsePowers
  toStr_thrustKgf
  toStr_distance
}

function getDescriptionInXrayMode(partType, params, commonData) {
  let res = {
    partLocId = partType
    desc = []
  }
  return (commonData.unit == null || commonData.unitBlk == null || params?.name == null) ? res
    : res.__update(xrayDescCtorsMap?[partType](partType, params, commonData) ?? {})
}

return {
  getSimpleUnitType
  xrayCommonGetters
  getDescriptionInXrayMode
  collectArmorClassToSteelMuls
}
