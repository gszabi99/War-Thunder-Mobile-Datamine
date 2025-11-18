from "%globalsDarg/darg_library.nut" import *

const defaultProgressColor = 0xFFE8E8E8
const progressbarBgColor = 0xFF827A7A
const progressbarHeight = hdpx(15)
const progressbarGap = hdpx(15)

let mkProgressStatusText = @(statusText, addStatusComp = null) @() {
  size = FLEX_H
  valign = ALIGN_BOTTOM
  children = [
    @() {
      watch = statusText
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = statusText.get()
    }.__update(fontMediumShaded)
    addStatusComp
  ]
}

let mkProgressbar = @(progressPercent, progressColor = defaultProgressColor) {
  size = const [flex(), progressbarHeight]
  rendObj = ROBJ_SOLID
  color = progressbarBgColor
  children = @() {
    watch = progressPercent
    size = [pw(progressPercent.get()), flex()]
    rendObj = ROBJ_SOLID
    color = progressColor
  }
}

return {
  mkProgressStatusText
  mkProgressbar
  progressbarGap
}
