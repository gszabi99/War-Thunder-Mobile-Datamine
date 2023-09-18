from "%globalsDarg/darg_library.nut" import *
let pServerApi = require("%appGlobals/pServer/pServerApi.nut")
let { add_unit_exp, add_player_exp, add_wp, add_gold, change_item_count, set_purch_player_type,
  check_new_offer, debug_offer_generation_stats, shift_all_offers_time, generate_fixed_type_offer,
  userstat_add_item, add_premium, remove_premium, add_unit, remove_unit, registerHandler,
  add_decorator, set_current_decorator, remove_decorator, unset_current_decorator,
  apply_profile_mutation, add_lootbox, add_warbond, add_event_key
} = pServerApi
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { resetCustomSettings } = require("%appGlobals/customSettings.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { register_command } = require("console")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")

registerHandler("consolePrintResult",
  @(res) console_print(res?.error == null ? "SUCCESS" : "FAILED")) //warning disable: -forbidden-function
registerHandler("consolePrint", console_print) //warning disable: -forbidden-function

register_command(function(exp) {
  let name = hangarUnitName.value
  if (name not in allUnitsCfg.value)
    return $"Unit '{name}' not exists"
  if (name not in myUnits.value)
    return $"Unit '{name}' not own"
  add_unit_exp(name, exp, "consolePrintResult")
}, "meta.add_cur_unit_exp")

register_command(@() resetCustomSettings(), "meta.reset_custom_settings")

register_command(@(exp) add_player_exp(curCampaign.value, exp, "consolePrintResult"), "meta.add_player_exp")
register_command(@(wp) add_wp(wp, "consolePrintResult"), "meta.add_wp")
register_command(@(gold) add_gold(gold, "consolePrintResult"), "meta.add_gold")
register_command(@(warbond) add_warbond(warbond, "consolePrintResult"), "meta.add_warbond")
register_command(@(event_key) add_event_key(event_key, "consolePrintResult"), "meta.add_event_key")
register_command(@(name, count) change_item_count(name, count, "consolePrintResult"), "meta.change_item_count")
register_command(@(id, count) userstat_add_item(id, count, "consolePrintResult"), "meta.userstat_add_item")
register_command(@(seconds) seconds < 0
    ? remove_premium(-seconds, "consolePrintResult")
    : add_premium(seconds, "consolePrintResult"),
  "meta.add_premium")
register_command(@(unitName) add_unit(unitName, "consolePrintResult"), "meta.add_unit")
register_command(@(unitName) remove_unit(unitName, "consolePrintResult"), "meta.remove_unit")
register_command(@() add_unit(hangarUnitName.value, "consolePrintResult"), "meta.add_hangar_unit")
register_command(@() remove_unit(hangarUnitName.value, "consolePrintResult"), "meta.remove_hangar_unit")

register_command(@(name) set_current_decorator(name, "consolePrintResult"), "meta.set_current_decorator")
register_command(@(name) add_decorator(name, "consolePrintResult"), "meta.add_decorator")
register_command(@(name) remove_decorator(name, "consolePrintResult"), "meta.remove_decorator")
register_command(@(name) unset_current_decorator(name, "consolePrintResult"), "meta.unset_current_decorator")
register_command(@(id) apply_profile_mutation(id, "consolePrintResult"), "meta.apply_profile_mutation")
register_command(@(id) add_lootbox(id, 1, "consolePrintResult"), "meta.add_lootbox")
register_command(@(id, count) add_lootbox(id, count, "consolePrintResult"), "meta.add_lootbox_several")

register_command(function(count) {
  add_wp(count * 100)
  add_gold(count * 10)
  add_warbond(count * 10)
  add_event_key(count * 1)
  foreach (item in itemsOrderFull)
    change_item_count(item, count)

  let seconds = count * 60
  if (seconds < 0)
    remove_premium(-seconds, "consolePrintResult")
  else
    add_premium(seconds, "consolePrintResult")
}, "meta.add_all_items_and_currency")

registerHandler("onCheatShiftTime", @(_) check_new_offer(curCampaign.value, "consolePrintResult"))

register_command(@() shift_all_offers_time(86400, "onCheatShiftTime"),
  "meta.gen_next_day_offer")
register_command(@() debug_offer_generation_stats(curCampaign.value, "consolePrint"),
  "meta.debug_offer_generation_stats")
foreach (ot in ["start", "gold", "collection", "sidegrade", "upgrade"]) {
  let offerType = ot
  register_command(@() generate_fixed_type_offer(curCampaign.value, offerType, "consolePrintResult"),
    $"meta.generate_offer_{offerType}")
}

foreach (cmd in ["get_all_configs", "reset_profile", "reset_profile_with_stats",
  "unlock_all_common_units", "unlock_all_premium_units", "unlock_all_units", "check_purchases",
  "reset_mutations_timestamp"
]) {
  let action = pServerApi[cmd]
  register_command(@() action("consolePrintResult"), $"meta.{cmd}")
}

let pPlayerTypes = {
  newbie = ""
  standard = "standard"
  whale = "whale"
}
pPlayerTypes.each(@(pType, id) register_command(@() set_purch_player_type(pType), $"meta.set_purch_player_type_{id}"))
