let mkPresentation = @(cfg, campaign) {
  campaign
  icon = "ui/gameuiskin#unit_ship.svg"
  treeBg = $"ships_blur_bg.avif"

  returnToHangarLocId = campaign == "ships" ? "return_to_port" : "return_to_hangar"
  returnToHangarShortLocId = campaign == "ships" ? "return_to_port/short" : "return_to_hangar/short"
  unitsLocId = "options/chooseUnitsType/ship"
  headerLocId = $"campaign/{campaign}"
  headerFullLocId = $"gamercard/levelCamp/header/{campaign}"
  levelUnitDetailsLocId = $"gamercard/levelUnitDetails/desc"
  levelUnitAttrLocId = $"gamercard/levelUnitAttr/desc"
  levelUnitModLocId = $"gamercard/levelUnitMod/desc"
  unitLevelMaxLocId = $"gamercard/levelCamp/maxLevel"
  debrUnitLevelDescLocId = $"gamercard/debriefing/desc"
  playerLevelDescLocId = "hints/campaignLvlByResearchesInfo"
  img = "ui/bkg/campaign_ship.avif"
  slotsPresetBtnIcon = $"ui/gameuiskin#icon_slot_preset_air.svg"
}.__update(cfg)

let presentations = {
  ships = {
    icon = "ui/gameuiskin#unit_ship.svg"
    unitsLocId = "options/chooseUnitsType/ship"
    debrUnitLevelDescLocId = $"gamercard/debriefing/desc/ships"
    levelUnitDetailsLocId = $"gamercard/levelUnitDetails/desc/ships"
    levelUnitModLocId = $"gamercard/levelUnitMod/desc/ships"
  }

  tanks = {
    img = "ui/bkg/campaign_tank.avif"
    icon = "ui/gameuiskin#unit_tank.svg"
    treeBg = $"tanks_blur_bg.avif"
    unitsLocId = "options/chooseUnitsType/tank"
    slotsPresetBtnIcon = "ui/gameuiskin#icon_slot_preset_tanks.svg"
  }

  air = {
    img = "ui/bkg/campaign_plane.avif"
    icon = "ui/gameuiskin#unit_air.svg"
    treeBg = $"air_blur_bg.avif"
    unitsLocId = "options/chooseUnitsType/aircraft"
    playerLevelDescLocId = "hints/aviationExlLvlInfo"
    unitLevelMaxLocId = $"gamercard/levelCamp/maxLevel/air"
    debrUnitLevelDescLocId = $"gamercard/debriefing/desc/air"
    levelUnitDetailsLocId = $"gamercard/levelUnitDetails/desc/air"
    levelUnitModLocId = $"gamercard/levelUnitMod/desc/air"
    levelUnitAttrLocId = $"gamercard/levelUnitAttr/desc/air"
  }
}
  .map(mkPresentation)

let defPresetntation = presentations.ships

let getCampaignPresentation = @(campaign) presentations?[campaign] ?? defPresetntation

return {
  getCampaignPresentation
  campaignPresentations = presentations
}