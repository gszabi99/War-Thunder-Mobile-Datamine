from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { cfgByUnitType } = require("%rGui/hudTuning/cfgByUnitType.nut")
let { unitTypeOrder } = require("%appGlobals/unitConst.nut")
let { tuningUnitType, isCurPresetChanged, saveCurrentTransform } = require("%rGui/hudTuning/hudTuningState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { unitTypesByEvent } = require("%rGui/event/eventState.nut")


let wndUid = "chooseTuningUnitType"
let close = @() removeModalWindow(wndUid)
let unitTypes = unitTypeOrder.filter(@(ut) ut in cfgByUnitType)

let gap = hdpx(10)

function changeUnitType(unitType) {
  close()
  if (unitType == tuningUnitType.get())
    return
  if (!isCurPresetChanged.get()) {
    tuningUnitType.set(unitType)
    return
  }
  openMsgBox({
    text = loc("hudTuning/apply"),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "reset", cb = @() tuningUnitType.set(unitType) }
      {
        text = loc("filesystem/btnSave")
        styleId = "PRIMARY"
        isDefault = true
        cb = function() {
          saveCurrentTransform()
          tuningUnitType.set(unitType)
        }
      }
    ]
  })
}

let content = @() {
  watch = [tuningUnitType, unitTypesByEvent]
  size = FLEX_H
  padding = gap
  flow = FLOW_VERTICAL
  gap
  children = [].extend(unitTypes, unitTypesByEvent.get()).map(@(ut)
    (ut == tuningUnitType.get() ? textButtonCommon : textButtonPrimary)(
      utf8ToUpper(loc($"mainmenu/type_{ut}")),
      @() changeUnitType(ut),
      { ovr = { size = const [flex(), hdpx(100)] } })
  )
}

return @() addModalWindow(bgShaded.__merge({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close }]]
  children = {
    size = const [sh(65), SIZE_TO_CONTENT]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = 0xF01E1E1E
    flow = FLOW_VERTICAL
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("hudTuning/chooseUnitType")
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      content
    ]
  }
}))