from "eventbus" import eventbus_subscribe
from "console" import register_command
from "dagor.random" import rnd_int
from "%globalsDarg/darg_library.nut" import *
from "hudState" import hud_request_hud_tank_debuffs_state


let debugDebuff = mkWatched(persist, "debugDebuff", 0)
let debugDebuffPercent = mkWatched(persist, "debugDebuffPercent", null)

let debugDebuffNorm = Computed(@() debugDebuffPercent.get() != null ? (debugDebuffPercent.get() / 100.0) : null)

let turretDriveDataActual = Watched({})
let gunDataActual = Watched({})
let engineDataActual = Watched({})
let tracksDataActual = Watched({})

eventbus_subscribe("TankDebuffs:TurretDrive", @(data) turretDriveDataActual.set(data))
eventbus_subscribe("TankDebuffs:Gun", @(data) gunDataActual.set(data))
eventbus_subscribe("TankDebuffs:Engine", @(data) engineDataActual.set(data))
eventbus_subscribe("TankDebuffs:Tracks", @(data) tracksDataActual.set(data))


const maxDebugDebuff = 0xFFFF
register_command(@() debugDebuff.set(debugDebuff.get() == maxDebugDebuff ? 0 : maxDebugDebuff),
  "hud.debug.tankDebuffsAll")
register_command(@() debugDebuff.set(rnd_int(0, maxDebugDebuff)), "hud.debug.tankDebuffsRandom")
register_command(@(value) debugDebuffPercent.set(debugDebuffPercent.get() == null ? value : null),
  "hud.debug.tankDebuffsAlternative")


return {
  debugDebuff
  debugDebuffNorm
  tracksData = Computed(function() {
    let actual = clone tracksDataActual.get()
    actual.trackBroken <- (!!actual?.trackBroken != ((debugDebuff.get() & 0x8000) != 0))
    if (debugDebuffNorm.get() != null)
      actual.trackHealth <- debugDebuffNorm.get()
    return actual
  })
  turretDriveData = Computed(function() {
    let actual = clone turretDriveDataActual.get()
    actual.horizontalDriveBroken <- (!!actual?.horizontalDriveBroken != ((debugDebuff.get() & 0x0200) != 0))
    actual.verticalDriveBroken <- (!!actual?.verticalDriveBroken != ((debugDebuff.get() & 0x0400) != 0))
    if (debugDebuffPercent.get() != null) {
      actual.turretRotationReductionPercent <- debugDebuffPercent.get()
      actual.horizontalDriveHealth <- debugDebuffNorm.get()
      actual.verticalDriveHealth <- debugDebuffNorm.get()
    }
    return actual
  })
  gunData = Computed(function() {
    let actual = clone gunDataActual.get()
    actual.barrelBroken <- (!!actual?.barrelBroken != ((debugDebuff.get() & 0x0800) != 0))
    actual.breechBroken <- (!!actual?.breechBroken != ((debugDebuff.get() & 0x1000) != 0))
    if (debugDebuffPercent.get() != null) {
      actual.misfireChancePercent <- debugDebuffPercent.get()
      actual.barrelHealth <- debugDebuffNorm.get()
      actual.rocketlauncherHealth <- debugDebuffNorm.get()
      actual.breechHealth <- debugDebuffNorm.get()
      actual.guidanceHealth <- debugDebuffNorm.get()
      actual.autoloaderHealth <- debugDebuffNorm.get()
    }
    return actual
  })
  engineData = Computed(function() {
    let actual = clone engineDataActual.get()
    actual.engineBroken <- (!!actual?.engineBroken != ((debugDebuff.get() & 0x2000) != 0))
    actual.transmissionBroken <- (!!actual?.transmissionBroken != ((debugDebuff.get() & 0x4000) != 0))
    if (debugDebuffPercent.get() != null) {
      actual.enginePowerReductionPercent <- debugDebuffPercent.get()
      actual.speedReductionPercent <- debugDebuffPercent.get()
      actual.engineHealth <- debugDebuffNorm.get()
      actual.transmissionHealth <- debugDebuffNorm.get()
    }
    return actual
  })
  reInitTankDebuffsStates = hud_request_hud_tank_debuffs_state
}
