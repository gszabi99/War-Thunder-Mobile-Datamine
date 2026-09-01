from "dagor.localize" import loc


let customGoodsLocId = {
  tanks_blueprints_slots = "shop/air_blueprints_slots"
  ships_blueprints_slots = "shop/air_blueprints_slots"
  air_top_blueprints_slots = "shop/top_blueprints_slots"
  ships_top_blueprints_slots = "shop/top_blueprints_slots"
  senrai_maidens_offer_elsa = "shop/senrai_maidens_offer_elsa"
  senrai_maidens_offer_ling = "shop/senrai_maidens_offer_ling"
  senrai_maidens_offer_kate = "shop/senrai_maidens_offer_kate"
  senrai_maidens_bundle = "shop/senrai_maidens_bundle"
}

let goodsLocIdByNamePart = {
  ["event_pass_vip_"] = "eventPassVIP",
  ["battle_pass_vip_"] = "battlePassVIP",
  ["event_pass_collectors_"] = "collectorsPass",
}

const defaultIcon = "ui/gameuiskin/icon_primary_attention.svg"
let icons = {
  air_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder.avif"
  air_top_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder.avif"
  ships_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder_ships.avif"
  ships_top_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder_ships.avif"
  tanks_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder_tanks.avif"
  senrai_maidens_bundle = "ui/gameuiskin#senrai_maidens_bundle_2026.avif"
}

let iconGoodsAsOffer = {
  senrai_maidens_offer_elsa = "ui/gameuiskin#senrai_maidens_elsa_offer_banner.avif"
  senrai_maidens_offer_ling = "ui/gameuiskin#senrai_maidens_ling_offer_banner.avif"
  senrai_maidens_offer_kate = "ui/gameuiskin#senrai_maidens_kate_offer_banner.avif"

  seasonal_event_offer_yellow_submarine = "ui/unitskin#uk_sub_swiftsure_yellow.avif"
  seasonal_event_offer_yellow_submarine_skin_only = "ui/unitskin#uk_sub_swiftsure_yellow.avif"

  seasonal_event_new_year_2026_ussr_t_90a_nc_with_skin = "ui/unitskin#ussr_t_90a_event.avif"
  seasonal_event_new_year_2026_us_m1_abrams_nc_with_skin = "ui/unitskin#us_m1_abrams_event.avif"
  seasonal_event_new_year_2026_germ_leopard_2a4_nc_with_skin = "ui/unitskin#germ_leopard_2a4_event.avif"
  seasonal_event_new_year_2026_uk_challenger_1_mk_3_gulf_nc_with_skin = "ui/unitskin#uk_challenger_1_mk_3_gulf_event.avif"
  seasonal_event_new_year_2026_cn_ztz_99_w_nc_with_skin = "ui/unitskin#cn_ztz_99_w_event.avif"
  seasonal_event_new_year_2026_il_merkava_mk_2d_nc_with_skin = "ui/unitskin#il_merkava_mk_2d_event.avif"
  seasonal_event_new_year_2026_jp_type_90_nc_with_skin = "ui/unitskin#jp_type_90_event.avif"

  anniversary_event_2026_br_tank_fr_amx_30_b2_brenus = "ui/unitskin#fr_amx_30_b2_brenus_event.avif"
  anniversary_event_2026_br_tank_us_m60a3_tts = "ui/unitskin#us_m60a3_tts_event.avif"
  anniversary_event_2026_br_tank_cn_type_69_2g = "ui/unitskin#cn_type_69_2g_event.avif"
  anniversary_event_2026_br_tank_germ_leopard_c2_mexas = "ui/unitskin#germ_leopard_c2_mexas_event.avif"
  anniversary_event_2026_br_tank_us_xm1_gm = "ui/unitskin#us_xm1_gm_event.avif"
  anniversary_event_2026_br_tank_ussr_t_72av_turms = "ui/unitskin#ussr_t_72av_turms_event.avif"
  anniversary_event_2026_br_tank_il_merkava_mk_2b_early = "ui/unitskin#il_merkava_mk_2b_early_event.avif"

  seasonal_event_valentine_day_2026_ship_old_us_destroyer_selfridge_skin_only = "ui/unitskin#us_destroyer_selfridge_vd.avif"
  seasonal_event_valentine_day_2026_ship_old_us_destroyer_selfridge = "ui/unitskin#us_destroyer_selfridge_vd.avif"
  seasonal_event_valentine_day_2026_air_kitsuka_skin_only = "ui/unitskin#kitsuka_pink.avif"
  valentine_event_timeline_offer_ship_battleship_bismarck_skin_only = "ui/unitskin#germ_battleship_bismarck_february_skin_c.avif"
}

const defaultSlotsPreviewBg = "ui/images/air_beta_access_bg.avif"
let slotsPreviewBg = {
  air_blueprints_slots = "ui/images/air_beta_access_bg.avif"
  air_top_blueprints_slots = "ui/images/air_beta_access_bg.avif"
  ships_blueprints_slots = "ui/images/ship_blueprint_bg.avif"
  ships_top_blueprints_slots = "ui/images/ship_blueprint_bg.avif"
  tanks_blueprints_slots = "ui/images/blueprint_folder_bg_tanks.avif"
  tanks_top_blueprints_slots = "ui/images/blueprint_folder_bg_tanks.avif"
}

let slotTexts = {
  air_blueprints_slots = {
    missing = "shop/air_blueprints_slots/missing"
    updateIn = "shop/air_blueprints_slots/updateIn"
    description = "shop/air_blueprints_slots/description"
  }
}
let defaultSlotsTexts = slotTexts["air_blueprints_slots"]

function calcCustomGoodsName(id) {
  if (id in customGoodsLocId)
    return loc(customGoodsLocId[id])
  foreach (part, locId in goodsLocIdByNamePart)
    if (id.indexof(part) != null)
      return loc(locId)
  return null
}

let customGoodsLoc = {}
function getCustomGoodsNameById(id) {
  if (id not in customGoodsLoc)
    customGoodsLoc[id] <- calcCustomGoodsName(id)
  return customGoodsLoc[id]
}

return {
  getCustomGoodsNameById
  getGoodsIcon = @(id) icons?[id] ?? defaultIcon
  getSlotsPreviewBg = @(id) slotsPreviewBg?[id] ?? defaultSlotsPreviewBg
  getSlotsTexts = @(id) slotTexts?[id] ?? defaultSlotsTexts
  getGoodsAsOfferIcon = @(id) iconGoodsAsOffer?[id]
}
