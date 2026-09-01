from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/attributes/attrWndTabs.nut" import contentMargin
from "%rGui/components/textButton.nut" import mkCustomButton, buttonStyles, mergeStyles, textButtonUnseenMargin
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/unit/hangarUnit.nut" import hangarUnitName
from "%rGui/unitMods/unitModsSlotsState.nut" import isHangarUnitHasWeaponSlots, openUnitModsSlotsWnd, mkListUnseenMods
from "%rGui/unitMods/unitModsState.nut" import openUnitModsWnd, mkMods
from "%rGui/unitMods/unseenBullets.nut" import mkUnseenUnitBullets
from "%rGui/unitMods/unseenMods.nut" import unseenCampUnitMods


const arsenalIconSize = hdpxi(80)

let mkArsenalBtnContent = {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = const [arsenalIconSize, arsenalIconSize]
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      image = Picture("ui/gameuiskin#arsenal.svg")
    }
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("mainmenu/btnArsenal"))
    }.__update(fontBoldTinyAccentedShaded)
  ]
}

return function(unit, styleOvr) {
  let unseenMods = mkListUnseenMods(unit)
  let mods = mkMods(unit)
  let hasButton = Computed(@() null != mods.get().findvalue(@(v) !v?.isHidden))
  let unseenUnitBullets = mkUnseenUnitBullets(hangarUnitName)
  let hasUnseenMarker = Computed(function() {
    let uName = hangarUnitName.get()
    if (isHangarUnitHasWeaponSlots.get())
      return unseenMods.get().len() > 0
    if (uName in unseenCampUnitMods.get())
      return true
    let { primary, secondary } = unseenUnitBullets.get()
    return primary.len() > 0 || secondary.len() > 0
  })
  let unseenMargin = Computed(@() isHangarUnitHasWeaponSlots.get() ? textButtonUnseenMargin
    : [textButtonUnseenMargin, textButtonUnseenMargin + contentMargin])
  return @() {
    watch = [hasButton, isHangarUnitHasWeaponSlots]
    children = !hasButton.get() ? null
      : [
          mkCustomButton(mkArsenalBtnContent,
            isHangarUnitHasWeaponSlots.get() ? openUnitModsSlotsWnd : openUnitModsWnd,
            mergeStyles(buttonStyles.COMMON, styleOvr))
          @() {
            watch = [hasUnseenMarker, unseenMargin]
            margin = unseenMargin.get()
            hplace = ALIGN_RIGHT
            children = hasUnseenMarker.get() ? priorityUnseenMark : null
          }
        ]
  }
}
