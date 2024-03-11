let soundOptions = require("options/soundOptions.nut")
let { graphicOptions } = require("options/graphicOptions.nut")
let { langOptions } = require("options/langOptions.nut")
let { controlsOptions } = require("options/controlsOptions.nut")
let { tankControlsOptions } = require("options/tankControlsOptions.nut")
let { shipControlsOptions } = require("options/shipControlsOptions.nut")
let { mkOptionsScene } = require("mkOptionsScene.nut")

let tabs = [ // id, locId, image, options, content
  {
    locId = "options/sound"
    image = "ui/gameuiskin#menu_sound.svg"
    options = soundOptions
  }
  {
    id = "graphic"
    locId = "options/graphicsParameters"
    image = "ui/gameuiskin#menu_graph.svg"
    options = graphicOptions
  }
  {
    locId = "profile/language"
    image = "ui/gameuiskin#menu_lang.svg"
    options = langOptions
  }
  {
    locId = "options/commonControls"
    image = "ui/gameuiskin#menu_controls.svg"
    options = controlsOptions
  }
  {
    locId = "options/tankControls"
    image = "ui/gameuiskin#unit_tank.svg"
    options = tankControlsOptions
  }
  {
    locId = "options/shipControls"
    image = "ui/gameuiskin#unit_ship.svg"
    options = shipControlsOptions
  }
]

return mkOptionsScene("optionsScene", tabs)
