from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")

let unseenPurchasesDebug = mkWatched(persist, "unseenPurchasesDebug", null)

let fakeUnseenPurchases = {
  [-1] = {
    source = "lootbox"
    goods = [
      { id = "wp", gType = "currency", count = 2000 },
      { id = "gold", gType = "currency", count = 1000 },
      { id = "warbond", gType = "currency", count = 100 },
      { id = "eventKey", gType = "currency", count = 50 },
      { id = "premium", gType = "premium", count = 30 },
      { id = "ship_tool_kit", gType = "item", count = 20 },
      { id = "ship_smoke_screen_system_mod", gType = "item", count = 15 },
      { id = "tank_tool_kit_expendable", gType = "item", count = 50 },
      { id = "tank_extinguisher", gType = "item", count = 30 },
      { id = "firework_kit", gType = "item", count = 3 },
      { id = "ircm_kit", gType = "item", count = 3 },
      { id = "cardicon_crosspromo", gType = "decorator", count = 0 },
      { id = "captain-lieutenant", gType = "decorator", count = 0 },
      { id = "pilot", gType = "decorator", count = 0 },
      { id = "cannon", gType = "decorator", count = 0 },
      { id = "bullet", gType = "decorator", count = 0 },
      { id = "spare", gType = "item", count = 100 },
      { id = "ussr_sub_pr641", gType = "unit", count = 1 },
      { id = "ussr_t_34_85_d_5t", gType = "unit", count = 1 },
      { id = "uk_destroyer_tribal", gType = "unitUpgrade", count = 1 },
      { id = "ussr_t_34_85_d_5t", gType = "unitUpgrade", count = 1 },
      { id = "playerExp", gType = "booster", count = 2 },
      { id = "germ_ru251", subId = "fiction", gType = "skin", count = 0 },
      { id = "uk_destroyer_tribal", subId = "upgraded", gType = "skin", count = 0 },
      { id = "pony_fighter", gType = "battleMod", count = 36000 },
      { id = "air_cbt_access", gType = "battleMod", count = 36000 },
    ]
  }
}

let toggle = @() unseenPurchasesDebug(unseenPurchasesDebug.value == null ? fakeUnseenPurchases : null)

register_command(toggle, "ui.debug.unseenPurchasesFake")

return unseenPurchasesDebug
