from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/clientState/clientState.nut" import isInBattle


let missionVariablesTable = mkWatched(persist, "missionVariablesTable", {})

isInBattle.subscribe(@(_) missionVariablesTable.set({}))

eventbus_subscribe("onMissionVar", @(evt) missionVariablesTable.mutate(@(v) v[evt.var_name] <- evt?.value))

let mkMissionVar = @(varName, defValue) Computed(@() missionVariablesTable.get()?[varName] ?? defValue)


return {
  mkMissionVar
}