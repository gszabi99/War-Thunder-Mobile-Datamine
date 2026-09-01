from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/backButton.nut" import backButtonHeight
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth, defButtonHeight
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/style/stdColors.nut" import selectColor


const iconSize = hdpxi(34)
const margin = hdpx(10)
const commonBgGradColor = 0x990C1113
let secondaryGradColor = selectColor
const sectionBtnHeight = hdpx(80)
const sectionBtnMaxWidth = hdpx(300)
const sectionBtnGap = hdpx(10)
const lineWidth = hdpx(5)
let collapseBtnSize = [sectionBtnHeight, sectionBtnHeight]
let bgGradient = mkColoredGradientY(commonBgGradColor, secondaryGradColor, 12)
const gamercardPadding = hdpx(10)
let gamercardHeight = backButtonHeight + gamercardPadding * 2

let unseenMark = {
  size = FLEX
  halign = ALIGN_RIGHT
  valign = ALIGN_TOP
  padding = hdpx(10)
  children = priorityUnseenMark
}

let mkGradText = @(text) doubleSideGradient.__merge({
  size = [SIZE_TO_CONTENT, defButtonHeight]
  minWidth = defButtonMinWidth
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(text)
  }.__update(fontSmall)
})

let mkIcon = @(img, ovr = {}) {
  size = iconSize
  margin
  rendObj = ROBJ_IMAGE
  image = Picture($"{img}:{iconSize}:{iconSize}:P")
  keepAspect = true
}.__update(ovr)

let mkArrowImageComp = @(isExpanded) {
  size = iconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#back_icon.svg:{iconSize}:{iconSize}:P")
  color = 0xFFFFFFFF
  transform = { rotate = !isExpanded ? 90 : 270 }
  transitions = [{ prop = AnimProp.rotate, from = 0, to = 180, duration = 0.1 }]
}

let toggleSectionBtn = @(isExpanded) {
  size = collapseBtnSize
  rendObj = ROBJ_BOX
  borderColor = secondaryGradColor
  borderWidth = const [lineWidth, lineWidth, 0, lineWidth]
  padding = const [lineWidth, lineWidth, 0, lineWidth]
  children = @() {
    watch = isExpanded
    size = FLEX
    padding = margin
    rendObj = ROBJ_BOX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    fillColor = commonBgGradColor
    behavior = Behaviors.Button
    onClick = @() isExpanded.set(!isExpanded.get())
    children = mkArrowImageComp(isExpanded.get())
  }
}

let mkSectionBtn = @(id, onClick, isSelected, hasUnseenContent) {
  size = const [FLEX, sectionBtnHeight]
  maxWidth = sectionBtnMaxWidth
  behavior = Behaviors.Button
  onClick
  sound = { click = "choose" }
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = commonBgGradColor
    }
    @() {
      watch = isSelected
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = bgGradient
      opacity = isSelected.get() ? 1 : 0
      transitions = [{ prop = AnimProp.opacity, duration = 0.3, easing = InOutQuad }]
    }
    {
      size = FLEX
      margin = const [0, sectionBtnGap / 2]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextArea, Behaviors.Marquee]
        delay = defMarqueeDelay
        text = utf8ToUpper(loc($"mainmenu/customization/{id}"))
      }.__update(fontTinyAccented)
    }
    hasUnseenContent ? unseenMark : null
  ]
}

let mkSectionTabs = @(sections, isExpanded, hasUnseenBySection, curSectionId = Watched(null), onSectionChange = @(_) null) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = sectionBtnGap
  rendObj = ROBJ_BOX
  borderColor = secondaryGradColor
  borderWidth = const [0, 0, lineWidth, 0]
  padding = const [0, 0, lineWidth, 0]
  children = [toggleSectionBtn(isExpanded)].extend(sections.map(@(id)
    mkSectionBtn(id, @() onSectionChange(id), Computed(@() curSectionId.get() == id), hasUnseenBySection?[id] ?? false)))
}

return {
  mkSectionTabs
  mkGradText
  mkIcon
  iconSize
  sectionBtnGap
  gamercardHeight
}
