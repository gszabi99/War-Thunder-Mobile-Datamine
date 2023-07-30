//checked for explicitness
#no-root-fallback
#explicit-this

let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let gameModesRaw = sharedWatched("gameModesRaw", @() {})
let allGameModes = Computed(@() gameModesRaw.value.filter(@(m) !(m?.disabled ?? false)))

return {
  gameModesRaw
  allGameModes
}
