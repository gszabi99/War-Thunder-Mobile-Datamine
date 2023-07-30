from "%globalsDarg/darg_library.nut" import *
let {
  CannonCount,
  CannonCooldownTime,
  CannonCooldownEndTime,

  MachineGunsCount,
  MachineGunsCooldownTime,
  MachineGunsCooldownEndTime,

  BombsCount,
  BombsCooldownTime,
  BombsCooldownEndTime,

  RocketsCount,
  RocketsCooldownTime,
  RocketsCooldownEndTime,

  TorpedoesCount,
  TorpedoesCooldownTime,
  TorpedoesCooldownEndTime
} = require("%rGui/hud/airState.nut")

let cannonCount0 = CannonCount[0]
let cannonCooldownTime0 = CannonCooldownTime[0]
let cannonCooldownEndTime0 = CannonCooldownEndTime[0]

let machineGunsCount0 = MachineGunsCount[0]
let machineGunsCooldownTime0 =  MachineGunsCooldownTime[0]
let machineGunsCooldownEndTime0 =  MachineGunsCooldownEndTime[0]

let airWeaponsItems = {
  cannon = Computed(@() {
    available = true
    count = cannonCount0.value
    cooldownTime = cannonCooldownTime0.value
    cooldownEndTime = cannonCooldownEndTime0.value
    broken = false
    aimReady = true
  })

  mGun = Computed(@() {
    available = true
    count = machineGunsCount0.value
    cooldownTime = machineGunsCooldownTime0.value
    cooldownEndTime = machineGunsCooldownEndTime0.value
    ammoLost = 0
    broken = false
    aimReady = true
  })

  bomb = Computed(@() {
    available = true
    count = BombsCount.value
    cooldownTime = BombsCooldownTime.value
    cooldownEndTime = BombsCooldownEndTime.value
    broken = false
    aimReady = true
  })

  rocket = Computed(@() {
    available = true
    count = RocketsCount.value
    cooldownTime = RocketsCooldownTime.value
    cooldownEndTime = RocketsCooldownEndTime.value
    broken = false
    aimReady = true
  })

  torpedo = Computed(@() {
    available = true
    count = TorpedoesCount.value
    cooldownTime = TorpedoesCooldownTime.value
    cooldownEndTime = TorpedoesCooldownEndTime.value
    broken = false
    aimReady = true
  })
}

return airWeaponsItems
