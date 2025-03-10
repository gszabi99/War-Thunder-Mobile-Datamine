let { soundOptions } = require("options/soundOptions.nut")
let { graphicOptions } = require("options/graphicOptions.nut")
let { langOptions } = require("options/langOptions.nut")
let { controlsOptions } = require("options/controlsOptions.nut")
let { tankControlsOptions } = require("options/tankControlsOptions.nut")
let { shipControlsOptions } = require("options/shipControlsOptions.nut")
let { airControlsOptions } = require("options/airControlsOptions.nut")
let { systemOptions } = require("options/systemOptions.nut")
let { gameOptions } = require("options/gameOptions.nut")
let { mkOptionsScene } = require("mkOptionsScene.nut")

let tabs = [ // id, locId, image, options, content
  {
    id = "graphic"
    locId = "options/graphicsParameters"
    image = "ui/gameuiskin#menu_graph.svg"
    options = graphicOptions
  }
  {
    locId = "options/sound"
    image = "ui/gameuiskin#menu_sound.svg"
    options = soundOptions
  }
  {
    locId = "options/controls"
    image = "ui/gameuiskin#menu_controls.svg"
    children = [
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
      {
        locId = "options/airControls"
        image = "ui/gameuiskin#unit_air.svg"
        options = airControlsOptions
      }
    ]
  }
  {
    locId = "profile/language"
    image = "ui/gameuiskin#menu_lang.svg"
    options = langOptions
  }
  {
    locId = "options/system"
    image = "ui/gameuiskin#menu_system.svg"
    options = systemOptions
  }
  {
    locId = "options/game"
    image = "ui/gameuiskin#menu_game.svg"
    options = gameOptions
  }
]

return mkOptionsScene("optionsScene", tabs)
