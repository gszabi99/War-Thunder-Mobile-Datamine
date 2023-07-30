from "%globalsDarg/darg_library.nut" import *
let pServerApi = require("%appGlobals/pServer/pServerApi.nut")
let { add_unit_exp, add_player_exp, add_wp, add_gold, change_item_count, set_purch_player_type,
  check_new_offer, debug_offer_generation_stats, shift_all_offers_time, generate_fixed_type_offer,
  userstat_add_item, add_premium, remove_premium, add_unit, remove_unit
} = pServerApi
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { resetCustomSettings } = require("%appGlobals/customSettings.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { register_command } = require("console")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")

let printRes = @(res) console_print(res?.error == null ? "SUCCESS" : "FAILED") //warning disable: -forbidden-function

register_command(function(exp) {
  let name = hangarUnitName.value
  if (name not in allUnitsCfg.value)
    return $"Unit '{name}' not exists"
  if (name not in myUnits.value)
    return $"Unit '{name}' not own"
  add_unit_exp(name, exp, printRes)
}, "meta.add_cur_unit_exp")

register_command(@() resetCustomSettings(), "meta.reset_custom_settings")

register_command(@(exp) add_player_exp(curCampaign.value, exp, printRes), "meta.add_player_exp")
register_command(@(wp) add_wp(wp, printRes), "meta.add_wp")
register_command(@(gold) add_gold(gold, printRes), "meta.add_gold")
register_command(@(name, count) change_item_count(name, count, printRes), "meta.change_item_count")
register_command(@(id, count) userstat_add_item(id, count, printRes), "meta.userstat_add_item")
register_command(@(seconds) seconds < 0 ? remove_premium(-seconds, printRes) : add_premium(seconds, printRes), "meta.add_premium")
register_command(@(unitName) add_unit(unitName, printRes), "meta.add_unit")
register_command(@(unitName) remove_unit(unitName, printRes), "meta.remove_unit")
register_command(@() add_unit(hangarUnitName.value, printRes), "meta.add_hangar_unit")
register_command(@() remove_unit(hangarUnitName.value, printRes), "meta.remove_hangar_unit")

register_command(function(count) {
  add_wp(count * 100)
  add_gold(count * 10)
  foreach (item in itemsOrderFull)
    change_item_count(item, count)

  let seconds = count * 60
  if (seconds < 0)
    remove_premium(-seconds, printRes)
  else
    add_premium(seconds, printRes)
}, "meta.add_all_items_and_currency")

register_command(@() shift_all_offers_time(86400, @(_) check_new_offer(curCampaign.value, printRes)),
  "meta.gen_next_day_offer")
register_command(@() debug_offer_generation_stats(curCampaign.value, console_print),  //warning disable: -forbidden-function
  "meta.debug_offer_generation_stats")
foreach (ot in ["start", "gold", "collection", "sidegrade", "upgrade"]) {
  let offerType = ot
  register_command(@() generate_fixed_type_offer(curCampaign.value, offerType, printRes),
    $"meta.generate_offer_{offerType}")
}

foreach (cmd in ["get_all_configs", "reset_profile", "reset_profile_with_stats",
  "unlock_all_common_units", "unlock_all_premium_units", "unlock_all_units", "check_purchases"
]) {
  let action = pServerApi[cmd]
  register_command(@() action(printRes), $"meta.{cmd}")
}

let pPlayerTypes = {
  newbie = ""
  standard = "standard"
  whale = "whale"
}
pPlayerTypes.each(@(pType, id) register_command(@() set_purch_player_type(pType), $"meta.set_purch_player_type_{id}"))
