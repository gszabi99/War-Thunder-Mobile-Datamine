from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { contentWidth } = require("optionsStyle.nut")
let { sliderWithButtons, sliderValueSound } = require("%rGui/components/slider.nut")
let listbox = require("%rGui/components/listbox.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { infoCommonButton } = require("%rGui/components/infoButton.nut")
let { showTooltip, hideTooltip } = require("%rGui/tooltip.nut")

let listMinWidth = hdpx(200)
let listMaxWidth = hdpx(600)
let columnsMin = max(1, ceil(contentWidth / listMaxWidth).tointeger())
let columnsMax = max((contentWidth / listMinWidth).tointeger(), columnsMin)

let function mkHeader(header, child) {
  if (header == "")
    return null

  let textComp = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    colorTable = {
      darken = 0xFFFFFFFF
    }
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

let function mkInfoButton(desc, locId){
  if(desc == "")
    return null

  let stateFlags = Watched(0)
  let key = {}
  return @(){
    key
    watch = stateFlags
    behavior = Behaviors.Button
    xmbNode = {}
    function onElemState(sf) {
      let hasHint = (stateFlags.value & S_ACTIVE) != 0
      let needHint =  (sf & S_ACTIVE) != 0
      stateFlags(sf)
      if (hasHint == needHint)
        return
      if (needHint)
        showTooltip(gui_scene.getCompAABBbyKey(key), {
          content = "\n".concat(loc(locId), desc),
          halign = ALIGN_LEFT })
      else
        hideTooltip()
    }
    fillColor = 0
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_VECTOR_CANVAS
    size = [hdpx(40),hdpx(40)]
    lineWidth = hdpx(2)
    commands = [
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    children = [
      {
        rendObj = ROBJ_TEXT
        text = "?"
        halign = ALIGN_CENTER
      }.__update(fontTinyAccented)
    ]
  }
}

let optBlock = @(header, content, openInfo, desc, locId, ovr = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkHeader(header,
      openInfo != null ? infoCommonButton(openInfo)
        : mkInfoButton(desc, locId))
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
    let { value = null, setValue = null, locId = "", list = [], valToString = @(v) v, openInfo = null,
      description = ""} = opt
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
            openInfo, description, locId,
            { watch = list })

    if (list.len() == 0)
      return null
    return optBlock(loc(locId),
      listbox({ value, list, valToString, setValue,
        columns = clamp(list.len(), columnsMin, columnsMax)
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

let function mkOption(opt) {
  let { ctrlType = null } = opt
  let ctor = optionCtors?[ctrlType]
  if (ctor == null)
    logerr($"Options: No creator for option ctrlType = {ctrlType}")
  return ctor?(opt)
}

return mkOption
