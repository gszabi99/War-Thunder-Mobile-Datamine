from "%globalsDarg/darg_library.nut" import *
let interopGen = require("interopGen.nut")

let state = {
  isInFlight = mkWatched(persist, "isInFlight", false)
}


interopGen({
  postfix = "Update"
  stateTable = state
})


return state