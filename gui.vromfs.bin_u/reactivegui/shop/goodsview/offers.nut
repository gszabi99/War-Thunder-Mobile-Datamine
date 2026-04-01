from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { G_BATTLE_MOD } = require("%appGlobals/rewardType.nut")
let { getGoodsLocName, mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { mkOfferGold } = require("%rGui/shop/goodsView/goodsGold.nut")
let { mkOfferUnit, mkOfferBlueprint, mkOfferBranchUnit, mkOfferBattleMode } = require("%rGui/shop/goodsView/goodsUnit.nut")
let { mkOfferLootbox } = require("%rGui/shop/goodsView/goodsLootbox.nut")

let constructors = {
  [SGT_GOLD] = mkOfferGold,
  [SGT_UNIT] = mkOfferUnit,
  [SGT_BLUEPRINTS] = mkOfferBlueprint,
  [SGT_BRANCH] = mkOfferBranchUnit,
  [SGT_LOOTBOX] = mkOfferLootbox,
}

function mkOffer(offer, onClick, state) {
  let { rewards } = offer
  let hasBattleMode = rewards.findvalue(@(r) r.gType == G_BATTLE_MOD) != null
  return hasBattleMode ? mkOfferBattleMode(offer, onClick, state)
    : (constructors?[getGoodsType(offer)](offer, onClick, state) ?? mkGoods(offer, onClick, state, null))
}

return {
  getOfferLocName = getGoodsLocName
  mkOffer
}