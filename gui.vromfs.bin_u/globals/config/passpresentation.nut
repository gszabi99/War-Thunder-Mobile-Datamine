let defPresentation = {
  icon = null
  iconVip = null
  iconInactive = "ui/gameuiskin#operation_pass_icon_not_active.avif"
  iconTab = "ui/gameuiskin#icon_personal_tank.svg"
  bg = "ui/images/blueprint_folder_bg_tanks.avif"
}

let operationPassPresentations = {
  tanks = {
    icon = "ui/gameuiskin#operation_pass_icon_active_tanks_season_26.avif"
    iconVip = "ui/gameuiskin#operation_pass_icon_active_vip_tanks_season_26.avif"
    iconTab = "ui/gameuiskin#icon_personal_tank.svg"
    bg = "ui/images/blueprint_folder_bg_tanks.avif"
  }
  ships = {
    icon = "ui/gameuiskin#operation_pass_icon_active_ships_season_26.avif"
    iconVip = "ui/gameuiskin#operation_pass_icon_active_vip_ships_season_26.avif"
    iconTab = "ui/gameuiskin#icon_personal_ship.svg"
    bg = "ui/images/ship_blueprint_bg.avif"
  }
  air = {
    icon = "ui/gameuiskin#operation_pass_icon_active_air_season_26.avif"
    iconVip = "ui/gameuiskin#operation_pass_icon_active_vip_air_season_26.avif"
    iconTab = "ui/gameuiskin#icon_personal_air.svg"
    bg = "ui/images/air_beta_access_bg.avif",
  }
}.map(@(c) defPresentation.__merge(c))

return {
  getOPPresentation = @(camp) operationPassPresentations?[camp] ?? defPresentation
}