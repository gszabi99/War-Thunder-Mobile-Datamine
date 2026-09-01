from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/backButton.nut" import backButton
from "%rGui/feedback/supportState.nut" import categoryList, getCategoryLocName, fieldCategory
from "%rGui/navState.nut" import registerScene
import "%rGui/options/mkOption.nut" as mkOption
from "%rGui/options/optCtrlType.nut" import OCT_LIST
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let isOpened = mkWatched(persist, "isOpened", false)
let onClose = @() isOpened.set(false)

let mkVerticalPannableArea = @(content, override) {
  size = FLEX
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = FLEX
    behavior = Behaviors.Pannable
    touchMarginPriority = TOUCH_BACKGROUND
    skipDirPadNav = true
    children = content
  }
}.__update(override)

let header = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    backButton(onClose)
    {
      hplace = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = loc("support/form/hint/select_a_category")
    }.__update(fontBig)
  ]
}

let optCategory = {
  ctrlType = OCT_LIST
  value = fieldCategory
  list = Watched(categoryList)
  valToString = getCategoryLocName
  columnsMaxCustom = 2
  function setValue(v) {
    fieldCategory.set(v)
    onClose()
  }
}

let categoriesBlock = mkOption(optCategory)

let supportChooseCategoryWnd = bgShaded.__merge({
  key = {}
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    header
    mkVerticalPannableArea(categoriesBlock, { size = FLEX })
  ]
  animations = wndSwitchAnim
})

registerScene("supportChooseCategoryWnd", supportChooseCategoryWnd, onClose, isOpened)

return @() isOpened.set(true)
