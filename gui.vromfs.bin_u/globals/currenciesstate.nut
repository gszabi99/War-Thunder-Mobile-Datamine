
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"
let WARBOND = "warbond"
let EVENT_KEY = "eventKey"

let balance = sharedWatched("balance", @() {})
let isValidBalance = Computed(@() balance.value.findindex(@(val) val < 0) == null)

let orderByCurrency = { [GOLD] = 1, [WP] = 2, [WARBOND] = 3, [EVENT_KEY] = 4 }

return {
  WP
  GOLD
  WARBOND
  EVENT_KEY
  balance
  balanceWp = Computed(@() balance.value?[WP] ?? 0)
  balanceGold = Computed(@() balance.value?[GOLD] ?? 0)
  balanceWarbond = Computed(@() balance.value?[WARBOND] ?? 0)
  balanceEventKey = Computed(@() balance.value?[EVENT_KEY] ?? 0)
  isValidBalance
  orderByCurrency
}
