from "%globalsDarg/darg_library.nut" import *
let interopGen = require("%rGui/interopGen.nut")
let { register_command } = require("console")
let { rnd_int } = require("dagor.random")
let { crewDriverState, crewGunnerState, crewLoaderState } = require("%rGui/hud/crewState.nut")

let debugDebuff = mkWatched(persist, "debugDebuff", 0)

let tankStateNative = {
  speed = Watched(0)
  cruiseControl = Watched(0)
  shootReadyness = Watched(0)
  hasDebuffGuns = Watched(0)
  hasDebuffTurretDrive = Watched(0)
  allowShoot = Watched(false)
  hasDebuffEngine = Watched(0)
  hasDebuffTracks = Watched(0)
  hasDebuffFire = Watched(0)
  primaryRocketGun = Watched(false)
  hasSecondaryGun = Watched(false)
}

interopGen({
  stateTable = tankStateNative
  prefix = "tank"
  postfix = "Update"
})

let { hasDebuffGuns, hasDebuffTurretDrive, hasDebuffEngine, hasDebuffTracks, hasDebuffFire } = tankStateNative

let driverReady = Computed(@() crewDriverState.value.state == "ok")
let gunnerReady = Computed(@() crewGunnerState.value.state == "ok")
let loaderReady = Computed(@() crewLoaderState.value.state == "ok")

let export = tankStateNative.__merge({
  hasDebuffGuns = Computed(@() !!hasDebuffGuns.value != ((debugDebuff.value & 1) != 0))
  hasDebuffTurretDrive = Computed(@() !!hasDebuffTurretDrive.value != ((debugDebuff.value & 2) != 0))
  hasDebuffEngine = Computed(@() !!hasDebuffEngine.value != ((debugDebuff.value & 4) != 0))
  hasDebuffTracks = Computed(@() !!hasDebuffTracks.value != ((debugDebuff.value & 8) != 0))
  hasDebuffFire = Computed(@() !!hasDebuffFire.value != ((debugDebuff.value & 16) != 0))
  hasDebuffDriver = Computed(@() !driverReady.value != ((debugDebuff.value & 32) != 0))
  hasDebuffGunner = Computed(@() !gunnerReady.value != ((debugDebuff.value & 64) != 0))
  hasDebuffLoader = Computed(@() !loaderReady.value != ((debugDebuff.value & 128) != 0))
})

let maxDebugDebuff = 255
register_command(@() debugDebuff(debugDebuff.value == maxDebugDebuff ? 0 : maxDebugDebuff), "hud.debug.tankDebuffsAll")
register_command(@() debugDebuff(rnd_int(0, maxDebugDebuff)), "hud.debug.tankDebuffsRandom")

return export
