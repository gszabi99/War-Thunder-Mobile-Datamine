from "frp" import Computed
from "%sqstd/globalState.nut" import hardPersistWatched


const WP = "wp"
const GOLD = "gold"
const WARBOND = "warbond"
const EVENT_KEY = "eventKey"
const SLOT_EXP_TANKS = "slot_exp_tanks"
const SLOT_EXP_AIR = "slot_exp_air"

const NYBOND = "nybond"
const LUNARBOND = "lunarbond"
const APRILBOND = "aprilbond"
const APRILINTEL = "aprilintel"
const PLATINUM = "platinum"
const BLACKFRIDAYBOND = "blackfridaybond"
const APRILMAPPIECE = "aprilMapPiece"
const APRILDOUBLON = "aprilDoublon"
const HOTMAYBOND = "hotmaybond"
const INDEPENDENCEBOND = "independencebond"
const ANNIVERSARYBOND = "anniversarybond"
const ANNIVERSARYTOKEN = "anniversarytoken"
const HALLOWEENBOND = "halloweenbond"
const VALENTINEBOND = "valentinebond"
const CANDYBOND = "candybond"
const LOLLIPOPBOND = "lollipopbond"
const CHOCOLATEBOND = "chocolatebond"
const UKBOND = "ukbond"
const JAPANBOND = "japanbond"
const MAPTOKEN = "maptoken"

let balance = hardPersistWatched("balance", {})
let isBalanceReceived = hardPersistWatched("isBalanceReceived", false)

let currencyOrder = [PLATINUM, GOLD, WP, WARBOND, EVENT_KEY, SLOT_EXP_TANKS, SLOT_EXP_AIR, CANDYBOND, LOLLIPOPBOND, CHOCOLATEBOND]
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
  MAPTOKEN
  EVENT_KEY
  SLOT_EXP_TANKS
  SLOT_EXP_AIR

  NYBOND
  LUNARBOND
  APRILBOND
  APRILINTEL
  APRILMAPPIECE
  APRILDOUBLON
  BLACKFRIDAYBOND
  HOTMAYBOND
  INDEPENDENCEBOND
  ANNIVERSARYBOND
  ANNIVERSARYTOKEN
  HALLOWEENBOND
  VALENTINEBOND
  CANDYBOND
  LOLLIPOPBOND
  CHOCOLATEBOND
  UKBOND
  JAPANBOND
}

let allCurrencies = currenciesRes.values()

return currenciesRes.__update({
  allCurrencies
  commonCurrencies = [ WP, GOLD, PLATINUM ].totable()

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
