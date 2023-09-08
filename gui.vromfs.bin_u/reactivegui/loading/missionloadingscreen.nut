from "%globalsDarg/darg_library.nut" import *
let { get_mp_session_id_int } = require("multiplayer")
let { curCampaign, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let helpShipParts = require("complexScreens/helpShipParts.nut")
let helpTankCaptureZone = require("complexScreens/helpTankCaptureZone.nut")
let helpTankControls = require("complexScreens/helpTankControls.nut")
let helpTankParts = require("complexScreens/helpTankParts.nut")
let { gradientLoadingTip } = require("mkLoadingTip.nut")
let { titleLogo, titleLogoSize } = require("%globalsDarg/components/titleLogo.nut")

let tanksScreensOrder = [ helpTankControls, helpTankParts, helpTankCaptureZone ]

//no need to subscribe on sharedStatsByCampaign because we do not want to switch loading screen during loading
let tanksScreen = @() get_mp_session_id_int() == -1 ? helpTankControls()
  : tanksScreensOrder[(sharedStatsByCampaign.value?.battles ?? 0) % tanksScreensOrder.len()]()

let mkBgImagesByCampaign = {
  ships = @() [
    helpShipParts
    gradientLoadingTip.__merge({ vplace = ALIGN_TOP, pos = [0, sh(82)] })
  ]
  tanks = @() [
    tanksScreen()
    gradientLoadingTip.__merge({ vplace = ALIGN_TOP, pos = [0, sh(82)] })
  ]
}

let bgImage = @() {
  watch = curCampaign
  size = flex()
  children = mkBgImagesByCampaign?[curCampaign.value]()
}

return {
  size = flex()
  children = [
    bgImage
    titleLogo.__merge({
      size = titleLogoSize.map(@(v) (0.7 * v + 0.5).tointeger())
      pos = saBorders
    })
  ]
}