from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent
from "%rGui/shop/shopConst.nut" import SGT_UNKNOWN, SGT_UNIT, SGT_CONSUMABLES, SGT_PREMIUM, SGT_WP, SGT_EVT_CURRENCY,
  SGT_DECORATOR, SGT_DECALS, SGT_LOOTBOX, SGT_GOLD, SGT_PLATINUM, SGT_BOOSTERS, SGT_SLOTS, SGT_BLUEPRINTS,
  SGT_UNIT_BUNDLE, SGT_SKIN
from "types" import String










const PURCH_SRC_HANGAR = "hangar"
const PURCH_SRC_UNITS = "units_list"
const PURCH_SRC_LEVELUP = "level_up"
const PURCH_SRC_UNIT_UPGRADES = "unit_upgrades"
const PURCH_SRC_UNIT_MODS = "unit_mods"
const PURCH_SRC_UNIT_RESEARCH = "unit_research"
const PURCH_SRC_PROFILE = "profile"
const PURCH_SRC_SHOP = "shop"
const PURCH_SRC_EVENT = "event"
const PURCH_SRC_BATTLE_PASS = "battle_pass"
const PURCH_SRC_EVENT_PASS = "event_pass"
const PURCH_SRC_OPERATION_PASS = "operation_pass"
const PURCH_SRC_SKINS = "skins"
const PURCH_SRC_BOOSTERS = "boosters"
const PURCH_SRC_SLOTBAR = "slotbar"
const PURCH_SRC_SLOT_UPGRADES = "slot_upgrades"
const PURCH_SRC_BLUEPRINTS = "blueprints"
const PURCH_SRC_BRANCH = "branch"
const PURCH_SRC_DECALS = "decals"
const PURCH_SRC_RESET_SLOT_LEVEL = "reset_slot_lvl"
const PURCH_SRC_DEBRIEFING = "debriefing"

const PURCH_TYPE_UNIT = "unit"
const PURCH_TYPE_UNIT_MOD = "unit_mod"
const PURCH_TYPE_UNIT_LEVEL = "unit_level"
const PURCH_TYPE_UNIT_EXP = "unit_exp"
const PURCH_TYPE_BP_LEVEL = "bp_level"
const PURCH_TYPE_EP_LEVEL = "ep_level"
const PURCH_TYPE_OP_LEVEL = "op_level"
const PURCH_TYPE_CONSUMABLES = "consumables"
const PURCH_TYPE_PLAYER_LEVEL = "player_level"
const PURCH_TYPE_DECORATOR = "player_decorator"
const PURCH_TYPE_PREMIUM = "premium"
const PURCH_TYPE_CURRENCY = "currency"
const PURCH_TYPE_LOOTBOX = "lootbox"
const PURCH_TYPE_SKIN = "skin"
const PURCH_TYPE_BOOSTERS = "boosters"
const PURCH_TYPE_MINI_EVENT = "mini_event"
const PURCH_TYPE_SLOT = "slot"
const PURCH_TYPE_GOODS_SLOT = "goods_slot"
const PURCH_TYPE_GOODS_LIMIT = "goods_limit"
const PURCH_TYPE_GOODS_REROLL_SLOTS = "goods_reroll_slots"
const PURCH_TYPE_SLOT_LEVEL = "slot_level"
const PURCH_TYPE_BLUEPRINTS = "blueprints"
const PURCH_TYPE_UNIT_BUNDLE = "unit_bundle"
const PURCH_TYPE_QUEUE_PENALTY = "queue_penalty"
const PURCH_TYPE_DECAL = "decal"
const PURCH_TYPE_QUEST_REROLL = "quest_reroll"
const PURCH_TYPE_RESET_SLOT_LEVEL = "reset_slot_lvl"

let goodsTypeToPurchTypeMap = {
  [SGT_UNKNOWN] = "unknown",
  [SGT_UNIT] = PURCH_TYPE_UNIT,
  [SGT_SKIN] = PURCH_TYPE_SKIN,
  [SGT_DECALS] = PURCH_TYPE_DECAL,
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
  [SGT_UNIT_BUNDLE] = PURCH_TYPE_UNIT_BUNDLE
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
    if (!(bqPurchaseInfo?[v] instanceof String)) {
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
  PURCH_SRC_EVENT_PASS
  PURCH_SRC_OPERATION_PASS
  PURCH_SRC_SKINS
  PURCH_SRC_BOOSTERS
  PURCH_SRC_SLOTBAR
  PURCH_SRC_SLOT_UPGRADES
  PURCH_SRC_BLUEPRINTS
  PURCH_SRC_BRANCH
  PURCH_SRC_DECALS
  PURCH_SRC_RESET_SLOT_LEVEL
  PURCH_SRC_DEBRIEFING

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
  PURCH_TYPE_EP_LEVEL
  PURCH_TYPE_OP_LEVEL
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
  PURCH_TYPE_DECAL
  PURCH_TYPE_QUEST_REROLL
  PURCH_TYPE_RESET_SLOT_LEVEL

  getPurchaseTypeByGoodsType
  mkBqPurchaseInfo
  sendBqEventOnOpenCurrencyShop
}
