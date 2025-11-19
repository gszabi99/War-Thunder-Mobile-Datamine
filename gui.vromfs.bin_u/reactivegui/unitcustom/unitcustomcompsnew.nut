from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")
let { backButtonHeight } = require("%rGui/components/backButton.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let iconSize = hdpxi(34)
let margin = hdpx(10)
let commonBgGradColor = 0x990C1113
let secondaryGradColor = selectColor
let sectionBtnHeight = hdpx(80)
let sectionBtnMaxWidth = hdpx(300)
let sectionBtnGap = hdpx(10)
let lineWidth = hdpx(5)
let collapseBtnSize = [sectionBtnHeight, sectionBtnHeight]
let bgGradient = mkColoredGradientY(commonBgGradColor, secondaryGradColor, 12)
let gamercardPadding = hdpx(10)
let gamercardHeight = backButtonHeight + gamercardPadding * 2

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
  borderWidth = [lineWidth, lineWidth, 0, lineWidth]
  padding = [lineWidth, lineWidth, 0, lineWidth]
  children = @() {
    watch = isExpanded
    size = flex()
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

let mkSectionBtn = @(id, onClick, isSelected) {
  size = [flex(), sectionBtnHeight]
  maxWidth = sectionBtnMaxWidth
  behavior = Behaviors.Button
  onClick
  sound = { click = "choose" }
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = commonBgGradColor
    }
    @() {
      watch = isSelected
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient
      opacity = isSelected.get() ? 1 : 0
      transitions = [{ prop = AnimProp.opacity, duration = 0.3, easing = InOutQuad }]
    }
    {
      size = flex()
      margin = [0, sectionBtnGap / 2]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextArea, Behaviors.Marquee]
        delay = defMarqueeDelay
        text = utf8ToUpper(loc($"mainmenu/customization/{id}"))
      }.__update(fontTinyAccented)
    }
  ]
}

let mkSectionTabs = @(sections, isExpanded, curSectionId = Watched(null), onSectionChange = @(_) null) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = sectionBtnGap
  rendObj = ROBJ_BOX
  borderColor = secondaryGradColor
  borderWidth = [0, 0, lineWidth, 0]
  padding = [0, 0, lineWidth, 0]
  children = [toggleSectionBtn(isExpanded)].extend(sections.map(@(id)
    mkSectionBtn(id, @() onSectionChange(id), Computed(@() curSectionId.get() == id))))
}

return {
  mkSectionTabs
  mkGradText
  mkIcon
  iconSize
  sectionBtnGap
  gamercardHeight
}
