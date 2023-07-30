from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { localizeAddonsLimited, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { openDownloadAddonsWnd, addonsToDownload } = require("%rGui/updater/updaterState.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { textButtonFaded } = require("%rGui/components/textButton.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")


let textArea = @(text, ovr = {}) {
  size = [saSize[0] - 2 * statsWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFD0D0D0
  text
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontTiny, ovr)

let function mkUnitPkgDownloadInfo(unitW, needProgress = true) {
  let reqPkgList = Computed(@() unitW.value == null ? []
    : getUnitPkgs(unitW.value.name, unitW.value.mRank).filter(@(a) !hasAddons.value?[a]))
  let isCurrentUnit = Computed(@() curUnit.value?.name == unitW.value?.name)
  return @() {
    watch = [reqPkgList, addonsToDownload]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = reqPkgList.value.len() == 0 ? null
      : reqPkgList.value.findvalue(@(a) a not in addonsToDownload.value) == null
        ? [
            @() !isCurrentUnit.value ? { watch = isCurrentUnit }
              : textArea(loc("msg/downloadPackToUseUnitOnline"), { watch = isCurrentUnit })
            needProgress ? downloadInfoBlock : null
          ]
      : [
          textArea(loc("msg/needDownloadPackToUseUnit", {
            pkg = localizeAddonsLimited(reqPkgList.value, 3)
            size = getAddonsSizeStr(reqPkgList.value)
          }))
          textButtonFaded(utf8ToUpper(loc("msgbox/btn_download")), @() openDownloadAddonsWnd(reqPkgList.value))
        ]
  }
}

return mkUnitPkgDownloadInfo

