let mkPresentation = @(cfg, campaign) {
  campaign
  icon = "ui/gameuiskin#unit_ship.svg"
  treeBg = $"{campaign}_blur_bg.avif"

  unitsLocId = "options/chooseUnitsType/ship"
  headerLocId = $"campaign/{campaign}"
  headerFullLocId = $"gamercard/levelCamp/header/{campaign}"
  levelUnitDetailsLocId = $"gamercard/levelUnitDetails/desc/{campaign}"
  levelUnitAttrLocId = $"gamercard/levelUnitAttr/desc/{campaign}"
  levelUnitModLocId = $"gamercard/levelUnitMod/desc/{campaign}"
  unitLevelMaxLocId = $"gamercard/levelCamp/maxLevel/{campaign}"
  debrUnitLevelDescLocId = $"gamercard/debriefing/desc/{campaign}"
}.__update(cfg)

let ships = mkPresentation(
  {
    icon = "ui/gameuiskin#unit_ship.svg"
    unitsLocId = "options/chooseUnitsType/ship"
  },
  "ships")

let presentations = {
  tanks = {
    icon = "ui/gameuiskin#unit_tank.svg",
    unitsLocId = "options/chooseUnitsType/tank"
  }
  air = {
    icon = "ui/gameuiskin#unit_air.svg",
    unitsLocId = "options/chooseUnitsType/aircraft"
  }
}
  .map(mkPresentation)
  .__update({
    ships
    ships_new = ships
  })

let getCampaignPresentation = @(campaign) presentations?[campaign] ?? ships

return {
  getCampaignPresentation
  campaignPresentations = presentations
}