from "%globalsDarg/darg_library.nut" import *
let { tabW, tabH } = require("optionsStyle.nut")
let { mkTabs } = require("%rGui/components/tabs.nut")

let iconSize = hdpx(100).tointeger()

let textColor = 0xFFFFFFFF

let function tabData(tab, idx) {
  let { locId  = "", image = null } = tab
  return {
    id = idx
    content = {
      size = [ flex(), tabH ]
      padding = [hdpx(10), hdpx(20)]
      children = [
        image == null ? null
          : {
              size = [iconSize, iconSize]
              vplace = ALIGN_CENTER
              rendObj = ROBJ_IMAGE
              image = Picture($"{image}:{iconSize}:{iconSize}")
              color = textColor
            }
        {
          hplace = ALIGN_RIGHT
          rendObj = ROBJ_TEXT
          color = textColor
          text = loc(locId)
        }.__update(fontSmall)
      ]
    }
  }
}

return @(tabs, curTabIdx)
  mkTabs(tabs.map(@(t, i) tabData(t, i)), curTabIdx).__merge({ size = [ tabW, SIZE_TO_CONTENT ] })
