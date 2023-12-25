
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"
let WARBOND = "warbond"
let EVENT_KEY = "eventKey"
let NYBOND = "nybond"

let balance = sharedWatched("balance", @() {})
let isValidBalance = Computed(@() balance.value.findindex(@(val) val < 0) == null)

let orderByCurrency = { [GOLD] = 1, [WP] = 2, [WARBOND] = 3, [EVENT_KEY] = 4, [NYBOND] = 5 }

return {
  WP
  GOLD
  WARBOND
  EVENT_KEY
  NYBOND
  balance
  balanceWp = Computed(@() balance.value?[WP] ?? 0)
  balanceGold = Computed(@() balance.value?[GOLD] ?? 0)
  isValidBalance
  orderByCurrency
}
