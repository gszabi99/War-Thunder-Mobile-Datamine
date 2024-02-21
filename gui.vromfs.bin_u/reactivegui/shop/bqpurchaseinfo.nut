from "%globalsDarg/darg_library.nut" import *
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { SGT_UNKNOWN, SGT_UNIT, SGT_CONSUMABLES, SGT_PREMIUM, SGT_WP, SGT_WARBONDS, SGT_EVENT_KEYS } = require("%rGui/shop/shopConst.nut")

/*
UI BQ event "open_currency_shop" format:
  id - currency id ("gold", "wp")
  from - source window (see PURCH_SRC_*)
  status - purchase type (see PURCH_TYPE_*)
  params - purchase details as string (unit name, level, etc)
*/

let PURCH_SRC_HANGAR = "hangar"
let PURCH_SRC_UNITS = "units_list"
let PURCH_SRC_LEVELUP = "level_up"
let PURCH_SRC_UNIT_UPGRADES = "unit_upgrades"
let PURCH_SRC_UNIT_MODS = "unit_mods"
let PURCH_SRC_PROFILE = "profile"
let PURCH_SRC_SHOP = "shop"
let PURCH_SRC_EVENT = "event"
let PURCH_SRC_BATTLE_PASS = "battle_pass"
let PURCH_SRC_SKINS = "skins"
let PURCH_SRC_BOOSTERS = "boosters"

let PURCH_TYPE_UNIT = "unit"
let PURCH_TYPE_UNIT_MOD = "unit_mod"
let PURCH_TYPE_UNIT_LEVEL = "unit_level"
let PURCH_TYPE_BP_LEVEL = "bp_level"
let PURCH_TYPE_CONSUMABLES = "consumables"
let PURCH_TYPE_PLAYER_LEVEL = "player_level"
let PURCH_TYPE_DECORATOR = "player_decorator"
let PURCH_TYPE_PREMIUM = "premium"
let PURCH_TYPE_CURRENCY = "currency"
let PURCH_TYPE_LOOTBOX = "lootbox"
let PURCH_TYPE_SKIN = "skin"
let PURCH_TYPE_BOOSTERS = "boosters"

let goodsTypeToPurchTypeMap = {
  [SGT_UNKNOWN] = "unknown",
  [SGT_UNIT] = PURCH_TYPE_UNIT,
  [SGT_CONSUMABLES] = PURCH_TYPE_CONSUMABLES,
  [SGT_PREMIUM] = PURCH_TYPE_PREMIUM,
  [SGT_WP] = PURCH_TYPE_CURRENCY,
  [SGT_WARBONDS] = PURCH_TYPE_CURRENCY,
  [SGT_EVENT_KEYS] = PURCH_TYPE_CURRENCY,
}

function getPurchaseTypeByGoodsType(gtype) {
  if (gtype not in goodsTypeToPurchTypeMap)
    logerr($"bqPurchaseInfo: Unknown goods type {gtype}")
  return goodsTypeToPurchTypeMap?[gtype] ?? ""
}

let mkBqPurchaseInfo = @(src, purchaseType, details) { from = src, status = purchaseType, params = details }

function sendBqEventOnOpenCurrencyShop(bqPurchaseInfo) {
  if (bqPurchaseInfo == null)
    return
  foreach (v in [ "id", "from", "status", "params" ])
    if (type(bqPurchaseInfo?[v]) != "string") {
      logerr($"bqPurchaseInfo: Key \"{v}\" must be string")
      return
    }
  sendUiBqEvent("open_currency_shop", bqPurchaseInfo)
}

return {
  PURCH_SRC_HANGAR
  PURCH_SRC_UNITS
  PURCH_SRC_LEVELUP
  PURCH_SRC_UNIT_UPGRADES
  PURCH_SRC_UNIT_MODS
  PURCH_SRC_PROFILE
  PURCH_SRC_SHOP
  PURCH_SRC_EVENT
  PURCH_SRC_BATTLE_PASS
  PURCH_SRC_SKINS
  PURCH_SRC_BOOSTERS

  PURCH_TYPE_UNIT
  PURCH_TYPE_UNIT_MOD
  PURCH_TYPE_UNIT_LEVEL
  PURCH_TYPE_CONSUMABLES
  PURCH_TYPE_PLAYER_LEVEL
  PURCH_TYPE_DECORATOR
  PURCH_TYPE_PREMIUM
  PURCH_TYPE_CURRENCY
  PURCH_TYPE_LOOTBOX
  PURCH_TYPE_BP_LEVEL
  PURCH_TYPE_SKIN
  PURCH_TYPE_BOOSTERS

  getPurchaseTypeByGoodsType
  mkBqPurchaseInfo
  sendBqEventOnOpenCurrencyShop
}
