let defaultIcon = "ui/gameuiskin#icon_primary_attention.svg"
let icons = {
  air_blueprints_slots = "ui/gameuiskin#shop_blueprints_folder.avif"
}

let defaultSlotsPreviewBg = "ui/images/air_beta_access_bg.avif"
let slotsPreviewBg = {
  air_blueprints_slots = "ui/images/air_beta_access_bg.avif"
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
  getGoodsIcon = @(id) icons?[id] ?? defaultIcon
  getSlotsPreviewBg = @(id) slotsPreviewBg?[id] ?? defaultSlotsPreviewBg
  getSlotsTexts = @(id) slotTexts?[id] ?? defaultSlotsTexts
}