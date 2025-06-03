from "%globalsDarg/darg_library.nut" import *

let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { getCampaignPkgsForNewbieSingle } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons, addonsSizes, addonsExistInGameFolder, addonsVersions } = require("%appGlobals/updater/addonsState.nut")
let { getModeAddonsInfo, allBattleUnits } = require("%appGlobals/updater/gameModeAddons.nut")
let { wantStartDownloadAddons } = require("%rGui/updater/updaterState.nut")
let { randomBattleMode, shouldStartNewbieSingleOnline } = require("%rGui/gameModes/gameModeState.nut")
let { newbieOfflineMissions } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let { statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")


let textArea = @(text, ovr = {}) {
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(50)]
  color = 0x90000000
  padding = [hdpx(5), hdpx(20)]
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

function mkUnitPkgForBattleDownloadInfo(ovr = {}) {
  let reqPkgList = Computed(function() {
    if ( isOfflineMenu || (newbieOfflineMissions.get() != null && !shouldStartNewbieSingleOnline.get())) {
      let unit = curUnit.get()
      return unit == null || !isReadyToFullLoad.get() ? []
        : getCampaignPkgsForNewbieSingle(curCampaign.get(), unit.mRank, [unit.name])
          .filter(@(v) !hasAddons.get()?[v])
    }
    return getModeAddonsInfo(
      randomBattleMode.get(),
      allBattleUnits.get(),
      serverConfigs.get(),
      hasAddons.get(),
      addonsExistInGameFolder.get(),
      addonsVersions.get()
    ).addonsToDownload
  })

  return @() {
    watch = [reqPkgList, wantStartDownloadAddons, addonsSizes]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(10)
    children = reqPkgList.get().len() == 0 || reqPkgList.get().findvalue(@(a) a not in wantStartDownloadAddons.get()) != null ? null
      : textArea(loc("msg/downloadPackToUseUnitOnline"))
  }.__update(ovr)
}

return mkUnitPkgForBattleDownloadInfo
