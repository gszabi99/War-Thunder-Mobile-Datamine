let ships = {
  icon = "ui/gameuiskin#unit_ship.svg"
  unitsLocId = "options/chooseUnitsType/ship"
}

let presentations = {
  ships
  tanks = {
    icon = "ui/gameuiskin#unit_tank.svg",
    unitsLocId = "options/chooseUnitsType/tank"
  }
  air = {
    icon = "ui/gameuiskin#unit_air.svg",
    unitsLocId = "options/chooseUnitsType/aircraft"
  }
}

let getCampaignPresentation = @(campaign) presentations?[campaign] ?? ships

return {
  getCampaignPresentation
  campaignPresentations = presentations
}