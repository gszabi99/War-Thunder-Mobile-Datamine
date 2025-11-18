from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { userstatDescList, userstatUnlocks, userstatStats, userstatStatsTables, userstatInfoTables
} = require("%rGui/unlocks/userstat.nut")

let tabs = Computed(@() [
  { id = "unlocks desc", data = userstatDescList.get()?.unlocks ?? {} }
  { id = "stats desc", data = userstatDescList.get()?.stats ?? {} }
  { id = "unlocks progress", data = userstatUnlocks.get()?.unlocks ?? {} }
  { id = "personal unlocks", data = userstatUnlocks.get()?.personalUnlocks ?? {} }
  { id = "stats", data = userstatStats.get()?.stats ?? {} }
  { id = "statsTables", data = userstatStatsTables.get()?.stats ?? {} }
  { id = "inactiveTables", data = userstatStatsTables.get()?.inactiveTables ?? {} }
  { id = "infoTables", data = userstatInfoTables.get() ?? {} }
])

return @() openDebugWnd(tabs)
