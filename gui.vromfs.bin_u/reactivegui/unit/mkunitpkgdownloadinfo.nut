from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { hasPackage, mkHasAllPackages } = require("%appGlobals/updater/hasPackage.nut")
let { localizeAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
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
  let reqPkgList = Computed(@() unitW.value == null ? [] : getUnitPkgs(unitW.value.name, unitW.value.mRank))
  let hasReqPkg = mkHasAllPackages(reqPkgList, true)
  let isCurrentUnit = Computed(@() curUnit.value?.name == unitW.value?.name)
  return @() {
    watch = [reqPkgList, hasReqPkg, addonsToDownload]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = hasReqPkg.value ? null
      : reqPkgList.value.findvalue(@(a) !hasPackage(a) && (a not in addonsToDownload.value)) == null
        ? [
            @() !isCurrentUnit.value ? { watch = isCurrentUnit }
              : textArea(loc("msg/downloadPackToUseUnitOnline"), { watch = isCurrentUnit })
            needProgress ? downloadInfoBlock : null
          ]
      : [
          textArea(loc("msg/needDownloadPackToUseUnit", {
            pkg = comma.join(localizeAddons(reqPkgList.value))
            size = getAddonsSizeStr(reqPkgList.value.filter(@(v) !hasPackage(v)))
          }))
          textButtonFaded(utf8ToUpper(loc("msgbox/btn_download")), @() openDownloadAddonsWnd(reqPkgList.value))
        ]
  }
}

return mkUnitPkgDownloadInfo

