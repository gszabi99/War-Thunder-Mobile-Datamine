from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")

let crewState = mkWatched(persist, "crewState", {})

eventbus_subscribe("CrewState:CrewState", @(data) crewState(data))

let crewDriverState = mkWatched(persist, "crewDriverState", { state = "ok" })
let crewGunnerState = mkWatched(persist, "crewGunnerState", { state = "ok" })
let crewLoaderState = mkWatched(persist, "crewLoaderState", { state = "ok" })

eventbus_subscribe("CrewState:DriverState", @(data) crewDriverState(data))
eventbus_subscribe("CrewState:GunnerState", @(data) crewGunnerState(data))
eventbus_subscribe("CrewState:LoaderState", @(data) crewLoaderState(data))

return {
  crewState

  crewDriverState
  crewGunnerState
  crewLoaderState
}
