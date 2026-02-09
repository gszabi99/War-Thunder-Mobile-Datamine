
let { Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")

let WP = "wp"
let GOLD = "gold"
let WARBOND = "warbond"
let EVENT_KEY = "eventKey"
let SLOT_EXP_TANKS = "slot_exp_tanks"
let SLOT_EXP_AIR = "slot_exp_air"

let NYBOND = "nybond"
let LUNARBOND = "lunarbond"
let APRILBOND = "aprilbond"
let PLATINUM = "platinum"
let BLACKFRIDAYBOND = "blackfridaybond"
let APRILMAPPIECE = "aprilMapPiece"
let APRILDOUBLON = "aprilDoublon"
let HOTMAYBOND = "hotmaybond"
let INDEPENDENCEBOND = "independencebond"
let ANNIVERSARYBOND = "anniversarybond"
let HALLOWEENBOND = "halloweenbond"
let VALENTINEBOND = "valentinebond"
let CANDYBOND = "candybond"
let LOLLIPOPBOND = "lollipopbond"
let CHOCOLATEBOND = "chocolatebond"

let balance = sharedWatched("balance", @() {})
let isBalanceReceived = sharedWatched("isBalanceReceived", @() false)

let currencyOrder = [PLATINUM, GOLD, WP, WARBOND, EVENT_KEY, SLOT_EXP_TANKS, SLOT_EXP_AIR]
let orderByCurrency = currencyOrder.reduce(@(res, c, i) res.$rawset(c, i + 1), {})

let dbgCurrencyCount = {
  [WP] = 100000,
  [EVENT_KEY] = 10,
}
let getDbgCurrencyCount = @(c) dbgCurrencyCount?[c] ?? 1000

let currenciesRes = {
  WP
  PLATINUM
  GOLD
  WARBOND
  EVENT_KEY
  SLOT_EXP_TANKS
  SLOT_EXP_AIR

  NYBOND
  LUNARBOND
  APRILBOND
  APRILMAPPIECE
  APRILDOUBLON
  BLACKFRIDAYBOND
  HOTMAYBOND
  INDEPENDENCEBOND
  ANNIVERSARYBOND
  HALLOWEENBOND
  VALENTINEBOND
  CANDYBOND
  LOLLIPOPBOND
  CHOCOLATEBOND
}

let allCurrencies = currenciesRes.values()

return currenciesRes.__update({
  allCurrencies

  isBalanceReceived
  balance
  balanceWp = Computed(@() balance.get()?[WP] ?? 0)
  balanceGold = Computed(@() balance.get()?[GOLD] ?? 0)
  onlineBattleBlockCurrencyId = Computed(@() (balance.get()?[PLATINUM] ?? 0) < 0 ? PLATINUM
    : (balance.get()?[GOLD] ?? 0) < 0 ? GOLD
    : null)
  orderByCurrency
  currencyOrder
  getDbgCurrencyCount
})
