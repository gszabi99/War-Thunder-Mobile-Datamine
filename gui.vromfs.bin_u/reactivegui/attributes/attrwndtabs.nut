from "%globalsDarg/darg_library.nut" import *
import "%rGui/attributes/mkAvailAttrMark.nut" as mkAvailAttrMark
from "%rGui/components/tabs.nut" import mkTabs


const tabH = hdpx(165)
const contentMargin = hdpx(20)

const textColor = 0xFFFFFFFF

let mkStatus = @(statusW) @() {
  watch = statusW
  margin = const [contentMargin, contentMargin]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = mkAvailAttrMark(statusW.get())
}

function tabData(tab) {
  let { id = "", locId  = "", image = null, statusW = null } = tab
  return {
    id
    content = {
      size = const [ FLEX,  tabH ]
      children = [
        image == null ? null
          : {
              size = FLEX
              rendObj = ROBJ_IMAGE
              image = Picture($"{image}:0:P")
              keepAspect = KEEP_ASPECT_FIT
              imageHalign = ALIGN_LEFT
              imageValign = ALIGN_BOTTOM
              color = textColor
            }
        {
          hplace = ALIGN_RIGHT
          margin = const [contentMargin - hdpx(10), contentMargin] 
          rendObj = ROBJ_TEXT
          color = textColor
          text = loc(locId)
        }.__update(fontTinyShaded)
        statusW != null ? mkStatus(statusW) : null
      ]
    }
  }
}

return {
  contentMargin
  mkAttrTabs = @(tabs, curTabId)
    mkTabs(tabs.map(@(t) tabData(t)), curTabId)
}
