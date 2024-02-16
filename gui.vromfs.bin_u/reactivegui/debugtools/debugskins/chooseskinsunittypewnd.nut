from "%globalsDarg/darg_library.nut" import *
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, textButtonBright } = require("%rGui/components/textButton.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")

let wndUid = "chooseSkinsUnitType"
let close = @() modalPopupWnd.remove(wndUid)

let gap = hdpx(10)

let content = @(unitTypes, curUnitType, onChange) {
  size = [flex(), SIZE_TO_CONTENT]
  padding = gap
  flow = FLOW_VERTICAL
  gap
  children = unitTypes.map(@(ut)
    (ut == curUnitType ? textButtonCommon : textButtonBright)(
      loc($"mainmenu/type_{ut}"),
      function() {
        close()
        onChange(ut)
      },
      { ovr = { size = [flex(), hdpx(100)] } })
  )
}

return @(targetRect, unitTypes, curUnitType, onChange) modalPopupWnd.add(targetRect, {
  uid = wndUid
  popupOffset = hdpx(20)
  hotkeys = [[btnBEscUp, close]]
  popupBg = bgShaded
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
        rendObj = ROBJ_TEXT
        text = loc("hudTuning/chooseUnitType")
      }.__update(fontSmall)
      content(unitTypes, curUnitType, onChange)
    ]
  }
})