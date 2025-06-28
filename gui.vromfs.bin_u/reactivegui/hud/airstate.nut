from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { AirThrottleMode, AirParamsMain } = require("%globalScripts/sharedEnums.nut")
let interopGen = require("%rGui/interopGen.nut")
let { registerInteropFunc } = require("%globalsDarg/interop.nut")
let { CANNON_1, MACHINE_GUNS_1, ROCKET, BOMBS, TORPEDO, CANNON_ADDITIONAL } = AirParamsMain
let { use_mgun_as_cannon_by_trigger } = require("hudAircraftStates")
let { isUnitAlive, isUnitDelayed, playerUnitName } = require("%rGui/hudState.nut")
let { FlightCameraType, getCameraViewType } = require("camera_control")
let debugDebuff = mkWatched(persist, "debugDebuff", 0)
let { rnd_int } = require("dagor.random")
let { TURRET } = FlightCameraType

use_mgun_as_cannon_by_trigger(true)
const NUM_TURRETS_MAX = 10

let MainMask         = Watched(0)
let Trt0             = Watched(0)
let TrtMode0         = Watched(0)
let Cannon0          = Watched({ count = 0, time = -1, endTime = -1 })
let MGun0            = Watched({ count = 0, time = -1, endTime = -1 }) 
let AddGun           = Watched({ count = 0, time = -1, endTime = -1 }) 

let BombsState       = Watched({ count = 0, time = -1, endTime = 1 }) 
let RocketsState     = Watched({ count = 0, time = -1, endTime = 1 }) 
let TorpedoesState   = Watched({ count = 0, time = -1, endTime = 1 }) 
let cannonsOverheat  = Watched(0)
let mgunsOverheat    = Watched(0)
let addgunsOverheat  = Watched(0)
let TurretsVisible = Watched(array(NUM_TURRETS_MAX, false))
let TurretsReloading = Watched(array(NUM_TURRETS_MAX, false))
let TurretsEmpty = Watched(array(NUM_TURRETS_MAX, false))
let activeCameraView = Watched(null)
let isActiveTurretCamera = Computed(@() activeCameraView.get() == TURRET)
let DmStateMask    = Watched(0)

let airState = {
  TrtMode0
  Trt0
  IsTrtWep0 = Computed(@() TrtMode0.get() == AirThrottleMode.AIRCRAFT_WEP)
  MainMask
  Cannon0
  MGun0
  AddGun
  hasCanon0  = Computed(@() (MainMask.get() & (1 << CANNON_1)) != 0)
  hasMGun0   = Computed(@() (MainMask.get() & (1 << MACHINE_GUNS_1)) != 0)
  hasAddGun  = Computed(@() (MainMask.get() & (1 << CANNON_ADDITIONAL)) != 0)
  isActiveTurretCamera
  cannonsOverheat
  mgunsOverheat
  addgunsOverheat

  TurretsVisible
  TurretsReloading
  TurretsEmpty

  BombsState
  RocketsState
  TorpedoesState

  hasBombs = Computed(@() (MainMask.get() & (1 << BOMBS)) != 0)
  hasRockets = Computed(@() (MainMask.get() & (1 << ROCKET)) != 0)
  hasTorpedos = Computed(@() (MainMask.get() & (1 << TORPEDO)) != 0)

  DistanceToGround = Watched(0)
  Spd = Watched(0)
  IsSpdCritical = Watched(false)

  TargetLockTime = Watched(0)
  DmStateMask
}

interopGen({
  stateTable = airState
  prefix = "air"
  postfix = "Update"
})

let planeState = {
  IsOnGround = Watched(false)
  wheelBrake = Watched(false)
}

interopGen({
  stateTable = planeState
  prefix = "plane"
  postfix = "Update"
})

registerInteropFunc("updateCannonsArray", function(index, count, _seconds, _selected, time, endTime, _mode) {
  if (index != 0)
    return
  let p = Cannon0.get()
  if (p.count != count || p.time != time || p.endTime != endTime)
    Cannon0.set({ count, time, endTime })
})

registerInteropFunc("updateGunsOverheat", function(cannons_overheat, mguns_overheat, addguns_overheat) {
  if (cannonsOverheat.get() != cannons_overheat)
    cannonsOverheat.set(cannons_overheat)
  if (mgunsOverheat.get() != mguns_overheat)
    mgunsOverheat.set(mguns_overheat)
  if (addgunsOverheat.get() != addguns_overheat)
    addgunsOverheat.set(addguns_overheat)
})

registerInteropFunc("updateMachineGunsArray", function(index, count, _seconds, _selected, time, endTime, _mode) {
  if (index != 0)
    return
  let p = MGun0.get()
  if (p.count != count || p.time != time || p.endTime != endTime)
    MGun0.set({ count, time, endTime })
})

registerInteropFunc("updateAdditionalCannons", function(count, _seconds, _mode, _selected, time, endTime) {
  let guns = AddGun.get()
  if (guns.count != count || guns.time != time || guns.endTime != endTime)
    AddGun.set(AddGun.get().__merge({ count, time, endTime }))
})

registerInteropFunc("updateBombs", @(count, _seconds, _mode, _selected, _salvo, _name, _actualCount, time, endTime)
  BombsState({ count, time, endTime }))

registerInteropFunc("updateRockets", @(count, _seconds, _mode, _selected, _salvo, _name, _actualCount, time, endTime)
  RocketsState({ count, time, endTime }))

registerInteropFunc("updateTorpedoes", @(count, _seconds, _mode, _selected, _salvo, _name, _actualCount, time, endTime)
  TorpedoesState({ count, time, endTime }))

registerInteropFunc("updateEnginesThrottle", function(mode, trt, _state, index) {
  if (index != 0)
    return
  TrtMode0.set(mode)
  Trt0.set(trt)
})
registerInteropFunc("updateTurrets", function(_, _, _, isReloading, empty, visible, index) {
  if (TurretsReloading.get()[index] != isReloading)
    TurretsReloading.mutate(@(v) v[index] = isReloading)
  if (TurretsEmpty.get()[index] != empty)
    TurretsEmpty.mutate(@(v) v[index] = empty)
  if (TurretsVisible.get()[index] != visible)
    TurretsVisible.mutate(@(v) v[index] = visible)
})

eventbus_subscribe("onSetCamera", @(v) activeCameraView.set(v.newType))

foreach(w in [isUnitAlive, isUnitDelayed, MainMask, playerUnitName])
  w.subscribe(@(_) activeCameraView.set(getCameraViewType()))

let logMask = @() log("MainMask = ",
  ", ".join(
    AirParamsMain
      .filter(@(v) (MainMask.get() & (1 << v)) != 0)
      .reduce(@(res, v, k) res.append({ v, k }), [])
      .sort(@(a, b) a.v <=> b.v)
      .map(@(v) v.k)))

register_command(logMask, "debug.airWeaponMask")

let maxDebugDebuff = 1023
register_command(@() debugDebuff(debugDebuff.value == maxDebugDebuff ? 0 : maxDebugDebuff), "hud.debug.airDebuffsAll")
register_command(@() debugDebuff(rnd_int(0, maxDebugDebuff)), "hud.debug.airDebuffsRandom")
register_command(function(idx) {
  let bit = 1 << idx
  log(debugDebuff.value)
  debugDebuff((debugDebuff.value & bit) ? (debugDebuff.value & ~bit) : (debugDebuff.value | bit))
  log(debugDebuff.value)
}, "hud.debug.airDebuffsToggle")

let export = planeState.__merge(airState).__merge({
  DmStateMask = Computed(@() DmStateMask.value | debugDebuff.value)
})

return export