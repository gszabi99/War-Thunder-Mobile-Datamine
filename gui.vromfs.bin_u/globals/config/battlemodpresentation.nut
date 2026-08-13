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
  tanks_japan_branch_access = {
    locId = "offer/earlyAccess/desc/tanks_japan_branch_access"
    image = "ui/images/offer_japan_tanks_early_access.avif"
    bannerImg = "ui/gameuiskin#japan_offer_banner.avif"
  }
  air_uk_branch_access = {
    locId = "offer/earlyAccess/desc/air_uk_branch_access"
    image = "ui/images/offer_uk_air_early_access.avif"
    bannerImg = "ui/gameuiskin#uk_offer_banner.avif"
  }
}

let eventUnitMods = {
  anniversary_BR_unit_1 = "cn_type_69_2g_event"
  anniversary_BR_unit_2 = "germ_leopard_c2_mexas_event"
  anniversary_BR_unit_3 = "ussr_t_72av_turms_event"
  anniversary_BR_unit_4 = "il_merkava_mk_2b_early_event"
}.reduce(@(res, id, modeId) res.$rawset(modeId, {
    id = modeId,
    viewType = "eventUnit"
    eventId = "anniversary_2026"
    unitCtor = @() mkUnitData(id)
  }),
{})


let mkCommonMod = @(id, locId, icon = null) { id, viewType = "common", locId, icon }

let commonMods = {
  air_cbt_access = { locId = "event_cbt/access", icon = "ui/gameuiskin#unit_air.svg" }
  japan_branch_access = { locId = "offer/earlyAccess/purch/japan_branch_access", icon = "ui/gameuiskin#unit_air.svg" }
  tanks_china_branch_access = { locId = "offer/earlyAccess/purch/tanks_china_branch_access", icon = "ui/gameuiskin#unit_tank.svg" }
  tanks_japan_branch_access = { locId = "offer/earlyAccess/purch/tanks_japan_branch_access", icon = "ui/gameuiskin#unit_tank.svg" }
  air_uk_branch_access = { locId = "offer/earlyAccess/purch/air_uk_branch_access", icon = "ui/gameuiskin#unit_air.svg" }
}.map(@(cfg, id) mkCommonMod(id, cfg.locId, cfg?.icon))

let allMods = eventUnitMods.__merge(
  commonMods
)

return {
  getBattleModPresentation = @(id) allMods?[id] ?? mkCommonMod(id, id) 
  getBattleModPresentationForOffer = @(mode) battleModsForOffer?[mode]
}
