from "%globalsDarg/darg_library.nut" import *

require("%rGui/levelUp/debugLevelUp.nut")
require("%rGui/debriefing/debriefingWnd.nut")
require("%rGui/levelUp/levelUpWnd.nut")
require("%rGui/attributes/unitAttr/unitAttrWnd.nut")
require("%rGui/attributes/slotAttr/slotAttrWnd.nut")
require("%rGui/unitMods/unitModsWnd.nut")
require("%rGui/unitMods/unitModsSlotsWnd.nut")
require("%rGui/unitsTree/unitsTreeWnd.nut")
require("%rGui/unitCustom/unitCustomWnd.nut")
require("slotBar/selectUnitToSlotWnd.nut")
require("slotBar/slotPresetsWnd.nut")
require("%rGui/quests/questsWnd.nut")
require("%rGui/quests/questRewardsWnd.nut")
require("%rGui/shop/shopWnd.nut")
require("%rGui/queue/queueWnd.nut")
require("%rGui/queue/queuePenaltyWnd.nut")
require("%rGui/unit/debugUnits.nut")
require("%rGui/hudHints/hintsDebug.nut")
require("%rGui/loading/debugLoadingTips.nut")
require("%rGui/notifications/bqEvents.nut")
require("%rGui/notifications/benchmarkResult.nut")
require("%rGui/notifications/allowLimitedConnectionDownload.nut")
require("%rGui/notifications/allowGameAutoUpdate.nut")
require("%rGui/notifications/negativeBalanceWarning.nut")
require("%rGui/notifications/suggestUpdateMsg.nut")
require("%rGui/notifications/suggestLinkEmailMsg.nut")
require("%rGui/notifications/logEventsAfterLogin.nut")
require("%rGui/notifications/levelUpAppsFlyerEvent.nut")
require("%rGui/notifications/infoPopupWnd.nut")
require("notifications/allowPushNotification.nut")
require("notifications/suggestUhqMsg.nut")
require("%rGui/account/notifyEmailRegistration.nut")
require("%rGui/account/emailLinkRewardState.nut")
require("%rGui/hudHints/shipObstacleWarning.nut")
require("%rGui/hudHints/shipDeathTimer.nut")
require("%rGui/hudHints/leaveZoneTimer.nut")
require("%rGui/hudHints/debuffWarnngs.nut")
require("%rGui/hudHints/killStreakHint.nut")
require("%rGui/hudHints/streakHint.nut")
require("hudTuning/hudTuningWnd.nut")
require("%rGui/tutorial/tutorialWnd/tutorialWnd.nut")
require("%rGui/tutorial/tutorialAfterFreeReward.nut")
require("%rGui/tutorial/tutorialUnitsResearch.nut")
require("%rGui/tutorial/tutorialArsenal.nut")
require("%rGui/tutorial/tutorialBattlePass.nut")
require("%rGui/tutorial/tutorialMainEvent.nut")
require("%rGui/tutorial/startFirstBattleTutorial.nut")
require("%rGui/tutorial/choosingShellsTutorial.nut")
require("%rGui/tutorial/tutorialSlotAttributes.nut")
require("%rGui/tutorial/tutorTreeEvent.nut")
require("%rGui/feedback/rateGameState.nut")
require("%rGui/updater/downloadAddonsWnd.nut")
require("%rGui/updater/backgroundContentUpdater.nut")
require("%rGui/report/reportPlayerWnd.nut")
require("weaponry/debugBullets.nut")
require("shop/unseenPurchaseMessage.nut")
require("shop/checkPurchases.nut")
require("shop/goodsPreview/goodsUnitPreviewWnd.nut")
require("shop/goodsPreview/goodsSkinPreviewWnd.nut")
require("shop/goodsPreview/goodsPremiumWnd.nut")
require("shop/goodsPreview/subscriptionWnd.nut")
require("shop/goodsPreview/goodsCurrencyPreviewWnd.nut")
require("shop/goodsPreview/goodsLootboxPreviewWnd.nut")
require("shop/goodsPreview/goodsSlotsPreviewWnd.nut")
require("shop/autoPreviewQueue.nut")
require("shop/autoOpenLootboxes.nut")
require("shop/lootboxOpenRouletteWnd.nut")
require("shop/lootboxPreviewWnd.nut")
require("shop/gifts.nut")
require("news/newsWnd.nut")
require("ads/debugAdsWnd.nut")
require("ads/adsPreloaderWnd.nut")
require("debugTools/pServerConsoleCmd.nut")
require("debugTools/debugGamepadIconsWnd.nut")
require("debugTools/debugHudSpam.nut")
require("debugTools/debugRewardPlateCompWnd.nut")
require("debugTools/debugStreakWnd.nut")
require("debugTools/debugFontsWnd.nut")
require("debugTools/debugSkins/debugTuneSkinsWnd.nut")
require("debugTools/debugMapPoints/mapEditorWnd.nut")
require("debugTools/debugOfflineBattleWnd.nut")
require("debugTools/debugLootboxWnd.nut")
require("debugTools/localAutoTests.nut")
require("unlocks/loginAwardWnd.nut")
require("unit/hangarUnitBattleData.nut")
require("%rGui/mainMenu/experienceWnd.nut")
require("%rGui/decorators/decoratorsScene.nut")
require("%rGui/battlePass/battlePassWnd.nut")
require("%rGui/battlePass/bpPurchaseWnd.nut")
require("%rGui/boosters/boostersPurchaseWnd.nut")
require("%rGui/notifications/consent/consentMainWnd.nut")
require("%rGui/notifications/consent/manageOptionsWnd.nut")
require("%rGui/notifications/consent/partnersWnd.nut")
require("%rGui/options/touchSenseOptConvert.nut")
require("%rGui/options/licenseWnd.nut")
require("options/chooseMovementControls/chooseMovementControlsWnd.nut")
require("contacts/contactsWnd.nut")
require("contacts/myContactPresence.nut")
require("invitations/invitationsWnd.nut")
require("squad/myExtData.nut")
require("event/eventWnd.nut")
require("event/buyEventCurrenciesWnd.nut")
require("event/profileUpdateOnSeasonEnd.nut")
require("event/gmEventWnd.nut")
require("event/treeEvent/treeEventWnd.nut")
require("leaderboard/lbWnd.nut")
require("leaderboard/lbBestBattlesWnd.nut")
require("debriefing/debrQuestsMgr.nut")
require("debriefing/debrUnitWeapons.nut")
require("%rGui/loading/loadingScreen.nut")
  .setMissionLoadingScreen(require("%rGui/loading/missionLoadingScreen.nut"))
require("%rGui/chat/mpChatHandler.nut")
require("levelUp/levelUpRewards.nut")
require("levelUp/unitLevelUpRewards.nut")
require("consoleCmdAfterLogin.nut")
require("%rGui/hud/indicators/missionIndicatorsMgr.nut")
require("unit/upgradeUnitWnd/unitUpgradeWnd.nut")
require("%rGui/dmViewer/modeXrayDebugExport.nut")
require("syncCurrencies.nut")


let { modalWindowsComponent } = require("%rGui/components/modalWindows.nut")
let { scenesOrder, getTopScene } = require("navState.nut")
let { behindScene } = require("behindScene.nut")
let { isInBattle, isInMpSession, isInFlightMenu, isMpStatisticsActive
} = require("%appGlobals/clientState/clientState.nut")
let { isInRespawn } = require("%appGlobals/clientState/respawnStateBase.nut")
let { isInSpectatorMode, isInArtilleryMap } = require("%rGui/hudState.nut")
let { compToCompAnimations } = require("%darg/helpers/compToCompAnim.nut")
let mainMenuWnd = require("%rGui/mainMenu/mainMenuWnd.nut")
let respawnWnd = require("%rGui/respawn/respawnWnd.nut")
let hudSpectator = require("%rGui/hud/hudSpectator.nut")
let hudArtilleryMap = require("%rGui/hud/hudArtilleryMap.nut")
let { isVoiceMsgMapSceneOpened, voiceMsgMapScene } = require("%rGui/hud/voiceMsg/hudVoiceMsgMapScene.nut")
let flightMenu = require("%rGui/flightMenu/flightMenu.nut")
let mpStatisticsWnd = require("%rGui/mpStatistics/mpStatisticsWnd.nut")
let hudBase = require("%rGui/hud/hudBase.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")

isInBattle.subscribe(@(v)
  sendNewbieBqEvent(v ? "enterBattle" : "leaveBattle", { status = isInMpSession.value ? "online" : "offline" }))

let battleScene = @() {
  watch = [isInRespawn, isInSpectatorMode, isInArtilleryMap, isInFlightMenu, isMpStatisticsActive, isVoiceMsgMapSceneOpened]
  key = {}
  size = flex()
  children = isInFlightMenu.value ? flightMenu
    : isMpStatisticsActive.value ? mpStatisticsWnd
    : isInSpectatorMode.value ? hudSpectator
    : isInRespawn.value ? respawnWnd
    : isInArtilleryMap.value ? hudArtilleryMap
    : isVoiceMsgMapSceneOpened.get() ? voiceMsgMapScene
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