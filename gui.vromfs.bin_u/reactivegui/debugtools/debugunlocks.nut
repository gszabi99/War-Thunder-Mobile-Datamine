from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/debugWnd.nut" import openDebugWnd
from "%rGui/unlocks/userstat.nut" import userstatDescList, userstatUnlocks, userstatStats, userstatStatsTables,
  userstatInfoTables


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

return @() openDebugWnd({ tabs })
