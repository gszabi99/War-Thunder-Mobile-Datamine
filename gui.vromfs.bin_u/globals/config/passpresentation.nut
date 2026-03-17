from "%appGlobals/currenciesState.nut" import *

let defBPPresentation = {
  bgColor = 0xFFFFFFFF
}

let bpPresentations = {}

let defOpPresentation = {
  icon = null
  iconVip = null
  iconInactive = "ui/gameuiskin#operation_pass_icon_not_active.avif"
  iconTab = "ui/gameuiskin#icon_personal_tank.svg"
  bg = "ui/images/blueprint_folder_bg_tanks.avif"
  bgColor = 0xFFFFFFFF
}

let opPresentations = {
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
    bg = "ui/images/air_beta_access_bg.avif"
  }
}.map(@(c) defOpPresentation.__merge(c))


let defEpPresentation = {
  descLocId = "eventPass/desc"
  shortDescLocId = "battlepass/tasksDesc"
  passWndCurrencies = []
  bgColor = 0xFFFFFFFF
}

let epPresentations = {
  valentine_day_2026 = {
    descLocId = "events/desc/battlesOrWin"
    shortDescLocId = "events/desc/short/battlesOrWin"
    passWndCurrencies = [ CANDYBOND, LOLLIPOPBOND, CHOCOLATEBOND ]
  }
  lunar_ny_2026 = {
    bgColor = 0xFF999999
    descLocId = "events/desc/tasksAndBattlesScore"
    shortDescLocId = "events/desc/short/tasksAndBattlesScore"
  }
}.map(@(c) defEpPresentation.__merge(c))

let defNewbieBpPresentation = {
  bg = "ui/images/blueprint_folder_bg_tanks.avif"
}

let newbieBpPresentations = {
  tanks = {
    bg = "ui/images/blueprint_folder_bg_tanks.avif"
  }
  ships = {
    bg = "ui/images/ship_blueprint_bg.avif"
  }
  air = {
    bg = "ui/images/air_beta_access_bg.avif"
  }
}.map(@(c) defNewbieBpPresentation.__merge(c))

return {
  getOPPresentation = @(camp) opPresentations?[camp] ?? defOpPresentation
  getEpPresentation = @(eventId) epPresentations?[eventId] ?? defEpPresentation
  getBPPresentation = @(seasonNumber) bpPresentations?[$"season_{seasonNumber}"] ?? defBPPresentation
  getNewbieBPPresentation = @(camp) newbieBpPresentations?[camp] ?? defNewbieBpPresentation
}
