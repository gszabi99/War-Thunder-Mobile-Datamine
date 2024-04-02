from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let listbox = require("%rGui/components/listbox.nut")


let columnsMin = 1
let columnsMax = 3

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
  [OCT_LIST] = function(optCfg, options, modifyOptions) {
    let { getValue = null, setValue = null, locId = "", list = [], valToString = @(v) v } = optCfg
    if (getValue == null || setValue == null) {
      logerr($"Options: Missing value for option {optCfg?.locId}")
      return null
    }
    if (list.len() == 0)
      return null

    let value = Computed(@() getValue(options.get()))
    return optBlock(loc(locId),
      listbox({
        value,
        setValue = @(v) v == value.get() ? null : modifyOptions(@(o) setValue(o, v)),
        list,
        valToString,
        columns = clamp(list.len(), columnsMin, columnsMax)
      }))
  },
}

function mkElemOption(optCfg, options, modifyOptions) {
  let { ctrlType = null } = optCfg
  let ctor = optionCtors?[ctrlType]
  if (ctor == null)
    logerr($"Options: No creator for option ctrlType = {ctrlType}")
  return ctor?(optCfg, options, modifyOptions)
}

return mkElemOption
