from "%globalsDarg/darg_library.nut" import *
let { mkTabs } = require("%rGui/components/tabs.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { hasUnseenGoodsByCategory, curCategoryId, onTabChange } = require("shopState.nut")

let tabW = hdpx(450)
let tabH = hdpx(153)

let textColor = 0xFFFFFFFF
let iconSize = hdpxi(130)

let function tabData(tab, campaign) {
  let { id = "", image = null, title = "", getImage = null, getTitle = null } = tab
  return {
    id
    content = {
      size = [flex(), tabH]
      children = [
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          children = [
            {
              size = [iconSize, iconSize]
              rendObj = ROBJ_IMAGE
              image = Picture($"{getImage?(campaign) ?? image}:{iconSize}:{iconSize}")
              keepAspect = KEEP_ASPECT_FIT
              imageHalign = ALIGN_LEFT
              imageValign = ALIGN_BOTTOM
              color = textColor
              margin = [0, hdpx(10)]
            }
            {
              size = flex()
              halign = ALIGN_RIGHT
              margin = [hdpx(15), hdpx(20)]
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              textOverflowX = TOVERFLOW_WORD
              color = textColor
              text = getTitle?(campaign) ?? title
              fontFx = FFT_GLOW
              fontFxFactor = hdpx(48)
              fontFxColor = 0xFF000000
            }.__update(fontSmall)
          ]
        }
        @() {
          watch = [hasUnseenGoodsByCategory, curCategoryId]
          margin = hdpx(30)
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          children = id == curCategoryId.value || !hasUnseenGoodsByCategory.value?[id] ? null
            : priorityUnseenMark
        }
      ]
    }
  }
}

return {
  mkShopTabs = @(tabs, curTabId, campaign)
    mkTabs(tabs.map(@(t) tabData(t, campaign)), curTabId, {}, onTabChange)
  tabW
}
