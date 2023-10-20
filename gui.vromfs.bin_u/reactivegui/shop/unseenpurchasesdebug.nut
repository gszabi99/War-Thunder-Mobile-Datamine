from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")

let unseenPurchasesDebug = mkWatched(persist, "unseenPurchasesDebug", null)

let fakeUnseenPurchases = {
  [-1] = {
    source = "lootbox"
    goods = [
      { id = "wp", gType = "currency", count = 2000 },
      { id = "alpha_tester", gType = "decorator", count = 0 },
      { id = "chevron", gType = "decorator", count = 0 },
      { id = "gold", gType = "currency", count = 1000 },
      { id = "warbond", gType = "currency", count = 100 },
      { id = "eventKey", gType = "currency", count = 50 },
      { id = "premium", gType = "premium", count = 30 },
      { id = "ship_tool_kit", gType = "item", count = 20 },
      { id = "ship_smoke_screen_system_mod", gType = "item", count = 15 },
      { id = "tank_tool_kit_expendable", gType = "item", count = 50 },
      { id = "tank_extinguisher", gType = "item", count = 30 },
      { id = "spare", gType = "item", count = 100 },
      { id = "ussr_sub_pr641", gType = "unit", count = 1 },
      { id = "ussr_t_34_85_zis_53", gType = "unit", count = 1 },
      { id = "uk_destroyer_tribal", gType = "unitUpgrade", count = 1 },
      { id = "ussr_t_34_85_zis_53", gType = "unitUpgrade", count = 1 },
    ]
  }
}

let toggle = @() unseenPurchasesDebug(unseenPurchasesDebug.value == null ? fakeUnseenPurchases : null)

register_command(toggle, "ui.debug.unseenPurchasesFake")

return unseenPurchasesDebug
