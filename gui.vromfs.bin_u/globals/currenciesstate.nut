//checked for explicitness
#no-root-fallback
#explicit-this

let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"

let balance = sharedWatched("balance", @() {})

return {
  WP
  GOLD
  balance
  balanceWp = Computed(@() balance.value?[WP] ?? 0)
  balanceGold = Computed(@() balance.value?[GOLD] ?? 0)
}
