from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { mkHasUnitsResources } = require("%appGlobals/updater/addonsState.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { openDownloadAddonsWnd, wantStartDownloadAddons } = require("%rGui/updater/updaterState.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")


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
  let unitNames = Computed(@() unitW.get() == null ? []
    : [unitW.get().name].extend(unitW.get()?.platoonUnits.map(@(pu) pu.name) ?? [])
        .map(getTagsUnitName))
  let hasResources = mkHasUnitsResources(unitNames)
  let { halign = ALIGN_CENTER } = ovr
  return @() {
    watch = [hasResources, wantStartDownloadAddons, unitNames]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = hasResources.get() || unitNames.get().len() == 0 ? null
      : !isEqual(wantStartDownloadAddons.get()?.units, unitNames.get().reduce(@(res, u) res.$rawset(u, true), {}))
        ? [
            textArea(loc("msg/needDownloadPackToShowUnit"), { halign })
            textButtonCommon(utf8ToUpper(loc("msgbox/btn_download")),
              @() openDownloadAddonsWnd([], unitNames.get(), "unitDownloadInfoBlock"))
          ]
      : needProgress ? downloadInfoBlock
      : null
  }.__update(ovr)
}

return mkUnitPkgDownloadInfo
