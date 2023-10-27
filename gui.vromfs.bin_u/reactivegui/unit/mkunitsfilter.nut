from "%globalsDarg/darg_library.nut" import *
let { OCT_TEXTINPUT, OCT_MULTISELECT } = require("%rGui/options/optCtrlType.nut")
let { textInput } = require("%rGui/components/textInput.nut")

let textColor = 0xFFE1E1E1
let inactiveTextColor = 0xFF808080
let checkBorderColor = 0xFF9FA7AF
let ctrlHeight = hdpx(40)
let valueGap = hdpx(20)
let inputFullHeight = hdpx(60)
let inputPadding = [hdpx(10), hdpx(20)]
let checkIconSize = hdpx(60)

let mkCheckIcon = @(isChecked, isActive, opacity) {
  size = array(2, ctrlHeight)
  rendObj = ROBJ_BOX
  opacity = isActive ? 1.0 : 0.5
  borderColor = checkBorderColor
  borderWidth = hdpx(3)
  children = {
    size = array(2, checkIconSize)
    pos = [0.1 * checkIconSize, 0.05 * checkIconSize]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = isChecked ? Picture($"ui/gameuiskin#check.svg:{checkIconSize}:{checkIconSize}") : null
    keepAspect = KEEP_ASPECT_FIT
    color = textColor
    opacity
  }
}

let function mkCheckBtn(text, isChecked, hasValues, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [SIZE_TO_CONTENT, ctrlHeight]
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags(s)
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      mkCheckIcon(isChecked, hasValues, stateFlags.value & S_ACTIVE ? 0.5 : 1.0)
      {
        rendObj = ROBJ_TEXT
        color = hasValues ? textColor : inactiveTextColor
        text
      }.__update(fontSmall)
    ]
  }
}

let filterCtors = {
  [OCT_TEXTINPUT] = @(filter, _) textInput(filter.value, {
    ovr = {
      size = [flex(), inputFullHeight]
      padding = inputPadding
    }
    setValue = filter.setValue
    onAttach = @() set_kb_focus(filter.value) //hack for keyboard, and work only because single
  }),

  [OCT_MULTISELECT] = @(filter, width) wrap(
    filter.allValuesV.map(function(v) {
      let isChecked = filter.valueV == null || v in filter.valueV
      return mkCheckBtn(filter?.valToString(v) ?? v, isChecked, v in filter.hasValues,
        @() filter.toggleValue(v, !isChecked))
    }),
    { width, hGap = valueGap, vGap = valueGap }),
}

let mkFilter = @(filter, width) {
  key = filter?.id
  size = [width, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    {
      rendObj = ROBJ_TEXT
      color = inactiveTextColor
      text = loc(filter.locId)
    }.__update(fontTiny)
    filterCtors?[filter.ctrlType](filter, width)
  ]
}

let arrToTbl = @(list) list.reduce(function(res, v) {
  res[v] <- true
  return res
}, {})

let function mkUnitsFilter(options, allUnits, width) {
  local watch = [allUnits]
  foreach (o in options)
    watch.append(o?.value, o?.allValues)
  watch = watch.filter(@(w) w != null)

  return function() {
    local filtered = allUnits.value
    let filters = []
    foreach (opt in options) {
      if (opt.ctrlType == OCT_MULTISELECT && opt.allValues.value.len() < 2)
        continue

      let hasValues = "getUnitValue" not in opt ? null
        : arrToTbl(filtered.map(opt.getUnitValue))

      let value = opt.value.value
      if (value != null)
        filtered = filtered.filter(@(u) opt.isFit(u, value))

      filters.append(opt.__merge({
        valueV = value
        allValuesV = opt?.allValues.value
        hasValues
      }))
    }
    return {
      watch
      stopMouse = true
      flow = FLOW_VERTICAL
      gap = valueGap
      children = filters.map(@(f) mkFilter(f, width))
    }
  }
}

return mkUnitsFilter