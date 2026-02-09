let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")

let mkUnitData = @(id) {
  name = id
  unitType = getUnitTagsCfg(id).unitType
  isPremium = false
  isHidden = true
}

let battleModsForOffer = {
  japan_branch_access = {
    locId = "offer/earlyAccess/desc/japan_branch_access"
    image = "ui/images/offer_japan_tree_bg.avif"
    bannerImg = "ui/gameuiskin#japan_offer_banner.avif"
  }
  tanks_china_branch_access = {
    locId = "offer/earlyAccess/desc/tanks_china_branch_access"
    image = "ui/images/offer_chinese_tree_bg.avif"
    bannerImg = "ui/gameuiskin#china_offer_banner.avif"
  }
}

let eventUnitMods = {
  new_year_unit_1 = "uk_challenger_1_mk_3_gulf_event"
  new_year_unit_2 = "il_merkava_mk_2d_event"
  new_year_unit_3 = "us_m1_abrams_event"
  new_year_unit_4 = "ussr_t_90a_event"
  new_year_unit_5 = "jp_type_90_event"
  new_year_unit_6 = "cn_ztz_99_w_event"
}.reduce(@(res, id, modeId) res.$rawset(modeId, {
    id = modeId,
    viewType = "eventUnit"
    eventId = "new_year_2026"
    unitCtor = @() mkUnitData(id)
  }),
{})


let mkCommonMod = @(id, locId, icon = null) { id, viewType = "common", locId, icon }

let commonMods = {
  air_cbt_access = { locId = "event_cbt/access", icon = "ui/gameuiskin#unit_air.svg" }
  japan_branch_access = { locId = "offer/earlyAccess/purch/japan_branch_access", icon = "ui/gameuiskin#unit_air.svg" }
  tanks_china_branch_access = { locId = "offer/earlyAccess/purch/tanks_china_branch_access", icon = "ui/gameuiskin#unit_tank.svg" }
}.map(@(cfg, id) mkCommonMod(id, cfg.locId, cfg?.icon))

let allMods = eventUnitMods.__merge(
  commonMods
)

return {
  getBattleModPresentation = @(id) allMods?[id] ?? mkCommonMod(id, id) 
  getBattleModPresentationForOffer = @(mode) battleModsForOffer?[mode]
}
