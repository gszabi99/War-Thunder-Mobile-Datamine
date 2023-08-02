from "%globalsDarg/darg_library.nut" import *
let { mkTabs } = require("%rGui/components/tabs.nut")
let mkAvailAttrMark = require("mkAvailAttrMark.nut")

let tabH = hdpx(184)
let contentMargin = hdpx(20)

let textColor = 0xFFFFFFFF

let mkStatus = @(statusW) @() {
  watch = statusW
  margin = [contentMargin, contentMargin]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = mkAvailAttrMark(statusW.value)
}

let function tabData(tab) {
  let { id = "", locId  = "", image = null, statusW = null } = tab
  return {
    id
    content = {
      size = [ flex(),  tabH ]
      children = [
        image == null ? null
          : {
              size = flex()
              rendObj = ROBJ_IMAGE
              image = Picture(image)
              keepAspect = KEEP_ASPECT_FILL
              imageHalign = ALIGN_LEFT
              imageValign = ALIGN_BOTTOM
              color = textColor
            }
        {
          hplace = ALIGN_RIGHT
          margin = [contentMargin - hdpx(10), contentMargin] //text block is bigger than visual
          rendObj = ROBJ_TEXT
          color = textColor
          text = loc(locId)
          fontFx = FFT_GLOW
          fontFxFactor = 48
          fontFxColor = 0xFF000000
        }.__update(fontSmall)
        statusW != null ? mkStatus(statusW) : null
      ]
    }
  }
}

return {
  mkUnitAttrTabs = @(tabs, curTabId)
    mkTabs(tabs.map(@(t) tabData(t)), curTabId)
}
