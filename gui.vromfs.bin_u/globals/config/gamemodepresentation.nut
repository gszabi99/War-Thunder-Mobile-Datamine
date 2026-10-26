from "%sqstd/functools.nut" import memoize

let defaultPresentation = {
  locId = "mainmenu/toBattle/short"
  bg = "ui/images/event_bg.avif"
  icon = "ui/gameuiskin#icon_primary_attention.svg"
}

let presentations = {
  plane_event_halloween_po2_race = {
    locId = "gameMode/plane_event_halloween_po2_race"
    bg = "ui/images/help/help_event_halloween.avif"
    icon = "ui/gameuiskin#objective_fighter.svg"
  }
  ship_event_halloween_pirates = {
    locId = "gameMode/ship_event_halloween_pirates"
    bg = "!ui/images/help/help_event_pirates.avif"
    icon = "ui/gameuiskin#objective_galleon.svg"
  }
}

let getGameModePresentation = memoize(@(name)
  name in presentations ? { ...defaultPresentation, ...presentations[name] }
    : defaultPresentation)

return {
  getGameModePresentation
}
