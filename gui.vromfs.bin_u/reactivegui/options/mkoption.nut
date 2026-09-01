from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "dagor.workcycle" import resetTimeout
from "%sqstd/math.nut" import ceil
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/infoButton.nut" import infoGreyButton, infoTooltipButton
import "%rGui/components/listbox.nut" as listbox
from "%rGui/components/slider.nut" import sliderWithButtons, sliderValueSound
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/options/optionsStyle.nut" import contentWidth
from "%rGui/options/tooltipCtors.nut" import mkOvrTooltipContent
from "types" import Function, Array


const listMinWidth = hdpx(200)
const listMaxWidth = hdpx(600)
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
    valign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      {
        pos = const [hdpx(-70), 0]
        children = child
      }
      textComp
    ]
  }
}

let mkTooltipContentCtor = @(title, desc) @() "\n".concat(
  colorize("@darken", title),
  desc instanceof Function ? desc() : desc
)

let optBlock = @(header, content, openInfo, desc, locId, tooltipCtorId, ovr = {}) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  margin = const [0, 0, hdpx(20), 0]
  children = [
    mkHeader(header,
      openInfo != null ? infoGreyButton(openInfo, { size = [evenPx(50), evenPx(50)], color = 0x80000000 })
        : tooltipCtorId != null ? infoTooltipButton(mkOvrTooltipContent(tooltipCtorId), { flowOffset = hdpx(100) })
        : desc != "" ? infoTooltipButton(mkTooltipContentCtor(loc(locId), desc), { flowOffset = hdpx(100) })
        : null)
    content
  ]
}.__update(ovr)

let optionCtors = {
  [OCT_SLIDER] = function(opt) {
    let { value = null, ctrlOverride = {}, locId = "", valToString = @(v) v, setValue = null, onChangeValue = null, visible = null} = opt
    if (value == null) {
      logerr($"Options: Missing value for option {opt?.locId}")
      return null
    }
    let sendChangeValue = @() onChangeValue?(value.get())
    let isVisibleW = visible instanceof Watched ? visible : Watched(true)
    return @() !isVisibleW.get()
      ? { watch = isVisibleW }
      : {
          watch = isVisibleW
          padding = const [0, 0, hdpx(20)]
          children = sliderWithButtons(value, loc(locId),
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
            valToString).__update({minHeight = 0})
        }
  },

  [OCT_LIST] = function(opt) {
    let { value = null, setValue = null, onChangeValue = null, locId = "", list = [], valToString = @(v) v, openInfo = null,
      description = "", mkContentCtor = null, columnsMaxCustom = columnsMax, visible = null, tooltipCtorId = null } = opt
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
    let isVisibleW = visible instanceof Watched ? visible : Watched(true)
    let listW = list instanceof Watched ? list : Watched(list)
    let watch = [ isVisibleW, listW ]
    return @() !isVisibleW.get() || listW.get().len() == 0
      ? { watch }
      : optBlock(loc(locId),
          listbox({ value, list = listW.get(), valToString,
            setValue = sendChangeValue,
            columns = clamp(listW.get().len(), columnsMin, columnsMaxCustom),
            mkContentCtor
          }),
          openInfo, description, locId, tooltipCtorId,
          { watch })
  },

  [OCT_BUTTON] = function(opt) {
    let { locId = null, onClick = null, visible = null } = opt
    if (locId == null || onClick == null) {
      logerr($"Options: Missing locId or onClick for button option {locId}")
      return null
    }
    let isVisibleW = visible instanceof Watched ? visible : Watched(true)
    let watch = isVisibleW
    return @() !isVisibleW.get()
      ? { watch }
      : {
          watch
          hplace = ALIGN_LEFT
          margin = const [hdpx(30), 0]
          children = textButtonCommon(utf8ToUpper(loc(locId)), onClick,
            { childOvr = { size = const [hdpx(430), SIZE_TO_CONTENT], halign = ALIGN_CENTER } })
        }
  }
}

function mkOptionImpl(opt) {
  let { ctrlType = null, comp = null } = opt
  if (comp != null)
    return comp

  let ctor = optionCtors?[ctrlType]
  if (ctor == null)
    logerr($"Options: No creator for option ctrlType = {ctrlType}, comp = {comp}")
  return ctor?(opt)
}

function mkOption(opt) {
  if (opt instanceof Array)
    return {
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      children = opt.map(mkOptionImpl)
    }
  return mkOptionImpl(opt)
}

return mkOption
