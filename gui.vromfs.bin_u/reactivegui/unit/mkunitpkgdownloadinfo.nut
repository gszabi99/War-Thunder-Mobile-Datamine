from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
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
  }.__update(fontTinyShaded, ovr)
}

function mkUnitPkgDownloadInfo(unitW, needProgress = true, ovr = {}) {
  let hasResources = Computed(@() unitW.get() == null || (unitSizes.get()?[unitW.get()?.name] ?? -1) == 0)
  let { halign = ALIGN_CENTER } = ovr
  return @() {
    watch = [hasResources, wantStartDownloadAddons, unitW]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = hasResources.get() || unitW.get() == null ? null
      : !isEqual(wantStartDownloadAddons.get()?.units, { [unitW.get().name] = true }, {})
        ? [
            textArea(loc("msg/needDownloadPackToShowUnit"), { halign })
            textButtonCommon(utf8ToUpper(loc("msgbox/btn_download")),
              @() openDownloadAddonsWnd([], [ unitW.get().name ], "unitDownloadInfoBlock"))
          ]
      : needProgress ? downloadInfoBlock
      : null
  }.__update(ovr)
}

return mkUnitPkgDownloadInfo
