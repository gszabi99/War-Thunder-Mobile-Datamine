from "%globalsDarg/darg_library.nut" import *

require("%rGui/levelUp/debugLevelUp.nut")
require("%rGui/debriefing/debriefingWnd.nut")
require("%rGui/levelUp/levelUpWnd.nut")
require("%rGui/unitAttr/unitAttrWnd.nut")
require("%rGui/shop/shopWnd.nut")
require("%rGui/queue/queueWnd.nut")
require("%rGui/unit/debugUnits.nut")
require("%rGui/hudHints/hintsDebug.nut")
require("%rGui/loading/debugLoadingTips.nut")
require("%rGui/notifications/bqEvents.nut")
require("%rGui/notifications/benchmarkResult.nut")
require("%rGui/notifications/allowLimitedConnectionDownload.nut")
require("%rGui/notifications/negativeBalanceWarning.nut")
require("%rGui/account/notifyEmailRegistration.nut")
require("%rGui/hudHints/shipObstacleWarning.nut")
require("%rGui/hudHints/shipDeathTimer.nut")
require("%rGui/hudHints/leaveZoneTimer.nut")
require("%rGui/hudHints/debuffWarnngs.nut")
require("%rGui/hudHints/killStreakHint.nut")
require("%rGui/tutorial/tutorialWnd/tutorialWnd.nut")
require("%rGui/tutorial/startFirstBattleTutorial.nut")
require("%rGui/feedback/feedbackWnd.nut")
require("%rGui/login/suggestUpdateMsg.nut")
require("%rGui/updater/downloadAddonsWnd.nut")
require("weaponry/debugBullets.nut")
require("shop/unseenPurchaseMessage.nut")
require("shop/checkPurchases.nut")
require("shop/goodsPreview/goodsUnitPreviewWnd.nut")
require("shop/goodsPreview/goodsPremiumWnd.nut")
require("shop/goodsPreview/goodsCurrencyPreviewWnd.nut")
require("shop/offerAutoPreview.nut")
require("shop/autoOpenLootboxes.nut")
require("changelog/changelogWnd.nut")
require("ads/debugAdsWnd.nut")
require("debugTools/debugGamepadIconsWnd.nut")
require("unlocks/loginAwardWnd.nut")
require("unit/hangarUnitBattleData.nut")
require("%rGui/mainMenu/expirienceWnd.nut")

let { modalWindowsComponent } = require("%rGui/components/modalWindows.nut")
let { scenesOrder, getTopScene } = require("navState.nut")
let { behindScene } = require("behindScene.nut")
let { isInBattle, isInFlightMenu, isMpStatisticsActive
} = require("%appGlobals/clientState/clientState.nut")
let { isInRespawn } = require("%appGlobals/clientState/respawnStateBase.nut")
let { isInSpectatorMode, isInArtilleryMap } = require("%rGui/hudState.nut")
let { compToCompAnimations } = require("%darg/helpers/compToCompAnim.nut")
let mainMenuWnd = require("%rGui/mainMenu/mainMenuWnd.nut")
let respawnWnd = require("%rGui/respawn/respawnWnd.nut")
let hudSpectator = require("%rGui/hud/hudSpectator.nut")
let hudArtilleryMap = require("%rGui/hud/hudArtilleryMap.nut")
let flightMenu = require("%rGui/flightMenu/flightMenu.nut")
let mpStatisticsWnd = require("%rGui/mpStatistics/mpStatisticsWnd.nut")
let { needChooseMoveControlsType, chooseMoveControlsTypeWnd
} = require("%rGui/options/chooseMovementControls/chooseMovementControlsWnd.nut")
let hudBase = require("%rGui/hud/hudBase.nut")

let battleScene = @() {
  watch = [isInRespawn, isInSpectatorMode, isInArtilleryMap, isInFlightMenu,
    isMpStatisticsActive, needChooseMoveControlsType]
  key = {}
  size = flex()
  children = isInFlightMenu.value ? flightMenu
    : isMpStatisticsActive.value ? mpStatisticsWnd
    : isInSpectatorMode.value ? hudSpectator
    : isInRespawn.value ? respawnWnd
    : isInArtilleryMap.value ? hudArtilleryMap
    : needChooseMoveControlsType.value ? chooseMoveControlsTypeWnd
    : hudBase
}

return {
  size = flex()
  children = [
    behindScene
    @() {
      watch = [scenesOrder, isInBattle]
      size = flex()
      waitForChildrenFadeOut = true
      children = getTopScene(scenesOrder.value)
        ?? (isInBattle.value ? battleScene : mainMenuWnd)
    }
    modalWindowsComponent
    compToCompAnimations
  ]
}