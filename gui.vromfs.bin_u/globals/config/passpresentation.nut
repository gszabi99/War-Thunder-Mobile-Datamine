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
  iconInactive = null
  btnBuyLocId = "eventPass/btn_buy"
  nameLocId = "eventPass"
  nameVipLocId = "eventPassVIP"
}

let collectorsPresentation = {
  descLocId = "events/desc/tasksAndBattlesScore"
  shortDescLocId = "events/desc/short/tasksAndBattlesScore"
  iconInactive = "ui/gameuiskin#operation_pass_icon_not_active.avif"
  btnBuyLocId = "collectorsPass/btn_buy"
  nameLocId = "collectorsPass"
  nameVipLocId = "collectorsPassVIP"
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
  anniversary_2026 = {
    shortDescLocId = "eventPass/desc"
    passWndCurrencies = [ ANNIVERSARYBOND, ANNIVERSARYTOKEN ]
  }
  halloween_2026 = {
    shortDescLocId = "eventPass/desc"
    passWndCurrencies = [ HALLOWEENBOND, HALLOWEENTOKEN ]
    icon = "ui/gameuiskin#event_pass_icon_halloween_2025.avif"
    iconVip = "ui/gameuiskin#event_pass_icon_halloween_2025_vip.avif"
  }
  uk_air_release = {
    descLocId = "events/desc/tasksAndBattlesScore"
    shortDescLocId = "events/desc/short/tasksAndBattlesScore"
    icon = "ui/gameuiskin#event_pass_icon_uk_air_release_event.avif"
    iconVip = "ui/gameuiskin#event_pass_icon_uk_air_release_event_vip.avif"
  }
  japan_spending = {
    descLocId = "events/desc/tasksAndBattlesScore"
    shortDescLocId = "events/desc/short/tasksAndBattlesScore"
    icon = "ui/gameuiskin#event_pass_icon_japan_tanks_release_event.avif"
    iconVip = "ui/gameuiskin#event_pass_icon_japan_tanks_release_event_vip.avif"
  }
  collectors_pass_tanks = collectorsPresentation
  collectors_pass_ships = collectorsPresentation
  collectors_pass_air = collectorsPresentation
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

let defPointsPresentation = { img = "ui/gameuiskin#passpoints_s39_goods_01.avif", amountAtLeast = 0 }
let pointsPresentations = [
  defPointsPresentation
  { img = "ui/gameuiskin#passpoints_s39_goods_02.avif", amountAtLeast = 10 }
  { img = "ui/gameuiskin#passpoints_s39_goods_03.avif", amountAtLeast = 100 }
]

let defGradePresentation = {
  locId = ""
  icon = @(_) "ui/gameuiskin#bp_icon_not_active.avif"
}
let defBpPresenration = {
  grades = [
    defGradePresentation
    {
      locId = "battlePass"
      icon = @(seasonIdx) seasonIdx != -1 ? $"ui/gameuiskin#bp_icon_active_season_{seasonIdx}.avif"
        : "ui/gameuiskin#bp_icon_not_active.avif"
    }
    {
      locId = "battlePassVIP"
      icon = @(seasonIdx) seasonIdx != -1 ? $"ui/gameuiskin#bp_icon_active_season_{seasonIdx}_vip.avif"
        : "ui/gameuiskin#bp_icon_not_active.avif"
      isVip = true
    }
  ]
}

let bpPresentations = {
  main_s39 = defBpPresenration
}

let mkCurrencyViewInfo = @(id, count) { subId = "", gType = "currency", count, id }

let defHelpBpPresentation = {
  bg = "ui/images/event_s39_background.avif",
  boardImg = "ui/images/event_s39_board.avif",
  currency = {
    subId = ""
    gType = "bpPoints"
    count = 100
    id = "main_s39"
  }
  rewards = [
    {
      subId = "camo"
      gType = "skin"
      count = 0
      id = "f9f-5"
    }
    {
      subId = "desert_threecolors_bp"
      gType = "skin"
      count = 0
      id = "il_frigate_rckt_saar5"
    }
    {
      subId = "forest"
      gType = "skin"
      count = 0
      id = "germ_leopard_2a5_pso"
    }
    mkCurrencyViewInfo(GOLD, 120)
    mkCurrencyViewInfo(GOLD, 120)
    mkCurrencyViewInfo(WP, 24000)
    mkCurrencyViewInfo(WP, 24000)
    mkCurrencyViewInfo(WP, 24000)
    mkCurrencyViewInfo(WP, 24000)
    mkCurrencyViewInfo(WARBOND, 250)
    mkCurrencyViewInfo(EVENT_KEY, 2)
    {
      subId = ""
      gType = "item"
      count = 5
      id = "spare"
    }
    {
      subId = ""
      gType = "prizeTicket"
      count = 1
      id = "blueprints_200_season_39"
    }
  ]
}

let bpHelpWndPresentations = {
  main_s39 = defHelpBpPresentation
}

return {
  getOPPresentation = @(camp) opPresentations?[camp] ?? defOpPresentation
  getEpPresentation = @(eventId) epPresentations?[eventId] ?? defEpPresentation
  getNewbieBPPresentation = @(camp) newbieBpPresentations?[camp] ?? defNewbieBpPresentation
  getPointsPresentation = @(amount) pointsPresentations.reduce(
    @(res, v) v.amountAtLeast <= amount && v.amountAtLeast >= res.amountAtLeast ? v : res,
    defPointsPresentation)
  getGradePresentation = @(bpId, grade) bpPresentations?[bpId].grades[grade] ?? bpPresentations?[bpId].grades[0]
    ?? defGradePresentation
  getBpHelpWndPresentation = @(bpId) bpHelpWndPresentations?[bpId] ?? defHelpBpPresentation
}
