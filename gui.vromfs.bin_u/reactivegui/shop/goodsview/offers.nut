from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { G_BATTLE_MOD } = require("%appGlobals/rewardType.nut")
let { getGoodsLocName, mkGoods } = require("%rGui/shop/goodsView/goods.nut")
let { mkOfferGold } = require("%rGui/shop/goodsView/goodsGold.nut")
let { mkOfferUnit, mkOfferBlueprint, mkOfferBranchUnit, mkOfferBattleMode } = require("%rGui/shop/goodsView/goodsUnit.nut")

let constructors = {
  [SGT_GOLD] = mkOfferGold,
  [SGT_UNIT] = mkOfferUnit,
  [SGT_BLUEPRINTS] = mkOfferBlueprint,
  [SGT_BRANCH] = mkOfferBranchUnit,
}

function mkOffer(offer, onClick, state) {
  let { rewards = null, battleMods = {} } = offer
  let hasBattleMode = rewards?.findvalue(@(r) r.gType == G_BATTLE_MOD) != null
    || battleMods.len() != 0 
  return hasBattleMode ? mkOfferBattleMode(offer, onClick, state)
    : (constructors?[offer.gtype](offer, onClick, state) ?? mkGoods(offer, onClick, state, null))
}

return {
  getOfferLocName = getGoodsLocName
  mkOffer
}