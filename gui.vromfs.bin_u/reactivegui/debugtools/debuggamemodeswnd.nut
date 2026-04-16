from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { gameModesRaw, allGameModes, endedModes } = require("%appGlobals/gameModes/gameModes.nut")

return @() openDebugWnd(Computed(@() [
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
]))
