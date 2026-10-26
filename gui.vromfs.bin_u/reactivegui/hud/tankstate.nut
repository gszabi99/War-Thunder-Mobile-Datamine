from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/tankHudDebuffsState.nut" import debugDebuff
import "%rGui/interopGen.nut" as interopGen


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


return tankStateNative.__merge({
  hasDebuffGuns = Computed(@() !!hasDebuffGuns.get() != ((debugDebuff.get() & 0x0001) != 0))
  hasDebuffTurretDrive = Computed(@() !!hasDebuffTurretDrive.get() != ((debugDebuff.get() & 0x0002) != 0))
  hasDebuffEngine = Computed(@() !!hasDebuffEngine.get() != ((debugDebuff.get() & 0x0004) != 0))
  hasDebuffTracks = Computed(@() !!hasDebuffTracks.get() != ((debugDebuff.get() & 0x0008) != 0))
  hasDebuffFire = Computed(@()   !!hasDebuffFire.get() != ((debugDebuff.get() & 0x0010) != 0))
  hasDebuffFireExternal = Computed(@() !!hasDebuffFireExternal.get() != ((debugDebuff.get() & 0x0100) != 0))
})
