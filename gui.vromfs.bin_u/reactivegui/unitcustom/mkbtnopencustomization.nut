from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/updater/addonsState.nut" import unitSizes
from "%rGui/components/textButton.nut" import mkCustomButton, buttonStyles, mergeStyles
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/unitCustom/unitCustomState.nut" import openUnitCustom
from "%rGui/unitCustom/unitDecals/unseenDecals.nut" import unseenDecals
from "%rGui/unitCustom/unitSkins/unseenSkins.nut" import unseenSkins
from "%rGui/updater/updaterState.nut" import openDownloadAddonsWnd


const iconSize = hdpxi(60)

let customizationBtnContent = {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      size = iconSize
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"ui/gameuiskin#skin_selection_icon.svg:{iconSize}:{iconSize}:P")
    }
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("unit/customization"))
    }.__update(fontBoldTinyAccentedShaded)
  ]
}

function mkBtnOpenCustomization(unitW, ovr) {
  let hasUnseenMark = Computed(function() {
    let { name = null, canShowOwnUnit = true } = unitW.get()
    return canShowOwnUnit
      && name in campMyUnits.get()
      && (name in unseenSkins.get() || unseenDecals.get().len() > 0)
  })
  return @() {
    watch = unitW
    children = !unitW.get() ? null : [
      mkCustomButton(customizationBtnContent,
        @() (unitSizes.get()?[unitW.get().name] ?? 0) == 0 ? openUnitCustom()
          : openDownloadAddonsWnd([], [unitW.get().name], "unitDownloadInfoBlock", {}, "openUnitCustom"),
        mergeStyles(buttonStyles.COMMON, ovr))
      @() {
        watch = hasUnseenMark
        margin = hdpx(10)
        hplace = ALIGN_RIGHT
        children = hasUnseenMark.get() ? priorityUnseenMark : null
      }
    ]
  }
}

eventbus_subscribe("openUnitCustom", @(_) openUnitCustom())

return mkBtnOpenCustomization