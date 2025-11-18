from "%globalsDarg/darg_library.nut" import *
let { number_of_set_bits, is_bit_set } = require("%sqstd/math.nut")
let { OCT_TEXTINPUT, OCT_MULTISELECT, OCT_MULTISELECT_MASK } = require("%rGui/options/optCtrlType.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { mkOvrTooltipContent } = require("%rGui/options/tooltipCtors.nut")

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
let MAX_CHECK_BUTTONS_IN_ROW = 15
let leftColWidth = (ctrlHeight + hGap) * MAX_CHECK_BUTTONS_IN_ROW - hGap

let mkCheckIcon = @(isChecked, isActive, opacity, inBoxValue) {
  size = ctrlHeight
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
    onElemState = @(s) stateFlags.set(s)
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
    onElemState = @(s) stateFlags.set(s)
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
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
      customValue ? mkCustomCheck(isChecked, hasValues, customValue)
        : mkCheckIcon(isChecked, hasValues, stateFlags.get() & S_ACTIVE ? 0.5 : 1.0, inBoxValue)
    ]
  }
}

function allToggleBtn(allValues, activeFiltersW, handleClick) {
  let stateFlags = Watched(0)

  let needMakeAllDisabled = Computed(function() {
    let total = allValues.len()
    let active = activeFiltersW.get()?.len() ?? allValues.len()
    let halfOfTotal = (total / 2).tointeger()

    return active > halfOfTotal
  })

  return @() {
    watch = [stateFlags, needMakeAllDisabled]
    behavior = Behaviors.Button
    onClick = @() handleClick(needMakeAllDisabled.get())
    onElemState = @(s) stateFlags.set(s)
    opacity = needMakeAllDisabled.get() ? 0.5 : 1
    children = {
      size = ctrlHeight
      rendObj = ROBJ_BOX
      borderColor = checkBorderColor
      borderWidth = hdpx(3)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      padding = inputPadding
      children = {
        size = [checkIconSize, checkIconSize]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#icon_filter_all.svg:{checkIconSize}:{checkIconSize}:P")
        keepAspect = true
      }
      transform = {
        scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1]
      }
    }
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
    onAttach = @() set_kb_focus(filter.value) 
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
    }).append(filter?.useAllToggle
        ? allToggleBtn(filter.allValuesV, filter.value, @(v) filter.toggleAllValues(v))
        : null),
    { width, hGap, vGap }),

  [OCT_MULTISELECT_MASK] = function(filter, width) {
    let res = []
    for (local i = 0; (1 << i) <= filter.allValuesV; i++) {
      if (is_bit_set(filter.allValuesV, i)) {
        let curBit = 1 << i
        let isChecked = filter.valueV == null || ((curBit & filter.valueV) != 0x0)
        res.append(mkCheckBtn(filter?.valToString(curBit) ?? curBit,
          isChecked,
          (curBit & filter.hasValues) != 0x0,
          @() filter.toggleValue(curBit, !isChecked),
          filter?.customValue(curBit),
          filter?.inBoxValue(curBit)))
      }
    }
    return wrap(res, { width, hGap, vGap })
  }
}

let mkFilter = @(filter) {
  key = filter?.id
  size = [leftColWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    {
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        !filter?.locId ? null
          : {
              rendObj = ROBJ_TEXT
              color = textColor
              text = loc(filter.locId)
            }.__update(fontTiny)
        !filter?.tooltipCtorId ? null
          : infoTooltipButton(mkOvrTooltipContent(filter.tooltipCtorId, filter.allValues),
              { flowOffset = hdpx(100) },
              { margin = [0, 0, hdpx(15), 0] })
      ]
    }
    filterCtors?[filter.ctrlType](filter, leftColWidth)
  ]
}

function mkUnitsFilter(options, allUnits, closeFilters, clearFilters, fillFilters) {
  local watch = [allUnits]
  foreach (o in options)
    watch.append(o?.value, o?.allValues)
  watch = watch.filter(@(w) w != null)

  return function() {
    local filtered = allUnits.get()
    let filters = []
    foreach (opt in options) {
      if (opt.ctrlType == OCT_MULTISELECT && opt.allValues.get().len() < 2)
        continue
      if (opt.ctrlType == OCT_MULTISELECT_MASK && number_of_set_bits(opt.allValues.get()) < 2)
        continue

      let hasValues = "getUnitValue" not in opt ? null
        : opt.ctrlType == OCT_MULTISELECT_MASK ? filtered.reduce(@(res, u) res | opt.getUnitValue(u), 0)
        : filtered.reduce(@(res, u) res.$rawset(opt.getUnitValue(u), true), {})

      let value = opt.value.get()
      if (value != null)
        filtered = filtered.filter(@(u) opt.isFit(u, value))

      filters.append(opt.__merge({
        valueV = value
        allValuesV = opt?.allValues.get()
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
          size = FLEX_V
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          halign = ALIGN_CENTER
          children = [
            mkFilterIcon(closeFilters, closeIconSize, "btn_close.svg")

            { size = flex() }

            {
              rendObj = ROBJ_TEXT
              text = loc("options/none")
            }.__update(fontTiny)
            mkFilterIcon(@() fillFilters(filters), clearIconSize, "btn_trash_return.svg")

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