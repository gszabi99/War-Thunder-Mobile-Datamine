from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")

let crewState = mkWatched(persist, "crewState", {})

eventbus_subscribe("CrewState:CrewState", @(data) crewState.set(data))

let crewDriverState = mkWatched(persist, "crewDriverState", { state = "ok" })
let crewGunnerState = mkWatched(persist, "crewGunnerState", { state = "ok" })
let crewLoaderState = mkWatched(persist, "crewLoaderState", { state = "ok" })

eventbus_subscribe("CrewState:DriverState", @(data) crewDriverState.set(data))
eventbus_subscribe("CrewState:GunnerState", @(data) crewGunnerState.set(data))
eventbus_subscribe("CrewState:LoaderState", @(data) crewLoaderState.set(data))

return {
  crewState

  crewDriverState
  crewGunnerState
  crewLoaderState
}
