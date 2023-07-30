from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { gameModesRaw, allGameModes } = require("%appGlobals/gameModes/gameModes.nut")

return @() openDebugWnd(Computed(@() [
  { id = "gameModesRaw",  data = gameModesRaw.value }
  { id = "allActiveGameModes", data = allGameModes.value }
  { id = "allActiveGameModes_noMm",
    data = allGameModes.value
      .map(function(v) {
        if ("matchmaking" not in v)
          return v
        let m = clone v
        delete m.matchmaking
        return m
      })
  }
]))
