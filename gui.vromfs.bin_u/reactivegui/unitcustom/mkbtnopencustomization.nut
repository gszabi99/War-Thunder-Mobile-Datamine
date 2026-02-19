from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { openUnitCustom } = require("%rGui/unitCustom/unitCustomState.nut")
let { unseenSkins } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { unseenDecals } = require("%rGui/unitCustom/unitDecals/unseenDecals.nut")


let iconSize = hdpxi(80)

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
    }.__update(fontTinyAccentedShadedBold)
  ]
}

let mkBtnOpenCustomization = @(unitW, ovr) @() {
  watch = unitW
  children = !unitW.get() ? null : [
    mkCustomButton(customizationBtnContent,
      @() (unitSizes.get()?[getTagsUnitName(unitW.get().name)] ?? 0) == 0 ? openUnitCustom()
        : openDownloadAddonsWnd([], [getTagsUnitName(unitW.get().name)], "unitDownloadInfoBlock", {}, "openUnitCustom"),
      mergeStyles(buttonStyles.COMMON, ovr))
    @() {
      watch = [unitW, unseenSkins, unseenDecals]
      margin = hdpx(10)
      hplace = ALIGN_RIGHT
      children = (unitW.get()?.name in unseenSkins.get() || unseenDecals.get().len() > 0) ? priorityUnseenMark : null
    }
  ]
}

eventbus_subscribe("openUnitCustom", @(_) openUnitCustom())

return mkBtnOpenCustomization