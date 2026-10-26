from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%rGui/hud/tankHudDebuffsState.nut" import debugDebuffNorm, debugDebuff


let crewState = mkWatched(persist, "crewState", {})

eventbus_subscribe("CrewState:CrewState", @(data) crewState.set(data))

let crewDriverStateActual = mkWatched(persist, "crewDriverState", { state = "ok", health = 1 })
let crewGunnerStateActual = mkWatched(persist, "crewGunnerState", { state = "ok", health = 1 })
let crewLoaderStateActual = mkWatched(persist, "crewLoaderState", { state = "ok", health = 1 })

eventbus_subscribe("CrewState:DriverState", @(data) crewDriverStateActual.set(data))
eventbus_subscribe("CrewState:GunnerState", @(data) crewGunnerStateActual.set(data))
eventbus_subscribe("CrewState:LoaderState", @(data) crewLoaderStateActual.set(data))

let mkCrewState = @(state, mask) Computed(@() state.get().__merge(
  debugDebuffNorm.get() != null ? { health = debugDebuffNorm.get() } : {},
  (debugDebuff.get() & mask) != 0 ? { state = "dead" } : {}))

return {
  crewState

  crewDriverState = mkCrewState(crewDriverStateActual, 0x0020)
  crewGunnerState = mkCrewState(crewGunnerStateActual, 0x0040)
  crewLoaderState = mkCrewState(crewLoaderStateActual, 0x0080)
}
