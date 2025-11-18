from "%globalsDarg/darg_library.nut" import *
let { mkTabs } = require("%rGui/components/tabs.nut")
let mkAvailAttrMark = require("%rGui/attributes/mkAvailAttrMark.nut")

let tabH = hdpx(165)
let contentMargin = hdpx(20)

let textColor = 0xFFFFFFFF

let mkStatus = @(statusW) @() {
  watch = statusW
  margin = [contentMargin, contentMargin]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = mkAvailAttrMark(statusW.get())
}

function tabData(tab) {
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
              image = Picture($"{image}:0:P")
              keepAspect = KEEP_ASPECT_FIT
              imageHalign = ALIGN_LEFT
              imageValign = ALIGN_BOTTOM
              color = textColor
            }
        {
          hplace = ALIGN_RIGHT
          margin = [contentMargin - hdpx(10), contentMargin] 
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
