from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/components/titleLogo.nut" import mkTitleLogo
from "%globalsDarg/loading/loadingAnimBg.nut" import screenWeights, loadingAnimBg, chooseRandomScreen, curScreenId
from "%globalsDarg/loading/loadingProgressbar.nut" import mkProgressStatusText, mkProgressbar, progressbarGap
from "%globalsDarg/loading/loadingScreensCfg.nut" import screensList
from "loadingTip.nut" import gradientLoadingTip
from "updaterState.nut" import statusText, progressPercent, hasAnyMsg


let { register_command  = null } = require_optional("console") 

const spinnerSize = hdpxi(100)





let loadingScreensWhitelist = [
  "simple_ship_6"
  "simple_tank_7"
  "simple_airplane_3"
]
let dbgScreen = mkWatched(persist, "dbgScreen", null)

function updateScreenList() {
  screenWeights.set(dbgScreen.get() != null ? { [dbgScreen.get()] = 1 }
    : screensList
        .filter(@(_, k) loadingScreensWhitelist.contains(k))
        .map(@(s) s.weight))
  if (curScreenId.get() not in screenWeights.get())
    chooseRandomScreen()
}

updateScreenList()
dbgScreen.subscribe(@(_) updateScreenList())

let waitSpinner = {
  size = const [spinnerSize, spinnerSize]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#progress_bar_circle.svg:{spinnerSize}:{spinnerSize}")
  color = 0x01606060
  transform = {}
  animations = [{ prop = AnimProp.rotate, from = 0, to = 360, duration = 3.0, play = true, loop = true }]
}

let bottomBlock = {
  size = FLEX_H
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = progressbarGap
  children = [
    mkProgressStatusText(statusText)
    mkProgressbar(progressPercent, 0xFF7FAEFF)
  ]
}

if (register_command != null)
  screensList.each(@(_, id) register_command(
    @() dbgScreen.get() == id ? dbgScreen.set(null) : dbgScreen.set(id),
    $"debug.loadingScreen.{id}"))

return {
  size = FLEX
  children = [
    loadingAnimBg
    {
      size = FLEX
      padding = saBordersRv
      children = [
        mkTitleLogo()
        waitSpinner
        @() {
          watch = hasAnyMsg
          size = const [FLEX, 0]
          pos = const [0, sh(-20)]
          vplace = ALIGN_BOTTOM
          children = hasAnyMsg.get() ? null : gradientLoadingTip
        }
        bottomBlock
      ]
    }
  ]
}
