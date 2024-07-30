from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { contentWidth } = require("optionsStyle.nut")
let { sliderWithButtons, sliderValueSound } = require("%rGui/components/slider.nut")
let listbox = require("%rGui/components/listbox.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { infoCommonButton, infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { resetTimeout } = require("dagor.workcycle")


let listMinWidth = hdpx(200)
let listMaxWidth = hdpx(600)
let columnsMin = max(1, ceil(contentWidth / listMaxWidth).tointeger())
let columnsMax = max((contentWidth / listMinWidth).tointeger(), columnsMin)

function mkHeader(header, child) {
  if (header == "")
    return null

  let textComp = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = header
  }.__update(fontSmall)

  if (child == null)
    return textComp

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      textComp
      child
    ]
  }
}

let optBlock = @(header, content, openInfo, desc, locId, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkHeader(header,
      openInfo != null ? infoCommonButton(openInfo)
        : desc != "" ? infoTooltipButton(@() "\n".concat(colorize("@darken", loc(locId)), desc), { halign = ALIGN_LEFT })
        : null)
    content
  ]
}.__update(ovr)

let optionCtors = {
  [OCT_SLIDER] = function(opt) {
    let { value = null, ctrlOverride = {}, locId = "", valToString = @(v) v, setValue = null, onChangeValue = null} = opt
    if (value == null) {
      logerr($"Options: Missing value for option {opt?.locId}")
      return null
    }
    let sendChangeValue = @() onChangeValue?(value.get())
    return sliderWithButtons(value, loc(locId),
      setValue == null && onChangeValue == null ? ctrlOverride
        : ctrlOverride.__merge({
          function onChange(v) {
            sliderValueSound()
            if (setValue != null)
              setValue(v)
            else
              value.set(v)
            resetTimeout(1, sendChangeValue)
         }
       }),
      valToString)
  },

  [OCT_LIST] = function(opt) {
    let { value = null, setValue = null, onChangeValue = null, locId = "", list = [], valToString = @(v) v, openInfo = null,
      description = "", mkContentCtor = null } = opt
    if (value == null) {
      logerr($"Options: Missing value for option {opt?.locId}")
      return null
    }
    let sendChangeValue = function(v) {
      if(setValue == null)
        value.set(v)
      else
        setValue(v)
      onChangeValue?(v)
    }
    if (list instanceof Watched)
      return @() list.value.len() == 0 ? { watch = list }
        : optBlock(loc(locId),
            listbox({ value, list = list.value, valToString,
              setValue = sendChangeValue,
              columns = clamp(list.value.len(), columnsMin, columnsMax),
              mkContentCtor
            }),
            openInfo, description, locId,
            { watch = list })

    if (list.len() == 0)
      return null
    return optBlock(loc(locId),
      listbox({ value, list, valToString,
        setValue = sendChangeValue,
        columns = clamp(list.len(), columnsMin, columnsMax),
        mkContentCtor
      }),
      openInfo, description, locId)
  },

  [OCT_BUTTON] = function(opt) {
    let { locId = null, onClick = null } = opt
    if (locId == null || onClick == null) {
      logerr($"Options: Missing locId or onClick for button option {locId}")
      return null
    }
    return textButtonCommon(loc(locId), onClick,
      { ovr = { hplace = ALIGN_LEFT, margin = [0, 0, hdpx(30), 0] } })
  }
}

function mkOption(opt) {
  let { ctrlType = null, comp = null } = opt
  if (comp != null)
    return comp

  let ctor = optionCtors?[ctrlType]
  if (ctor == null)
    logerr($"Options: No creator for option ctrlType = {ctrlType}, comp = {comp}")
  return ctor?(opt)
}

return mkOption
