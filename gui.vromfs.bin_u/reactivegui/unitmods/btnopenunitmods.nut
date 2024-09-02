from "%globalsDarg/darg_library.nut" import *
let { openUnitModsWnd, modsCategories } = require("unitModsState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { unseenModsByCategory } = require("%rGui/unitMods/unitModsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { contentMargin } = require("%rGui/attributes/attrWndTabs.nut")
let { isHangarUnitHasWeaponSlots, openUnitModsSlotsWnd } = require("unitModsSlotsState.nut")

let arsenalIconSize = hdpxi(80)

let mkArsenalBtnContent = {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = [arsenalIconSize, arsenalIconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      image = Picture("ui/gameuiskin#arsenal.svg")
    }
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("mainmenu/btnArsenal"))
    }.__update(fontSmallAccentedShaded)
  ]
}

return @(styleOvr) @() {
  watch = [modsCategories, isHangarUnitHasWeaponSlots]
  children = modsCategories.value.len() == 0 && !isHangarUnitHasWeaponSlots.get() ? null
    : [
        mkCustomButton(mkArsenalBtnContent,
          isHangarUnitHasWeaponSlots.get() ? openUnitModsSlotsWnd : openUnitModsWnd,
          mergeStyles(buttonStyles.PRIMARY, styleOvr))
        @() {
          watch = unseenModsByCategory
          margin = [hdpx(20), hdpx(20) + contentMargin]
          children = unseenModsByCategory.value.len() == 0 ? null : priorityUnseenMark
        }
      ]
}
