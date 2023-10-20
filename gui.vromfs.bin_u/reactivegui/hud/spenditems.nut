from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
let { register_command } = require("console")
let { EventSpendItems } = require("dasevents")

let spendItemsQueue = Watched([])

let addSpendItem = @(itemId, count) spendItemsQueue.mutate(@(v) v.append({ itemId, count }))

let function removeSpendItem(itemData) {
  let idx = spendItemsQueue.value.indexof(itemData)
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
register_command(@(amount) addSpendItem("tank_tool_kit_expendable", amount), "debug.spend_item_tank_toolkit")
register_command(@(amount) addSpendItem("tank_extinguisher", amount), "debug.spend_item_extinguisher")
register_command(@(amount) addSpendItem("ship_smoke_screen_system_mod", amount), "debug.spend_item_smoke_screen")
register_command(@(amount) addSpendItem("spare", amount), "debug.spend_spare")

return {
  spendItemsQueue
  removeSpendItem
}
