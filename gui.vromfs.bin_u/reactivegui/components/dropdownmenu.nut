from "%globalsDarg/darg_library.nut" import *
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")

let defColor = 0xFFFFFFFF
let primaryColor = 0xD0000000
let secondaryColor = 0xFFE1E1E1

const OPTIONS_UID = "select_options"
let closeOptions = @() modalPopupWnd.remove(OPTIONS_UID)

let openSelectOptions = @(event, options, current, setValue, isVisible, valToString, ovr = {})
  modalPopupWnd.add(event.targetRect, {
    uid = OPTIONS_UID
    key = isVisible
    rendObj = ROBJ_BOX
    fillColor = primaryColor
    borderColor = secondaryColor
    borderWidth = hdpxi(1)
    popupValign = ALIGN_TOP
    popupHalign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = options.map(@(option) {
      size = FLEX_H
      padding = const [hdpx(30), hdpx(20)]
      rendObj = ROBJ_BOX
      behavior = Behaviors.Button
      vplace = ALIGN_CENTER
      fillColor = current == option ? defColor : null
      sound = { click = "click" }
      function onClick() {
        setValue(option)
        closeOptions()
      }
      children = {
        rendObj = ROBJ_TEXT
        color = current == option ? primaryColor : defColor
        text = valToString(option)
      }.__update(fontSmall)
    })
    hotkeys = [[btnBEscUp, closeOptions]]
    onAttach = @() isVisible.set(true)
    onDetach = @() isVisible.set(false)
  }.__merge(ovr))

function dropDownMenu(state, styles = {}) {
  let { values, currentOption, setValue, onAttach = @() null,
    onDetach = @() null, valToString = @(v) v } = state

  let { width = hdpx(780), height = hdpx(90), iconSize = evenPx(40) } = styles

  let stateFlags = Watched(0)
  let isOptionsVisible = Watched(false)
  return @() {
    watch = [stateFlags, currentOption, isOptionsVisible]
    key = state
    size = [width, height]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    borderWidth = hdpxi(1)
    fillColor = stateFlags.get() & S_ACTIVE ? 0x20000000 : 0x50000000
    borderColor = defColor
    padding = const [hdpx(10), hdpx(25)]
    behavior = Behaviors.Button
    onElemState = @(s) stateFlags.set(s)
    sound = { click = "click" }
    onClick = @(e) openSelectOptions(e, values, currentOption.get(), setValue,
      isOptionsVisible, valToString, { size = [width, SIZE_TO_CONTENT] })
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    onAttach
    onDetach
    children = [
      {
        rendObj = ROBJ_TEXT
        text = valToString(currentOption.get())
      }.__update(fontTinyAccented)
      {
        size = flex()
      }
      {
        size = [iconSize, iconSize]
        rendObj = ROBJ_IMAGE
        transform = {
          rotate = isOptionsVisible.get() ? 0 : 180
        }
        image = Picture($"ui/gameuiskin#spinnerListBox_arrow_up.svg:{iconSize}:{iconSize}:P")
      }
    ]
  }
}

return { dropDownMenu }