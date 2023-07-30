from "%globalsDarg/darg_library.nut" import *
let textInput = require("textInputBase.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")

let paddingY = (0.3 * defButtonHeight).tointeger()
let contentHeight = defButtonHeight - 2 * paddingY
let defOptions = {
  size = [flex(), contentHeight]
  padding = [paddingY, hdpx(15)]
  textmargin = 0
  valignText = ALIGN_CENTER
  colors = { backGroundColor = Color(61, 66, 72), textColor = Color(255, 255, 255) }
  margin = 0
  showPlaceHolderOnFocus = true
}.__update(fontSmall)

let defFrame = @(inputObj, group, _sf) {
  size = [flex(), SIZE_TO_CONTENT]
  group
  valign = ALIGN_CENTER
  children = inputObj
}

return {
  textInput = @(text_state, optionsOvr = {})
    textInput(text_state, defOptions.__merge(optionsOvr), defFrame)
}