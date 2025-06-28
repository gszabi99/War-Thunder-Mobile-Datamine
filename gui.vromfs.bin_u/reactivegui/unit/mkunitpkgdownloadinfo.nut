from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons, addonsSizes } = require("%appGlobals/updater/addonsState.nut")
let { localizeAddonsLimited, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { openDownloadAddonsWnd, wantStartDownloadAddons } = require("%rGui/updater/updaterState.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")


let textArea = @(text, ovr = {}) {
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(50)]
  color = 0x90000000
  padding = const [hdpx(5), hdpx(20)]
  gap = hdpx(20)
  children = @() {
    size = [saSize[0] - 2 * statsWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = textColor
    halign = ALIGN_CENTER
    text
    fontFxColor = Color(0, 0, 0, 255)
    fontFxFactor = 50
    fontFx = FFT_GLOW
  }.__update(fontTinyShaded, ovr)
}

function mkUnitPkgDownloadInfo(unitW, needProgress = true, ovr = {}) {
  let reqPkgList = Computed(@() unitW.get() == null || !isReadyToFullLoad.get() ? []
    : getUnitPkgs(unitW.value.name, unitW.value.mRank).filter(@(a) !hasAddons.value?[a]))
  let { halign = ALIGN_CENTER } = ovr
  return @() {
    watch = [reqPkgList, wantStartDownloadAddons, addonsSizes]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = reqPkgList.value.len() == 0 ? null
      : isEqual(wantStartDownloadAddons.get(), reqPkgList.get().reduce(@(res, a) res.$rawset(a, true), {}))
        ? [
            needProgress ? downloadInfoBlock : null
          ]
      : [
          textArea(
            loc("msg/needDownloadPackToUseUnit", {
              pkg = localizeAddonsLimited(reqPkgList.get(), 3)
              size = getAddonsSizeStr(reqPkgList.get(), addonsSizes.get())
            }),
            { halign })
          textButtonCommon(utf8ToUpper(loc("msgbox/btn_download")),
            @() openDownloadAddonsWnd(reqPkgList.value, "unitDownloadInfoBlock"))
        ]
  }.__update(ovr)
}

return mkUnitPkgDownloadInfo
