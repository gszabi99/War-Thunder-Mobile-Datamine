from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/tabs.nut" import mkTabs
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/shop/shopState.nut" import onTabChange
from "%rGui/shop/shopWndConst.nut" import iconSize, iconMarginW, tabW, tabH


function tabData(tab, campaign, hasUnseenGoodsByCategory, curTabId) {
  let { id = "", image = null, getImage = null } = tab
  let icon = getImage?(campaign) ?? image
  return {
    id
    size = FLEX_H
    override = { size = [tabW, SIZE_TO_CONTENT], key = $"shop_tab_{id}" } 
    content = {
      size = [FLEX, tabH]
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
          watch = [hasUnseenGoodsByCategory, curTabId]
          margin = hdpx(6)
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = id == curTabId.get() || !hasUnseenGoodsByCategory.get()?[id] ? null
            : priorityUnseenMark
        }
      ]
    }
  }
}

return {
  mkShopTabs = @(tabs, curTabId, campaign, hasUnseenGoodsByCategory, onTabChangeFn = onTabChange)
    mkTabs(tabs.map(@(t) tabData(t, campaign, hasUnseenGoodsByCategory, curTabId)), curTabId, {}, onTabChangeFn)
  tabW
}
