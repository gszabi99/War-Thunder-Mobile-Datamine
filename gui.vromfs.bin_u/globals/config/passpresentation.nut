from "%appGlobals/currenciesState.nut" import *

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
}

let epPresentations = {
  valentine_day_2026 = {
    descLocId = "events/desc/battlesOrWin"
    shortDescLocId = "events/desc/short/battlesOrWin"
    passWndCurrencies = [ CANDYBOND, LOLLIPOPBOND, CHOCOLATEBOND ]
  }
  lunar_ny_2026 = {
    descLocId = "events/desc/tasksAndBattlesScore"
    shortDescLocId = "events/desc/short/tasksAndBattlesScore"
  }
  event_april_2026 = {
    passWndCurrencies = [ APRILINTEL, APRILBOND ]
  }
  uk_air_release = {
    descLocId = "events/desc/tasksAndBattlesScore"
    shortDescLocId = "events/desc/short/tasksAndBattlesScore"
    icon = "ui/gameuiskin#event_pass_icon_uk_air_release_event.avif"
    iconVip = "ui/gameuiskin#event_pass_icon_uk_air_release_event_vip.avif"
  }
  japan_tanks_release = {
    descLocId = "events/desc/tasksAndBattlesScore"
    shortDescLocId = "events/desc/short/tasksAndBattlesScore"
    icon = "ui/gameuiskin#event_pass_icon_japan_tanks_release_event.avif"
    iconVip = "ui/gameuiskin#event_pass_icon_japan_tanks_release_event_vip.avif"
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
  getNewbieBPPresentation = @(camp) newbieBpPresentations?[camp] ?? defNewbieBpPresentation
}
