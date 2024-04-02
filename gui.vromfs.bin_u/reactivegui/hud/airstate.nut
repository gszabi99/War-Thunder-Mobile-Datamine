from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { AirThrottleMode, AirParamsMain } = require("%globalScripts/sharedEnums.nut")
let interopGen = require("%rGui/interopGen.nut")
let { registerInteropFunc } = require("%globalsDarg/interop.nut")
let { CANNON_1, MACHINE_GUNS_1, ROCKET, BOMBS, TORPEDO } = AirParamsMain

let MainMask         = Watched(0)
let Trt0             = Watched(0)
let TrtMode0         = Watched(0)
let Cannon0          = Watched({ count = 0, time = -1, endTime = -1 })
let MGun0            = Watched({ count = 0, time = -1, endTime = -1 }) // -duplicate-assigned-expr

let BombsState       = Watched({ count = 0, time = -1, endTime = 1 }) // -duplicate-assigned-expr
let RocketsState     = Watched({ count = 0, time = -1, endTime = 1 }) // -duplicate-assigned-expr
let TorpedoesState   = Watched({ count = 0, time = -1, endTime = 1 }) // -duplicate-assigned-expr


let airState = {
  TrtMode0
  Trt0
  IsTrtWep0 = Computed(@() TrtMode0.get() == AirThrottleMode.AIRCRAFT_WEP)
  MainMask
  Cannon0
  MGun0
  hasCanon0  = Computed(@() (MainMask.get() & (1 << CANNON_1)) != 0)
  hasMGun0   = Computed(@() (MainMask.get() & (1 << MACHINE_GUNS_1)) != 0)

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
}

interopGen({
  stateTable = airState
  prefix = "air"
  postfix = "Update"
})

let planeState = {
  IsOnGround = Watched(false)
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

registerInteropFunc("updateMachineGunsArray", function(index, count, _seconds, _selected, time, endTime, _mode) {
  if (index != 0)
    return
  let p = MGun0.get()
  if (p.count != count || p.time != time || p.endTime != endTime)
    MGun0.set({ count, time, endTime })
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

let logMask = @() log("MainMask = ",
  ", ".join(
    AirParamsMain
      .filter(@(v) (MainMask.get() & (1 << v)) != 0)
      .reduce(@(res, v, k) res.append({ v, k }), [])
      .sort(@(a, b) a.v <=> b.v)
      .map(@(v) v.k)))

register_command(logMask, "debug.airWeaponMask")

return planeState.__merge(airState)