from "%globalsDarg/darg_library.nut" import *

let supportPlaneConfig = [
  {
    image = "ui/gameuiskin#hud_aircraft_torpedo.svg"
    imageSwitch = "ui/gameuiskin#hud_aircraft_torpedo_switch.svg"
    shortcutId = "ID_WTM_LAUNCH_AIRCRAFT"
  },
  {
    image = "ui/gameuiskin#hud_aircraft_bomber.svg"
    imageSwitch = "ui/gameuiskin#hud_aircraft_bomber_switch.svg"
    shortcutId = "ID_WTM_LAUNCH_AIRCRAFT_2"
  },
  {
    image = "ui/gameuiskin#hud_aircraft_fighter.svg"
    imageSwitch = "ui/gameuiskin#hud_aircraft_fighter_switch.svg"
    shortcutId = "ID_WTM_LAUNCH_AIRCRAFT_3"
  },
  {
    image = "ui/gameuiskin#hud_aircraft_fighter.svg"
    imageSwitch = "ui/gameuiskin#hud_aircraft_fighter_switch.svg"
    shortcutId = "ID_WTM_LAUNCH_AIRCRAFT_4"
  }
]
  .map(@(v, i) v.$rawset("groupIdx", i))

return supportPlaneConfig
