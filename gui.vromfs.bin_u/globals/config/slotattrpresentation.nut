let customSlotAttrBackgrounds = {
  tanks = "ui/images/tank_crew_bg.avif"
  air = "ui/images/air_crew_bg.avif"
}

let slotAttrDef = {
  img = "ui/gameuiskin#icon_primary_attention.svg"
  locId = "ui/empty"
}

let slotAttrTabsPresetnation = {
  tank_fire_power = {
    img = "ui/gameuiskin/upgrades_tank_fire_control.avif"
    locId = "slot_attrib_section/tank_fire_power"
  }
  tank_crew = {
    img = "ui/gameuiskin/upgrades_tank_commander.avif"
    locId = "slot_attrib_section/tank_crew"
  }
  tank_protection = {
    img = "ui/gameuiskin/upgrades_tank_techical_service.avif"
    locId = "slot_attrib_section/tank_protection"
  }
  plane_flight_performance = {
    img = "ui/gameuiskin/upgrades_flight_performance.avif"
    locId = "attrib_section/plane_flight_performance"
  }
  plane_crew = {
    img = "ui/gameuiskin/upgrades_plane_crew.avif"
    locId = "attrib_section/plane_crew"
  }
  plane_weapon = {
    img = "ui/gameuiskin/upgrades_plane_weapon.avif"
    locId = "attrib_section/plane_weapon"
  }
}

let getSlotAttrBg = @(campaign) customSlotAttrBackgrounds?[campaign] ?? "ui/images/air_crew_bg.avif"
let getAttrTabPresentation = @(id) slotAttrTabsPresetnation?[id] ?? slotAttrDef.__merge({ locId = id })

return {
  getSlotAttrBg
  getAttrTabPresentation
}
