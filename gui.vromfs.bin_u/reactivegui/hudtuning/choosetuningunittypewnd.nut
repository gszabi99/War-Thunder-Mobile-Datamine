from "%globalsDarg/darg_library.nut" import *
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, textButtonBright } = require("%rGui/components/textButton.nut")
let cfgByUnitType = require("cfgByUnitType.nut")
let { unitTypeOrder } = require("%appGlobals/unitConst.nut")
let { tuningUnitType, isCurPresetChanged, saveCurrentTransform } = require("hudTuningState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndUid = "chooseTuningUnitType"
let close = @() removeModalWindow(wndUid)
let unitTypes = unitTypeOrder.filter(@(ut) ut in cfgByUnitType)

let gap = hdpx(10)

let function changeUnitType(unitType) {
  close()
  if (unitType == tuningUnitType.value)
    return
  if (!isCurPresetChanged.value) {
    tuningUnitType(unitType)
    return
  }
  openMsgBox({
    text = loc("hudTuning/apply"),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "reset", cb = @() tuningUnitType(unitType) }
      {
        text = loc("filesystem/btnSave")
        styleId = "PRIMARY"
        isDefault = true
        cb = function() {
          saveCurrentTransform()
          tuningUnitType(unitType)
        }
      }
    ]
  })
}

let content = @() {
  watch = tuningUnitType
  size = [flex(), SIZE_TO_CONTENT]
  padding = gap
  flow = FLOW_VERTICAL
  gap
  children = unitTypes.map(@(ut)
    (ut == tuningUnitType.value ? textButtonCommon : textButtonBright)(
      loc($"mainmenu/type_{ut}"),
      @() changeUnitType(ut),
      { ovr = { size = [flex(), hdpx(100)] } })
  )
}

return @() addModalWindow(bgShaded.__merge({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close }]]
  children = {
    size = [sh(65), SIZE_TO_CONTENT]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = 0xF01E1E1E
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
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