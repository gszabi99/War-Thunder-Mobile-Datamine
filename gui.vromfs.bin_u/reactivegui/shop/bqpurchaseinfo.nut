from "%globalsDarg/darg_library.nut" import *
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { SGT_UNKNOWN, SGT_UNIT, SGT_CONSUMABLES, SGT_PREMIUM, SGT_WP, SGT_EVT_CURRENCY, SGT_DECORATOR
  SGT_LOOTBOX, SGT_GOLD, SGT_PLATINUM, SGT_BOOSTERS, SGT_SLOTS, SGT_BLUEPRINTS, SGT_BRANCH
} = require("%rGui/shop/shopConst.nut")









let PURCH_SRC_HANGAR = "hangar"
let PURCH_SRC_UNITS = "units_list"
let PURCH_SRC_LEVELUP = "level_up"
let PURCH_SRC_UNIT_UPGRADES = "unit_upgrades"
let PURCH_SRC_UNIT_MODS = "unit_mods"
let PURCH_SRC_UNIT_RESEARCH = "unit_research"
let PURCH_SRC_PROFILE = "profile"
let PURCH_SRC_SHOP = "shop"
let PURCH_SRC_EVENT = "event"
let PURCH_SRC_BATTLE_PASS = "battle_pass"
let PURCH_SRC_SKINS = "skins"
let PURCH_SRC_BOOSTERS = "boosters"
let PURCH_SRC_SLOTBAR = "slotbar"
let PURCH_SRC_SLOT_UPGRADES = "slot_upgrades"
let PURCH_SRC_BLUEPRINTS = "blueprints"
let PURCH_SRC_BRANCH = "branch"

let PURCH_TYPE_UNIT = "unit"
let PURCH_TYPE_UNIT_MOD = "unit_mod"
let PURCH_TYPE_UNIT_LEVEL = "unit_level"
let PURCH_TYPE_UNIT_EXP = "unit_exp"
let PURCH_TYPE_BP_LEVEL = "bp_level"
let PURCH_TYPE_CONSUMABLES = "consumables"
let PURCH_TYPE_PLAYER_LEVEL = "player_level"
let PURCH_TYPE_DECORATOR = "player_decorator"
let PURCH_TYPE_PREMIUM = "premium"
let PURCH_TYPE_CURRENCY = "currency"
let PURCH_TYPE_LOOTBOX = "lootbox"
let PURCH_TYPE_SKIN = "skin"
let PURCH_TYPE_BOOSTERS = "boosters"
let PURCH_TYPE_MINI_EVENT = "mini_event"
let PURCH_TYPE_SLOT = "slot"
let PURCH_TYPE_GOODS_SLOT = "goods_slot"
let PURCH_TYPE_GOODS_LIMIT = "goods_limit"
let PURCH_TYPE_GOODS_REROLL_SLOTS = "goods_reroll_slots"
let PURCH_TYPE_SLOT_LEVEL = "slot_level"
let PURCH_TYPE_BLUEPRINTS = "blueprints"
let PURCH_TYPE_BRANCH = "branch"
let PURCH_TYPE_QUEUE_PENALTY = "queue_penalty"

let goodsTypeToPurchTypeMap = {
  [SGT_UNKNOWN] = "unknown",
  [SGT_UNIT] = PURCH_TYPE_UNIT,
  [SGT_CONSUMABLES] = PURCH_TYPE_CONSUMABLES,
  [SGT_PREMIUM] = PURCH_TYPE_PREMIUM,
  [SGT_WP] = PURCH_TYPE_CURRENCY,
  [SGT_PLATINUM] = PURCH_TYPE_CURRENCY,
  [SGT_GOLD] = PURCH_TYPE_CURRENCY,
  [SGT_EVT_CURRENCY] = PURCH_TYPE_CURRENCY,
  [SGT_LOOTBOX] = PURCH_TYPE_LOOTBOX,
  [SGT_BOOSTERS] = PURCH_TYPE_BOOSTERS,
  [SGT_SLOTS] = PURCH_TYPE_GOODS_SLOT,
  [SGT_BLUEPRINTS] = PURCH_TYPE_BLUEPRINTS,
  [SGT_DECORATOR] = PURCH_TYPE_DECORATOR,
  [SGT_BRANCH] = PURCH_TYPE_BRANCH
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
  PURCH_SRC_UNIT_RESEARCH
  PURCH_SRC_PROFILE
  PURCH_SRC_SHOP
  PURCH_SRC_EVENT
  PURCH_SRC_BATTLE_PASS
  PURCH_SRC_SKINS
  PURCH_SRC_BOOSTERS
  PURCH_SRC_SLOTBAR
  PURCH_SRC_SLOT_UPGRADES
  PURCH_SRC_BLUEPRINTS
  PURCH_SRC_BRANCH

  PURCH_TYPE_UNIT
  PURCH_TYPE_UNIT_MOD
  PURCH_TYPE_UNIT_LEVEL
  PURCH_TYPE_UNIT_EXP
  PURCH_TYPE_CONSUMABLES
  PURCH_TYPE_PLAYER_LEVEL
  PURCH_TYPE_DECORATOR
  PURCH_TYPE_PREMIUM
  PURCH_TYPE_CURRENCY
  PURCH_TYPE_LOOTBOX
  PURCH_TYPE_BP_LEVEL
  PURCH_TYPE_SKIN
  PURCH_TYPE_BOOSTERS
  PURCH_TYPE_MINI_EVENT
  PURCH_TYPE_SLOT
  PURCH_TYPE_GOODS_SLOT
  PURCH_TYPE_GOODS_LIMIT
  PURCH_TYPE_GOODS_REROLL_SLOTS
  PURCH_TYPE_SLOT_LEVEL
  PURCH_TYPE_BLUEPRINTS
  PURCH_TYPE_QUEUE_PENALTY

  getPurchaseTypeByGoodsType
  mkBqPurchaseInfo
  sendBqEventOnOpenCurrencyShop
}
