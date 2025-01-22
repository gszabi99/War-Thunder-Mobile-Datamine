from "%globalScripts/logs.nut" import *
let { Watched } = require("frp")
let { eventbus_send,eventbus_subscribe } = require("eventbus")
let { rnd_int } = require("dagor.random")
let { loc } = require("dagor.localize")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let servProfile = require("servProfile.nut")
let { updateAllConfigs } = require("servConfigs.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")


const PROGRESS_UNIT = "UnitInProgress"
const PROGRESS_CUR_UNIT = "CurUnitInProgress"
const PROGRESS_REWARD = "RewardInProgress"
const PROGRESS_SHOP = "ShopPurchaseInProgress"
const PROGRESS_SHOP_SLOT = "ShopGenSlotInProgress"
const PROGRESS_DECORATORS = "DecoratorInProgress"
const PROGRESS_SCH_REWARD = "SchRewardInProgress"
const PROGRESS_LOOTBOX = "LootboxInProgress"
const PROGRESS_LEVEL = "LevelInProgress"
const PROGRESS_MODS = "ModsInProgress"
const PROGRESS_SKINS = "SkinsInProgress"
const PROGRESS_BOOSTER = "BoosterInProgress"
const PROGRESS_SLOT = "SlotInProgress"
const PROGRESS_PERSONAL_GOODS = "PersonalGoodsInProgress"

let handlers = {}
let requestData = persist("requestData", @() { id = rnd_int(0, 32767), callbacks = {} })
let lastProfileKeysUpdated = Watched({})
let progressList = {}
let progressUpdate = {}


function call(id, result, context) {
  if (id not in handlers)
    return
  let handler = handlers[id]
  if (handler.getfuncinfos().parameters.len() == 2)
    handler(result)
  else
    handler(result, context)
}

function callAll(execData, result) {
  if (type(execData) == "string") {
    call(execData, result, null)
    return
  }
  if (type(execData) == "array") {
    foreach(e in execData)
      callAll(e, result)
    return
  }
  if (type(execData) != "table")
    return

  let { id = null, executeAfter = null } = execData
  call(id, result, execData)
  if (executeAfter != null)
    callAll(executeAfter, result)
}

function popCallback(uid, result) {
  if (uid in requestData.callbacks)
    callAll(requestData.callbacks.$rawdelete(uid), result)
}

function handleMessages(msg) {
  let result = msg.data?.result
  if (!result) {
    popCallback(msg.id, { error = "unknown error" }.__update(type(msg.data) == "table" ? msg.data : { data = msg.data }))
    return
  }

  updateAllConfigs(result)

  if (!(result?.isCustom ?? false))
    if (result?.full ?? false) {
      log("Full servProfile received")
      if ("removed" in result)
        logerr($"Not empty removed field on full profile update on '{msg?.method}'")
      servProfile(result)
      lastProfileKeysUpdated(result
        .map(@(v, k) type(v) == "table" && k != "configs")
        .filter(@(v) v))
    }
    else {
      let newProfile = clone servProfile.value
      let updatedKeys = {}
      foreach (k, v in result)
        if (type(v) != "table" || k == "configs" || k == "removed")
          continue
        else {
          if (k == "receivedLvlRewards") {
            let curV = clone (newProfile?[k] ?? {})
            foreach (camp, list in v)
              curV[camp] <- (camp in curV) ? curV[camp].__merge(list) : list
            newProfile[k] <- curV
          }
          else
            newProfile[k] <- (k in newProfile) ? newProfile[k].__merge(v) : v
          updatedKeys[k] <- true
        }
      foreach(k, list in result?.removed ?? {})
        if (k in newProfile) {
          newProfile[k] = clone newProfile[k]
          foreach(id in list)
            if (id in newProfile[k])
              newProfile[k].$rawdelete(id)
          updatedKeys[k] <- true
        }
      if (updatedKeys.len() != 0) {
        servProfile(newProfile)
        lastProfileKeysUpdated(updatedKeys)
      }
    }

  popCallback(msg.id, result)
}

lastProfileKeysUpdated.whiteListMutatorClosure(handleMessages)

eventbus_subscribe("profile_srv.response", handleMessages)

function checkHandlerId(id) {
  if (id not in handlers)
    logerr($"Not registered pServerApi callbakc id: {id}")
}

function addCallback(idStr, cb) {
  if (type(cb) == "string") {
    requestData.callbacks[idStr] <- cb
    checkHandlerId(cb)
  }
  else if (type(cb) == "table") {
    if (type(cb?.id) == "string") {
      requestData.callbacks[idStr] <- cb
      checkHandlerId(cb.id)
    } else
      logerr($"Bad type of pServerApi callback id: {type(cb?.id)}. String required.")
  }
  else if (type(cb) == "array")
    requestData.callbacks[idStr] <- cb
  else
    logerr($"Bad type of pServerApi callback data: {type(cb)}. String, table or array required")
}

function onProgressChange(id, value, isInProgress) {
  let update = progressUpdate?[id]
  let watch = progressList?[id]
  if (update == null || watch == null)
    return
  update(watch, isInProgress, value)
}

eventbus_subscribe($"profile_srv.progressChange", @(m) onProgressChange(m.id, m.value, m.isInProgress))

function request(data, cb = null) {
  requestData.id = requestData.id + 1
  let idStr = requestData.id.tostring()
  if (cb != null)
    addCallback(idStr, cb)

  let { progressId = null, progressValue = null } = data
  if (progressId != null)
    onProgressChange(progressId, progressValue, true)

  eventbus_send("profile_srv.request", { id = idStr, data })
}

function mkProgressImpl(id, update, defValue = null) {
  if (id in progressUpdate)
    logerr($"Duplicate pServerApi progress create {id}")
  else {
    progressUpdate[id] <- update
    progressList[id] <- hardPersistWatched($"pServerApi.progress.{id}", defValue)
    progressList[id].whiteListMutatorClosure(update)
  }
  return progressList[id]
}

let mkProgress = @(id) mkProgressImpl(id, @(watch, isInProgress, value) watch.set(isInProgress ? value : null))

let mkMultiProgress = @(id) mkProgressImpl(id,
  function(watch, isInProgress, value) {
    if ((watch.get()?[value] ?? false) == isInProgress)
      return
    watch.mutate(function(v) {
      if (isInProgress)
        v[value] <- true
      else
        v.$rawdelete(value)
    })
  },
  {})

function registerHandler(id, handler) {
  if (id in handlers) {
    logerr($"pServerApi handler {id} is already registered")
    return
  }
  let nargs = handler.getfuncinfos().parameters.len() - 1
  if (nargs == 1 || nargs == 2)
    handlers[id] <- handler
  else
    logerr($"pServerApi handler {id} has wrong number of parameters. Should be 1 or 2")
}

function localizePServerError(err) {
  if (type(err) == "table" && "message" in err) {
    let msg = loc($"error/{err.message}", err.message)
    let code = "code" in err ? $"(code: {err.code})" : ""
    return { bqLocId = err.message, text = "\n".join([msg, code], true) }
  }
  if (type(err) == "string")
    return { bqLocId = err, text = loc($"error/{err}", err) }
  return { bqLocId = "profile server internal error", text = loc("matching/SERVER_ERROR_INTERNAL") }
}

isAuthorized.subscribe(function(v) {
  if (v)
    return
  servProfile.set({})
  updateAllConfigs({ configs = {} })
})

return {
  registerHandler
  callHandler = callAll
  localizePServerError
  lastProfileKeysUpdated

  unitInProgress = mkProgress(PROGRESS_UNIT)
  curUnitInProgress = mkProgress(PROGRESS_CUR_UNIT)
  rewardInProgress = mkProgress(PROGRESS_REWARD)
  shopPurchaseInProgress = mkProgress(PROGRESS_SHOP)
  shopGenSlotInProgress = mkProgress(PROGRESS_SHOP_SLOT)
  decoratorInProgress = mkProgress(PROGRESS_DECORATORS)
  schRewardInProgress = mkMultiProgress(PROGRESS_SCH_REWARD)
  lootboxInProgress = mkProgress(PROGRESS_LOOTBOX)
  levelInProgress = mkProgress(PROGRESS_LEVEL)
  modsInProgress = mkProgress(PROGRESS_MODS)
  skinsInProgress = mkProgress(PROGRESS_SKINS)
  boosterInProgress = mkProgress(PROGRESS_BOOSTER)
  slotInProgress = mkProgress(PROGRESS_SLOT)
  personalGoodsInProgress = mkProgress(PROGRESS_PERSONAL_GOODS)

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
  royal_beta_units_unlock = @(cb = null) request({ method = "royal_beta_units_unlock" }, cb)
  generate_full_offline_profile = @(cb = null) request({ method = "generate_full_offline_profile" }, cb)

  add_player_exp = @(campaign, playerExp, cb = null) request({
    method = "add_player_exp"
    params = { campaign, playerExp }
  }, cb)

  add_decorator = @(name, cb = null) request({
    method = "add_decorator"
    params = { name }
  }, cb)

  set_current_decorator = @(name, cb = null) request({
    method = "set_current_decorator"
    params = { name }
    progressId = PROGRESS_DECORATORS
    progressValue = name
  }, cb)

  remove_decorator = @(name, cb = null) request({
    method = "remove_decorator"
    params = { name }
  }, cb)

  buy_decorator = @(name, currencyId, price, cb = null) request({
    method = "buy_decorator"
    params = { name, currencyId, price }
    progressId = PROGRESS_DECORATORS
    progressValue = name
  }, cb)

  unset_current_decorator = @(decorType , cb = null) request({
    method = "unset_current_decorator"
    params = { decorType }
    progressId = PROGRESS_DECORATORS
    progressValue = decorType
  }, cb)

  mark_decorators_seen = @(names, cb = null) request({
    method = "mark_decorators_seen"
    params = { names }
  }, cb)

  mark_decorators_unseen = @(names, cb = null) request({
    method = "mark_decorators_unseen"
    params = { names }
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

  add_slot_attributes = @(campaign, slotIdx, attributes, totalSpCost, cb = null) request({
    method = "add_slot_attributes"
    params = { campaign, slotIdx, attributes, totalSpCost }
    progressId = PROGRESS_SLOT
    progressValue = slotIdx
  }, cb)

  buy_slot_level = @(campaign, slotIdx, curLevel, tgtLevel, expLeft, price, cb = null) request({
    method = "buy_slot_level"
    params = { campaign, slotIdx, curLevel, tgtLevel, expLeft, price }
    progressId = PROGRESS_SLOT
    progressValue = slotIdx
  }, cb)

  add_slot_exp = @(campaign, slotIdx, exp, cb = null) request({
    method = "add_slot_exp"
    params = { campaign, slotIdx, exp }
  }, cb)

  buy_unit = @(unitName, currencyId, price, cb = null) request({
    method = "buy_unit"
    params = { unitName, currencyId, price }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  levelup_without_unit = @(campaign, cb = null) request({
    method = "levelup_without_unit"
    progressId = PROGRESS_LEVEL
    progressValue = campaign
    params = { campaign }
  }, cb)

  halt_unit_purchase = @(unitName, cb = null) request({
    method = "halt_unit_purchase"
    params = { unitName }
  }, cb)

  set_current_unit = @(unitName, cb = null) request({
    method = "set_current_unit"
    params = { unitName }
    progressId = PROGRESS_CUR_UNIT
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

  get_battle_data_for_overrided_preset = @(preset, unitList, cb = null)
    request({
      method = "get_battle_data_for_overrided_preset"
      params = { preset, unitList }
    }, cb)

  get_battle_data_jwt = @(unitId, cb = null) request({
    method = "get_battle_data_jwt"
    params = { unitId }
  }, cb)

  get_battle_data_slots_jwt = @(unitList, cb = null) request({
    method = "get_battle_data_slots_jwt"
    params = { unitList }
  }, cb)

  get_queue_data_jwt = @(unitName, cb = null) request({
    method = "get_queue_data_jwt"
    params = { unitName }
  }, cb)

  get_queue_data_slots_jwt = @(unitList, cb = null) request({
    method = "get_queue_data_slots_jwt"
    params = { unitList }
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
    progressId = PROGRESS_MODS
    progressValue = modName
  }, cb)

  enable_unit_mod = @(unitName, modName, enable, cb = null) request({
    method = "enable_unit_mod"
    params = { unitName, modName, enable }
    progressId = PROGRESS_MODS
    progressValue = modName
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
    progressId = PROGRESS_LEVEL
    progressValue = curLevel
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

  buy_goods = @(shopId, currencyId, price, count = 1, cb = null) request({
    method = "buy_goods"
    params = { shopId, currencyId, price, count }
    progressId = PROGRESS_SHOP
    progressValue = shopId
  }, cb)

  halt_goods_purchase = @(shopId, cb = null) request({
    method = "halt_goods_purchase"
    params = { shopId }
  }, cb)

  increase_goods_limit = @(goodsId, currencyId, price, cb = null) request({
    method = "increase_goods_limit"
    params = { goodsId, currencyId, price }
    progressId = PROGRESS_SHOP
    progressValue = goodsId
  }, cb)

  buy_goods_slot = @(goodsId, slotIdx, currencyId, price, cb = null) request({
    method = "buy_goods_slot"
    params = { goodsId, slotIdx, currencyId, price }
    progressId = PROGRESS_SHOP
    progressValue = goodsId
  }, cb)

  gen_goods_slots = @(goodsId, currencyId, price, cb = null) request({
    method = "gen_goods_slots"
    params = { goodsId, currencyId, price }
    progressId = PROGRESS_SHOP_SLOT
    progressValue = goodsId
  }, cb)

  reset_reward_slots = @(cb = null) request({ method = "reset_reward_slots" }, cb)

  debug_apply_items_in_battle = @(items, cb = null) request({
    method = "debug_apply_items_in_battle"
    params = { items }
  }, cb)

  change_item_count = @(name, count, cb = null) request({
    method = "change_item_count"
    params = { name, count }
  }, cb)

  userstat_add_item = @(itemdef, count, externalTag, cb = null) request({
    method = "userstat_add_item"
    params = { itemdef, count, externalTag }
  }, cb)

  add_currency_no_popup = @(currency, count, cb = null) request({
    method = "add_currency_no_popup"
    params = { currency, count }
  }, cb)

  apply_client_mission_reward = @(campaign, missionId, cb = null) request({
    method = "apply_client_mission_reward"
    params = { campaign, missionId }
  }, cb)

  apply_first_battles_reward = @(campaign, unitName, rewardId, kills, cb = null) request({
    method = "apply_first_battles_reward_v2"
    params = { campaign, unitName, rewardId, kills }
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

  check_empty_offer = @(campaign, cb = null) request({
    method = "check_empty_offer"
    params = { campaign }
  }, cb)

  update_branch_offer = @(campaign, cb = null) request({
    method = "update_branch_offer"
    params = { campaign }
  }, cb)

  check_new_offer = @(campaign, cb = null) request({
    method = "check_new_offer"
    params = { campaign }
  }, cb)

  buy_offer = @(campaign, offerId, currencyId, price, cb = null) request({
    method = "buy_offer"
    params = { campaign, offerId, currencyId, price }
    progressId = PROGRESS_SHOP
    progressValue = offerId
  }, cb)

  halt_offer_purchase = @(offerId, cb = null) request({
    method = "halt_offer_purchase"
    params = { offerId }
  }, cb)

  debug_offer_generation_stats = @(campaign, cb = null) request({
    method = "debug_offer_generation_stats"
    params = { campaign }
  }, cb)

  debug_offer_possible_units = @(cb = null) request({
    method = "debug_offer_possible_units"
    params = {}
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

  open_lootbox_several = @(id, count, cb = null) request({
    method = "open_lootbox_several"
    params = { id, count }
    progressId = PROGRESS_LOOTBOX
    progressValue = id
  }, cb)

  add_lootbox = @(id, count, cb = null) request({
    method = "add_lootbox"
    params = { id, count }
  }, cb)

  buy_lootbox = @(id, currencyId, price, count, cb = null) request({
    method = "buy_lootbox"
    params = { id, currencyId, price, count }
    progressId = PROGRESS_LOOTBOX
    progressValue = id
  }, cb)

  get_my_lootbox_chances = @(id, cb = null) request({
    method = "get_my_lootbox_chances"
    params = { id }
  }, cb)

  get_base_lootbox_chances = @(id, cb = null) request({
    method = "get_base_lootbox_chances"
    params = { id }
  }, cb)

  reset_lootbox_counters = @(id, cb = null) request({
    method = "reset_lootbox_counters"
    params = { id }
  }, cb)

  reset_mutations_timestamp = @(cb = null) request({ method = "reset_mutations_timestamp" }, cb)

  apply_profile_mutation = @(id, cb = null) request({
    method = "apply_profile_mutation"
    params = { id }
  }, cb)

  renew_ad_budget = @(cb = null) request({
    method = "renew_ad_budget"
    params = {}
  }, cb)

  speed_up_unlock_progress = @(id, cb = null) request({
    method = "speed_up_unlock_progress"
    params = { id }
  }, cb)

  enable_unit_skin = @(unitName, vehicleName, skinName, cb = null) request({
    method = "enable_unit_skin"
    params = { unitName, vehicleName, skinName }
    progressId = PROGRESS_SKINS
    progressValue = unitName
  }, cb)

  buy_unit_skin = @(unitName, skinName, currencyId, price, cb = null) request({
    method = "buy_unit_skin"
    params = { unitName, skinName, currencyId, price }
    progressId = PROGRESS_SKINS
    progressValue = unitName
  }, cb)

  add_all_skins_for_unit = @(unitName, cb = null) request({
    method = "add_all_skins_for_unit"
    params = { unitName }
    progressId = PROGRESS_SKINS
    progressValue = unitName
  }, cb)

  remove_all_skins_for_unit = @(unitName, cb = null) request({
    method = "remove_all_skins_for_unit"
    params = { unitName }
    progressId = PROGRESS_SKINS
    progressValue = unitName
  }, cb)

  add_boosters = @(list, cb = null) request({
    method = "add_boosters"
    params = { list }
  }, cb)

  debug_apply_boosters_in_battle = @(boosters, cb = null) request({
    method = "debug_apply_boosters_in_battle"
    params = { boosters }
  }, cb)

  debug_apply_unit_daily_bonus_in_battle = @(unitName, cb = null) request({
    method = "debug_apply_unit_daily_bonus_in_battle"
    params = { unitName }
  }, cb)

  debug_reset_all_unit_daily_bonus = @(cb = null) request({
    method = "debug_reset_all_unit_daily_bonus"
    params = {}
  }, cb)

  buy_booster = @(name, currencyId, price, cb = null) request({
    method = "buy_booster"
    params = { name, currencyId, price }
    progressId = PROGRESS_BOOSTER
    progressValue = name
  }, cb)

  toggle_booster_activation = @(name, isDisabled, cb = null) request({
    method = "toggle_booster_activation"
    params = { name, isDisabled }
    progressId = PROGRESS_BOOSTER
    progressValue = name
  }, cb)

  add_blueprints = @(name, count, cb = null) request({
    method = "add_blueprints"
    params = { name, count }
    progressId = PROGRESS_UNIT
    progressValue = name
  }, cb)

  add_battle_mod = @(id, time, cb = null) request({
    method = "add_battle_mod"
    params = { id, time }
  }, cb)

  set_unit_to_slot = @(unitName, slotId, cb = null) request({
    method = "set_unit_to_slot"
    params = { unitName, slotId }
  }, cb)

  clear_unit_slot = @(campaign, slotId, cb = null) request({
    method = "clear_unit_slot"
    params = { campaign, slotId }
  }, cb)

  buy_unit_slot = @(campaign, slotId, costGold, cb = null) request({
    method = "buy_unit_slot"
    params = { campaign, slotId, costGold }
  }, cb)

  set_research_unit = @(campaign, unitName, cb = null) request({
    method = "set_research_unit"
    params = { campaign, unitName }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  buy_unit_research = @(unitName, campaign, costGold, exp, cb = null) request({
    method = "buy_unit_research"
    params = { unitName, campaign, costGold, exp }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  apply_prize_tickets = @(id, rewardIndexes, cb = null) request({
    method = "apply_prize_tickets"
    params = { id, rewardIndexes }
    progressId = PROGRESS_REWARD
    progressValue = rewardIndexes
  }, cb)

  apply_unit_level_rewards = @(unitName, campaign, cb = null)  request({
    method = "apply_unit_level_rewards"
    params = { unitName, campaign }
    progressId = PROGRESS_UNIT
    progressValue = unitName
  }, cb)

  check_new_personal_goods = @(cb = null) request({
    method = "check_new_personal_goods"
    progressId = PROGRESS_PERSONAL_GOODS
    progressValue = ""
  }, cb)

  shift_all_personal_goods_time = @(time, cb = null) request({
    method = "shift_all_personal_goods_time"
    params = { time }
    progressId = PROGRESS_PERSONAL_GOODS
    progressValue = ""
  }, cb)

  buy_personal_goods = @(goodsId, groupId, variantId, currencyId, price, cb = null) request({
    method = "buy_personal_goods"
    params = { goodsId, groupId, variantId, currencyId, price }
    progressId = PROGRESS_PERSONAL_GOODS
    progressValue = ""
  }, cb)

  halt_personal_goods_purchase = @(goodsId, cb = null) request({
    method = "halt_personal_goods_purchase"
    params = { goodsId }
    progressId = PROGRESS_PERSONAL_GOODS
    progressValue = ""
  }, cb)

  apply_deeplink_reward = @(id, campaign, cb = null) request({
    method = "apply_deeplink_reward"
    params = { id, campaign }
  }, cb)

  authorize_deeplink_reward = @(id, cb = null) request({
    method = "authorize_deeplink_reward"
    params = { id }
  }, cb)
}
