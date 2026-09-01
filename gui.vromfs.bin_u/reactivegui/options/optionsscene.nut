from "%globalsDarg/darg_library.nut" import *
from "app" import get_game_version_str, get_base_game_version_str
from "%appGlobals/unitConst.nut" import WALKER
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
from "%rGui/event/eventState.nut" import unitTypesByEvent
from "%rGui/options/mkOptionsScene.nut" import mkOptionsScene
from "%rGui/options/options/airControlsOptions.nut" import airControlsOptions
from "%rGui/options/options/controlsOptions.nut" import controlsOptions
from "%rGui/options/options/gameOptions.nut" import gameOptions
from "%rGui/options/options/graphicOptions.nut" import graphicOptions
from "%rGui/options/options/langOptions.nut" import langOptions
from "%rGui/options/options/shipControlsOptions.nut" import shipControlsOptions
from "%rGui/options/options/soundOptions.nut" import soundOptions
from "%rGui/options/options/systemOptions.nut" import systemOptions
from "%rGui/options/options/tankControlsOptions.nut" import tankControlsOptions
from "%rGui/options/options/walkerControlsOptions.nut" import walkerControlsOptions


const SCENE_ID = "optionsScene"
let isOpened = mkWatched(persist, $"{SCENE_ID}_isOpened", false)
let curTabId = Watched(null)

let tabs = [ 
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
      {
        locId = "options/walkerControls"
        image = "ui/gameuiskin#unit_walker.svg"
        options = walkerControlsOptions
        isVisible = Computed(@() unitTypesByEvent.get()?[WALKER] ?? false)
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

let backBtn = backButton(function() {
  curTabId.set(null)
  isOpened.set(false)
})

let header = headerGradientWithRightBlock(
  [
    backBtn
    {
      rendObj = ROBJ_TEXT
      text = loc("mainmenu/btnOptions")
    }.__update(fontBigShaded)
  ]
  {
    size = FLEX_H
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    children = [get_base_game_version_str(), get_game_version_str()]
      .map(@(text) {
        rendObj = ROBJ_TEXT
        text
        color = 0xFFC0C0C0
      }.__update(fontVeryVeryTinyShaded))
  })

return mkOptionsScene(SCENE_ID, tabs, isOpened, curTabId, header)
