from "%globalsDarg/darg_library.nut" import *
let interopGen = require("interopGen.nut")

let state = {
  isInFlight = false
}.map(@(val, key) mkWatched(persist, key, val))


interopGen({
  postfix = "Update"
  stateTable = state
})


return state