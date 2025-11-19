let { loc } = require("dagor.localize")

let customGoodsLocId = {
  tanks_blueprints_slots = "shop/air_blueprints_slots"
  ships_blueprints_slots = "shop/air_blueprints_slots"
  air_top_blueprints_slots = "shop/top_blueprints_slots"
  ships_top_blueprints_slots = "shop/top_blueprints_slots"
}

let defaultIcon = "ui/gameuiskin/icon_primary_attention.svg"
let icons = {
  air_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder.avif"
  air_top_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder.avif"
  ships_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder_ships.avif"
  ships_top_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder_ships.avif"
  tanks_blueprints_slots = "ui/gameuiskin/shop_blueprints_folder_tanks.avif"
}

let iconGoodsAsOffer = {
  seasonal_event_offer_yellow_submarine = "ui/unitskin#uk_sub_swiftsure_yellow.avif"
  seasonal_event_offer_yellow_submarine_skin_only = "ui/unitskin#uk_sub_swiftsure_yellow.avif"
}

let defaultSlotsPreviewBg = "ui/images/air_beta_access_bg.avif"
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

return {
  getGoodsNameById = @(id) loc(customGoodsLocId?[id] ?? $"shop/{id}")
  getGoodsIcon = @(id) icons?[id] ?? defaultIcon
  getSlotsPreviewBg = @(id) slotsPreviewBg?[id] ?? defaultSlotsPreviewBg
  getSlotsTexts = @(id) slotTexts?[id] ?? defaultSlotsTexts
  getGoodsAsOfferIcon = @(id) iconGoodsAsOffer?[id]
}