
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"
let WARBOND = "warbond"
let EVENT_KEY = "eventKey"
let NYBOND = "nybond"
let PLATINUM = "platinum"

let balance = sharedWatched("balance", @() {})
let isValidBalance = Computed(@() balance.value.findindex(@(val) val < 0) == null)

let orderByCurrency = { [PLATINUM] = 1, [GOLD] = 2, [WP] = 3, [WARBOND] = 4, [EVENT_KEY] = 5, [NYBOND] = 6 }

return {
  WP
  PLATINUM
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
