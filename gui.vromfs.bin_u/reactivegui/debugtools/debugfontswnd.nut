from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { arrayByRows } = require("%sqstd/underscore.nut")
let fontStyleAll = require("%globalsDarg/fontsStyle.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")


let isOpened = mkWatched(persist, "isOpened", false)
let curText = mkWatched(persist, "curText", "")

let wndHeaderHeight = hdpx(60)
let opacityGradientSize = saBorders[1]
let wndContentHeight = saSize[1] - wndHeaderHeight + opacityGradientSize
let hGap = hdpx(30)
let vGap = hdpx(20)
let colCount = max(3, saSize[0] / hdpxi(700))

let close = @() isOpened.set(false)

let viewText = Computed(@() curText.get() == "" ? "Text example 1230" : curText.get())

let inputBlock = textInput(curText, {
  ovr = {
    size = const [hdpx(400), hdpx(60)]
    padding = const [hdpx(10), hdpx(20)]
  }
  onAttach = @() set_kb_focus(curText) 
  onEscape = @() curText.get() == "" ? close() : curText.set("")
  placeholder = "Input text here..."
})

let wndHeader = {
  size = [flex(), wndHeaderHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(15)
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      text = "ui.debug.fonts"
    }.__update(fontBig)
    { size = flex() }
    inputBlock
  ]
}

let textResultBlock = @(id, style) {
  size = FLEX_H
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  fillColor = 0x800F0F0F
  borderColor = 0xFF323232
  padding = hdpx(5)
  gap = hdpx(5)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = id
    }.__update(style)
     @() {
      watch = viewText
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = viewText.get()
      halign = ALIGN_CENTER
    }.__update(style)
  ]
}

function textsList() {
  let fontBoxes = [].extend(fontsLists.common, fontsLists.accented, fontsLists.monospace)
    .reduce(@(res, style, idx) res.append({ id = fontStyleAll.findindex(@(v) v == style) ?? idx, style }), [])
    .sort(@(a, b)  (a.style?.fontSize ?? 0) <=> (b.style?.fontSize ?? 0))
    .map(@(d) textResultBlock(d.id, d.style))
  return {
    size = FLEX_H
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = vGap
    children = arrayByRows(fontBoxes, colCount)
      .map(@(children) {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = hGap
        children
      })
  }
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight, [opacityGradientSize, opacityGradientSize])
let mkDebugFontsWnd = @() bgShaded.__merge({
  key = isOpened
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    pannableArea(textsList)
  ]
  animations = wndSwitchAnim
})

registerScene("debugFontsWnd", mkDebugFontsWnd, close, isOpened)

register_command(@() isOpened.set(true), "ui.debug.fonts")
