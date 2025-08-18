from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


let missionVariablesTable = mkWatched(persist, "missionVariablesTable", {})

isInBattle.subscribe(@(_) missionVariablesTable.set({}))

eventbus_subscribe("onMissionVar", @(evt) missionVariablesTable.mutate(@(v) v[evt.var_name] <- evt?.value))

let mkMissionVar = @(varName, defValue) Computed(@() missionVariablesTable.get()?[varName] ?? defValue)


return {
  mkMissionVar
}