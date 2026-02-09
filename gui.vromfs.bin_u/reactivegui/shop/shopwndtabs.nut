from "%globalsDarg/darg_library.nut" import *
let { mkTabs } = require("%rGui/components/tabs.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { curCategoryId, onTabChange } = require("%rGui/shop/shopState.nut")
let { iconSize, iconMarginW, tabW, tabH } = require("%rGui/shop/shopWndConst.nut")


function tabData(tab, campaign, hasUnseenGoodsByCategory) {
  let { id = "", image = null, getImage = null } = tab
  let icon = getImage?(campaign) ?? image
  return {
    id
    size = FLEX_H
    override = { size = [tabW, SIZE_TO_CONTENT] }
    content = {
      size = [flex(), tabH]
      children = [
        icon == null ? null
          : @() {
              watch = icon instanceof Watched ? icon : null
              size = [iconSize, iconSize]
              rendObj = ROBJ_IMAGE
              image = Picture($"{icon instanceof Watched ? icon.get() : icon}:{iconSize}:{iconSize}:P")
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
          children = id == curCategoryId.get() || !hasUnseenGoodsByCategory.get()?[id] ? null
            : priorityUnseenMark
        }
      ]
    }
  }
}

return {
  mkShopTabs = @(tabs, curTabId, campaign, hasUnseenGoodsByCategory)
    mkTabs(tabs.map(@(t) tabData(t, campaign, hasUnseenGoodsByCategory)), curTabId, {}, onTabChange)
  tabW
}
