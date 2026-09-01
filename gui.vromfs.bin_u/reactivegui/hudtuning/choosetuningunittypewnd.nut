from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/unitConst.nut" import unitTypeOrder
from "%rGui/components/debugWnd.nut" import closeButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/event/eventState.nut" import unitTypesByEvent
from "%rGui/hudTuning/cfgByUnitType.nut" import cfgByUnitType
from "%rGui/hudTuning/hudTuningState.nut" import tuningUnitType, isCurPresetChanged, saveCurrentTransform, openTuning
from "%rGui/style/backgrounds.nut" import bgShaded


const wndUid = "chooseTuningUnitType"
let close = @() removeModalWindow(wndUid)
let unitTypes = unitTypeOrder.filter(@(ut) ut in cfgByUnitType)

const gap = hdpx(10)

function changeUnitType(unitType) {
  close()
  if (unitType == tuningUnitType.get())
    return
  if (!isCurPresetChanged.get()) {
    openTuning(unitType)
    return
  }
  openMsgBox({
    text = loc("hudTuning/apply"),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "reset", cb = @() openTuning(unitType) }
      {
        text = loc("filesystem/btnSave")
        styleId = "PRIMARY"
        isDefault = true
        cb = function() {
          saveCurrentTransform()
          openTuning(unitType)
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
  children = [].extend(unitTypes, unitTypesByEvent.get().keys()).map(@(ut)
    (ut == tuningUnitType.get() ? textButtonCommon : textButtonPrimary)(
      utf8ToUpper(loc($"mainmenu/type_{ut}")),
      @() changeUnitType(ut),
      { ovr = { size = const [FLEX, hdpx(100)] } })
  )
}

return @() addModalWindow(bgShaded.__merge({
  key = wndUid
  size = FLEX
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close }]]
  children = {
    size = const [hdpx(700), SIZE_TO_CONTENT]
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
          { size = FLEX }
          closeButton(close)
        ]
      }
      content
    ]
  }
}))