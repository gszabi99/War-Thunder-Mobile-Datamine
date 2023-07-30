//checked for explicitness
#no-root-fallback
#explicit-this

from "%globalScripts/logs.nut" import *
let { Watched } = require("frp")
let eventbus = require("eventbus")
let { rnd_int } = require("dagor.random")
let servProfile = require("servProfile.nut")
let { updateAllConfigs } = require("servConfigs.nut")


const PROGRESS_UNIT = "UnitInProgress"
const PROGRESS_REWARD = "RewardInProgress"
const PROGRESS_SHOP = "ShopPurchaseInProgress"
const PROGRESS_SCH_REWARD = "SchRewardInProgress"
const PROGRESS_LOOTBOX = "LootboxInProgress"


let requestData = persist("requestData", @() { id = rnd_int(0, 32767), callbacks = {} })

let function handleMessages(msg) {
  let result = msg.data?.result
  let cb = requestData.callbacks?[msg.id]

  if (!result) {
    let errorStr = msg.data?.error?.message ?? msg.data?.error ?? "unknown error"
    if (cb)
      cb({ error = errorStr })
    return
  }

  updateAllConfigs(result)

  if (!(result?.isCustom ?? false))
    if (result?.full ?? false) {
      log("Full servProfile received")
      servProfile(result)
    }
    else {
      let newProfile = clone servProfile.value
      local hasChanges = false
      foreach (k, v in result)
        if (type(v) != "table" || k == "configs")
          continue
        else {
          if (k == "receivedLevelsRewards") {
            let curV = clone (newProfile?[k] ?? {})
            foreach (camp, list in v)
              curV[camp] <- (camp in curV) ? curV[camp].__merge(list) : list
            newProfile[k] <- curV
          }
          else
            newProfile[k] <- (k in newProfile) ? newProfile[k].__merge(v) : v
          hasChanges = true
        }
      if (hasChanges)
        servProfile(newProfile)
    }

  if (cb) {
    delete requestData.callbacks[msg.id]
    cb(result)
  }
}

eventbus.subscribe("profile_srv.response", handleMessages)

let function request(data, cb = null) {
  requestData.id = requestData.id + 1
  let idStr = requestData.id.tostring()
  if (cb)
    requestData.callbacks[idStr] <- cb

  eventbus.send("profile_srv.request", { id = idStr, data })
}

let function mkProgress(id) {
  let res = Watched(null)
  let upd = @(msg) res(msg.isInProgress ? msg.value : null)
  eventbus.subscribe($"profile_srv.progressStart.{id}", upd)
  res.whiteListMutatorClosure(upd)
  return res
}

return {
  unitInProgress = mkProgress(PROGRESS_UNIT)
  rewardInProgress = mkProgress(PROGRESS_REWARD)
  shopPurchaseInProgress = mkProgress(PROGRESS_SHOP)
  schRewardInProgress = mkProgress(PROGRESS_SCH_REWARD)
  lootboxInProgress = mkProgress(PROGRESS_LOOTBOX)

  get_profile  = @(sysInfo = {}, cb = null) request({
    method = "get_profile"
    params = { sysInfo }
  }, cb)
  get_all_configs = @(cb = null) request({ method = "get_all_configs" }, cb)
  check_purchases = @(cb = null) request({ method = "check_purchases" }, cb)
  reset_profile = @(cb = null) request({ method = "reset_profile" }, cb)
  reset_profile_with_stats = @(cb = null) request({ method = "reset_profile_with_stats" }, cb)
  get_default_battle_data = @(cb = null) request({ method = "get_default_battle_data" }, cb)
  unlock_all_common_units = @(cb = null) request({ method = "unlock_all_common_units" }, cb)
  unlock_all_premium_units = @(cb = null) request({ method = "unlock_all_premium_units" }, cb)
  unlock_all_units = @(cb = null) request({ method = "unlock_all_units" }, cb)
  generate_full_offline_profile = @(cb = null) request({ method = "generate_full_offline_profile" }, cb)

  add_player_exp = @(campaign, playerExp, cb = null) request({
    method = "add_player_exp"
    params = { campaign, playerExp }
  }, cb)

  get_player_level_rewards = @(campaign, level, cb = null) request({
    method = "get_player_level_rewards"
    params = { campaign, level }
    progressId = PROGRESS_REWARD
    progressValue = level
  }, cb)

  set_current_campaign = @(campaign, cb = null) request({
    method = "set_current_campaign"
    params = { campaign }
  }, cb)

  add_unit_exp = @(unitName, exp, cb = null) request({
    method = "add_unit_exp"
    params = { unitName, exp }
  }, cb)

  set_seen_player_level = @(campaign, level, cb = null) request({
    method = "set_seen_player_level"
    params = { campaign, level }
  }, cb)

  set_seen_unit_level = @(unitName, level, cb = null) request({
    method = "set_seen_unit_level"
    params = { unitName, level }
  }, cb)

  buy_unit = @(unitName, currencyId, price, cb = null) request({
    method = "buy_unit"
    params = { unitName, currencyId, price }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  levelup_without_unit = @(campaign, cb = null) request({
    method = "levelup_without_unit"
    params = { campaign }
  }, cb)

  halt_unit_purchase = @(unitName, cb = null) request({
    method = "halt_unit_purchase"
    params = { unitName }
  }, cb)

  set_current_unit = @(unitName, cb = null) request({
    method = "set_current_unit"
    params = { unitName }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  add_unit = @(unitName, cb = null) request({
    method = "add_unit"
    params = { unitName }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  remove_unit = @(unitName, cb = null) request({
    method = "remove_unit"
    params = { unitName }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  upgrade_unit = @(unitName, cb = null) request({
    method = "upgrade_unit"
    params = { unitName }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  downgrade_unit = @(unitName, cb = null) request({
    method = "downgrade_unit"
    params = { unitName }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  get_battle_data = @(unitId, cb = null) request({
    method = "get_battle_data"
    params = { unitId }
  }, cb)

  get_battle_data_jwt = @(unitId, cb = null) request({
    method = "get_battle_data_jwt"
    params = { unitId }
  }, cb)

  get_queue_data = @(unitName, cb = null) request({
    method = "get_queue_data"
    params = { unitName }
  }, cb)

  get_queue_data_jwt = @(unitName, cb = null) request({
    method = "get_queue_data_jwt"
    params = { unitName }
  }, cb)

  add_unit_attributes = @(unitName, attributes, totalSpCost, cb = null) request({
    method = "add_unit_attributes"
    params = { unitName, attributes, totalSpCost }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  buy_unit_mod = @(unitName, modName, currencyId, price, cb = null) request({
    method = "buy_unit_mod"
    params = { unitName, modName, currencyId, price }
  }, cb)

  enable_unit_mod = @(unitName, modName, enable, cb = null) request({
    method = "enable_unit_mod"
    params = { unitName, modName, enable }
  }, cb)

  buy_unit_weapon = @(unitName, weaponName, price, cb = null) request({
    method = "buy_unit_weapon"
    params = { unitName, weaponName, price }
  }, cb)

  set_current_unit_weapon = @(unitName, weaponName, cb = null) request({
    method = "set_current_unit_weapon"
    params = { unitName, weaponName }
  }, cb)

  add_premium = @(duration, cb = null) request({
    method = "add_premium"
    params = { duration }
  }, cb)

  remove_premium = @(duration, cb = null) request({
    method = "remove_premium"
    params = { duration }
  }, cb)

  buy_player_level = @(campaign, curLevel, expLeft, price, cb = null) request({
    method = "buy_player_level"
    params = { campaign, curLevel, expLeft, price }
  }, cb)

  buy_unit_level = @(unitName, curLevel, tgtLevel, expLeft, price, cb = null) request({
    method = "buy_unit_level"
    params = { unitName, curLevel, tgtLevel, expLeft, price }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  cheat_get_goods = @(shopId, cb = null) request({
    method = "cheat_get_goods"
    params = { shopId }
  }, cb)

  buy_goods = @(shopId, currencyId, price, cb = null) request({
    method = "buy_goods"
    params = { shopId, currencyId, price }
    progressId = PROGRESS_SHOP
    progressValue = shopId
  }, cb)

  halt_goods_purchase = @(shopId, cb = null) request({
    method = "halt_goods_purchase"
    params = { shopId }
  }, cb)

  debug_apply_items_in_battle = @(items, cb = null) request({
    method = "debug_apply_items_in_battle"
    params = { items }
  }, cb)

  change_item_count = @(name, count, cb = null) request({
    method = "change_item_count"
    params = { name, count }
  }, cb)

  userstat_add_item = @(itemdef, count, cb = null) request({
    method = "userstat_add_item"
    params = { itemdef, count }
  }, cb)

  add_wp = @(count, cb = null) request({
    method = "add_wp"
    params = { count }
  }, cb)

  add_gold = @(count, cb = null) request({
    method = "add_gold"
    params = { count }
  }, cb)

  apply_client_mission_reward = @(campaign, missionId, cb = null) request({
    method = "apply_client_mission_reward"
    params = { campaign, missionId }
  }, cb)

  apply_scheduled_reward = @(rewardId, cb = null) request({
    method = "apply_scheduled_reward"
    params = { rewardId }
    progressId = PROGRESS_SCH_REWARD
    progressValue = rewardId
  }, cb)

  reset_scheduled_reward_timers = @(cb = null) request({
    method = "reset_scheduled_reward_timers"
  }, cb)

  send_to_bq = @(tableId, info, cb = null) request({
    method = "send_to_bq"
    params = { tableId, info }
  }, cb)

  send_to_bq_offer = @(campaign, info, cb = null) request({
    method = "send_to_bq_offer"
    params = { campaign, info }
  }, cb)

  clear_unseen_purchases = @(list, cb = null) request({
    method = "clear_unseen_purchases"
    params = { list }
  }, cb)

  set_purch_player_type = @(playerType, cb = null) request({
    method = "set_purch_player_type"
    params = { playerType }
  }, cb)

  check_new_offer = @(campaign, cb = null) request({
    method = "check_new_offer"
    params = { campaign }
  }, cb)

  debug_offer_generation_stats = @(campaign, cb = null) request({
    method = "debug_offer_generation_stats"
    params = { campaign }
  }, cb)

  shift_all_offers_time = @(time, cb = null) request({
    method = "shift_all_offers_time"
    params = { time }
  }, cb)

  generate_fixed_type_offer = @(campaign, offerType, cb = null) request({
    method = "generate_fixed_type_offer"
    params = { campaign, offerType }
  }, cb)

  open_lootbox = @(id, cb = null) request({
    method = "open_lootbox"
    params = { id }
    progressId = PROGRESS_LOOTBOX
    progressValue = id
  }, cb)
}
