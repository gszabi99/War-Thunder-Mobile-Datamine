from "%globalsDarg/darg_library.nut" import *
let { register_command  = null } = require_optional("console") 
let { statusText, progressPercent } = require("updaterState.nut")
let { screensList } = require("%globalsDarg/loading/loadingScreensCfg.nut")
let { screenWeights, loadingAnimBg, chooseRandomScreen, curScreenId } = require("%globalsDarg/loading/loadingAnimBg.nut")
let { mkProgressStatusText, mkProgressbar, progressbarGap } = require("%globalsDarg/loading/loadingProgressbar.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { gradientLoadingTip } = require("loadingTip.nut")

let spinnerSize = hdpxi(100)





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
  size = [spinnerSize, spinnerSize]
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
  size = flex()
  children = [
    loadingAnimBg
    {
      size = flex()
      padding = saBordersRv
      children = [
        mkTitleLogo()
        waitSpinner
        gradientLoadingTip
        bottomBlock
      ]
    }
  ]
}
