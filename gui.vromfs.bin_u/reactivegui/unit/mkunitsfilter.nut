from "%globalsDarg/darg_library.nut" import *
let { OCT_TEXTINPUT, OCT_MULTISELECT } = require("%rGui/options/optCtrlType.nut")
let { textInput } = require("%rGui/components/textInput.nut")

let textColor = 0xFFFFFFFF
let inactiveTextColor = 0xFF808080
let checkBorderColor = 0xFF9FA7AF
let ctrlHeight = hdpx(80)
let vGap = hdpx(20)
let hGap = hdpx(15)
let inputFullHeight = hdpx(60)
let inputPadding = [hdpx(10), hdpx(20)]
let checkIconSize = hdpxi(60)
let closeIconSize = hdpxi(80)
let clearIconSize = hdpxi(50)
let leftColWidth = hdpx(1000)

let mkCheckIcon = @(isChecked, isActive, opacity, inBoxValue) {
  size = array(2, ctrlHeight)
  rendObj = ROBJ_BOX
  opacity = isActive && isChecked ? 1.0 : 0.5
  borderColor = checkBorderColor
  borderWidth = hdpx(3)
  children = !inBoxValue
    ? {
        size = array(2, checkIconSize)
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = isChecked ? Picture($"ui/gameuiskin#check.svg:{checkIconSize}:{checkIconSize}") : null
        keepAspect = KEEP_ASPECT_FIT
        color = textColor
        opacity
      }
  : {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = inBoxValue
    }
}

let mkCustomCheck = @(isChecked, isActive, customValue) {
  opacity = isActive && isChecked ? 1.0 : 0.4
  children = customValue
}

function mkFilterIcon(onClick, iconSize, img) {
  let stateFlags = Watched(0)
  let size = max(closeIconSize, clearIconSize)
  return @() {
    watch = stateFlags
    size = [size, size]
    rendObj = ROBJ_SOLID
    color = 0xFF303030
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags(s)
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    children = {
      size = [iconSize, iconSize]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{img}:{iconSize}:{iconSize}")
    }
  }
}

function mkCheckBtn(text, isChecked, hasValues, onClick, customValue = null, inBoxValue = null) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags(s)
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      (customValue || inBoxValue) ? null : {
        minWidth = ctrlHeight * 1.5
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = hasValues ? textColor : inactiveTextColor
        text
      }.__update(fontTiny)
      customValue
          ? mkCustomCheck(isChecked, hasValues, customValue)
        : mkCheckIcon(isChecked, hasValues, stateFlags.value & S_ACTIVE ? 0.5 : 1.0, inBoxValue)
    ]
  }
}

let filterCtors = {
  [OCT_TEXTINPUT] = @(filter, _) textInput(filter.value, {
    ovr = {
      size = [leftColWidth, inputFullHeight]
      padding = inputPadding
      fillColor = 0xFF606060
    }
    setValue = filter.setValue
    onAttach = @() set_kb_focus(filter.value) //hack for keyboard, and work only because single
  }),

  [OCT_MULTISELECT] = @(filter, width) wrap(
    filter.allValuesV.map(function(v) {
      let isChecked = filter.valueV == null || v in filter.valueV
      return mkCheckBtn(filter?.valToString(v) ?? v,
        isChecked,
        v in filter.hasValues,
        @() filter.toggleValue(v, !isChecked),
        filter?.customValue(v),
        filter?.inBoxValue(v))
    }),
    { width, hGap, vGap }),
}

let mkFilter = @(filter) {
  key = filter?.id
  size = [leftColWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    !filter.locId ? null : {
      rendObj = ROBJ_TEXT
      color = textColor
      text = loc(filter.locId)
    }.__update(fontTiny)
    filterCtors?[filter.ctrlType](filter, leftColWidth)
  ]
}

let arrToTbl = @(list) list.reduce(function(res, v) {
  res[v] <- true
  return res
}, {})

function mkUnitsFilter(options, allUnits, closeFilters, clearFilters) {
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
      flow = FLOW_HORIZONTAL
      gap = hdpx(50)
      children = [
        {
          flow = FLOW_VERTICAL
          gap = vGap
          children = [{
            hplace = ALIGN_CENTER
            rendObj = ROBJ_TEXT
            text = loc("filters")
          }.__update(fontSmall)]
            .extend(filters.map(@(f) mkFilter(f)))
        }
        {
          size = [SIZE_TO_CONTENT, flex()]
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          halign = ALIGN_CENTER
          children = [
            mkFilterIcon(closeFilters, closeIconSize, "btn_close.svg")

            { size = flex() }

            {
              rendObj = ROBJ_TEXT
              text = loc("options/clearIt")
            }.__update(fontTiny)

            mkFilterIcon(clearFilters, clearIconSize, "btn_trash.svg")
          ]
        }
      ]
    }
  }
}

return mkUnitsFilter