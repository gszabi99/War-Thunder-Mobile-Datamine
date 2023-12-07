from "%globalsDarg/darg_library.nut" import *
let { AirThrottleMode } = require("wtSharedEnums")
let interopGen = require("%rGui/interopGen.nut")

const NUM_ENGINES_MAX = 6
const NUM_CANNONS_MAX = 3

let Trt = []
let TrtMode = []

let CannonState = []
for (local i = 0; i < NUM_CANNONS_MAX; ++i) {
  CannonState.append(Watched({ count = 0, time = -1, endTime = -1 }))
}

let MachineGunState = []
for (local i = 0; i < NUM_CANNONS_MAX; ++i) {
  MachineGunState.append(Watched({ count = 0, time = -1, endTime = -1 }))
}

let BombsState = Watched({
  count = 0, time = -1, endTime = 1 })
let RocketsState = Watched({    // -duplicate-assigned-expr
  count = 0, time = -1, endTime = 1 })
let TorpedoesState = Watched({  // -duplicate-assigned-expr
  count = 0, time = -1, endTime = 1 })


let airState = {
  TrtMode,
  Trt,
  MainMask = Watched(0),

  CannonCount = CannonState.map(@(c) Computed(@() c.value.count)),
  CannonCooldownTime = CannonState.map(@(c) Computed(@() c.value.time)),
  CannonCooldownEndTime = CannonState.map(@(c) Computed(@() c.value.endTime)),

  MachineGunsCount = MachineGunState.map(@(c) Computed(@() c.value.count)),
  MachineGunsCooldownTime = MachineGunState.map(@(c) Computed(@() c.value.time)),
  MachineGunsCooldownEndTime = MachineGunState.map(@(c) Computed(@() c.value.endTime)),

  BombsCount = Computed(@() BombsState.value.count)
  BombsCooldownTime = Computed(@() BombsState.value.time)
  BombsCooldownEndTime = Computed(@() BombsState.value.endTime)

  RocketsCount = Computed(@() RocketsState.value.count)
  RocketsCooldownTime = Computed(@() RocketsState.value.time)
  RocketsCooldownEndTime = Computed(@() RocketsState.value.endTime)

  TorpedoesCount = Computed(@() TorpedoesState.value.count)
  TorpedoesCooldownTime = Computed(@() TorpedoesState.value.time)
  TorpedoesCooldownEndTime = Computed(@() TorpedoesState.value.endTime)

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

::interop.updateCannonsArray <- @(index, count, _seconds, _selected, time, endTime, _mode)
  CannonState[index]({ count, time, endTime })

::interop.updateMachineGunsArray <- @(index, count, _seconds, _selected, time, endTime, _mode)
  MachineGunState[index]({ count, time, endTime })

::interop.updateBombs <- @(count, _seconds, _mode, _selected, _salvo, _name, _actualCount, time, endTime)
  BombsState({ count, time, endTime })

::interop.updateRockets <- @(count, _seconds, _mode, _selected, _salvo, _name, _actualCount, time, endTime)
  RocketsState({ count, time, endTime })

::interop.updateTorpedoes <- @(count, _seconds, _mode, _selected, _salvo, _name, _actualCount, time, endTime)
  TorpedoesState({ count, time, endTime })

for (local i = 0; i < NUM_ENGINES_MAX; ++i) {
  TrtMode.append(Watched(0))
  Trt.append(Watched(0))
}

::interop.updateEnginesThrottle <- function(mode, trt, _state, index) {
  TrtMode[index](mode)
  if (mode == AirThrottleMode.AIRCRAFT_WEP)
    Trt[index](100)
  else
    Trt[index](trt)
}

return airState