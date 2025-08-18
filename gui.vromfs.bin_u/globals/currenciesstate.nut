
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
let APRILMAPPIECE = "aprilMapPiece"
let APRILDOUBLON = "aprilDoublon"
let HOTMAYBOND = "hotmaybond"
let INDEPENDENCEBOND = "independencebond"
let ANNIVERSARYBOND = "anniversarybond"

let balance = sharedWatched("balance", @() {})
let isBalanceReceived = sharedWatched("isBalanceReceived", @() false)
let isValidBalance = Computed(@() balance.get().findindex(@(val) val < 0) == null)

let currencyOrder = [PLATINUM, GOLD, WP, WARBOND, EVENT_KEY, NYBOND, APRILBOND, BLACK_FRIDAY_BOND, APRILMAPPIECE, APRILDOUBLON, HOTMAYBOND, INDEPENDENCEBOND, ANNIVERSARYBOND]
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
  APRILMAPPIECE
  APRILDOUBLON
  BLACK_FRIDAY_BOND
  HOTMAYBOND
  INDEPENDENCEBOND
  ANNIVERSARYBOND

  isBalanceReceived
  balance
  balanceWp = Computed(@() balance.get()?[WP] ?? 0)
  balanceGold = Computed(@() balance.get()?[GOLD] ?? 0)
  isValidBalance
  orderByCurrency
  currencyOrder
  getDbgCurrencyCount
}
