from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "console" import register_command
from "dasevents" import EventSpendItems
from "%appGlobals/clientState/clientState.nut" import isInBattle


const TANK_TOOLKIT = "tank_tool_kit_expendable"

let spendItemsQueue = Watched([])
let tankToolkitSpent = mkWatched(persist, "tankToolkitSpent", 0)

function addSpendItem(itemId, count) {
  spendItemsQueue.mutate(@(v) v.append({ itemId, count }))
  if (itemId == TANK_TOOLKIT)
    tankToolkitSpent.set(tankToolkitSpent.get() + count)
}

isInBattle.subscribe(function(_) {
  spendItemsQueue.set([])
  tankToolkitSpent.set(0)
})

function removeSpendItem(itemData) {
  let idx = spendItemsQueue.get().indexof(itemData)
  if (idx != null)
    spendItemsQueue.mutate(@(v) v.remove(idx))
}

register_es("spend_items_es",
  {
    [EventSpendItems] = @(evt, _eid, _comp) addSpendItem(evt.itemId, evt.count)
  },
  {
    comps_rq = [["server_player__userId", TYPE_UINT64]]
  })

register_command(@(amount) addSpendItem("ship_tool_kit", amount), "debug.spend_item_ship_toolkit")
register_command(@(amount) addSpendItem(TANK_TOOLKIT, amount), "debug.spend_item_tank_toolkit")
register_command(@(amount) addSpendItem("tank_extinguisher", amount), "debug.spend_item_extinguisher")
register_command(@(amount) addSpendItem("ship_smoke_screen_system_mod", amount), "debug.spend_item_smoke_screen")
register_command(@(amount) addSpendItem("spare", amount), "debug.spend_spare")

return {
  spendItemsQueue
  removeSpendItem
  tankToolkitSpent
}
