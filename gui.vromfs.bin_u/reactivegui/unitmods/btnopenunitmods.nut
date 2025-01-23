from "%globalsDarg/darg_library.nut" import *
let { openUnitModsWnd, modsCategories } = require("unitModsState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCustomButton, buttonStyles, mergeStyles, textButtonUnseenMargin } = require("%rGui/components/textButton.nut")
let { unseenModsByCategory } = require("%rGui/unitMods/unitModsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { contentMargin } = require("%rGui/attributes/attrWndTabs.nut")
let { isHangarUnitHasWeaponSlots, openUnitModsSlotsWnd, mkListUnseenMods } = require("unitModsSlotsState.nut")

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
    }.__update(fontSmallShaded)
  ]
}

return function(unit, styleOvr) {
  let unseenMods = mkListUnseenMods(unit)
  let hasUnseenMarker = Computed(@() isHangarUnitHasWeaponSlots.get() ? unseenMods.get().len() > 0
    : unseenModsByCategory.get().len() > 0)
  let unseenMargin = Computed(@() isHangarUnitHasWeaponSlots.get() ? textButtonUnseenMargin
    : [textButtonUnseenMargin, textButtonUnseenMargin + contentMargin])
  return @() {
    watch = [modsCategories, isHangarUnitHasWeaponSlots]
    children = modsCategories.get().len() == 0 && !isHangarUnitHasWeaponSlots.get() ? null
      : [
          mkCustomButton(mkArsenalBtnContent,
            isHangarUnitHasWeaponSlots.get() ? openUnitModsSlotsWnd : openUnitModsWnd,
            mergeStyles(buttonStyles.PRIMARY, styleOvr))
          @() {
            watch = [hasUnseenMarker, unseenMargin]
            margin = unseenMargin.get()
            children = hasUnseenMarker.get() ? priorityUnseenMark : null
          }
        ]
  }
}
