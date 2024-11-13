from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { optionWidth } = require("hudTuningConsts.nut")
let listbox = require("%rGui/components/listbox.nut")
let { sliderWithButtons, sliderValueSound, sliderH, sliderBtnSize, sliderGap
} = require("%rGui/components/slider.nut")


let columnsMin = 1
let columnsMax = 5

let optBlock = @(header, content) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    header == null ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = header
        }.__update(fontSmall)
    content
  ]
}

let optionCtors = {
  [OCT_LIST] = function(optCfg, value, setValue) {
    let { locId = "", list = [], valToString = @(v) v } = optCfg
    if (list.len() == 0)
      return null

    return optBlock(loc(locId),
      listbox({
        value,
        setValue,
        list,
        valToString,
        columns = clamp(list.len(), columnsMin, columnsMax)
      }))
  },

  [OCT_SLIDER] = function(optCfg, value, setValue) {
    let { ctrlOverride = {}, locId = "", valToString = @(v) v } = optCfg
    return sliderWithButtons(value, loc(locId),
      ctrlOverride.__merge({
        size = [optionWidth - 2 * sliderBtnSize - 2 * sliderGap, sliderH]
        function onChange(v) {
          sliderValueSound()
          setValue(v, 1.0)
        }
      }),
      valToString)
  },
}

function mkElemOption(optCfg, elemId, options, modifyOptions) {
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
  let value = Computed(@() getValue(options.get(), elemId))
  let setValueExt = @(v, changeStackTime = 0) v == value.get() ? null
    : changeStackTime <= 0 ? modifyOptions(@(o) setValue(o, elemId, v))
    : modifyOptions(@(o) setValue(o, elemId, v), $"{locId}&{elemId}", changeStackTime)
  return ctor?(optCfg, value, setValueExt)
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
