from "%globalsDarg/darg_library.nut" import *
let textInput = require("textInputBase.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")

let paddingY = (0.3 * defButtonHeight).tointeger()
let defOptions = {
  ovr = {
    size = [flex(), defButtonHeight]
    padding = [paddingY, hdpx(15)]
    fillColor = Color(61, 66, 72)
  }
  textStyle = fontSmall
  showPlaceHolderOnFocus = true
}

let function mergeInputOptions(o1, o2) {
  let res = o1.__merge(o2)
  foreach(key in ["ovr", "textStyle"])
    if ((key in o2) && (key in o1))
      res[key] <- o1[key].__merge(o2[key])
  return res
}

return {
  textInput = @(text_state, optionsOvr = {})
    textInput(text_state, mergeInputOptions(defOptions, optionsOvr))
}