from "%globalsDarg/darg_library.nut" import *
let { openUnitModsWnd, mkMods } = require("%rGui/unitMods/unitModsState.nut")
let { unseenCampUnitMods } = require("%rGui/unitMods/unseenMods.nut")
let { mkUnseenUnitBullets } = require("%rGui/unitMods/unseenBullets.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCustomButton, buttonStyles, mergeStyles, textButtonUnseenMargin } = require("%rGui/components/textButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { contentMargin } = require("%rGui/attributes/attrWndTabs.nut")
let { isHangarUnitHasWeaponSlots, openUnitModsSlotsWnd, mkListUnseenMods } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")


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
    }.__update(fontTinyAccentedShadedBold)
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
            children = hasUnseenMarker.get() ? priorityUnseenMark : null
          }
        ]
  }
}
