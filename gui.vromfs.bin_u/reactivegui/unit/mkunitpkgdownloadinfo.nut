from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons, addonsSizes } = require("%appGlobals/updater/addonsState.nut")
let { localizeAddonsLimited, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { openDownloadAddonsWnd, addonsToDownload } = require("%rGui/updater/updaterState.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")


let textArea = @(text, ovr = {}) {
  size = [saSize[0] - 2 * statsWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = textColor
  text
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontTinyShaded, ovr)

function mkUnitPkgDownloadInfo(unitW, needProgress = true, ovr = {}) {
  let reqPkgList = Computed(@() unitW.get() == null || !isReadyToFullLoad.get() ? []
    : getUnitPkgs(unitW.value.name, unitW.value.mRank).filter(@(a) !hasAddons.value?[a]))
  let isCurrentUnit = Computed(@() curUnit.value?.name == unitW.value?.name)
  let { halign = ALIGN_CENTER } = ovr
  return @() {
    watch = [reqPkgList, addonsToDownload, addonsSizes]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = reqPkgList.value.len() == 0 ? null
      : reqPkgList.value.findvalue(@(a) a not in addonsToDownload.value) == null
        ? [
            @() !isCurrentUnit.value ? { watch = isCurrentUnit }
              : textArea(loc("msg/downloadPackToUseUnitOnline"), { watch = isCurrentUnit, halign })
            needProgress ? downloadInfoBlock : null
          ]
      : [
          textArea(
            loc("msg/needDownloadPackToUseUnit", {
              pkg = localizeAddonsLimited(reqPkgList.get(), 3)
              size = getAddonsSizeStr(reqPkgList.get(), addonsSizes.get())
            }),
            { halign })
          textButtonCommon(utf8ToUpper(loc("msgbox/btn_download")), @() openDownloadAddonsWnd(reqPkgList.value))
        ]
  }.__update(ovr)
}

return mkUnitPkgDownloadInfo

