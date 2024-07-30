let defaultIcon = "ui/gameuiskin#icon_primary_attention.svg"
let icons = {
  air_blueprints_slots = "ui/unitskin#blueprint_bf-109k-4.avif"
}

let defaultSlotsPreviewBg = "ui/images/air_beta_access_bg.avif"
let slotsPreviewBg = {
  air_blueprints_slots = "ui/images/air_beta_access_bg.avif"
}

return {
  getGoodsIcon = @(id) icons?[id] ?? defaultIcon
  getSlotsPreviewBg = @(id) slotsPreviewBg?[id] ?? defaultSlotsPreviewBg
}