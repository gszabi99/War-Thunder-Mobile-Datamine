from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkGamercard, gamercardItemsBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let { textButtonBattle, textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { translucentButton, translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { hangarUnit, setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curUnit, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let unitsWnd = require("%rGui/unit/unitsWnd.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let btnOpenUnitAttr = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { firstBattleTutor, needFirstBattleTutor, startTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { isMainMenuAttached } = require("mainMenuState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { totalPlayers } = require("%appGlobals/gameModes/gameModes.nut")
let { campaignsList, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let chooseCampaignWnd = require("chooseCampaignWnd.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { startTestFlight, startOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let downloadInfoBlock = require("%rGui/updater/downloadInfoBlock.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { newbieOfflineMissions, startCurNewbieMission } = require("%rGui/gameModes/newbieOfflineMissions.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { allow_players_online_info } = require("%appGlobals/permissions.nut")
let { lqTexturesWarningHangar } = require("%rGui/hudHints/lqTexturesWarning.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { curUnitMRankRange } = require("%rGui/state/matchingRank.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { isInSquad, isSquadLeader, isReady } = require("%appGlobals/squadState.nut")
let setReady = require("%rGui/squad/setReady.nut")
let { needReadyCheckButton, initiateReadyCheck, isReadyCheckSuspended } = require("%rGui/squad/readyCheck.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let btnOpenQuests = require("%rGui/quests/btnOpenQuests.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let eventBanner = require("%rGui/event/eventBanner.nut")


let unitNameStateFlags = Watched(0)

let mainMenuUnitToShow = keepref(Computed(function() {
  if (!isMainMenuAttached.value)
    return null
  return curUnit.value?.name
    ?? allUnitsCfg.value.reduce(@(res, unit) res == null || res.rank > unit.rank ? unit : res)?.name
}))

mainMenuUnitToShow.subscribe(@(unitId) unitId == null ? null : setHangarUnit(unitId))

let unitName = @() hangarUnit.value == null ? { watch = hangarUnit }
  : {
    watch = [hangarUnit, unitNameStateFlags]
    onElemState = @(sf) unitNameStateFlags(sf)
    behavior = Behaviors.Button
    flow = FLOW_HORIZONTAL
    gap = hdpx(24)
    onClick = @() unitDetailsWnd({ name = hangarUnit.value.name })
    children = [
      mkPlatoonOrUnitTitle(
        hangarUnit.value, {}, unitNameStateFlags.value & S_HOVER ? { color = hoverColor } : {})
      mkGradRank(hangarUnit.value.mRank)
    ]
  }

let campaignsBtnComp = translucentButton("ui/gameuiskin#campaign.svg",
  loc("changeCampaign"), chooseCampaignWnd)

let campaignsBtn = @() {
  watch = campaignsList
  margin = [hdpx(20), 0]
  children = campaignsList.value.len() <= 1 ? null
    : campaignsBtnComp
}

let onlineInfo = @() {
  watch = [totalPlayers, allow_players_online_info]
  rendObj = ROBJ_TEXT
  text = !allow_players_online_info.value || totalPlayers.value < 0
    ? null
    : loc("mainmenu/online_info/player_online", {
        playersOnline = totalPlayers.value
      })
  color = 0xD0D0D0D0
}.__update(fontVeryTinyShaded)

let gamercardPlace = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkGamercard
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        {
          pos = [0, hdpx(45)]
          children = [
            onlineInfo
            downloadInfoBlock
          ]
        }
        {
          flow = FLOW_VERTICAL
          gap = translucentButtonsVGap / 2
          hplace = ALIGN_RIGHT
          children = [
            offerPromo
            eventBanner
          ]
        }
      ]
    }
  ]
}

let curCampPresentation = Computed(@() getCampaignPresentation(curCampaign.value))
let leftBottomButtons = @() {
  watch = curCampPresentation
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = translucentButtonsVGap
  children = [
    campaignsBtn
    btnOpenQuests
    btnOpenUnitAttr
    translucentButton(curCampPresentation.value.icon, loc(curCampPresentation.value.unitsLocId),
      function() {
        unitsWnd()
        openLvlUpWndIfCan()
      })
  ]
}


let queueCurRandomBattleMode = @() send("queueToGameMode", { modeId = randomBattleMode.value?.gameModeId })

let function startCurUnitOfflineBattle() {
  if (curUnit.value == null) {
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = "no unit!!!" })
    return
  }
  let { name, campaign } = curUnit.value
  let missions = newbieGameModesConfig?[campaign]
    .reduce(@(res, cfg) res.extend(cfg?.offlineMissions ?? []), [])
    ?? []
  if (missions.len() == 0) {
    log($"OflineStartBattle: test flight, because no mission for campaign {campaign} ({name})")
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = "testflight" })
    startTestFlight(curUnit.value?.name)
  }
  else {
    let mission = chooseRandom(missions)
    log($"OflineStartBattle: start mission {mission} for {name}")
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = mission })
    startOfflineBattle(name, mission)
  }
}

let hotkeyX = ["^J:X | Enter"]
let battleBtnOvr = { ovr = { key = "toBattleButton" }, hotkeys = hotkeyX }
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))
let toBattleButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "online_battle", params = randomBattleMode.value?.name ?? "" })
    if (curUnit.value != null)
      offerMissingUnitItemsMessage(curUnit.value, queueCurRandomBattleMode)
    else if (!openLvlUpWndIfCan())
      logerr($"Unable to start battle because no units (unit in hangar = {hangarUnit.value?.name})")
  },
  battleBtnOvr)
let startTutorButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "tutorial" })
    startTutor(firstBattleTutor.value)
  },
  battleBtnOvr)
let startOfflineBattleButton = textButtonBattle(toBattleText,
  startCurUnitOfflineBattle,
  battleBtnOvr)
let startOfflineMissionButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = ", ".join(newbieOfflineMissions.value) })
    startCurNewbieMission()
  },
  battleBtnOvr)

let toSquadBattleButton = toBattleButton
let readyButton = textButtonBattle(utf8ToUpper(loc("mainmenu/btnReady")),
  @() setReady(true),
  { hotkeys = hotkeyX })
let notReadyButton = textButtonCommon(utf8ToUpper(loc("multiplayer/state/player_not_ready")),
  @() setReady(false),
  { hotkeys = hotkeyX })
let readyCheckText = utf8ToUpper(loc("squad/readyCheckBtn"))
let readyCheckButton = textButtonPrimary(readyCheckText, initiateReadyCheck, { hotkeys = hotkeyX })
let readyCheckButtonInactive = textButtonCommon(readyCheckText, initiateReadyCheck, { hotkeys = hotkeyX })

let mkMRankRange = @() curUnitMRankRange.value == null
  ? { watch = curUnitMRankRange }
  : {
      watch = curUnitMRankRange
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(12)
      children = [
        { rendObj = ROBJ_TEXT, text = loc("mainmenu/battleTiers") }.__update(fontTinyAccented)
        mkGradRank(curUnitMRankRange.value.minMRank)
        { rendObj = ROBJ_TEXT, text = "-" }.__update(fontTinyAccented)
        mkGradRank(curUnitMRankRange.value.maxMRank)
      ]
    }

let toBattleButtonPlace = @() {
  watch = [ needFirstBattleTutor, newbieOfflineMissions, isInSquad, isSquadLeader, isReady,
    needReadyCheckButton, isReadyCheckSuspended ]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      padding = [ hdpx(24), 0, hdpx(12), 0 ]
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(70)]
      color = 0x50000000
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        unitName
        gamercardItemsBalanceBtns
        mkMRankRange
      ]
    }
    needReadyCheckButton.value && isReadyCheckSuspended.value ? readyCheckButtonInactive
      : needReadyCheckButton.value ? readyCheckButton
      : isSquadLeader.value ? toSquadBattleButton
      : isInSquad.value && !isReady.value ? readyButton
      : isInSquad.value && isReady.value ? notReadyButton
      : isOfflineMenu ? startOfflineBattleButton
      : needFirstBattleTutor.value ? startTutorButton
      : newbieOfflineMissions.value != null ? startOfflineMissionButton
      : toBattleButton
  ]
}

let exitMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionQuitGame")
  buttons = [
    { id = "cancel", isCancel = true }
    { text = loc("mainmenu/btnQuit"), styleId = "PRIMARY", cb = @() send("exitGame", {}) }
  ]
})

let bottomCenterBlock = {
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(24)
  children = [
    mkUnitPkgDownloadInfo(curUnit, false)
    squadPanel
  ]
}

return {
  key = {}
  size = saSize
  behavior = Behaviors.HangarCameraControl
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  onAttach = @() isMainMenuAttached(true)
  onDetach = @() isMainMenuAttached(false)
  children = [
    lqTexturesWarningHangar
    gamercardPlace
    leftBottomButtons
    toBattleButtonPlace
    bottomCenterBlock
  ]
  animations = wndSwitchAnim
  hotkeys = [
    [btnBEscUp, {action=exitMsgBox}]
  ]
}
