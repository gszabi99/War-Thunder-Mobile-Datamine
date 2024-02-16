from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { mkGamercard } = require("%rGui/mainMenu/gamercard.nut")
let offerPromo = require("%rGui/shop/offerPromo.nut")
let { textButtonBattle, textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { translucentButtonsVGap } = require("%rGui/components/translucentButton.nut")
let { gamercardGap } = require("%rGui/components/currencyStyles.nut")
let { hangarUnit, setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { unitSpecificItems } = require("%appGlobals/unitSpecificItems.nut")
let { curUnit, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { mkPlatoonOrUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { btnOpenUnitAttr } = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let { firstBattleTutor, needFirstBattleTutor, startTutor } = require("%rGui/tutorial/tutorialMissions.nut")
let { isMainMenuAttached } = require("mainMenuState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { totalPlayers } = require("%appGlobals/gameModes/gameModes.nut")
let { curCampaign, campaignsList } = require("%appGlobals/pServer/campaign.nut")
let chooseCampaignWnd = require("chooseCampaignWnd.nut")
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
let { mkMRankRange } = require("%rGui/state/matchingRank.nut")
let squadPanel = require("%rGui/squad/squadPanel.nut")
let { isInSquad, isSquadLeader, isReady } = require("%appGlobals/squadState.nut")
let setReady = require("%rGui/squad/setReady.nut")
let { needReadyCheckButton, initiateReadyCheck, isReadyCheckSuspended } = require("%rGui/squad/readyCheck.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { btnOpenQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { specialEventGamercardItems, openEventWnd } = require("%rGui/event/eventState.nut")
let btnsOpenSpecialEvents = require("%rGui/event/btnsOpenSpecialEvents.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let bpBanner = require("%rGui/battlePass/bpBanner.nut")
let { openShopWnd } = require("%rGui/shop/shopState.nut")
let { SC_CONSUMABLES } = require("%rGui/shop/shopCommon.nut")
let showNoPremMessageIfNeed = require("%rGui/shop/missingPremiumAccWnd.nut")
let btnOpenUnitsTree = require("%rGui/unitsTree/btnOpenUnitsTree.nut")
let { mkDropMenuBtn } = require("%rGui/components/mkDropDownMenu.nut")
let { getTopMenuButtons, topMenuButtonsGenId } = require("%rGui/mainMenu/topMenuButtonsList.nut")
let { mkItemsBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let boostersListActive = require("%rGui/boosters/boostersListActive.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

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

let campaignsBtn = @() {
  watch = [campaignsList, curCampaign]
  children = campaignsList.value.len() <= 1 || curCampaign.value == null  ? null
    : framedImageBtn(getCampaignPresentation(curCampaign.value).icon, chooseCampaignWnd,
        {
          padding = [hdpx(0), hdpx(20), hdpx(0), hdpx(20) ]
          size = SIZE_TO_CONTENT
          sound = { click = "click" }
          imageSize = [hdpx(70) , hdpx(70)]
          flow = FLOW_HORIZONTAL
          gap = hdpx(20)
        },
        {
          size = [SIZE_TO_CONTENT, flex()]
          rendObj = ROBJ_TEXT
          valign = ALIGN_CENTER
          color = 0xFFFFFFFF
          text = loc("changeCampaignShort")
          fontFx = FFT_GLOW
          fontFxFactor = 64
          fontFxColor = Color(0, 0, 0)
        }.__update(fontTinyAccented)
      )
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

let dropMenuBtn = mkDropMenuBtn(getTopMenuButtons, topMenuButtonsGenId)

let gamercardPlace = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkGamercard(dropMenuBtn)
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      children = offerPromo
    }
  ]
}

let btnHorRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = translucentButtonsVGap
  children
}

let btnVerRow = @(children) {
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = translucentButtonsVGap
  children
}

let leftBottomButtons = btnVerRow([
  campaignsBtn
  bpBanner
  btnHorRow([
    btnOpenQuests
    btnsOpenSpecialEvents
  ])
  btnHorRow([
    btnVerRow([
      btnOpenUnitAttr
      btnOpenUnitsTree
    ])
    btnVerRow([
      onlineInfo
      downloadInfoBlock
    ])
  ])
])

let gamercardBattleItemsBalanceBtns = @(){
  watch = [itemsOrder, specialEventGamercardItems, unitSpecificItems]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gamercardGap
  children = specialEventGamercardItems.get().map(@(v) mkItemsBalance(v.itemId, @() openEventWnd(v.eventName)))
    .extend(itemsOrder.get().map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES))))
    .extend(unitSpecificItems.get().map(@(id) mkItemsBalance(id, @() openShopWnd(SC_CONSUMABLES))))
}

let queueCurRandomBattleMode = @() eventbus_send("queueToGameMode", { modeId = randomBattleMode.value?.gameModeId })

function startCurUnitOfflineBattle() {
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
    startTestFlight(curUnit.get())
  }
  else {
    let mission = chooseRandom(missions)
    log($"OflineStartBattle: start mission {mission} for {name}")
    sendNewbieBqEvent("pressToBattleButton", { status = "offline_battle", params = mission })
    startOfflineBattle(curUnit.get(), mission)
  }
}

let hotkeyX = ["^J:X | Enter"]
let battleBtnOvr = {
  ovr = {
    key = "toBattleButton"
    animations = [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.4, easing = CosineFull, play = true, delay = 2 }]
  }
  hotkeys = hotkeyX
}
let toBattleText = utf8ToUpper(loc("mainmenu/toBattle/short"))
let toBattleButton = textButtonBattle(toBattleText,
  function() {
    sendNewbieBqEvent("pressToBattleButton", { status = "online_battle", params = randomBattleMode.value?.name ?? "" })
    if (curUnit.value != null){
      showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.value, queueCurRandomBattleMode))
    }
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
    showNoPremMessageIfNeed(@() offerMissingUnitItemsMessage(curUnit.value, startCurNewbieMission))
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

let toBattleButtonPlace = @() {
  watch = [ needFirstBattleTutor, newbieOfflineMissions, isInSquad, isSquadLeader, isReady,
    needReadyCheckButton, isReadyCheckSuspended ]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  children = [
    {
      pos = [saBorders[0] * 0.5, 0]
      rendObj = ROBJ_9RECT
      image = gradTranspDoubleSideX
      padding = [ hdpx(24), saBorders[0] * 0.5, hdpx(12), saBorders[0] * 0.5 ]
      texOffs = [0 , gradDoubleTexOffset]
      screenOffs = [0, hdpx(70)]
      color = 0x50000000
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      children = [
        unitName
        gamercardBattleItemsBalanceBtns
        mkMRankRange
      ]
    }
    @(){
      watch = serverConfigs
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      children = [
        (serverConfigs.get()?.allBoosters.len() ?? 0) > 0 ? boostersListActive : null
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
  ]
}

let exitMsgBox = @() openMsgBox({
  text = loc("mainmenu/questionQuitGame")
  buttons = [
    { id = "cancel", isCancel = true }
    { text = loc("mainmenu/btnQuit"), styleId = "PRIMARY", cb = @() eventbus_send("exitGame", {}) }
  ]
})

let bottomCenterBlock = {
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    mkUnitPkgDownloadInfo(curUnit, false,
      { pos = [0, -evenPx(150) - translucentButtonsVGap] })
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
