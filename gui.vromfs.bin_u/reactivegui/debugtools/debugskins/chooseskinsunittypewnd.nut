from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
import "%rGui/components/modalPopupWnd.nut" as modalPopupWnd
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/style/backgrounds.nut" import bgShaded


const wndUid = "chooseSkinsUnitType"
let close = @() modalPopupWnd.remove(wndUid)

const gap = hdpx(10)

let content = @(unitTypes, curUnitType, onChange) {
  size = FLEX_H
  padding = gap
  flow = FLOW_VERTICAL
  gap
  children = unitTypes.map(@(ut)
    (ut == curUnitType ? textButtonCommon : textButtonPrimary)(
      utf8ToUpper(loc($"mainmenu/type_{ut}")),
      function() {
        close()
        onChange(ut)
      },
      { ovr = { size = const [FLEX, hdpx(100)] } })
  )
}

return @(targetRect, unitTypes, curUnitType, onChange) modalPopupWnd.add(targetRect, {
  uid = wndUid
  popupOffset = hdpx(20)
  hotkeys = [[btnBEscUp, close]]
  popupBg = bgShaded
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
        pos = const [hdpx(10), 0]
        rendObj = ROBJ_TEXT
        text = loc("hudTuning/chooseUnitType")
      }.__update(fontSmall)
      content(unitTypes, curUnitType, onChange)
    ]
  }
})