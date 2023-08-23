
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"

let balance = sharedWatched("balance", @() {})
let isValidBalance = Computed(@() balance.value.findindex(@(val) val < 0) == null)

let orderByCurrency = { [GOLD] = 1, [WP] = 2 }

return {
  WP
  GOLD
  balance
  balanceWp = Computed(@() balance.value?[WP] ?? 0)
  balanceGold = Computed(@() balance.value?[GOLD] ?? 0)
  isValidBalance
  orderByCurrency
}
