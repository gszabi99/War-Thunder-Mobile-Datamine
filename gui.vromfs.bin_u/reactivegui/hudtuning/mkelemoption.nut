from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { optionWidth } = require("%rGui/hudTuning/hudTuningConsts.nut")
let listbox = require("%rGui/components/listbox.nut")
let { sliderWithButtons, sliderValueSound, sliderH, sliderBtnSize, sliderGap
} = require("%rGui/components/slider.nut")
let { infoGreyButton, infoTooltipButton } = require("%rGui/components/infoButton.nut")


let columnsMin = 1
let columnsMax = 5

let checkBoxIconSize = hdpxi(60)

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
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      child
      textComp
    ]
  }
}

let mkTooltipContentCtor = @(title, desc) @() "\n".concat(
  colorize("@darken", title),
  type(desc) == "function" ? desc() : desc
)

let optBlock = @(header, content, openInfo, desc, locId, ovr = {}) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = [
    mkHeader(header,
      openInfo != null ? infoGreyButton(openInfo, { size = [evenPx(40), evenPx(40)] })
        : desc != "" ? infoTooltipButton(mkTooltipContentCtor(loc(locId), desc), { flowOffset = hdpx(80) })
        : null)
    content
  ]
}.__update(ovr)

let optionCtors = {
  [OCT_LIST] = function(optCfg, value, setValue) {
    let { locId = "", list = [], valToString = @(v) v, openInfo = null, description = "" } = optCfg

    if (list instanceof Watched)
      return @() list.get().len() == 0 ? { watch = list }
        : optBlock(loc(locId),
            listbox({
              value,
              list = list.get(),
              valToString,
              setValue,
              columns = clamp(list.get().len(), columnsMin, columnsMax),
            }),
            openInfo, description, locId,
            { watch = list })

    if (list.len() == 0)
      return null

    return optBlock(loc(locId),
      listbox({
        value,
        setValue,
        list,
        valToString,
        columns = clamp(list.len(), columnsMin, columnsMax)
      }),
      openInfo, description, locId)
  },

  [OCT_CHECKBOX] = function(optCfg, value, setValue) {
    let { locId = "", icon = "check.svg" } = optCfg
    let stateFlags = Watched(0)

    return {
      behavior = Behaviors.Button
      onElemState = @(v) stateFlags.set(v)
      onClick = @() setValue(!value.get())
      sound = { click = "click" }
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      gap = hdpx(10)
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc(locId)
          color = 0xFFFFFFFF
        }.__update(fontSmall)
        {
          size = hdpx(80)
          rendObj = ROBJ_BOX
          borderColor = 0xFF9FA7AF
          borderWidth = hdpx(3)
          fillColor = 0x88000000
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = @() {
            watch = [value, stateFlags]
            size = checkBoxIconSize
            rendObj = ROBJ_IMAGE
            image = value.get()
              ? Picture($"ui/gameuiskin#{icon}:{checkBoxIconSize}:{checkBoxIconSize}:P")
              : null
            keepAspect = KEEP_ASPECT_FIT
            color = stateFlags.get() & S_HOVER ? 0xFF7FAEFF : 0xFFFFFFFF
          }
        }
      ]
    }
  },

  [OCT_SLIDER] = function(optCfg, value, setValue) {
    let { ctrlOverride = {}, locId = "", valToString = @(v) v } = optCfg
    let trackWidth = (optCfg?.rowWidth ?? optionWidth) - 2 * sliderBtnSize - 2 * sliderGap
    return sliderWithButtons(value, loc(locId),
      ctrlOverride.__merge({
        size = [trackWidth, sliderH]
        function onChange(v) {
          sliderValueSound()
          setValue(v, 1.0)
        }
      }),
      valToString)
  },
}

function mkElemOption(optCfg, elemId, options, modifyOptions) {
  let { value = null, ctrlType = null, getValue = null, setValue = null, locId = "", onChangeValue = null } = optCfg
  let ctor = optionCtors?[ctrlType]
  if (ctor == null) {
    logerr($"Options: No creator for option ctrlType = {ctrlType}")
    return null
  }
  if (value == null && (getValue == null || setValue == null)) {
    logerr($"Options: Missing value for option {optCfg?.locId}")
    return null
  }

  let optValue = value ?? Computed(@() getValue(options.get(), elemId))
  let sendChangeValue = function(v, changeStackTime = 0) {
    onChangeValue?(v)
    return v == optValue.get() ? null
      : value != null ? value.set(v)
      : changeStackTime <= 0 ? modifyOptions(@(o) setValue(o, elemId, v))
      : modifyOptions(@(o) setValue(o, elemId, v), $"{locId}&{elemId}", changeStackTime)
  }
  return ctor?(optCfg, optValue, sendChangeValue)
}

function mkAllElemsOption(optCfg, allIds, options, modifyOptions) {
  let { ctrlType = null, getValue = null, setValue = null, locId = "" } = optCfg
  let ctor = optionCtors?[ctrlType]
  if (ctor == null) {
    logerr($"Options: No creator for option ctrlType = {ctrlType}")
    return null
  }
  if (getValue == null || setValue == null) {
    logerr($"Options: Missing value for option {optCfg?.locId}")
    return null
  }
  let value = Computed(function() {
    let counts = {}
    local maxCount = 0
    foreach(id in allIds) {
      let v = getValue(options.get(), id)
      let c = (counts?[v] ?? 0) + 1
      counts[v] <- c
      maxCount = max(c, maxCount)
    }
    return counts.findindex(@(c) c == maxCount)
  })
  function setValueForAll(o, v) {
    foreach(id in allIds)
      setValue(o, id, v)
  }
  let setValueExt = @(v, changeStackTime = 0) changeStackTime <= 0
    ? modifyOptions(@(o) setValueForAll(o, v))
    : modifyOptions(@(o) setValueForAll(o, v), $"{locId}&__all_elems__", changeStackTime)
  return ctor?(optCfg, value, setValueExt)
}

return {
  mkElemOption
  mkAllElemsOption
}
