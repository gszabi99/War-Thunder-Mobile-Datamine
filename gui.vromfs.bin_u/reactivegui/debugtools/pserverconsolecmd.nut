from "%globalsDarg/darg_library.nut" import *
let { set_clipboard_text } = require("dagor.clipboard")
let { object_to_json_string } = require("json")
let { roundToDigits, round_by_value } = require("%sqstd/math.nut")
let pServerApi = require("%appGlobals/pServer/pServerApi.nut")
let { add_unit_exp, add_player_exp, add_wp, add_gold, add_platinum, change_item_count, set_purch_player_type,
  check_new_offer, debug_offer_generation_stats, shift_all_offers_time, generate_fixed_type_offer,
  userstat_add_item, add_premium, remove_premium, add_unit, remove_unit, registerHandler,
  add_decorator, set_current_decorator, remove_decorator, unset_current_decorator,
  apply_profile_mutation, add_lootbox, add_warbond, add_event_key,
  get_base_lootbox_chances, get_my_lootbox_chances,
  reset_lootbox_counters, reset_profile_with_stats, renew_ad_budget, add_nybond, halt_goods_purchase,
  halt_offer_purchase, add_boosters, debug_apply_boosters_in_battle, add_aprilbond,
  add_all_skins_for_unit, remove_all_skins_for_unit, upgrade_unit, downgrade_unit, add_blueprints,
  add_battle_mod, set_research_unit, add_slot_exp
} = pServerApi
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { resetUserstatAppData } = require("%rGui/unlocks/unlocks.nut")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { resetCustomSettings } = require("%appGlobals/customSettings.nut")
let { mainHangarUnitName, mainHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { register_command } = require("console")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { makeSideScroll } = require("%rGui/components/scrollbar.nut")

registerHandler("consolePrintResult",
  @(res) console_print(res?.error == null ? "SUCCESS" : "FAILED")) //warning disable: -forbidden-function
registerHandler("consolePrint", console_print) //warning disable: -forbidden-function

let infoTextOvr = {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_LEFT,
  preformatted = FMT_KEEP_SPACES | FMT_NO_WRAP
}.__update(fontTiny)

registerHandler("onDebugLootboxChances",
  function(res) {
    let data = clone res
    data?.$rawdelete("isCustom")
    if ("percents" in data)
      data.percents = data.percents.map(@(v)
        $"{v > 0.1 ? round_by_value(v, 0.01) : roundToDigits(v, 2)}%")
    let text = object_to_json_string(data)
    openMsgBox({
      uid = "debug_lootbox_chances"
      text = makeSideScroll(msgBoxText(text, infoTextOvr))
      wndOvr = { size = [hdpx(1100), hdpx(1000)] }
      buttons = [
        { text = "COPY", cb = @() set_clipboard_text(text) }   //warning disable: -forbidden-function
        { id = "ok", styleId = "PRIMARY", isDefault = true }   //warning disable: -forbidden-function
      ]
    })
  })

registerHandler("upgradeUnit",
  @(res, context) res?.error != null ? console_print("FAILED") //warning disable: -forbidden-function
    : upgrade_unit(context.name, "consolePrintResult"))
registerHandler("downgradeUnit",
  @(res, context) res?.error != null ? console_print("FAILED") //warning disable: -forbidden-function
    : downgrade_unit(context.name, "consolePrintResult"))

register_command(function(exp) {
  let name = mainHangarUnitName.get()
  if (name not in allUnitsCfg.value)
    return $"Unit '{name}' not exists"
  if (name not in myUnits.value)
    return $"Unit '{name}' not own"
  add_unit_exp(name, exp, "consolePrintResult")
  return "OK"
}, "meta.add_cur_unit_exp")

register_command(@() resetCustomSettings(), "meta.reset_custom_settings")

register_command(@(exp) add_player_exp(curCampaign.value, exp, "consolePrintResult"), "meta.add_player_exp")
register_command(@(wp) add_wp(wp, "consolePrintResult"), "meta.add_wp")
register_command(@(platinum) add_platinum(platinum, "consolePrintResult"), "meta.add_platinum")
register_command(@(gold) add_gold(gold, "consolePrintResult"), "meta.add_gold")
register_command(@(warbond) add_warbond(warbond, "consolePrintResult"), "meta.add_warbond")
register_command(@(event_key) add_event_key(event_key, "consolePrintResult"), "meta.add_event_key")
register_command(@(nybond) add_nybond(nybond, "consolePrintResult"), "meta.add_nybond")
register_command(@(aprilbond) add_aprilbond(aprilbond, "consolePrintResult"), "meta.add_aprilbond")
register_command(@(name, count) change_item_count(name, count, "consolePrintResult"), "meta.change_item_count")
register_command(@(seconds) seconds < 0
    ? remove_premium(-seconds, "consolePrintResult")
    : add_premium(seconds, "consolePrintResult"),
  "meta.add_premium")
register_command(@(unitName) add_unit(unitName, "consolePrintResult"), "meta.add_unit")
register_command(@(unitName) remove_unit(unitName, "consolePrintResult"), "meta.remove_unit")
register_command(@() add_unit(mainHangarUnitName.get(), "consolePrintResult"), "meta.add_hangar_unit")
register_command(@() remove_unit(mainHangarUnitName.get(), "consolePrintResult"), "meta.remove_hangar_unit")
register_command(@(name, count) add_blueprints(name, count, "consolePrintResult"), "meta.add_blueprints")
register_command(@(count) add_blueprints(mainHangarUnitName.get(), count, "consolePrintResult"), "meta.add_blueprints_hangar_unit")
register_command(@(name) add_battle_mod(name, 3600 * 24 * 30, "consolePrintResult"), "meta.add_battle_mod")

register_command(@(name) set_current_decorator(name, "consolePrintResult"), "meta.set_current_decorator")
register_command(@(name) add_decorator(name, "consolePrintResult"), "meta.add_decorator")
register_command(@(name) remove_decorator(name, "consolePrintResult"), "meta.remove_decorator")
register_command(@(name) unset_current_decorator(name, "consolePrintResult"), "meta.unset_current_decorator")
register_command(@(id) apply_profile_mutation(id, "consolePrintResult"), "meta.apply_profile_mutation")
register_command(@(id) add_lootbox(id, 1, "consolePrintResult"), "meta.add_lootbox")
register_command(@(id, count) add_lootbox(id, count, "consolePrintResult"), "meta.add_lootbox_several")
register_command(@(id) halt_goods_purchase(id, "consolePrintResult"), "meta.halt_goods_purchase")
register_command(@(id) halt_offer_purchase(id, "consolePrintResult"), "meta.halt_offer_purchase")
register_command(@(slotIdx, exp) add_slot_exp(curCampaign.get(), slotIdx, exp, "consolePrintResult"), "meta.add_slot_exp")

register_command(@(id) get_my_lootbox_chances(id, "onDebugLootboxChances"), "meta.debug_lootbox_chances_my")
register_command(@(id) get_base_lootbox_chances(id, "onDebugLootboxChances"), "meta.debug_lootbox_chances_base")
register_command(@(id) reset_lootbox_counters(id, "consolePrintResult"), "meta.reset_lootbox_counters")

register_command(@() renew_ad_budget("consolePrintResult"), "meta.renew_ad_budget")

register_command(@(name, count) add_boosters({ [name] = count }, "consolePrintResult"), "meta.add_booster")
register_command(
  @(count) add_boosters(serverConfigs.get()?.allBoosters.map(@(_) count) ?? {}, "consolePrintResult"),
  "meta.add_all_boosters")
register_command(
  @() debug_apply_boosters_in_battle(servProfile.get()?.boosters.filter(@(v) v.battlesLeft > 0 && !v.isDisabled).keys() ?? [], "consolePrintResult"),
  "meta.debug_apply_boosters_in_battle")

register_command(@() upgrade_unit(mainHangarUnitName.get(), "consolePrintResult"), "meta.upgrade_hangar_unit")
register_command(@() downgrade_unit(mainHangarUnitName.get(), "consolePrintResult"), "meta.downgrade_hangar_unit")
register_command(@()
  add_all_skins_for_unit(mainHangarUnitName.get(),
    mainHangarUnit.get()?.isUpgraded || mainHangarUnit.get()?.isPremium ? "consolePrintResult"
      : { id = "upgradeUnit", name = mainHangarUnitName.get() })
  "meta.add_all_skins_for_hangar_unit")
register_command(@()
  remove_all_skins_for_unit(mainHangarUnitName.get(),
    !mainHangarUnit.get()?.isUpgraded ? "consolePrintResult"
      : { id = "downgradeUnit", name = mainHangarUnitName.get() })
  "meta.remove_all_skins_for_hangar_unit")

register_command(function(count) {
  add_wp(count * 100)
  add_gold(count * 10)
  add_warbond(count * 10)
  add_event_key(count * 1)
  add_nybond(count * 10)
  add_aprilbond(count * 10)
  foreach (item in itemsOrderFull)
    change_item_count(item, count)
  change_item_count("ircm_kit", count)

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

foreach (cmd in ["get_all_configs", "reset_profile",
  "unlock_all_common_units", "unlock_all_premium_units", "unlock_all_units", "check_purchases",
  "reset_mutations_timestamp", "reset_scheduled_reward_timers"
]) {
  let action = pServerApi[cmd]
  register_command(@() action("consolePrintResult"), $"meta.{cmd}")
}

register_command(function() {
  reset_profile_with_stats("consolePrintResult")
  resetUserstatAppData()
},
  $"meta.reset_profile_with_stats")

let pPlayerTypes = {
  newbie = ""
  standard = "standard"
  whale = "whale"
}
pPlayerTypes.each(@(pType, id) register_command(@() set_purch_player_type(pType), $"meta.set_purch_player_type_{id}"))


register_command(@(id, count) userstat_add_item(id, count, "userStat", "consolePrintResult"), "meta.userstat_add_item")
register_command(function(id) {
    let tags = [
      { table = "ships_event_leaderboard", mode = "ships", tillPlaces = [10, 100], place = 8, tillPercent = [5, 10, 20], percent = 4 }
      { table = "tanks_event_leaderboard", mode = "tanks", place = 50342, tillPercent = [50], percent = 44 }
      { table = "wp_event_leaderboard", mode = "battle_common", tillPlaces = [100], place = 17 }
    ]
    userstat_add_item(id, 1, object_to_json_string(tags, false), "consolePrintResult")
    return "Sent"
  },
  $"meta.add_lb_reward")

register_command(@(unitname) set_research_unit("air", unitname), "meta.set_research_unit")
