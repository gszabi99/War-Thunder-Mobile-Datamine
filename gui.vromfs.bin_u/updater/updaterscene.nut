from "%globalsDarg/darg_library.nut" import *
let { statusText, progressPercent } = require("updaterState.nut")
let { loadingAnimBg } = require("%globalsDarg/loading/loadingAnimBg.nut")
let { titleLogo } = require("%globalsDarg/components/titleLogo.nut")
let { gradientLoadingTip } = require("loadingTip.nut")

let spinnerSize = hdpxi(100)

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
        titleLogo
        waitSpinner
        gradientLoadingTip
        bottomBlock
      ]
    }
  ]
}
