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
  hasDebuffFireExternal = Watched(0)
  primaryRocketGun = Watched(false)
  hasSecondaryGun = Watched(false)
  IsTracked = Watched(true)
}

interopGen({
  stateTable = tankStateNative
  prefix = "tank"
  postfix = "Update"
})

let { hasDebuffGuns, hasDebuffTurretDrive, hasDebuffEngine, hasDebuffTracks, hasDebuffFire, hasDebuffFireExternal } = tankStateNative

let driverReady = Computed(@() crewDriverState.get().state == "ok")
let gunnerReady = Computed(@() crewGunnerState.get().state == "ok")
let loaderReady = Computed(@() crewLoaderState.get().state == "ok")

let export = tankStateNative.__merge({
  hasDebuffGuns = Computed(@() !!hasDebuffGuns.value != ((debugDebuff.get() & 1) != 0))
  hasDebuffTurretDrive = Computed(@() !!hasDebuffTurretDrive.value != ((debugDebuff.get() & 2) != 0))
  hasDebuffEngine = Computed(@() !!hasDebuffEngine.value != ((debugDebuff.get() & 4) != 0))
  hasDebuffTracks = Computed(@() !!hasDebuffTracks.value != ((debugDebuff.get() & 8) != 0))
  hasDebuffFire = Computed(@()   !!hasDebuffFire.value != ((debugDebuff.get() & 16) != 0))
  hasDebuffDriver = Computed(@() !driverReady.get() != ((debugDebuff.get() & 32) != 0))
  hasDebuffGunner = Computed(@() !gunnerReady.get() != ((debugDebuff.get() & 64) != 0))
  hasDebuffLoader = Computed(@() !loaderReady.get() != ((debugDebuff.get() & 128) != 0))
  hasDebuffFireExternal = Computed(@() !!hasDebuffFireExternal.value != ((debugDebuff.get() & 256) != 0))
})

let maxDebugDebuff = 255
register_command(@() debugDebuff.set(debugDebuff.get() == maxDebugDebuff ? 0 : maxDebugDebuff), "hud.debug.tankDebuffsAll")
register_command(@() debugDebuff.set(rnd_int(0, maxDebugDebuff)), "hud.debug.tankDebuffsRandom")

return export
