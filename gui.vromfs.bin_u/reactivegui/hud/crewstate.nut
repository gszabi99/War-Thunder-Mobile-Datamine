from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")

let crewState = mkWatched(persist, "crewState", {})

subscribe("CrewState:CrewState", @(data) crewState(data))

let crewDriverState = mkWatched(persist, "crewDriverState", { state = "ok" })
let crewGunnerState = mkWatched(persist, "crewGunnerState", { state = "ok" })
let crewLoaderState = mkWatched(persist, "crewLoaderState", { state = "ok" })

subscribe("CrewState:DriverState", @(data) crewDriverState(data))
subscribe("CrewState:GunnerState", @(data) crewGunnerState(data))
subscribe("CrewState:LoaderState", @(data) crewLoaderState(data))

return {
  crewState

  crewDriverState
  crewGunnerState
  crewLoaderState
}
