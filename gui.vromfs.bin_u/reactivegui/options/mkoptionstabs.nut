from "%globalsDarg/darg_library.nut" import *
let { tabW, tabH } = require("optionsStyle.nut")
let { mkTabs } = require("%rGui/components/tabs.nut")
let { mkUnseenMark } = require("%rGui/components/unseenMark.nut")
let { SEEN } = require("%rGui/unseenPriority.nut")

let iconSize = hdpxi(100)

let textColor = 0xFFFFFFFF

let function tabData(tab, idx, curTabIdx) {
  let { locId  = "", image = null, isVisible = null, unseen = null, tabContent = null, tabHeight = tabH } = tab
  local unseenMark = null
  if (unseen != null) {
    let unseenExt = Computed(@() curTabIdx.value == idx ? SEEN : unseen.value)
    unseenMark = mkUnseenMark(unseenExt, { vplace = ALIGN_BOTTOM, hplace = ALIGN_RIGHT })
  }

  return {
    id = idx
    isVisible
    content = {
      size = [ flex(), tabHeight ]
      padding = [hdpx(10), hdpx(20)]
      children = [
        {
          size = flex()
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
            tabContent ?? {
              size = flex()
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              halign = ALIGN_RIGHT
              color = textColor
              text = loc(locId)
            }.__update(fontSmall)
          ]
        }
        unseenMark
      ]
    }
  }
}

return @(tabs, curTabIdx)
  mkTabs(tabs.map(@(t, i) tabData(t, i, curTabIdx)), curTabIdx, { size = [ tabW, SIZE_TO_CONTENT ] })
