
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"
let WARBOND = "warbond"
let EVENT_KEY = "eventKey"
let NYBOND = "nybond"
let APRILBOND = "aprilbond"
let PLATINUM = "platinum"
let BLACK_FRIDAY_BOND = "blackfridaybond"

let balance = sharedWatched("balance", @() {})
let isValidBalance = Computed(@() balance.value.findindex(@(val) val < 0) == null)

let currencyOrder = [PLATINUM, GOLD, WP, WARBOND, EVENT_KEY, NYBOND, APRILBOND, BLACK_FRIDAY_BOND]
let orderByCurrency = currencyOrder.reduce(@(res, c, i) res.$rawset(c, i + 1), {})

let dbgCurrencyCount = {
  [WP] = 100000,
  [EVENT_KEY] = 10,
}
let getDbgCurrencyCount = @(c) dbgCurrencyCount?[c] ?? 1000

return {
  WP
  PLATINUM
  GOLD
  WARBOND
  EVENT_KEY
  NYBOND
  APRILBOND
  BLACK_FRIDAY_BOND
  balance
  balanceWp = Computed(@() balance.value?[WP] ?? 0)
  balanceGold = Computed(@() balance.value?[GOLD] ?? 0)
  isValidBalance
  orderByCurrency
  currencyOrder
  getDbgCurrencyCount
}
