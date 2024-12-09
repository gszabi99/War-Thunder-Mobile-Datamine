from "%globalsDarg/darg_library.nut" import *
let { mkTabs } = require("%rGui/components/tabs.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { hasUnseenGoodsByCategory, curCategoryId, onTabChange } = require("shopState.nut")
let { iconSize, iconMarginW, tabW, tabH } = require("shopWndConst.nut")


function tabData(tab, campaign) {
  let { id = "", image = null, getImage = null } = tab
  let icon = getImage?(campaign) ?? image
  return {
    id
    size = [flex(), SIZE_TO_CONTENT]
    override = { size = [tabW, SIZE_TO_CONTENT] }
    content = {
      size = [flex(), tabH]
      children = [
        icon == null ? null
          : {
              size = [iconSize, iconSize]
              rendObj = ROBJ_IMAGE
              image = Picture($"{icon}:{iconSize}:{iconSize}:P")
              keepAspect = KEEP_ASPECT_FIT
              imageHalign = ALIGN_CENTER
              imageValign = ALIGN_CENTER
              margin = [0, iconMarginW]
            }
        @() {
          watch = [hasUnseenGoodsByCategory, curCategoryId]
          margin = hdpx(6)
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
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
