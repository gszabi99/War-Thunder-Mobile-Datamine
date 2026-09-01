from "%globalsDarg/darg_library.nut" import *
import "%rGui/interopGen.nut" as interopGen


let state = {
  isInFlight = mkWatched(persist, "isInFlight", false)
}


interopGen({
  postfix = "Update"
  stateTable = state
})


return state