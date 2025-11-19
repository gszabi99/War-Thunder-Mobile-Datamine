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
  slotsPresetBtnIcon = $"ui/gameuiskin#icon_slot_preset_air.svg"
}.__update(cfg)

let ships = mkPresentation(
  {
    icon = "ui/gameuiskin#unit_ship.svg"
    unitsLocId = "options/chooseUnitsType/ship"
    debrUnitLevelDescLocId = $"gamercard/debriefing/desc/ships"
    levelUnitDetailsLocId = $"gamercard/levelUnitDetails/desc/ships"
    levelUnitModLocId = $"gamercard/levelUnitMod/desc/ships"
  },
  "ships")

let tanks = mkPresentation(
  {
    icon = "ui/gameuiskin#unit_tank.svg"
    treeBg = $"tanks_blur_bg.avif"
    unitsLocId = "options/chooseUnitsType/tank"
    unitLevelMaxLocId = $"gamercard/levelCamp/maxLevel/tanks"
    debrUnitLevelDescLocId = $"gamercard/debriefing/desc/tanks"
    levelUnitDetailsLocId = $"gamercard/levelUnitDetails/desc/tanks"
    levelUnitModLocId = $"gamercard/levelUnitMod/desc/tanks"
    levelUnitAttrLocId = $"gamercard/levelUnitAttr/desc/tanks"
  },
  "tanks")

let tanks_new = mkPresentation(
  {
    icon = "ui/gameuiskin#unit_tank.svg"
    treeBg = $"tanks_blur_bg.avif"
    unitsLocId = "options/chooseUnitsType/tank"
    slotsPresetBtnIcon = "ui/gameuiskin#icon_slot_preset_tanks.svg"
  },
  "tanks")

let presentations = {
  air = {
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
  .__update({
    ships
    ships_new = ships
    tanks
    tanks_new
  })

let getCampaignPresentation = @(campaign) presentations?[campaign] ?? ships

return {
  getCampaignPresentation
  campaignPresentations = presentations
}