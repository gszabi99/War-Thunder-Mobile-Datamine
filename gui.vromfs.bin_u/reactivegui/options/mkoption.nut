from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { contentWidth } = require("optionsStyle.nut")
let { sliderWithButtons, sliderValueSound } = require("%rGui/components/slider.nut")
let listbox = require("%rGui/components/listbox.nut")

let listMinWidth = hdpx(200)
let listMaxWidth = hdpx(600)
let columnsMin = max(1, ceil(contentWidth / listMaxWidth).tointeger())
let columnsMax = max((contentWidth / listMinWidth).tointeger(), columnsMin)
let textColor = 0xFFFFFFFF

let optBlock = @(header, content, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    header == "" ? null : {
      rendObj = ROBJ_TEXT
      color = textColor
      text = header
    }.__update(fontSmall)
    content
  ]
}.__update(ovr)

let optionCtors = {
  [OCT_SLIDER] = function(opt) {
    let { value = null, ctrlOverride = {}, locId = "", valToString = @(v) v, setValue = null} = opt
    if (value == null) {
      logerr($"Options: Missing value for option {opt?.locId}")
      return null
    }
    return sliderWithButtons(value, loc(locId),
      setValue == null ? ctrlOverride
        : ctrlOverride.__merge({
            function onChange(v) {
              sliderValueSound()
              setValue(v)
            }
          }),
      valToString)
  },

  [OCT_LIST] = function(opt) {
    let { value = null, setValue = null, locId = "", list = [], valToString = @(v) v } = opt
    if (value == null) {
      logerr($"Options: Missing value for option {opt?.locId}")
      return null
    }

    if (list instanceof Watched)
      return @() list.value.len() == 0 ? { watch = list }
        : optBlock(loc(locId),
            listbox({ value, list = list.value, valToString, setValue,
              columns = clamp(list.value.len(), columnsMin, columnsMax)
            }),
            { watch = list })

    if (list.len() == 0)
      return null
    return optBlock(loc(locId),
      listbox({ value, list, valToString, setValue,
        columns = clamp(list.len(), columnsMin, columnsMax)
      }))
  },
}

let function mkOption(opt) {
  let { ctrlType = null } = opt
  let ctor = optionCtors?[ctrlType]
  if (ctor == null)
    logerr($"Options: No creator for option ctrlType = {ctrlType}")
  return ctor?(opt)
}

return mkOption
