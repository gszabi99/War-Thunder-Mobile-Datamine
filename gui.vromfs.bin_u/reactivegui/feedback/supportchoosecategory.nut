from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { OCT_LIST } = require("%rGui/options/optCtrlType.nut")
let mkOption = require("%rGui/options/mkOption.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { categoryList, getCategoryLocName, fieldCategory } = require("%rGui/feedback/supportState.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let onClose = @() isOpened(false)

let mkVerticalPannableArea = @(content, override) {
  size = flex()
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = flex()
    behavior = Behaviors.Pannable
    skipDirPadNav = true
    children = content
  }
}.__update(override)

let header = {
  size = [flex(), SIZE_TO_CONTENT]
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
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    header
    mkVerticalPannableArea(categoriesBlock, { size = flex() })
  ]
  animations = wndSwitchAnim
})

registerScene("supportChooseCategoryWnd", supportChooseCategoryWnd, onClose, isOpened)

return @() isOpened(true)
