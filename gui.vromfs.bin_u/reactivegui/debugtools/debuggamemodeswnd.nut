from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/gameModes/gameModes.nut" import gameModesRaw, allGameModes, endedModes
from "%rGui/components/debugWnd.nut" import openDebugWnd


return @() openDebugWnd({
  tabs = Computed(@() [
    { id = "gameModesRaw",  data = gameModesRaw.get() }
    { id = "allActiveGameModes", data = allGameModes.get() }
    { id = "endedModes by time", data = endedModes.get() }
    { id = "allActiveGameModes_noMm",
      data = allGameModes.get()
        .map(function(v) {
          if ("matchmaking" not in v)
            return v
          let m = clone v
          m.$rawdelete("matchmaking")
          return m
        })
    }
  ])
})
