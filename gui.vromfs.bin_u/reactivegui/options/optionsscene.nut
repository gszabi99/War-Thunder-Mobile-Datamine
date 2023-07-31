let soundOptions = require("options/soundOptions.nut")
let graphicOptions = require("options/graphicOptions.nut")
let { langOptions } = require("options/langOptions.nut")
let { controlsOptions } = require("options/controlsOptions.nut")
let mkOptionsScene = require("mkOptionsScene.nut")

let tabs = [ // id, locId, image, options, content
  {
    locId = "options/sound"
    image = "ui/gameuiskin#menu_sound.svg"
    options = soundOptions
  }
  {
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
    locId = "mainmenu/btnControls"
    image = "ui/gameuiskin#menu_controls.svg"
    options = controlsOptions
  }
]

return mkOptionsScene("optionsScene", tabs)
