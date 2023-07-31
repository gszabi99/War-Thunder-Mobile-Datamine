from "%globalsDarg/darg_library.nut" import *
let { tabW, tabH } = require("optionsStyle.nut")
let { mkTabs } = require("%rGui/components/tabs.nut")

let iconSize = hdpx(100).tointeger()

let textColor = 0xFFFFFFFF

let function tabData(tab, idx) {
  let { locId  = "", image = null, isVisible = null } = tab
  return {
    id = idx
    isVisible
    content = {
      size = [ flex(), tabH ]
      padding = [hdpx(10), hdpx(20)]
      flow = FLOW_HORIZONTAL
      children = [
        image == null ? null
          : {
              size = [iconSize, iconSize]
              vplace = ALIGN_CENTER
              rendObj = ROBJ_IMAGE
              image = Picture($"{image}:{iconSize}:{iconSize}:P")
              color = textColor
              keepAspect = KEEP_ASPECT_FIT
            }
        {
          size = flex()
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_RIGHT
          color = textColor
          text = loc(locId)
        }.__update(fontSmall)
      ]
    }
  }
}

return @(tabs, curTabIdx)
  mkTabs(tabs.map(@(t, i) tabData(t, i)), curTabIdx, { size = [ tabW, SIZE_TO_CONTENT ] })
