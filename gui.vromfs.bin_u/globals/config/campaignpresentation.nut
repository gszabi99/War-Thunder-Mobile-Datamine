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
}

let getCampaignPresentation = @(campaign) presentations?[campaign] ?? ships

return {
  getCampaignPresentation
}