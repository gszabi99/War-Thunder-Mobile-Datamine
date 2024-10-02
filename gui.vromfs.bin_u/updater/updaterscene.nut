from "%globalsDarg/darg_library.nut" import *
let { statusText, progressPercent } = require("updaterState.nut")
let { screensList } = require("%globalsDarg/loading/loadingScreensCfg.nut")
let { screenWeights, loadingAnimBg } = require("%globalsDarg/loading/loadingAnimBg.nut")
let { mkTitleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { gradientLoadingTip } = require("loadingTip.nut")

let spinnerSize = hdpxi(100)

// ONLY images for those LoadingScreen IDs exist in Updater VROMs,
// and if you edit this list, you MUST make the correcponding changes in Updater VROMs too.
// Also you may need to change the "fallbackLoadingImage" in loadingScreensCfg.nut,
// because "fallbackLoadingImage" image MUST exist in both game client VROMs and Updater VROMs.
let loadingScreensWhitelist = [
  "simple_ship_6"
  "simple_tank_7"
  "simple_airplane_3"
]
screenWeights.set(screensList
  .filter(@(_, k) loadingScreensWhitelist.contains(k))
  .map(@(s) s.weight))

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
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  children = [
    @() {
      watch = statusText
      rendObj = ROBJ_TEXT
      text = statusText.value
    }.__update(fontMediumShaded)
    {
      size = [flex(), hdpx(15)]
      rendObj = ROBJ_SOLID
      color = 0xFF827A7A
      children = @() {
        watch = progressPercent
        size = [pw(progressPercent.value), flex()]
        rendObj = ROBJ_SOLID
        color = 0xFF00FDFF
      }
    }
  ]
}

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
