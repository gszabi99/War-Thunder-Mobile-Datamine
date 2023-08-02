from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { userstatDescList, userstatUnlocks, userstatStats } = require("%rGui/unlocks/userstat.nut")

let tabs = Computed(@() [
  { id = "unlocks desc", data = userstatDescList.value?.unlocks ?? {} }
  { id = "stats desc", data = userstatDescList.value?.stats ?? {} }
  { id = "unlocks progress", data = userstatUnlocks.value?.unlocks ?? {} }
  { id = "personal unlocks", data = userstatUnlocks.value?.personalUnlocks ?? {} }
  { id = "stats", data = userstatStats.value?.stats ?? {} }
])

return @() openDebugWnd(tabs)
